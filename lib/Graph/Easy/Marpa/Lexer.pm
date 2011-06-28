package Graph::Easy::Marpa::Lexer;

use strict;
use warnings;

use Graph::Easy::Marpa::Lexer::DFA;

use Hash::FieldHash ':all';

use IO::File;

use List::Compare;

use Log::Handler;

use OpenOffice::OODoc;

use Perl6::Slurp;

use Set::Array;
use Set::FA::Element;

use Text::CSV_XS;

fieldhash my %cooked_file  => 'cooked_file';
fieldhash my %description  => 'description';
fieldhash my %dfa          => 'dfa';
fieldhash my %graph_text   => 'graph_text';
fieldhash my %input_file   => 'input_file';
fieldhash my %items        => 'items';
fieldhash my %logger       => 'logger';
fieldhash my %maxlevel     => 'maxlevel';
fieldhash my %minlevel     => 'minlevel';
fieldhash my %report_items => 'report_items';
fieldhash my %report_stt   => 'report_stt';
fieldhash my %result       => 'result';
fieldhash my %stt_file     => 'stt_file';
fieldhash my %type         => 'type';

our $myself; # Is a copy of $self for functions called by Set::FA::Element.
our $VERSION = '0.90';

# --------------------------------------------------

sub _check_accept
{
	my($self, $value, $current, $state) = @_;

	my($this)                = $$current{name};
	my($tos)                 = $#{$$state{$this} };
	my($item)                = ${$$state{$this} }[$tos];
	$$item{accept}           = $value && ($value =~ /Yes/i) ? $$current{name} : 0;
	${$$state{$this} }[$tos] = $item;

} # End of _check_accept.

# --------------------------------------------------

