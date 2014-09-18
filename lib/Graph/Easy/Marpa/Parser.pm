package Graph::Easy::Marpa::Parser;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

# The next line is mandatory, else
# the action names cannot be resolved.

use Graph::Easy::Marpa::Actions;

use Log::Handler;

use Marpa::R2;

use Moo;

use Set::Array;

use Text::CSV;

use Try::Tiny;

has description =>
(
	default  => sub{return ''},
	is       => 'rw',
#	isa      => 'Str',
	required => 0,
);

has grammar =>
(
	default  => sub{return ''},
	is       => 'rw',
#	isa      => 'Marpa::R2::Scanless::G',
	required => 0,
);

has graph_text =>
(
	default  => sub{return ''},
	is       => 'rw',
#	isa      => 'Str',
	required => 0,
);

has input_file =>
(
	default  => sub{return ''},
	is       => 'rw',
#	isa      => 'Str',
	required => 0,
);

has items =>
(
	default  => sub{return ''},
	is       => 'rw',
#	isa      => 'Set::Array',
	required => 0,
);

has logger =>
(
	default  => sub{return undef},
	is       => 'rw',
#	isa      => 'Str',
	required => 0,
);

has maxlevel =>
(
	default  => sub{return 'info'},
	is       => 'rw',
#	isa      => 'Str',
	required => 0,
);

has minlevel =>
(
	default  => sub{return 'error'},
	is       => 'rw',
#	isa      => 'Str',
	required => 0,
);

has recce =>
(
	default  => sub{return ''},
	is       => 'rw',
#	isa      => 'Marpa::R2::Scanless::R',
	required => 0,
);

has report_tokens =>
(
	default  => sub{return 0},
	is       => 'rw',
#	isa      => 'Int',
	required => 0,
);

has subgraph_name =>
(
	default  => sub{return {} },
	is       => 'rw',
#	isa      => 'String',
	required => 0,
);

has token_file =>
(
	default  => sub{return ''},
	is       => 'rw',
#	isa      => 'Str',
	required => 0,
);

our $VERSION = '2.05';

# ------------------------------------------------

