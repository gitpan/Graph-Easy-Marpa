package Graph::Easy::Marpa::Lexer;

use strict;
use warnings;

use Data::Section::Simple 'get_data_section';

use Graph::Easy::Marpa::Lexer::DFA;

use Hash::FieldHash ':all';

use IO::File;

use List::Compare;

use Log::Handler;

use Module::Load;

use Perl6::Slurp;

use Set::Array;
use Set::FA::Element;

use Text::CSV_XS;

use Try::Tiny;

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
fieldhash my %timeout      => 'timeout';
fieldhash my %tokens       => 'tokens';
fieldhash my %type         => 'type';

our $myself; # Is a copy of $self for functions called by Set::FA::Element.
our $VERSION = '1.01';

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
	my($self, $stt) = @_;
	my($result)     = List::Compare -> new([grep{!/Interpretation|Regexp/} keys(%$stt)], [qw/Start Accept State Event Next Entry Exit/]);
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
	my($self, $stt) = @_;
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
		$cell  = $stt -> getTableCell(0, $coord);
		$value = $stt -> getCellValue($cell);

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

	for my $item (@{$self -> tokens})
	{
		print OUT $self -> justify($$item[0]), ", $$item[1]\n";
	}

	close OUT;

} # End of _generate_cooked_file.

# --------------------------------------------------