sub _check_all_nexts
{
	my($self, $state) = @_;

	# Every state's next state must exist.

	my($item);
	my($next);

	for my $name (keys %$state)
	{
		for my $event_index (0 .. $#{$$state{$name} })
		{
			$item = ${$$state{$name} }[$event_index];
			$next = $$item{next_state};

			if (! $$state{$next})
			{
				die "State '$name'. The next state '$next' is not defined";
			}
		}
	}

} # End of _check_all_nexts;

# --------------------------------------------------

sub _check_csv_headings
{
	my($self, $doc) = @_;
	my($result)     = List::Compare -> new([grep{!/Interpretation|Regexp/} keys(%$doc)], [qw/Start Accept State Event Next Entry Exit/]);
	my(@unique)     = $result -> get_unique;
	my(@complement) = $result -> get_complement;

	if ($#unique >= 0)
	{
		die "Unexpected column heading(s) '" . join("', '", @unique) . "' in the CSV file";
	}

	if ($#complement >= 0)
	{
		die "Column heading(s) '" . join("', '", @complement) . "' not found in the CSV file";
	}

} # End of _check_csv_headings.

# --------------------------------------------------

sub _check_event
{
	my($self, $value, $current, $state) = @_;

	if (! defined $value)
	{
		die "Cell for state '$$current{current}' must contain an event";
	}

	# Every state's events must be unique.

	my($this) = $$current{name};

	my(%event);
	my($item);

	for my $event_index (0 .. $#{$$state{$this} })
	{
		$item = ${$$state{$this} }[$event_index];

		if ($$item{event} eq $value)
		{
			die "State '$this'. The event '$value' is not unique";
		}
	}

	push @{$$state{$this} },
	{
		entry      => '',
		event      => $value,
		exit       => '',
		next_state => '',
	};

} # End of _check_event.

# --------------------------------------------------

sub _check_function
{
	my($self, $value, $current, $state, $function) = @_;

	my($this)                = $$current{name};
	my($tos)                 = $#{$$state{$this} };
	my($item)                = ${$$state{$this} }[$tos];
	$$item{$function}        = $value;
	${$$state{$this} }[$tos] = $item;

} # End of _check_function.

# --------------------------------------------------

sub _check_next
{
	my($self, $value, $current, $state) = @_;

	my($this)                = $$current{name};
	my($tos)                 = $#{$$state{$this} };
	my($item)                = ${$$state{$this} }[$tos];
	$$item{next_state}       = $value;
	${$$state{$this} }[$tos] = $item;

} # End of _check_next.

# --------------------------------------------------

sub _check_ods_headings
{
	my($self, $doc) = @_;
	my(%heading)    =
		(
		 A1 => 'Start',
		 B1 => 'Accept',
		 C1 => 'State',
		 D1 => 'Event',
		 E1 => 'Next',
		 F1 => 'Entry',
		 G1 => 'Exit',
		);

	my($column, $coord, $cell);
	my($value);

	for $column (qw/A B C D E F G/)
	{
		$coord = "${column}1";
		$cell  = $doc -> getTableCell(0, $coord);
		$value = $doc -> getCellValue($cell);

		if (! $value || ($value ne $heading{$coord}) )
		{
			die "Cell '$cell' should contain '$heading{$cell}'";
		}
	}

} # End of _check_ods_headings.

# --------------------------------------------------

sub _check_state
{
	my($self, $value, $current, $state) = @_;

	if ($value)
	{
		$$current{name} = $$current{previous} = $value;
	}
	else
	{
		$$current{name} = $$current{previous};
	}

	$value = $$current{name};

	if (! $$state{$value})
	{
		$$state{$value} = [];
	}

} # End of _check_state.

# --------------------------------------------------

sub _generate_cooked_file
{
	my($self, $file_name) = @_;

	open(OUT, '>', $file_name) || die "Can't open(> $file_name): $!";

	print OUT qq|"key","value"\n|;

	my(%name) =
		(
		 attribute        => 'attr_name_id',
		 daisy_chain_node => 'daisy_chain_node',
		 edge             => 'edge_id',
		 group            => 'group_name_id',
		 node             => 'node_name_id',
		 pop_group        => 'pop_group',
		);
	my(%type) =
		(
		 attribute =>
		 {
			 prefix_1 => 'left_brace',
			 prefix_2 => ', {',
			 suffix_1 => 'right_brace',
			 suffix_2 => ', }',
		 },
		 class =>
		 {
			 prefix_1 => 'left_brace',
			 prefix_2 => ', {',
			 suffix_1 => 'right_brace',
			 suffix_2 => ', }',
		 },
		 class_attribute =>
		 {
			 prefix_1 => 'left_brace',
			 prefix_2 => ', {',
			 suffix_1 => 'right_brace',
			 suffix_2 => ', }',
		 },
		 edge =>
		 {
			 prefix => '',
			 suffix => '',
		 },
		 group =>
		 {
			 prefix => '',
			 suffix => '',
		 },
		 node =>
		 {
			 prefix_1 => 'left_bracket',
			 prefix_2 => ', [',
			 suffix_1 => 'right_bracket',
			 suffix_2 => ', ]',
		 },
		 pop_group =>
		 {
			 prefix => '',
			 suffix => '',
		 },
		 subclass =>
		 {
			 prefix_1 => 'left_brace',
			 prefix_2 => ', {',
			 suffix_1 => 'right_brace',
			 suffix_2 => ', }',
		 },
		);

	my($name);
	my($type);
	my($value);

	for my $item (@{$self -> items})
	{
		$name  = $$item{name};
		$type  = $$item{type};
		$value = $$item{value};

		print OUT $self -> justify($type{$type}{prefix_1}), "$type{$type}{prefix_2}\n" if ($type{$type}{prefix_1});
		print OUT $self -> justify($name{$type}), ", '$name'\n";

		if ($type eq 'attribute')
		{
			print OUT $self -> justify('colon'), ", :\n";
			print OUT $self -> justify('attr_value_id'), ", '$value'\n";
			print OUT $self -> justify('semi_colon'), ", ;\n";
		}

		print OUT $self -> justify($type{$type}{suffix_1}), "$type{$type}{suffix_2}\n" if ($type{$type}{suffix_1});
	}

	close OUT;

} # End of _generate_cooked_file.

# --------------------------------------------------

sub get_graph_from_command_line
{
	my($self) = @_;

	$self -> graph_text($self -> graph);

} # End of get_graph_from_command_line.

# --------------------------------------------------

sub get_graph_from_file
{
	my($self) = @_;
	my(@line) = slurp($self -> input_file, {chomp => 1});

	shift(@line) while ( ($#line >= 0) && ($line[0] =~ /^\s*#/) );

	$self -> log(debug => 'Graph file ' . $self -> input_file);
	$self -> graph_text(join('', @line) );

} # End of get_graph_from_file.

# --------------------------------------------------

sub _init
{
	my($self, $arg)     = @_;
	$$arg{cooked_file}  ||= ''; # Caller can set.
	$$arg{description}  ||= ''; # Caller can set.
	$$arg{dfa}          = '';
	$$arg{graph_text}   = '';
	$$arg{input_file}   ||= ''; # Caller can set.
	$$arg{items}        = Set::Array -> new;
	$$arg{logger}       = Log::Handler -> new;
	$$arg{maxlevel}     ||= 'info';  # Caller can set.
	$$arg{minlevel}     ||= 'error'; # Caller can set.
	$$arg{report_items} ||= 0;       # Caller can set.
	$$arg{report_stt}   ||= 0;       # Caller can set.
	$$arg{result}       = 0;
	$$arg{stt_file}     ||= '';    # Caller can set.
	$$arg{type}         ||= 'csv'; # Caller can set.
	$self               = from_hash($self, $arg);

	$self -> logger -> add
		(
		 screen =>
		 {
			 alias          => 'screen',
			 maxlevel       => $self -> maxlevel,
			 message_layout => '%m',
			 minlevel       => $self -> minlevel,
		 }
		);

	return $self;

} # End of _init.

# --------------------------------------------------

sub justify
{
	my($self, $s) = @_;
	my($width) = 16;

	return $s, ' ' x ($width - length $s);

} # End of justify.

# --------------------------------------------------

sub log
{
	my($self, $level, $s) = @_;

	$self -> logger -> $level($s);

} # End of log.

# --------------------------------------------------

sub new
{
	my($class, %arg) = @_;
	my($self)        = bless {}, $class;
	$self            = $self -> _init(\%arg);

	return $self;

}	# End of new.

# --------------------------------------------------

sub _process
{
	my($self, $start, $state) = @_;

	$self -> _check_all_nexts($state);
	$self -> dfa
		(
		 Graph::Easy::Marpa::Lexer::DFA -> new
		 (
		  graph_text => $self -> graph_text,
		  logger     => $self -> logger,
		  report_stt => $self -> report_stt,
		  state      => $state,
		  start      => $start,
		 )
		);
	$self -> result($self -> dfa -> run);
	$self -> items -> push($_) for @{$self -> dfa -> items};
	$self -> logger -> set_level(screen => {maxlevel => $self -> maxlevel, minlevel => $self -> minlevel});
	$self -> report if ($self -> report_items);
	$self -> dfa('');

	if ($self -> result == 0)
	{
		my($file_name) = $self -> cooked_file;

		$self -> _generate_cooked_file($file_name) if ($file_name);
	}

	# Return 0 for success and 1 for failure.

	return $self -> result;

} # End of _process.

# --------------------------------------------------

sub _process_csv_file
{
	my($self) = @_;
	my($doc)  = $self -> read_csv_file($self -> stt_file);

	$self -> _check_csv_headings($$doc[0]);

	my($accept);
	my($column, %current);
	my($start, %state);
	my($value);

	for my $item (@$doc)
	{
		# Skip blank lines, i.e. lines not containing an event in column D.

		next if (! $$item{Event});

		for $column (qw/Start Accept State Event Next Entry Exit/)
		{
			$value = $$item{$column};

			if ($column eq 'Start')
			{
				if ($value && ($value =~ /Yes/i) )
				{
					# If column Start is Yes, column State is the name of the start state.

					$start = $$item{State};
				}
			}
			elsif ($column eq 'Accept')
			{
				$accept = $value;
			}
			elsif ($column eq 'State')
			{
				$self -> _check_state($value, \%current, \%state);
			}
			elsif ($column eq 'Event')
			{
				$self -> _check_event($value, \%current, \%state);
				$self -> _check_accept($accept, \%current, \%state);
			}
			elsif ($column eq 'Next')
			{
				$self -> _check_next($value, \%current, \%state);
			}
			else # Entry, Exit. Warning: Change next line to match.
			{
				$self -> _check_function($value, \%current, \%state, $column eq 'Entry' ? 'entry' : 'exit');
			}
		}
	}

	if (! $state{$start})
	{
		die "Start state '$start' is not defined";
	}

	return $self -> _process($start, \%state);

} # End of _process_csv_file.

# --------------------------------------------------

sub _process_ods_file
{
	my($self)  = @_;
	my($doc)   = odfDocument(file => $self -> stt_file);
	my($table) = $doc -> normalizeSheet(0, 'full');

	$self -> _check_ods_headings($doc);

	# %current tells us what state we are processing.
	# %state tells us about states we have processed.

	my($accept);
	my($column, $coord, $cell, %current);
	my(@row);
	my($start, %state);
	my($value);

	for my $row (2 .. 2000)
	{
		# Skip blank lines, i.e. lines not containing an event in column D.

		@row = $doc -> getRowCells(0, $row - 1);

		next if (! $doc -> getCellValue($row[3]) );

		# Process columns:
		# o A => Start.
		# o B => Accept.
		# o C => State.
		# o D => Event.
		# o E => Next.
		# o F => Entry
		# o G => Exit.

		for $column (qw/A B C D E F G/)
		{
			$coord = "${column}$row";
			$cell  = $doc -> getTableCell(0, $coord);
			$value = $doc -> getCellValue($cell);

			#$self -> log(debug => "$coord => $value");

			if ($column eq 'A')
			{
				if ($value && ($value =~ /Yes/i) )
				{
					# If column A is Yes, column C is the name of the start state.

					$start = $doc -> getCellValue($row[2]);
				}
			}
			elsif ($column eq 'B')
			{
				$accept = $value;
			}
			elsif ($column eq 'C')
			{
				$self -> _check_state($value, \%current, \%state);
			}
			elsif ($column eq 'D')
			{
				$self -> _check_event($value, \%current, \%state);
				$self -> _check_accept($accept, \%current, \%state);
			}
			elsif ($column eq 'E')
			{
				$self -> _check_next($value, \%current, \%state);
			}
			else # F, G. Warning: Change next line to match.
			{
				$self -> _check_function($value, \%current, \%state, $column eq 'F' ? 'entry' : 'exit');
			}
		}
	}

	if (! $state{$start})
	{
		die "Start state '$start' is not defined";
	}

	return $self -> _process($start, \%state);

} # End of _process_ods_file.

# -----------------------------------------------

sub read_csv_file
{
	my($self, $file_name) = @_;
	my($csv) = Text::CSV_XS -> new({allow_whitespace => 1});
	my($io)  = IO::File -> new($file_name, 'r');

	$csv -> column_names($csv -> getline($io) );

	return $csv -> getline_hr_all($io);

} # End of read_csv_file.

# -----------------------------------------------

sub report
{
	my($self)   = @_;
	my($format) = '%4s  %-20s  %-20s';
	my(@item)   = $self -> items;

	$self -> log(info => sprintf($format, 'Item', 'Type', 'Name') );

	my($item);

	for my $i (0 .. $#item)
	{
		$item = $item[$i];

		$self -> log(info => sprintf($format, $$item{count}, $$item{type}, $$item{name} . ($$item{value} ? ":$$item{value}" : '') ) );
	}

	$self -> log(info => $self -> result ? 'Fail' : 'OK');

} # End of report.

# --------------------------------------------------

sub run
{
	my($self) = @_;

	if ($self -> description)
	{
		$self -> get_graph_from_command_line;
	}
	elsif ($self -> input_file)
	{
		$self -> get_graph_from_file;
	}
	else
	{
		die 'You must provide a graph either by -i or -g';
	}

	$self -> log(debug => 'State transition table: ' . $self -> stt_file);

	my($result) = 1; # Default to failure.

	if ($self -> type eq 'csv')
	{
		$result = $self -> _process_csv_file;
	}
	elsif ($self -> type eq 'ods')
	{
		$result = $self -> _process_ods_file;
	}
	else
	{
		die '-type must be one of csv or ods for the state transition table file';
	}

	# Return 0 for success and 1 for failure.

	return $result;

} # End of run.

# --------------------------------------------------

1;

=pod

=head1 NAME

L<Graph::Easy::Marpa::Lexer> - A Set::FA::Element-based lexer for Graph::Easy

=head1 Synopsis

See L<Graph::Easy::Marpa/Data and Script Interaction>.

=head1 Description

L<Graph::Easy::Marpa::Lexer> provides a L<Set:FA::Element>-based lexer for L<Graph::Easy>-style graph definitions.

=head1 Installation

Install L<Graph::Easy::Marpa> as you would for any C<Perl> module:

Run:

	cpanm Graph::Easy::Marpa

or run:

	sudo cpan Graph::Easy::Marpa

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($parser) = Graph::Easy::Marpa::Lexer -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Graph::Easy::Marpa::Lexer>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. graph()]):

=over 4

=item o cooked_file => $csv_file_name

This is the name of the file to write containing the tokens (items) output from L<Graph::Easy::Marpa::Lexer>.

This file can be input to L<Graph::Easy::Marpa::Parser>.

=item o description => '[node.1]<->[node.2]'

Specify a string for the graph definition.

You are strongly encouraged to surround this string with '...' to protect it from your shell.

See also the 'input_file' key to read the graph from a file.

The 'description' key takes precedence over the 'input_file' key.

=item o input_file => $graph_file_name

Read the graph definition from this file.

See also the 'graph' key to read the graph from the command line.

The whole file is slurped in as 1 graph.

The first lines of the file can start with /^\s*#/, and will be discarded as comments.

The 'description' key takes precedence over the 'input_file' key.

=item o maxlevel => $level

This option affects L<Log::Handler>. See L<Log::Handler::Levels>.

The default maxlevel is 'info'. A typical value is 'debug'.

=item o minlevel => $level

This option affects L<Log::Handler>. See L<Log::Handler::Levels>.

The default minlevel is 'error'.

No lower levels are used.

=item o report_items => $Boolean

Calls L</report()> to report, via the log, the items recognized by the state machine.

=item o report_stt => $Boolean

Calls Set::FA::Element.report(). Set min and max log levels to 'info' for this.

=item o stt_file => $stt_file_name

Specify which file contains the state transition table.

Default: data/default.stt.csv.

Possible is: data/default.stt.odt.

These 2 files are the same.

The type of this file must be specified by the 'type' key.

=item o type => $stt_file_type

Specify the type of the stt_file: csv for CSV, or ods for Open Office Calc spreadsheet.

Default is 'csv'.

This option must be used with the 'stt_file' key.

=back

See L<Graph::Easy::Marpa/Data and Script Interaction>.

=head1 Methods

=head2 cooked_file([$csv_file_name])

The [] indicate an optional parameter.

Get or set the name of the CSV file to write containing the tokens which can be parsed by L<Graph::Easy::Marpa::Parser>.

=head2 file([$file_name])

The [] indicate an optional parameter.

Get or set the name of the file the graph will be read from.

See L</get_graph_from_file()>.

=head2 get_graph_from_command_line()

If the caller has requested a graph be parsed from the command line, with the graph option to new(), get it now.

Called as appropriate by run().

=head2 get_graph_from_file()

If the caller has requested a graph be parsed from a file, with the file option to new(), get it now.

Called as appropriate by run().

=head2 graph([$graph])

The [] indicate an optional parameter.

Get or set the value of the L<Graph::Easy> graph definition string.

=head2 items()

Returns a object of type L<Set::Array>, which is an arrayref of items output by the state machine.

These items are I<not> the same as the arrayref of items returned by the items() method in
L<Graph::Easy::Marpa::Parser>, but they are the same as in L<Graph::Easy::Marpa::DFA>.

See L<Graph::Easy::Marpa::DFA/items()> for details.

=head2 log($level, $s)

Calls $self -> logger -> $level($s).

=head2 logger()

Returns a object of type L<Log::Handler>.

=head2 maxlevel([$level])

The [] indicate an optional parameter.

Get or set the value of the logger's maxlevel option.

=head2 minlevel([$level])

The [] indicate an optional parameter.

Get or set the value of the logger's minlevel option.

=head2 read_csv_file($file_name)

Read the named CSV file into ann arrayref of hashrefs.

=head2 report()

Report, via the log, the list of items recognized by the state machine.

=head2 report_items([0 or 1])

The [] indicate an optional parameter.

Get or set the value which determines whether or not to report the items recognised by the state machine.

=head2 report_stt([0 or 1])

The [] indicate an optional parameter.

Get or set the value which determines whether or not to report the parsed state transition table (STT).

=head2 run()

This is the only method the caller needs to call. All parameters are supplied to new().

Returns 0 for success and 1 for failure.

=head2 stt_file([$stt_file_name])

The [] indicate an optional parameter.

Get or set the name of the file containing the state transition table.

This option is used in conjunction with the type() option.

=head2 type([$type])

The [] indicate an optional parameter.

Get or set the value which determines what type of stt_file is read.

=head1 Machine-Readable Change Log

The file CHANGES was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Graph::Easy::Marpa>.

=head1 Author

L<Graph::Easy::Marpa> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2011.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2011, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