sub attribute_list
{
	my($self, $attribute_list) = @_;
	my(@char)          = split(//, $attribute_list);
	my($inside_name)   = 1;
	my($inside_value)  = 0;
	my($quote)         = '';
	my($name)          = '';
	my($previous_char) = '';

	my($char);
	my(%attribute);
	my($key);
	my($value);

	for my $i (0 .. $#char)
	{
		$char = $char[$i];

		# Name matches /^[a-zA-Z_]+$/.

		if ($inside_name)
		{
			next if ($char =~ /\s/);

			if ($char eq ':')
			{
				$self -> log(debug => "Attribute name: $name");

				$inside_name = 0;
				$key         = $name;
				$name        = '';
			}
			elsif ($char =~ /[a-zA-Z_]/)
			{
				$name .= $char;
			}
			else
			{
				die "The char '$char' is not allowed in the names of attributes\n";
			}
		}
		elsif ($inside_value)
		{
			if ($char eq $quote)
			{
				# Get out of quotes if matching one found.
				# But, ignore an escaped quote.
				# The first 2 backslashes are just to fix syntax highlighting in UltraEdit.

				if ($char =~ /[\"\']/)
				{
					if ($previous_char ne '\\')
					{
						$quote = '';
					}
				}
				else
				{
					if ( (substr($value, 0, 2) eq '<<') && ($i > 0) && ($char[$i - 1]) eq '>')
					{
						$quote = '';
					}
					elsif ( (substr($value, 0, 1) eq '<') && (substr($value, 1, 1) ne '<') && ($previous_char ne '\\') )
					{
						$quote = '';
					}
				}

				$value .= $char;
			}
			elsif ( ($char eq ';') && ($quote eq '') )
			{
				if ($previous_char eq '\\')
				{
					$value .= $char;
				}
				else
				{
					$attribute{$key} = $value;

					$self -> log(debug => "Attribute value: $value");

					$inside_name  = 1;
					$inside_value = 0;
					$quote        = '';
					$key          = '';
					$value        = '';
				}
			}
			else
			{
				$value .= $char;
			}
		}
		else # After name and ':' but before label.
		{
			next if ($char =~ /\s/);

			$inside_value = 1;
			$value        = $char;

			# Look out for quotes, amd make '<' match '>'.
			# The backslashes are just to fix syntax highlighting in UltraEdit.
			# Also, this being the 1st char in the value, there can't be a '\' before it.

			if ($char =~ /[\"\'<]/)
			{
				$quote = $char eq '<' ? '>' : $char;
			}
		}

		$previous_char = $char;
	}

	# Beware {a:b;}. In this case, the ';' leaves $key eq ''.

	if (length $key)
	{
		$attribute{$key} = $value;

		$self -> log(debug => "Attribute value: $value");
	}

	for $key(sort keys %attribute)
	{
		$value = $attribute{$key};
		$value =~ s/\s+$//;

		# The first 2 backslashes are just to fix syntax highlighting in UltraEdit.

		$value =~ s/^([\"\'])(.*)\1$/$2/;

		$self -> log(debug => "Attribute: $key => $value");

		$self -> items -> push
		({
			name  => $key,
			type  => 'attribute',
			value => $value,
		});
	}

} # End of attribute_list.

# --------------------------------------------------
# References from an email from Jeffrey to the Marpa Google Groups list:
# Check out the SLIF grammar:
# <https://github.com/jeffreykegler/Marpa--R2/blob/master/cpan/lib/Marpa/R2/meta/metag.bnf>.
# It's full of stuff you can steal, including rules for quoted strings.
# The basic idea is that strings must be G0 lexemes, not assembled in G1 as your (Paul Bennett) gist has it.
# Jean-Damien's C language BNF:
# <https://github.com/jddurand/MarpaX-Languages-C-AST/blob/master/lib/MarpaX/Languages/C/AST/Grammar/ISO_ANSI_C_2011.pm>
# is also full of stuff to do all the C syntax, including strings and C-style comments. -- jeffrey

sub BUILD
{
	my($self) = @_;

	if (! defined $self -> logger)
	{
		$self -> logger(Log::Handler -> new);
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

	$self -> items(Set::Array -> new);

	$self -> grammar
	(
		Marpa::R2::Scanless::G -> new
		({
source					=> \(<<'END_OF_SOURCE'),

:default				::= action => [values]

lexeme default			= latm => 1

# Overall stuff.

:start 					::= graph_grammar

graph_grammar			::= class_and_graph		action => graph

class_and_graph			::= class_definition graph_definition

# Class stuff.

class_definition		::= class_statement*

# This uses attribute_statement and not attribute_definition
# because attributes are mandatory after class names.

class_statement			::= class_lexeme attribute_statement

:lexeme					~ class_lexeme		pause => before		event => class
class_lexeme			~ [a-z.]+

# Graph stuff.

graph_definition		::= node_definition
							| edge_definition
							| subgraph_definition
# Node stuff

node_definition			::= node_statement
							| node_statement graph_definition

node_statement			::= node_name
							| node_name attribute_definition
							| node_statement (',') node_statement

node_name				::= start_node end_node

:lexeme					~ start_node		pause => before		event => start_node
start_node				~ '['

:lexeme					~ end_node
end_node				~ ']'

# Edge stuff

edge_definition			::= edge_statement
							| edge_statement graph_definition

edge_statement			::= edge_name
							| edge_name attribute_definition
							| edge_statement (',') edge_statement

edge_name				::= directed_edge
							| undirected_edge

:lexeme					~ directed_edge		pause => before		event => directed_edge
directed_edge			~ '->'

:lexeme					~ undirected_edge	pause => before		event => undirected_edge
undirected_edge			~ '--'

# Attribute stuff.

attribute_definition	::= attribute_statement*

attribute_statement		::= start_attributes end_attributes

:lexeme					~ start_attributes	pause => before		event => start_attributes
start_attributes		~ '{'

:lexeme					~ end_attributes
end_attributes			~ '}'

# subgraph stuff.

subgraph_definition		::= subgraph_sequence
							| subgraph_sequence graph_definition

subgraph_sequence		::= subgraph_statement
							| subgraph_statement attribute_definition

subgraph_statement		::= subgraph_prefix subgraph_name (':') graph_definition subgraph_suffix

subgraph_prefix			::= '('
subgraph_name			::= subgraph_name_lexeme
subgraph_suffix			::= subgraph_suffix_lexeme

:lexeme					~ subgraph_name_lexeme		pause => before		event => push_subgraph
subgraph_name_lexeme	~ [a-zA-Z_.0-9]+

:lexeme					~ subgraph_suffix_lexeme	pause => before		event => pop_subgraph
subgraph_suffix_lexeme	~ ')'

# Boilerplate.

:discard				~ whitespace
whitespace				~ [\s]+

END_OF_SOURCE
		})
	);

	$self -> recce
	(
		Marpa::R2::Scanless::R -> new
		({
			grammar           => $self -> grammar,
			semantics_package => 'Graph::Easy::Marpa::Actions',
		})
	);

} # End of BUILD.

# ------------------------------------------------

sub class
{
	my($self, $class_name) = @_;

	$self -> log(debug => "Class: $class_name");

	my($reserved_class_name) = 'edge|global|graph|group|node';

	if ($class_name !~ /^(?:$reserved_class_name)(?:\.[a-zA-Z_]+)?$/)
	{
		die "Class name '$class_name' must be one of '$reserved_class_name'\n";
	}

	$self -> items -> push
	({
		name  => $class_name,
		type  => 'class',
		value => '',
	});

} # End of class.

# ------------------------------------------------

sub edge
{
	my($self, $edge_name) = @_;

	$self -> log(debug => "Edge: $edge_name");

	$self -> items -> push
	({
		name  => $edge_name,
		type  => 'edge',
		value => '',
	});

} # End of edge.

# -----------------------------------------------
# $target is either qr/]/ or qr/}/, and allows us to handle
# both node names and either edge or node attributes.
# The special case is <<...>>, as used in attributes.

sub find_terminator
{
	my($self, $string, $target, $start) = @_;
	my(@char)   = split(//, substr($$string, $start) );
	my($offset) = 0;
	my($quote)  = '';
	my($angle)  = 0; # Set to 1 if inside <<...>>.

	my($char);

	for my $i (0 .. $#char)
	{
		$char   = $char[$i];
		$offset = $i;

		if ($quote)
		{
			# Ignore an escaped quote.
			# The first 2 backslashes are just to fix syntax highlighting in UltraEdit.

			next if ( ($char =~ /[\]\"\'>]/) && ($i > 0) && ($char[$i - 1] eq '\\') );

			# Get out of quotes if matching one found.

			if ($char eq $quote)
			{
				if ($quote eq '>')
				{
					$quote = '' if (! $angle || ($char[$i - 1] eq '>') );

					next;
				}

				$quote = '';

				next;
			}
		}
		else
		{
			# Look for quotes.
			# 1: Skip escaped chars.

			next if ( ($i > 0) && ($char[$i - 1] eq '\\') );

			# 2: " and '.
			# The backslashes are just to fix syntax highlighting in UltraEdit.

			if ($char =~ /[\"\']/)
			{
				$quote = $char;

				next;
			}

			# 3: <.
			# In the case of attributes ($target eq '}') but not nodes names,
			# quotes can be <...> or <<...>>.

			if ( ($target =~ '}') && ($char =~ '<') )
			{
				$quote = '>';
				$angle = 1 if ( ($i < $#char) && ($char[$i + 1] eq '<') );

				next;
			}

			last if ($char =~ $target);
		}
	}

	return $start + $offset;

} # End of find_terminator.

# -----------------------------------------------

sub format_token
{
	my($self, $item) = @_;
	my($format) = '%4s  %-13s  %-s';
	my($value)  = $$item{name};
	$value      = "$value => $$item{value}" if (length($$item{value}) > 0);

	return sprintf($format, $$item{count}, $$item{type}, $value);

} # End of format_token.

# --------------------------------------------------

sub generate_token_file
{
	my($self, $file_name) = @_;
	my($csv) = Text::CSV -> new
	({
		always_quote => 1,
		binary       => 1,
	});

	open(OUT, '>', $file_name) || die "Can't open(> $file_name): $!";

	# Don't call binmode here, because we're already using it.

	$csv -> print(\*OUT, ['key', 'name', 'value']);
	print OUT "\n";

	for my $item ($self -> items -> print)
	{
		$csv -> print(\*OUT, [$$item{type}, $$item{name}, $$item{value}]);
		print OUT "\n";
	}

	close OUT;

} # End of generate_token_file.

# --------------------------------------------------

sub get_graph_from_command_line
{
	my($self) = @_;

	$self -> graph_text($self -> description);

} # End of get_graph_from_command_line.

# --------------------------------------------------

sub get_graph_from_file
{
	my($self) = @_;

	# This code accepts utf8 data, due to the standard preamble above.

	open(INX, $self -> input_file) || die "Can't open input file(" . $self -> input_file . "): $!\n";
	my(@line) = <INX>;
	close INX;
	chomp @line;

	shift(@line) while ( ($#line >= 0) && ($line[0] =~ /^\s*#/) );

	$self -> graph_text(join(' ', @line) );

} # End of get_graph_from_file.

# --------------------------------------------------

sub log
{
	my($self, $level, $s) = @_;

	$self -> logger -> log($level => $s) if ($self -> logger);

} # End of log.

# ------------------------------------------------

sub node
{
	my($self, $node_name) = @_;
	$node_name =~ s/^\s+//;
	$node_name =~ s/\s+$//;

	# The first 2 backslashes are just to fix syntax highlighting in UltraEdit.

	$node_name =~ s/^([\"\'])(.*)\1$/$2/;

	$self -> log(debug => "Node: $node_name");

	$self -> items -> push
	({
		name  => $node_name,
		type  => 'node',
		value => '',
	});

	if ($node_name eq '')
	{
		$self -> items -> push
		({
			name  => 'color',
			type  => 'attribute',
			value => 'invis',
		});
	}

} # End of node.

# --------------------------------------------------

sub process
{
	my($self)   = @_;
	my($string) = $self -> graph_text;
	my($length) = length $string;

	# We use read()/lexeme_read()/resume() because we pause at each lexeme.

	my($attribute_list);
	my($do_lexeme_read);
	my(@event, $event_name);
	my($lexeme_name, $lexeme);
	my($node_name);
	my($span, $start);

	for
	(
		my $pos = $self -> recce -> read(\$string);
		$pos < $length;
		$pos = $self -> recce -> resume($pos)
	)
	{
		$self -> log(debug => "read() => pos: $pos");

		$do_lexeme_read = 1;
		@event          = @{$self -> recce -> events};
		$event_name     = ${$event[0]}[0];
		($start, $span) = $self -> recce -> pause_span;
		$lexeme_name    = $self -> recce -> pause_lexeme;
		$lexeme         = $self -> recce -> literal($start, $span);

		$self -> log(debug => "pause_span($lexeme_name) => start: $start. " .
			"span: $span. lexeme: $lexeme. event: $event_name");

		if ($event_name eq 'start_attributes')
		{
			# Read the attribute_start lexeme, but don't do lexeme_read()
			# at the bottom of the for loop, because we're just about
			# to fiddle $pos to skip the attributes.

			$pos            = $self -> recce -> lexeme_read($lexeme_name);
			$pos            = $self -> find_terminator(\$string, qr/}/, $start);
			$attribute_list = substr($string, $start + 1, $pos - $start - 1);
			$do_lexeme_read = 0;

			$self -> log(debug => "index() => attribute list: $attribute_list");

			$self -> attribute_list($attribute_list);
		}
		elsif ($event_name eq 'start_node')
		{
			# Read the node_start lexeme, but don't do lexeme_read()
			# at the bottom of the for loop, because we're just about
			# to fiddle $pos to skip the node's name.

			$pos            = $self -> recce -> lexeme_read($lexeme_name);
			$pos            = $self -> find_terminator(\$string, qr/]/, $start);
			$node_name      = substr($string, $start + 1, $pos - $start - 1);
			$do_lexeme_read = 0;

			$self -> log(debug => "index() => node name: $node_name");

			$self -> node($node_name);
		}
		elsif ($event_name eq 'directed_edge')
		{
			$self -> edge($lexeme);
		}
		elsif ($event_name eq 'undirected_edge')
		{
			$self -> edge($lexeme);
		}
		elsif ($event_name eq 'class_lexeme')
		{
			$self -> class($lexeme);
		}
		elsif ($event_name eq 'push_subgraph')
		{
			$self -> push_subgraph($lexeme);
		}
		elsif ($event_name eq 'pop_subgraph')
		{
			$self -> pop_subgraph($lexeme);
		}
		else
		{
			die "Unexpected lexeme '$lexeme_name' with a pause\n";
		}

		$pos = $self -> recce -> lexeme_read($lexeme_name) if ($do_lexeme_read);

		$self -> log(debug => "lexeme_read($lexeme_name) => $pos");
    }

	# Return a defined value for success and undef for failure.

	return $self -> recce -> value;

} # End of process.

# ------------------------------------------------

sub pop_subgraph
{
	my($self, $subgraph_suffix) = @_;
	my($subgraph_name) = $self -> subgraph_name;

	$self -> log(debug => "Pop subgraph: $subgraph_name");

	$self -> items -> push
	({
		name  => $subgraph_name,
		type  => 'pop_subgraph',
		value => '',
	});

	$self -> subgraph_name('');

} # End of pop_subgraph.

# ------------------------------------------------

sub push_subgraph
{
	my($self, $subgraph_name) = @_;

	$self -> log(debug => "Push subgraph: $subgraph_name");

	my($subgraph_name_regexp) = '^(?:[a-zA-Z_.][a-zA-Z_.0-9]*)$';

	if ($subgraph_name !~ /^$subgraph_name_regexp/)
	{
		die "Subgraph name '$subgraph_name' must match '$subgraph_name_regexp'\n";
	}

	$self -> items -> push
	({
		name  => $subgraph_name,
		type  => 'push_subgraph',
		value => '',
	});

	$self -> subgraph_name($subgraph_name);

} # End of push_subgraph.

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
	my($self) = @_;

	$self -> log(info => $self -> format_token
	({
		count => 'Item',
		name  => 'Name',
		type  => 'Type',
		value => '',
	}) );

	for my $item ($self -> items -> print)
	{
		$self -> log(info => $self -> format_token($item) );
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
		die "Error: You must provide a graph using one of -input_file or -description\n";
	}

	# Return 0 for success and 1 for failure.

	my($result) = 0;

	try
	{
		if (defined $self -> process)
		{
			$self -> renumber_items;
			$self -> report if ($self -> report_tokens);

			my($file_name) = $self -> token_file;

			$self -> generate_token_file($file_name) if ($file_name);
		}
		else
		{
			$result = 1;

			$self -> log(error => 'Parse failed');
		}
	}
	catch
	{
		$result = 1;

		$self -> log(error => "Parse failed: $_");
	};

	# Return 0 for success and 1 for failure.

	$self -> log(info => "Parse result: $result (0 is success)");

	return $result;

} # End of run.

# --------------------------------------------------

1;

=pod

=head1 NAME

C<Graph::Easy::Marpa::Parser> - A Marpa-based parser for Graph::Easy::Marpa files

=head1 Synopsis

See L<Graph::Easy::Marpa/Synopsis>.

=head1 Description

C<Graph::Easy::Marpa::Parser> provides a Marpa-based parser for L<Graph::Easy::Marpa>-style graph definitions.

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

C<new()> is called as C<< my($parser) = Graph::Easy::Marpa::Parser -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Graph::Easy::Marpa::Parser>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. graph()]):

=over 4

=item o description => '[node.1]<->[node.2]'

Specify a string for the graph definition.

You are strongly encouraged to surround this string with '...' to protect it from your shell.

See also the 'input_file' key to read the graph from a file.

The 'description' key takes precedence over the 'input_file' key.

=item o input_file => $graph_file_name

Read the graph definition from this file.

See also the 'graph' key to read the graph from the command line.

The whole file is slurped in as 1 graph.

The first lines of the input file can start with /^\s*#/, and will be discarded as comments.

The 'description' key takes precedence over the 'input_file' key.

=item o logger => $logger_object

Specify a logger object.

To disable logging, just set logger to the empty string.

The default value is an object of type L<Log::Handler>.

=item o maxlevel => $level

This option is only used if an object of type L<Log::Handler> is created. See I<logger> above.

See also L<Log::Handler::Levels>.

Default: 'info'. A typical value is 'debug'.

=item o minlevel => $level

This option is only used if an object of type L<Log::Handler> is created. See I<logger> above.

See also L<Log::Handler::Levels>.

Default: 'error'.

No lower levels are used.

=item o report_items => $Boolean

Calls L</report()> to report, via the log, the items recognized by the state machine.

=back

See L<Graph::Easy::Marpa/Data and Script Interaction>.

=head1 Methods

=head2 file([$file_name])

The [] indicate an optional parameter.

Get or set the name of the file the graph will be read from.

See L</get_graph_from_file()>.

=head2 generate_token_file($file_name)

Returns nothing.

Writes a CSV file of tokens output by the parse if new() was called with the C<token_file> option.

=head2 get_graph_from_command_line()

If the caller has requested a graph be parsed from the command line, with the graph option to new(), get it now.

Called as appropriate by run().

=head2 get_graph_from_file()

If the caller has requested a graph be parsed from a file, with the file option to new(), get it now.

Called as appropriate by run().

=head2 grammar()

Returns an object of type L<Marpa::R2::Scanless::G>.

=head2 input_file([$graph_file_name])

Here, the [] indicate an optional parameter.

Get or set the name of the file to read the graph definition from.

See also the description() method.

The whole file is slurped in as 1 graph.

The first lines of the input file can start with /^\s*#/, and will be discarded as comments.

The value supplied to the description() method takes precedence over the value read from the input file.

=head2 items()

Returns a object of type L<Set::Array>, which is an arrayref of items output by the state machine.

See the L</FAQ> for details.

=head2 log($level, $s)

Calls $self -> logger -> $level($s).

=head2 logger([$logger_object])

Here, the [] indicate an optional parameter.

Get or set the logger object.

To disable logging, just set logger to the empty string.

=head2 maxlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

This option is only used if an object of type L<Log::Handler> is created. See L<Log::Handler::Levels>.

=head2 minlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

This option is only used if an object of type L<Log::Handler> is created. See L<Log::Handler::Levels>.

=head2 recce()

Returns an object of type L<Marpa::R2::Scanless::R>.

=head2 renumber_items()

Ensures each item in the stack as a sequential number 1 .. N.

=head2 report()

Report, via the log, the list of items recognized by the state machine.

=head2 report_items([0 or 1])

The [] indicate an optional parameter.

Get or set the value which determines whether or not to report the items recognised by the state machine.

=head2 run()

This is the only method the caller needs to call. All parameters are supplied to new().

Returns 0 for success and 1 for failure.

=head2 token_file([$csv_file_name])

The [] indicate an optional parameter.

Get or set the name of the file to write containing the tokens (items) output from the parser.

=head2 tokens()

Returns an arrayref of tokens. Each element of this arrayref is an arrayref of 2 elements:

=over 4

=item o The type of the token

=item o The value of the token

=back

If you look at the source code for the run() method in L<Graph::Easy::Marpa>, you'll see this arrayref can be
passed directly as the value of the items key in the call to L<Graph::Easy::Marpa::Renderer::GraphViz2>'s run()
method.

=head1 FAQ

=head2 What is the Graph::Easy::Marpa language?

Basically, it is derived from, and very similar to, the L<Graph::Easy> language, with a few irregularities
cleaned up. It exists to server as a wrapper around L<the DOT language|http://www.graphviz.org/content/dot-language>.

The re-write took place because, instead of L<Graph::Easy>'s home-grown parser, Graph::Easy::Marpa::Parser uses
L<Marpa::R2>, which requires a formally-spelled-out grammar for the language being parsed.

That grammar is in the source code of Graph::Easy::Marpa::Parser, in C<sub BUILD()>, and is explained next.

Firstly, a summary:

	Element        Syntax
	---------------------
	Edge names     Either '->' or '--'
	---------------------
	Node names     1: Delimited by '[' and ']'.
	               2: May be quoted with " or '.
	               3: Escaped characters, using '\', are allowed.
	               4: Internal spaces in node names are preserved even if not quoted.
	---------------------
	Attributes     1: Delimited by '{' and '}'.
	               2: Within that, any number of "key : value" pairs separated by ';'.
	               3: Values may be quoted with " or ' or '<...>' or '<<table>...</table>>'.
	               4: Escaped characters, using '\', are allowed.
	               5: Internal spaces in attribute values are preserved even if not quoted.
	---------------------

Note: Both edges and nodes can have attributes.

Note: HTML-like labels trigger special-case processing in Graphviz.
See L</Why doesn't the parser handle my HTML-style labels?> below.

Demo pages:

	L<Graph::Easy::Marpa|http://savage.net.au/Perl-modules/html/graph.easy.marpa/>
	L<MarpaX::Demo::StringParser|http://savage.net.au/Perl-modules/html/marpax.demo.stringparser/>

The latter page utilizes a cut-down version of the Graph::Easy::Marpa language, as documented in
L<MarpaX::Demo::StringParser/What is the grammar you parse?>.

And now the details:

=over 4

=item o Attributes

Both nodes and edges can have any number of attributes.

Attributes are delimited by '{' and '}'.

These attributes are listed immdiately after their owing node or edge.

Each attribute consists of a key:value pair, where ':' must appear literally.

These key:value pairs must be separated by the ';' character. A trailing ';' is optional.

The values for 'key' are reserved words used by Graphviz's L<attributes|http://graphviz.org/content/attrs>.
These keys match the regexp /^[a-zA-Z_]+$/.

For the 'value', any printable character can be used.

Some escape sequences are a special meaning within L<Graphviz|http://www.graphviz.org/content/attrs>.

E.g. if you use [node name] {label: \N}, then if that graph is input to Graphviz's I<dot>, \N will be replaced
by the name of the node.

Some literals - ';', '}', '<', '>', '"', "'" - can be used in the attribute's value, but they must satisfy one
of these conditions. They must be:

=over 4

=item o Escaped using '\'.

Eg: \;, \}, etc.

=item o Placed inside " ... "

=item o Placed inside ' ... '

=item o Placed inside <...>

This does I<not> mean you can use <<Some text>>. See the next point.

=item o Placed inside <<table> ... </table>>

Using this construct allows you to use HTML entities such as &amp;, &lt;, &gt; and &quot;.

=back

Internal spaces are preserved within an attribute's value, but leading and trailing spaces are not (unless quoted).

Samples:

	[node.1] {color: red; label: Green node}
	-> {penwidth: 5; label: From Here to There}
	[node.2]
	-> {label: "A literal semicolon '\;' in a label"}

Note: That '\;' does not actually need those single-quote characters, since it is within a set of double-quotes.

Note: Attribute values quoted with a balanced pair or single- or double-quotes will have those quotes stripped.

=item o Classes

Class and subclass names must match /^(edge|global|graph|group|node)(\.[a-z]+)?$/.

The name before the '.' is the class name.

'global' is used to specify whether you want a directed or undirected graph. The default is directed.

	global {directed: 1} [node.1] -> [node.2]

'graph' is used to specify the direction of the graph as a whole, and must be one of: LR or RL or TB or BT.
The default is TB.

	graph {rankdir: LR} [node.1] -> [node.2]

The name after the '.' is the subclass name. And if '.' is present, the subclass name must be present.
This means things like 'edge.' etc are syntax errors.

	node {shape: rect} node.forest {color: green}
	[node.1] -> [node.2] {class: forest} -> [node.3] {shape: circle; color: blue}

Here, node.1 gets the default shape, rect, and node.2 gets both shape rect and color green. node.3
gets shape circle and color blue.

As always, specific attributes override class attributes.

You use the subclass name in the attributes of an edge, a group or a node, whereas 'global' and 'graph'
appear only once, at the start of the input stream. That is, tt does not make sense for a class of I<global>
or I<graph> to have any subclasses.

=item o Comments

The first few lines of the input file can start with /^\s*#/, and will be discarded as comments.

=item o Daisy-chains

See L<Wikipedia|https://en.wikipedia.org/wiki/Daisy_chain> for the origin of this term.

=over 4

=item o Edges

Edges can be daisy-chained by juxtaposition, or by using a comma (','), newline, space, or attributes ('{...}')
to separate them.

Hence both of these are valid: '->,->{color:green}' and '->{color:red}->{color:green}'.

See data/edge.03.ge and data/edge.09.ge.

=item o Groups

Groups can be daisy chained by juxtaposition, or by using a newline or space to separate them.

=item o Nodes

Nodes can be daisy-chained by juxtaposition, or by using a comma (','), newline, space, or attributes ('{...}')
to separate them.

Hence all of these are valid: '[node.1][node.2]' and '[node.1],[node.2]' and '[node.1]{color:red}[node.2]'.

=back

=item o Edges

Edge names are either '->' or '--'.

No other edge names are accepted.

Note: The syntax for edges is just a visual clue for the user. The I<directed> 'v' I<undirected> nature of the
graph depends on the value of the 'directed' attribute present (explicitly or implicitly) in the input stream.
Nevertheless, usage of '->' or '--' must match the nature of the graph, or Graphviz will issue a syntax error.

The default is {directed: 1}. See data/class.global.01.ge for a case where we use {directed: 0} attached to
class 'global'.

Edges can have attributes such as arrowhead, arrowtail, etc. See L<Graphviz|http://www.graphviz.org/content/attrs>

Samples:

	->
	-- {penwidth: 9}

=item o Graphs

Graphs are sequences of nodes and edges, in any order.

The sample given just above for attributes is in fact a single graph.

A sample:

	[node]
	[node] ->
	-> {label: Start} -> {color: red} [node.1] {color: green] -> [node.2]
	[node.1] [node.2] [node.3]

For more samples, see the data/*.ge files shipped with the distro.

=item o Line-breaks

These are converted into a single space.

=item o Nodes

Nodes are delimited by '[' and ']'.

Within those, any printable character can be used for a node's name.

Some literals - ']', '"', "'" - can be used in the node's value, but they must satisfy one of these
conditions. They must be:

=over 4

=item o Escaped using '\'

Eg: \].

=item o Placed inside " ... "

=item o Placed inside ' ... '

=back

Internal spaces are preserved within a node's name, but leading and trailing spaces are not (unless quoted).

Lastly, the node's name can be empty. I.e.: You use '[]' in the input stream to create an anonymous node.

Samples:

	[]
	[node.1]
	[node 1]
	[[node\]]
	["[node]"]
	[     From here     ] -> [     To there     ]

Note: Node names quoted with a balanced pair or single- or double-quotes will have those quotes stripped.

=item o Subgraphs aka Groups

Subgraph names must match /^[a-zA-Z_.][a-zA-Z_0-9. ]*$/.

Subgraph names beginning with 'cluster' trigger special-case processing within Graphviz.

See 'Subgraphs and Clusters' on L<this page|http://www.graphviz.org/content/dot-language>.

Samples:

	Here, the subgraph name is 'cluster.1':
	(cluster.1: [node.1] -> [node.2])
	group {bgcolor: red} (cluster.1: [node.1] -> [node.2]) {class: group}

=back

=head2 Does this module handle utf8?

Yes. See the last sample on L<the demo page|http://savage.net.au/Perl-modules/html/graph.easy.marpa/>.

=head2 How is the parsed graph stored in RAM?

Items are stored in an arrayref. This arrayref is available via the L</items()> method.

Each element in the array is a hashref, listed here in alphabetical order by type.

Note: Items are numbered from 1 up.

=over 4

=item o Attributes

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
	count => $n + 1,
	name  => 'shape',
	type  => 'attribute',
	value => 'circle',
	}

Attribute hashrefs appear in the arrayref immediately after the item (edge, group, node) to which they belong.
For subgraphs, this means they appear straight after the hashref whose type is 'pop_subgraph'.

The following has been extracted manually from the Graphviz documentation, and is listed here in case I need it.
Classes are written as [x] rather than [x]+, etc, so it uses various abbreviations.

	Attribute	Regexp+			Interpretation
	---------	------			--------------
	addDouble	+?[0-9.]		A double preceeded by an optional '+'
	arrowType	[a-z]			A word
	aspectType	[0-9.,]			A double or a double + ',' + an integer
	bool		[a-zA-Z0-0]		Case-insensitive 'true', 'false', 0 or N (true)
	color		[#0-9a-f]		'#' followed by 3 or 4 hex numbers
				[0-9. ]			3 numbers 0 .. 1 separated by '.' or \s
				[/a-z]			A word or /word or /word1/word2
	clusterMode	[a-z]			A word
	colorList	color(;[0-9.])?	N tokens separated by ':'.
	dirType		[a-z]			A word
	doubleList	[0-9.:]			Various doubles separated by ':'
	escString	\[NGETHLnlr]	A list of escaped letters
	HTML label	<<[.]>>			A quoted list of stuff
	layerRange
	lblString	escString or HTML label
	outputMode	[a-z]			A word
	pagedir		[A-Z]			A word of 2 caps (TB etc)
	point		[0-9.,]!?		2 doubles followed by an optional '!'
	pointList	[0-9., ]!?		A list of points separated by spaces
	quadType	[a-z]			A word
	rankdir		[A-Z]			A word of 2 caps (TB etc)
	rankType	[a-z]			A word
	rect		[0-9.,]			Four doubles seperated by ','s
	shape		[a-z]			A word, or
				[<>{}]			Bracketed strings, or
				?				User-defined
	smoothType	[a-z]			A word
	splineType	[0-9.,;es]		Various doubles, with ',' and ';', and optional 'e', 's'
	startType	[a-z][0-9]		A word optionally followed by a number
	style		[a-z(),]		A list of words separated by ',' each with optional '(...)'
	viewPort	[0-9.,]			A list of 5 doubles or
				[0-9.,]			A list of 4 doubles followed by a node name

=item o Classes and class attributes

These notes apply to all classes and subclasses.

A class definition of 'edge {color: white}' would produce 2 hashrefs:

	{
	count => $n,
	name  => 'edge',
	type  => 'class_name',
	value => '',
	}

	{
	count => $n + 1,
	name  => 'color',
	type  => 'attribute',
	value => 'white',
	}

A class definition of 'node.green {color: green; shape: rect}' would produce 3 hashrefs:

	{
	count => $n,
	name  => 'node.green',
	type  => 'class_name',
	value => '',
	}

	{
	count => $n + 1,
	name  => 'color',
	type  => 'attribute',
	value => 'green',
	}

	{
	count => $n + 2,
	name  => 'shape',
	type  => 'attribute',
	value => 'rect',
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

A node can have a definition of '[]', which means it has no name. Such nodes are called anonymous (or
invisible) because while they take up space in the output stream, they have no printable or visible
characters in the output stream.

Each anonymous node will have at least these 2 attributes:

	{
		count => $n,
		name  => '',
		type  => 'node',
		value => '',
	}

	{
		count => $n + 1,
		name  => 'color',
		type  => 'attribute',
		value => 'invis',
	}

You can of course give your anonymous nodes any attributes, but they will be forced to have
these attributes.

E.g. If you give it a color, that would become element $n + 2 in the arrayref, and hence that color would override
the default color 'invis'. See the output for data/node.04.ge on
L<the demo page|http://savage.net.au/Perl-modules/html/graph.easy.marpa/>.

Node names are case-sensitive in C<dot>.

=item o Subgraphs

Subgraph names must match /^(?:[a-zA-Z_.][a-zA-Z_.0-9]*)^/.

A subgraph produces 2 hashrefs, one at the start of the subgraph, and one at the end.

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
	count => $n + N,
	name  => 'Solar system',
	type  => 'pop_subgraph',
	value => '',
	}

=back

=head2 Why doesn't the parser handle my HTML-style labels?

Traps for young players:

=over 4

=item o The <br /> component must include the '/'

=item o If any tag's attributes use double-quotes, they will be doubled in the CSV output file

That is, just like double-quotes everywhere else.

=back

See L<http://www.graphviz.org/content/dot-language> for details of Graphviz's HTML-like syntax.

See data/node.16.ge and data/node.17.ge for a couple of examples.

=head2 Why do I get error messages like the following?

	Error: <stdin>:1: syntax error near line 1
	context: digraph >>>  Graph <<<  {

Graphviz reserves some words as keywords, meaning they can't be used as an ID, e.g. for the name of the graph.
So, don't do this:

	strict graph graph{...}
	strict graph Graph{...}
	strict graph strict{...}
	etc...

Likewise for non-strict graphs, and digraphs. You can however add double-quotes around such reserved words:

	strict graph "graph"{...}

Even better, use a more meaningful name for your graph...

The keywords are: node, edge, graph, digraph, subgraph and strict. Compass points are not keywords.

See L<keywords|http://www.graphviz.org/content/dot-language> in the discussion of the syntax of DOT
for details.

=head2 Where are the action subs named in the grammar?

In L<Graph::Easy::Marpa::Actions>.

=head2 Has any graph syntax changed moving from V 1.* to V 2.*?

Yes. Under V 1.*, to specify an empty label, this was possible:

	[node] { label: ;}

Any attribute, here C<label>, without a value, is unacceptable under V 2.*. Just use:

	[node] { label: ''; }

Of cource, the same applies to attributes for edges.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Graph::Easy::Marpa>.

=head1 Author

L<Graph::Easy::Marpa> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2011.

Home page: L<http://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2011, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