sub _generate_cooked_tokens
{
	my($self) = @_;
	my(%name) =
		(
		 attribute        => 'attribute_name_id',
		 class            => 'class',
		 class_attribute  => 'class_attribute_name_id',
		 daisy_chain_node => 'daisy_chain_node',
		 edge             => 'edge_id',
		 node             => 'node_id',
		 pop_subgraph     => 'pop_subgraph',
		 push_subgraph    => 'push_subgraph',
		);
	my(%type) =
		(
		 attribute =>
		 {
			 prefix_1 => 'left_brace',
			 prefix_2 => '{',
			 suffix_1 => 'right_brace',
			 suffix_2 => '}',
		 },
		 class =>
		 {
			 prefix_1 => '',
			 prefix_2 => '',
			 suffix_1 => '',
			 suffix_2 => '',
		 },
		 class_attribute =>
		 {
			 prefix_1 => 'left_brace',
			 prefix_2 => '{',
			 suffix_1 => 'right_brace',
			 suffix_2 => '}',
		 },
		 edge =>
		 {
			 prefix_1 => '',
			 prefix_2 => '',
			 suffix_1 => '',
			 suffix_2 => '',
		 },
		 node =>
		 {
			 prefix_1 => 'left_bracket',
			 prefix_2 => '[',
			 suffix_1 => 'right_bracket',
			 suffix_2 => ']',
		 },
		 pop_group =>
		 {
			 prefix_1 => '',
			 prefix_2 => '',
			 suffix_1 => '',
			 suffix_2 => '',
		 },
		 push_subgraph =>
		 {
			 prefix_1 => '',
			 prefix_2 => '',
			 suffix_1 => '',
			 suffix_2 => '',
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
	my($type, @token);
	my($value);

	for my $item (@{$self -> items})
	{
		$name  = $$item{name};
		$type  = $$item{type};
		$value = $$item{value};

		push @token, [$type{$type}{prefix_1}, $type{$type}{prefix_2}] if ($type{$type}{prefix_1});
		push @token, [$name{$type}, "'$name'"];

		if ($type =~ /^(class_|)attribute/)
		{
			push @token, ['colon', ':'];
			push @token, ['attribute_value_id', "'$value'"];
			push @token, ['semi_colon', ';'];
		}

		push @token, [$type{$type}{suffix_1}, $type{$type}{suffix_2}] if ($type{$type}{suffix_1});
	}

	$self -> tokens(\@token);

} # End of _generate_cooked_tokens.

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

	$self -> log(debug => 'Graph file: ' . $self -> input_file);
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
	my($user_logger)    = defined($$arg{logger}); # Caller can set (e.g. to '').
	$$arg{logger}       = $user_logger ? $$arg{logger} : Log::Handler -> new;
	$$arg{maxlevel}     ||= 'info';  # Caller can set.
	$$arg{minlevel}     ||= 'error'; # Caller can set.
	$$arg{report_items} ||= 0;       # Caller can set.
	$$arg{report_stt}   ||= 0;       # Caller can set.
	$$arg{result}       = 0;
	$$arg{stt_file}     ||= ''; # Caller can set.
	$$arg{timeout}      ||= 3;  # Caller can set.
	$$arg{tokens}       = [];
	$$arg{type}         ||= ''; # Caller can set.
	$self               = from_hash($self, $arg);

	if (! $user_logger)
	{
		$self -> logger -> add
			(
			 screen =>
			 {
				 maxlevel       => $self -> maxlevel,
				 message_layout => '%m',
				 minlevel       => $self -> minlevel,
			 }
			);
	}

	return $self;

} # End of _init.

# --------------------------------------------------

sub justify
{
	my($self, $s) = @_;
	my($width)    = 24;

	return $s . ' ' x ($width - length $s);

} # End of justify.

# --------------------------------------------------

sub log
{
	my($self, $level, $s) = @_;

	$self -> logger -> $level($s) if ($self -> logger);

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

	$self -> log(debug => 'Graph text: ' . $self -> graph_text);

	my($died) = '';

	try
	{
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

		local $SIG{ALRM} = sub{$died = 'DFA timed out'; die};

		alarm $self -> timeout;

		$self -> result($self -> dfa -> run);
	}
	catch
	{
		# Don't overwrite $died if set due to the alarm.

		$died = $_ if (! $died);
	};

	alarm 0;

	if ($died)
	{
		$self -> log(error => $died);
		$self -> result(1);
	}

	if ($self -> result == 0)
	{
		$self -> items -> push(@{$self -> dfa -> items});
		$self -> renumber_items;
		$self -> report if ($self -> report_items);
		$self -> _generate_cooked_tokens;

		my($file_name) = $self -> cooked_file;

		$self -> _generate_cooked_file($file_name) if ($file_name);
	}

	$self -> log(info => $self -> result ? 'Fail' : 'OK');

	# Return 0 for success and 1 for failure.

	return $self -> result;

} # End of _process.

# --------------------------------------------------

sub _process_csv_file
{
	my($self, $stt) = @_;

	$self -> _check_csv_headings($$stt[0]);

	my($accept);
	my($column, %current);
	my($start, %state);
	my($value);

	for my $item (@$stt)
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

	load OpenOffice::OODoc;

	my($stt)   = odfDocument(file => $self -> stt_file);
	my($table) = $stt -> normalizeSheet(0, 'full');

	$self -> _check_ods_headings($stt);

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

		@row = $stt -> getRowCells(0, $row - 1);

		next if (! $stt -> getCellValue($row[3]) );

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
			$cell  = $stt -> getTableCell(0, $coord);
			$value = $stt -> getCellValue($cell);

			#$self -> log(debug => "$coord => $value");

			if ($column eq 'A')
			{
				if ($value && ($value =~ /Yes/i) )
				{
					# If column A is Yes, column C is the name of the start state.

					$start = $stt -> getCellValue($row[2]);
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

sub read_internal_file
{
	my($self)   = @_;
	my($stt)    = get_data_section('stt');
	my(@stt)    = split(/\n/, $stt);
	my($csv)    = Text::CSV_XS -> new({allow_whitespace => 1});
	my($status) = $csv -> parse(shift @stt);

	if (! $status)
	{
		die 'Unable to read STT headers from __DATA__';
	}

	my(@column_name) = $csv -> fields;

	my(@field);
	my($i);
	my(%line);
	my(@row);

	for my $line (@stt)
	{
		$status = $csv -> parse($line);

		if (! $status)
		{
			die "Unable to read STT line '$line' from __DATA__";
		}

		@field = $csv -> fields;
		%line  = ();

		for $i (0 .. $#column_name)
		{
			$line{$column_name[$i]} = $field[$i];
		}

		push @row, {%line};
	}

	return \@row;

} # End of read_internal_file.

# -----------------------------------------------

sub renumber_items
{
	my($self)  = @_;
	my(@item)  = @{$self -> items};
	my($count) = 0;

	my(@new);

	for my $item (@item)
	{
		$$item{count} = ++$count;

		push @new, $item;
	}

	$self -> items(Set::Array -> new(@new) );

} # End of renumber_items.

# -----------------------------------------------

sub report
{
	my($self)   = @_;
	my($format) = '%4s  %-20s  %-20s';

	$self -> log(info => sprintf($format, 'Item', 'Type', 'Name') );

	for my $item ($self -> items -> print)
	{
		$self -> log(info => sprintf($format, $$item{count}, $$item{type}, $$item{name} . ($$item{value} ? ":$$item{value}" : '') ) );
	}

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

	my($result) = 1; # Default to failure.

	if (! $self -> type)
	{
		$result = $self -> _process_csv_file($self -> read_internal_file);
	}
	elsif ($self -> type eq 'csv')
	{
		$result = $self -> _process_csv_file($self -> read_csv_file($self -> stt_file) );
	}
	elsif ($self -> type eq 'ods')
	{
		$result = $self -> _process_ods_file;
	}
	else
	{
		die "type must be one of '', 'csv' or 'ods' for the state transition table file";
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

=item o logger => $logger_object

Specify a logger object.

To disable logging, just set logger to the empty string.

The default value is an object of type L<Log::Handler>.

This logger is passed to L<Graph::Easy::Marpa::Lexer::DFA>.

=item o maxlevel => $level

This option is only used if L<Graph::Easy::Marpa:::Lexer> or L<Graph::Easy::Marpa::Parser>
create an object of type L<Log::Handler>. See L<Log::Handler::Levels>.

The default 'maxlevel' is 'info'. A typical value is 'debug'.

=item o minlevel => $level

This option is only used if L<Graph::Easy::Marpa:::Lexer> or L<Graph::Easy::Marpa::Parser>
create an object of type L<Log::Handler>. See L<Log::Handler::Levels>.

The default 'minlevel' is 'error'.

No lower levels are used.

=item o report_items => $Boolean

Calls L</report()> to report, via the log, the items recognized by the state machine.

=item o report_stt => $Boolean

Calls Set::FA::Element.report(). Set min and max log levels to 'info' for this.

=item o stt_file => $stt_file_name

Specify which file contains the state transition table.

Default: ''.

The default value means the STT is read from the source code of Graph::Easy::Marpa::Lexer.

Candidate files are '', 'data/default.stt.csv' and 'data/default.stt.ods'.

The type of this file must be specified by the 'type' key.

Note: If you use stt_file => your.stt.ods and type => 'ods', L<Module::Load>'s load() will be used to
load L<OpenOffice::OODoc>. This module is no longer listed in Build.PL and Makefile.PL as a pre-req,
so you will need to install it manually.
 
=item o type => $stt_file_type

Specify the type of the stt_file: '' for internal, csv for CSV, or ods for Open Office Calc spreadsheet.

Default is ''.

The default value means the STT is read from the source code of Graph::Easy::Marpa::Lexer.

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

=head2 input_file([$graph_file_name])

Here, the [] indicate an optional parameter.

Get or set the name of the file to read the graph definition from.

See also the description() method.

The whole file is slurped in as 1 graph.

The first lines of the file can start with /^\s*#/, and will be discarded as comments.

The value supplied to the description() method takes precedence over the value read from the input file.

=head2 items()

Returns a object of type L<Set::Array>, which is an arrayref of items output by the state machine.

See the L</FAQ> for details.

=head2 log($level, $s)

Calls $self -> logger -> $level($s).

=head2 log($level, $s)

Calls $self -> logger -> $level($s).

=head2 logger([$logger_object])

Here, the [] indicate an optional parameter.

Get or set the logger object.

To disable logging, just set logger to the empty string.

This logger is passed to L<Graph::Easy::Marpa::Lexer::DFA>.

=head2 maxlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

This option is only used if L<Graph::Easy::Marpa:::Lexer> or L<Graph::Easy::Marpa::Parser>
create an object of type L<Log::Handler>. See L<Log::Handler::Levels>.

=head2 minlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

This option is only used if L<Graph::Easy::Marpa:::Lexer> or L<Graph::Easy::Marpa::Parser>
create an object of type L<Log::Handler>. See L<Log::Handler::Levels>.

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

=head2 timeout($seconds)

The [] indicate an optional parameter.

Get or set the timeout for how long to run the DFA.

=head2 tokens()

Returns an arrayref of cooked tokens. Each element of this arrayref is an arrayref of 2 elements:

=over 4

=item o The type of the token

=item o The value of the token

=back

If you provide an output file by using the cooked_file option to new(), or the cooked_file() method,
the tokens written to that file are exactly the same as the tokens returned by tokens().

E.g.: If the cooked file looks like:

	"key","value"
	left_bracket       , [
	node_name_id       , 'Murrumbeena'
	right_bracket      , ]
	left_brace         , {
	attribute_name_id  , 'color'
	colon              , :
	attribute_value_id , 'blue'
	semi_colon         , ;
	right_brace        , }
	...

then the arrayref will contain:

	['left_bracket',       '[']
	['node_name_id',       'Murrumbeena']
	['right_bracket',      ']']
	['left_brace',         '{']
	['attribute_name_id',  'color']
	['colon',              ':']
	['attribute_value_id', 'blue']
	['semi_colon',         ';']
	['right_brace',        '}']
	...

If you look at the source code for the run() method in L<Graph::Easy::Marpa>, you'll see this arrayref can be
passed directly as the value of the tokens key in the call to L<Graph::Easy::Marpa::Parser>'s new().

=head2 type([$type])

The [] indicate an optional parameter.

Get or set the value which determines what type of stt_file is read.

=head1 FAQ

=head2 Where are the functions named in the STT?

In L<Graph::Easy::Marpa::Lexer::DFA>.

=head2 How is the lexed or parsed graph stored in RAM?

Items are stored in an arrayref. This arrayref is available via the L</items()> method.

These items are the same as the arrayref of items returned by the items() method in
L<Graph::Easy::Marpa::Parser>, and the same as in L<Graph::Easy::Marpa::Lexer::DFA>.

Each element in the array is a hashref, listed here in alphabetical order by type.

Note: Items are numbered from 1 up.

=over 4

=item o Attributes

The attribute name must match /^[a-z][a-z0-9_]*$/.

The attribute value is everything up to the next ';' or '}'.

The name and value are separated by a ':'.

An attribute can belong to a graph, node or an edge. An attribute definition of
'{color: red;}' would produce a hashref of:

	{
	count => $n,
	name  => 'color',
	type  => 'attribute',
	value => 'red',
	}

An attribute definition of '{color: red; shape: circle;}' will produce 2 hashrefs,
i.e. 2 sequential elements in the arrayref:

	{
	count => $n,
	name  => 'color',
	type  => 'attribute',
	value => 'red',
	}

	{
	count => $n,
	name  => 'shape',
	type  => 'attribute',
	value => 'circle',
	}

Attribute hashrefs appear in the arrayref immediately after the item (edge, group, node) to which they belong.
For groups, this means they appear straight after the hashref whose type is 'pop_subgraph'.

=item o Classes and class attributes

These notes apply to the 4 class names, /^(?:edge|graph|group|node)$/, and all their subclasses.

Note: It does not make sense for a class of 'graph' to have any subclasses.

A class definition of 'edge {color: white}' would produce 2 hashrefs:

	{
	count => $n,
	name  => 'edge',
	type  => 'class_name',
	value => '',
	}

	{
	count => $n,
	name  => 'color',
	type  => 'attribute',
	value => 'white',
	}

A class definition of 'node.green {color: green; shape: square}' would produce 3 hashrefs:

	{
	count => $n,
	name  => 'node.green',
	type  => 'class_name',
	value => '',
	}

	{
	count => $n,
	name  => 'color',
	type  => 'attribute',
	value => 'green',
	}

	{
	count => $n,
	name  => 'shape',
	type  => 'attribute',
	value => 'square',
	}

Class and class attribute hashrefs always appear at the start of the arrayref of items.

=item o Edges

An edge definition of '->' would produce a hashref of:

	{
	count => $n,
	name  => '->',
	type  => 'edge',
	value => '',
	}

=item o Nodes

A node definition of '[Name]' would produce a hashref of:

	{
	count => $n,
	name  => 'Name',
	type  => 'node',
	value => '',
	}

A node can have a definition of '[]', which means it has no name. Such node are called anonymous (or
invisible) because while they take up space in the output stream, they have no printable or visible
characters in the output stream. See L<Graph::Easy> for details.

Each anonymous node will have at least these 2 attributes:

	{
	count => $n,
	name  => 'color',
	type  => 'attribute',
	value => 'invis',
	}

	{
	count => $n,
	name  => 'label',
	type  => 'attribute',
	value => '',
	}

You can of course give your anonymous nodes any attributes, but they will be forced to have
these 2 attributes.

Node names are case-sensitive.

=item o Subgraphs

A group produces 2 hashrefs, one at the start of the group, and one at the end.

A group defnition of '(Solar system: [Mercury] -> [Neptune])' would produce a hashref like this at the start,
i.e. when the '(' - just before 'Solar' - is detected in the input stream:

	{
	count => $n,
	name  => 'Solar system',
	type  => 'push_subgraph',
	value => '',
	}

and a hashref like this at the end, i.e. when the ')' - just after '[Neptune]' - is detected:

	{
	count => $n,
	name  => 'Solar system',
	type  => 'pop_subgraph',
	value => '',
	}

=back

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

__DATA__

@@ stt
"Start","Accept","State","Event","Next","Entry","Exit","Regexp","Interpretation"
"Yes",,"global","(?:edge|global|graph|group|node)(?:\.[a-z]+)?","class",,"save_class_name","[a-z]+\s*:","Attribute name"
,,,"(?:->|--)","start_edge",,,"[^}]+}","Attribute value"
,,,"\(","start_group",,,"(?:edge|global|graph|group|node)(?:\.[a-z]+)?","Class name"
,,,"\[","start_node",,,"(?:->|--)","Edge name"
,,,"\s+","global",,,"[a-zA-Z_][a-zA-Z_0-9]*","Event name"
,,,,,,,"[a-zA-Z_.][a-zA-Z_0-9. ]*:","Group name"
,,,,,,,"[^\]]*]","Node name"
,,"class",",","daisy_chain_class","validate_class_name",,"[a-zA-Z_][a-zA-Z_0-9]*","State name"
,,,"{","start_class_attribute",,,,
,,,"\(","start_group",,,"[a-zA-Z_0-9. ]","Real node name"
,,,"\[","start_node",,,,
,,,"(?:->|--)","start_edge",,,,
,,,"\s+","class",,,,
,,,,,,,,
,,"start_class_attribute","[a-z]+\s*:","class_attribute_value",,"save_class_attribute_name",,
,,,,,,,,
,,"class_attribute_value","[^}]+}","post_class_attribute","validate_class_attribute_name","save_class_attribute_value",,
,,,,,,,,
,,"daisy_chain_class","(?:edge|global|graph|group|node)(?:\.[a-z]+)?","class",,"save_class_name",,
,,,"\s+","daisy_chain_class",,,,
,,,,,,,,
,,"post_class_attribute","(?:edge|global|graph|group|node)(?:\.[a-z]+)?","class","validate_class_attribute_value","save_class_name",,
,,,"\(","start_group",,,,
,,,"\[","start_node",,,,
,,,"(?:->|--)","start_edge",,,,
,,,"\s+","post_class_attribute",,,,
,,,,,,,,
,,"start_group","[a-zA-Z_.][a-zA-Z_0-9. ]*:","group","push_group","save_group_name",,
,,,"(?:->|--)","start_edge",,,,
,,,"\)","post_group",,,,
,,,"\s+","start_group",,,,
,,,,,,,,
,,"group","(?:edge|global|graph|group|node)(?:\.[a-z]+)?","class","validate_group_name",,,
,,,"\[","start_node",,,,
,,,"(?:->|--)","start_edge",,,,
,,,"\s+","group",,,,
,,,,,,,,
,"Yes","post_group","{","start_attribute","pop_group",,,
,,,"\[","start_node",,,,
,,,"\(","start_group",,,,
,,,"(?:->|--)","start_edge",,,,
,,,"\s+","post_group",,,,
,,,,,,,,
,"Yes","start_node","[^\]]*]","post_node",,"save_node_name",,
,,,"\s+","start_node",,,,
,,,,,,,,
,"Yes","post_node","{","start_attribute","validate_node_name",,,
,,,"\(","start_group",,,,
,,,"\)","post_group",,,,
,,,"\[","start_node",,,,
,,,"(?:->|--)","start_edge",,,,
,,,",","daisy_chain_node",,,,
,,,"\s+","post_node",,,,
,,,,,,,,
,,"start_attribute","[a-z]+\s*:","attribute_value",,"save_attribute_name",,
,,,"\s+","start_attribute",,,,
,,,,,,,,
,,"attribute_value","[^}]+}","post_attribute","validate_attribute_name","save_attribute_value",,
,,,,,,,,
,"Yes","post_attribute","\(","start_group","validate_attribute_value",,,
,,,"\)","post_group",,,,
,,,"\[","start_node",,,,
,,,"(?:->|--)","start_edge",,,,
,,,",","post_attribute",,,,
,,,"\s+","post_attribute",,,,
,,,,,,,,
,"Yes","start_edge","{","start_attribute","save_edge_name","validate_edge_name",,
,,,"\(","start_group",,,,
,,,"\)","post_group",,,,
,,,"\[","start_node",,,,
,,,",","daisy_chain_edge",,,,
,,,"\s+","start_edge",,,,
,,,,,,,,
,"Yes","daisy_chain_node","\[","start_node",,,,
,,,"\s+","daisy_chain_node",,,,
,,,,,,,,
,"Yes","daisy_chain_edge","(?:->|--)","start_edge",,,,
,,,"\s+","daisy_chain_edge",,,,
