package Graph::Easy::Marpa::Parser;

use strict;
use warnings;

use Graph::Easy::Marpa::Renderer::GraphViz2;

use Hash::FieldHash ':all';

use IO::File;

use Log::Handler;

use Marpa::R2;

use Set::Array;

use Text::CSV_XS;

use Try::Tiny;

fieldhash my %attrs              => 'attrs';
fieldhash my %attribute_name     => 'attribute_name';
fieldhash my %counter            => 'counter';
fieldhash my %dot_input_file     => 'dot_input_file';
fieldhash my %format             => 'format';
fieldhash my %group_name         => 'group_name';
fieldhash my %input_file         => 'input_file';
fieldhash my %items              => 'items';
fieldhash my %logger             => 'logger';
fieldhash my %maxlevel           => 'maxlevel';
fieldhash my %minlevel           => 'minlevel';
fieldhash my %node_name          => 'node_name';
fieldhash my %output_file        => 'output_file';
fieldhash my %rankdir            => 'rankdir';
fieldhash my %renderer           => 'renderer';
fieldhash my %report_items       => 'report_items';
fieldhash my %parsed_tokens_file => 'parsed_tokens_file';
fieldhash my %tokens             => 'tokens';

# $myself is a copy of $self for use by functions called by Marpa.

our $myself;
our $VERSION = '1.10';

# --------------------------------------------------
# This is a function, not a method.

sub attribute_name_id
{
	my(undef, $t1, undef, $t2)  = @_;

	$myself -> attribute_name($t1);

	return $t1;

} # End of attribute_name_id.

# --------------------------------------------------
# This is a function, not a method.

sub attribute_value_id
{
	my(undef, $t1, undef, $t2)  = @_;

	$myself -> attrs -> push
	({
		count => $myself -> _count,
		name  => $myself -> attribute_name,
		type  => 'attribute',
		value => $t1,
	});

	return $t1;

} # End of attribute_value_id.

# --------------------------------------------------
# This is a function, not a method.

sub class_name
{
	my(undef, $t1, undef, $t2)  = @_;

	$myself -> items -> push
	({
		count => $myself -> _count,
		name  => $t1,
		type  => 'class_name',
		value => '',
	});

	return $t1;

} # End of class_name.

# --------------------------------------------------

sub _count
{
	my($self) = @_;

	# Warning! Don't use:
	# return $self -> counter($self -> counter + 1);
	# It returns $self.

	$self -> counter($self -> counter + 1);

	return $self -> counter;

} # End of _count.

# --------------------------------------------------
# This is a function, not a method.

sub edge_id
{
	my(undef, $t1, undef, $t2)  = @_;

	# This regexp defines what is and isn't allowed for edge names.

	if ($t1 !~ /^<?(-|=|\.|~|- |= |\.-|\.\.-){1,}>?$/)
	{
		die "Unexpected edge syntax: '$t1'";
	}

	$myself -> items -> push
	({
		count => $myself -> _count,
		name  => $t1,
		type  => 'edge',
		value => '',
	});

	return $t1;

} # End of edge_id.

# --------------------------------------------------
# This is a function, not a method.

sub end_attribute
{
	my(undef, $t1, undef, $t2)  = @_;

	# $t1 will be '}'.
	# Add all attributes to the item list.
	# They belong to the preceeding node or edge.

	$myself -> items -> push($myself -> attrs -> print);
	$myself -> attrs -> clear;

	return $t1;

} # End of end_attribute.

# --------------------------------------------------
# This is a function, not a method.

sub end_node
{
	my(undef, $t1, undef, $t2)  = @_;

	# $t1 will be ']'.

	$myself -> items -> push
	({
		count => $myself -> _count,
		name  => $myself -> node_name,
		type  => 'node',
		value => '',
	});

	return $t1;

} # End of end_node.

# --------------------------------------------------

sub _generate_item_file
{
	my($self, $file_name) = @_;
	my(@item) = $self -> items -> print;

	open(OUT, '>', $file_name) || die "Can't open(> $file_name): $!";

	my($item);
	my($s);

	for my $i (0 .. $#item)
	{
		$item = $item[$i];
		$s    = join('', map{"$_: $$item{$_}. "} sort keys %$item);

		if ($$item{type} =~ /(?:edge|node|(?:push|pop)_subgraph)/)
		{
			print OUT "$s\n";
		}
		else
		{
			print OUT"\t$s\n";
		}
	}

	close OUT;

} # End of _generate_item_file.

# --------------------------------------------------

sub grammar
{
	my($self)    = @_;
	my($grammar) = Marpa::R2::Grammar -> new
	({
		actions => __PACKAGE__,
		start   => 'graph_grammar',
		rules   =>
		[
		{   # Global stuff.
			lhs    => 'graph_grammar',
			rhs    => [qw/class_and_graph/],
			action => 'parse_result',
		},
		{
			lhs => 'class_and_graph',
			rhs => [qw/class_definition graph_definition/],
		},
		{   # Class stuff.
			lhs => 'class_definition',
			rhs => [qw/class_sequence/],
			min => 0,
		},
		{
			lhs => 'class_sequence', # 1 of 2.
			rhs => [qw/class_statement/],
		},
		{
			lhs => 'class_sequence', # 2 of 2.
			rhs => [qw/class_statement daisy_chain_class/],
		},
		{
			lhs => 'class_statement',
			rhs => [qw/class_name class_attribute_definition/],
		},
		{
			lhs    => 'class_name',
			rhs    => [qw/class/],
			action => 'class_name',
		},
		{   # Graph stuff.
			lhs => 'graph_definition',
			rhs => [qw/graph_statement/],
		},
		{
			lhs => 'graph_statement', # 1 of 3.
			rhs => [qw/group_definition/],
		},
		{
			lhs => 'graph_statement', # 2 of 3.
			rhs => [qw/node_definition/],
		},
		{
			lhs => 'graph_statement', # 3 of 3.
			rhs => [qw/edge_definition/],
		},
		{   # Class attribute stuff. Some components are defined under 'Attribute stuff', below.
			lhs => 'class_attribute_definition',
			rhs => [qw/class_attribute_statement/],
			min => 0,
		},
		{
			lhs => 'class_attribute_statement',
			rhs => [qw/start_attribute class_attribute_sequence end_attribute/],
		},
		{
			lhs => 'class_attribute_sequence',
			rhs => [qw/class_attribute_declaration/],
			min => 1,
		},
		{
			lhs => 'class_attribute_declaration',
			rhs => [qw/class_attribute_name colon attribute_value attribute_terminator/],
		},
		{
			lhs    => 'class_attribute_name',
			rhs    => [qw/class_attribute_name_id/],
			min    => 1,
			action => 'attribute_name_id',
		},
		{   # Group stuff.
			lhs => 'group_definition',
			rhs => [qw/group_sequence/],
			min => 0,
		},
		{
			lhs => 'group_sequence', # 1 of 4.
			rhs => [qw/group_statement/],
		},
		{
			lhs => 'group_sequence', # 2 of 4.
			rhs => [qw/group_statement daisy_chain_group/],
		},
		{
			lhs => 'group_sequence', # 3 of 4.
			rhs => [qw/group_statement node_definition/],
		},
		{
			lhs => 'group_sequence', # 4 of 4.
			rhs => [qw/group_statement edge_definition/],
		},
		{
			lhs => 'group_statement',
			rhs => [qw/group_name graph_statement exit_group attribute_definition/],
		},
		{
			lhs    => 'group_name',
			rhs    => [qw/push_subgraph/],
			min    => 0,
			action => 'start_subgraph',
		},
		{
			lhs    => 'exit_group',
			rhs    => [qw/pop_subgraph/],
			action => 'pop_subgraph',
		},
		{   # Node stuff.
			lhs => 'node_definition',
			rhs => [qw/node_sequence/],
			min => 0,
		},
		{
			lhs => 'node_sequence', # 1 of 4.
			rhs => [qw/node_statement/],
		},
		{
			lhs => 'node_sequence', # 2 of 4.
			rhs => [qw/node_statement daisy_chain_node/],
		},
		{
			lhs => 'node_sequence', # 3 of 4.
			rhs => [qw/node_statement edge_definition/],
		},
		{
			lhs => 'node_sequence', # 4 of 4.
			rhs => [qw/node_statement group_definition/],
		},
		{
			lhs => 'node_statement',
			rhs => [qw/start_node node_name end_node attribute_definition/],
		},
		{
			lhs    => 'start_node',
			rhs    => [qw/left_bracket/],
			action => 'start_node',
		},
		{
			lhs    => 'node_name',
			rhs    => [qw/node_id/],
			min    => 0,
			action => 'node_id',
		},
		{
			lhs    => 'end_node',
			rhs    => [qw/right_bracket/],
			action => 'end_node',
		},
		{   # Edge stuff.
			lhs => 'edge_definition',
			rhs => [qw/edge_sequence/],
			min => 0,
		},
		{
			lhs => 'edge_sequence', # 1 of 4.
			rhs => [qw/edge_statement/],
		},
		{
			lhs => 'edge_sequence', # 2 of 4.
			rhs => [qw/edge_statement daisy_chain_edge/],
		},
		{
			lhs => 'edge_sequence', # 3 of 4.
			rhs => [qw/edge_statement node_definition/],
		},
		{
			lhs => 'edge_sequence', # 4 of 4.
			rhs => [qw/edge_statement group_definition/],
		},
		{
			lhs => 'edge_statement',
			rhs => [qw/edge_name attribute_definition/],
		},
		{
			lhs    => 'edge_name',
			rhs    => [qw/edge_id/],
			action => 'edge_id',
		},
		{   # Attribute stuff.
			lhs => 'attribute_definition',
			rhs => [qw/attribute_statement/],
			min => 0,
		},
		{
			lhs => 'attribute_statement',
			rhs => [qw/start_attribute attribute_sequence end_attribute/],
		},
		{
			lhs    => 'start_attribute',
			rhs    => [qw/left_brace/],
			action => 'start_attribute',
		},
		{
			lhs => 'attribute_sequence',
			rhs => [qw/attribute_declaration/],
			min => 1,
		},
		{
			lhs => 'attribute_declaration',
			rhs => [qw/attribute_name colon attribute_value attribute_terminator/],
		},
		{
			lhs    => 'attribute_name',
			rhs    => [qw/attribute_name_id/],
			min    => 1,
			action => 'attribute_name_id',
		},
		{
			lhs    => 'attribute_value',
			rhs    => [qw/attribute_value_id/],
			min    => 1,
			action => 'attribute_value_id',
		},
		{
			lhs => 'attribute_terminator',
			rhs => [qw/semi_colon/],
			min => 1,
		},
		{
			lhs    => 'end_attribute',
			rhs    => [qw/right_brace/],
			action => 'end_attribute',
		},
		],
	});

	$grammar -> precompute;

	return $grammar;

} # End of grammar;

# --------------------------------------------------

sub _init
{
	my($self, $arg)           = @_;
	$$arg{attrs}              = Set::Array -> new;
	$$arg{attribute_name}     = '';
	$$arg{counter}            = 0;
	$$arg{dot_input_file}     ||= ''; # Caller can set.
	$$arg{format}             ||= 'svg';
	$$arg{input_file}         ||= ''; # Caller can set.
	$$arg{items}              = Set::Array -> new;
	my($user_logger)          = defined $$arg{logger}; # Caller can set (e.g. to '').
	$$arg{logger}             = $user_logger ? $$arg{logger} : Log::Handler -> new;
	$$arg{maxlevel}           ||= 'debug'; # Caller can set.
	$$arg{minlevel}           ||= 'error'; # Caller can set.
	$$arg{node_name}          = '';
	$$arg{output_file}        ||= '';   # Caller can set.
	$$arg{parsed_tokens_file} ||= '';   # Caller can set.
	$$arg{rankdir}            ||= 'TB'; # Caller can set.
	my($user_renderer)        = defined $$arg{renderer}; # Caller can set.
	#$$arg{renderer}          = ...   # Do not execute. Check it below.
	$$arg{report_items}       ||= 0;  # Caller can set.
	$$arg{tokens}             ||= []; # Caller can set.
	$self                     = from_hash($self, $arg);
	$myself                   = $self;

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

	if (! $user_renderer)
	{
		# We have to pass in the logger here, or GraphViz2 will instantiate one itself.
		# Don't forget! The caller may have set logger to '' (not undef), to stop logging.

		$self -> renderer
			(
			 Graph::Easy::Marpa::Renderer::GraphViz2 -> new
			 (
			  dot_input_file => $self -> dot_input_file,
			  logger         => $self -> logger,
			  rankdir        => $self -> rankdir,
			 )
			);
	}

	return $self;

} # End of _init.

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
# This is a function, not a method.

sub node_id
{
	my(undef, $t1, undef, $t2)  = @_;

	$myself -> node_name($t1);

	return $t1;

} # End of node_id.

# --------------------------------------------------
# This is a function, not a method.

sub parse_result
{
	my(undef, $t1, undef, $t2)  = @_;

	# Return 0 for success and 1 for failure.

	return 0;

} # End of parse_result.

# --------------------------------------------------
# This is a function, not a method.

sub pop_subgraph
{
	my(undef, $t1, undef, $t2)  = @_;

	# $t1 will be ')'.

	$myself -> items -> push
	({
		count => $myself -> _count,
		name  => $myself -> group_name,
		type  => 'pop_subgraph',
		value => '',
	});

	return $t1;

} # End of pop_subgraph.

# -----------------------------------------------

sub read_csv_file
{
	my($self, $file_name) = @_;
	my($csv) = Text::CSV_XS -> new({allow_whitespace => 1});
	my($io)  = IO::File -> new($file_name, 'r');

	$csv -> column_names($csv -> getline($io) );

	return $csv -> getline_hr_all($io);

} # End of read_csv_file.

# --------------------------------------------------

sub report
{
	my($self) = @_;
	my(@item) = $self -> items -> print;

	my($item);
	my($s);

	for my $i (0 .. $#item)
	{
		$item = $item[$i];
		$s    = join('', map{"$_: $$item{$_}. "} sort keys %$item);

		if ($$item{type} =~ /(?:edge|node)/)
		{
			$self -> log(info => $s);
		}
		else
		{
			$self -> log(info => "\t$s");
		}
	}

} # End of report.

# --------------------------------------------------

sub run
{
	my($self)       = @_;
	my($recognizer) = Marpa::R2::Recognizer -> new({grammar => $self -> grammar});

	if ($#{$self -> tokens} < 0)
	{
		for my $record (@{$self -> read_csv_file($self -> input_file)})
		{
			# Remove '...' surrounding edge, etc names.
			# Use .* not .+ to allow for anonymous nodes.

			$$record{value} =~ s/^'(.*)'$/$1/;

			$recognizer -> read($$record{key}, $$record{value});
		}
	}
	else
	{
		for my $item (@{$self -> tokens})
		{
			$$item[1] =~ s/^'(.*)'$/$1/;

			$recognizer -> read($$item[0], $$item[1]);
		}
	}

	my($result) = $recognizer -> value;
	$result     = defined $result ? ref $result ? ${$result} : $result : 'Parse failed';

	die $result if ($result);

	$self -> report if ($self -> report_items);

	my($file_name) = $self -> parsed_tokens_file;

	if ($file_name)
	{
		$self -> _generate_item_file($file_name);
	}

	$file_name = $self -> output_file;

	if ($file_name && $self -> renderer)
	{
		$self -> renderer -> run
			(
			 dot_input_file => $self -> dot_input_file,
			 'format'       => $self -> format,
			 items          => [$self -> items -> print],
			 logger         => $self -> logger,
			 output_file    => $file_name,
			);
	}

	# Return 0 for success and 1 for failure.

	return 0;

} # End of run.

# --------------------------------------------------
# This is a function, not a method.

sub start_attribute
{
	my(undef, $t1, undef, $t2)  = @_;

	# $t1 will be '{'.

	$myself -> attribute_name('');

	return $t1;

} # End of start_attribute.

# --------------------------------------------------
# This is a function, not a method.

sub start_node
{
	my(undef, $t1, undef, $t2)  = @_;

	# $t1 will be '['.

	$myself -> node_name('');

	return $t1;

} # End of start_node.

# --------------------------------------------------
# This is a function, not a method.

sub start_subgraph
{
	my(undef, $t1, undef, $t2)  = @_;

	$myself -> group_name($t1);
	$myself -> items -> push
	({
		count => $myself -> _count,
		name  => $t1,
		type  => 'push_subgraph',
		value => '',
	});

	return $t1;

} # End of start_subgraph.

# --------------------------------------------------

1;

=pod

=head1 NAME

L<Graph::Easy::Marpa::Parser> - A Marpa-based parser for Graph::Easy

=head1 Synopsis

See L<Graph::Easy::Marpa/Data and Script Interaction>.

=head1 Description

L<Graph::Easy::Marpa::Parser> provides a L<Marpa>-based parser for L<Graph::Easy>-style graph definitions.

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
[e.g. maxlevel()]):

=over 4

=item o dot_input_file => $file_name

Specify the name of a file that the rendering engine can write to, which will contain the input
to dot (or whatever). This is good for debugging.

Default: ''.

If '', the file will not be created.

=item o format => $format_name

This is the format of the output file, to be created by the renderer.

Default is 'svg'.

=item o input_file => $csv_file_name

This is the name of the file to read containing the tokens (items) output from L<Graph::Easy::Marpa::Lexer>.

=item o logger => $logger_object

Specify a logger object.

To disable logging, just set logger to the empty string.

The default value is an object of type L<Log::Handler>.

This logger is passed to L<Graph::Easy::Marpa::Renderer::GraphViz2>.

=item o maxlevel => $level

This option is only used if L<Graph::Easy::Marpa:::Lexer> or L<Graph::Easy::Marpa::Parser>
create an object of type L<Log::Handler>. See L<Log::Handler::Levels>.

The default 'maxlevel' is 'info'. A typical value is 'debug'.

=item o minlevel => $level

This option is only used if L<Graph::Easy::Marpa:::Lexer> or L<Graph::Easy::Marpa::Parser>
create an object of type L<Log::Handler>. See L<Log::Handler::Levels>.

The default 'minlevel' is 'error'.

No lower levels are used.

=item o output_file => $output_file_name

If an output file name is supplied, and a rendering object is also supplied, then this call is made:

	$self -> renderer -> run
	(
	format      => $self -> format,
	items       => [$self -> items -> print],
	logger      => $self -> logger,
	output_file => $file_name,
	);

This is how the plotted graph is actually created.

=item o parsed_tokens_file => $token_file_name

This is the name of the file to write containing the tokens (items) output from L<Graph::Easy::Marpa::Parser>.

The default value is '', meaning the file is not written.

See also the input_file, above.

=item o rankdir => $direction

$direction must be one of: LR or RL or TB or BT.

Specify the rankdir of the graph as a whole.

The default value is: 'TB' (top to bottom).

=item o renderer => $renderer_object

This is the object whose run() method will be called to render the result of parsing
the cooked file received from L<Graph::Easy::Marpa::Lexer>.

The format of the parameters passed to the renderer are documented in L<Graph::Easy::Marpa::Renderer::GraphViz2/run(%arg)>,
which is the default value for this object.

=item o report_items => $Boolean

Calls L</report()> to report, via the log, the items recognized in the cooked file.

=item o tokens => $arrayref

This is an arrayref of tokens normally output by L<Graph::Easy::Marpa::Lexer>.

In some test files, this arrayref is constructed manually, and the 'input_file' is not used.

See L<Graph::Easy::Marpa::Lexer/tokens()> for a detailed explanation.

=back

=head1 Methods

=head2 dot_input_file([$file_name])

Here, the [] indicate an optional parameter.

Get or set the name of the file into which the rendering engine will write to input to dot (or whatever).

=head2 format([$format])

Here, the [] indicate an optional parameter.

Get or set the format of the output file.

=head2 grammar()

Initializes and returns a data structure of type L<Marpa::Grammar>. This defines the acceptable syntax
of the precise subset of L<Graph::Easy> definitions which this module is able to parse.

Note that the method grammar() calls (via L<Marpa>) various helper functions (i.e. not methods),
including edge_id(). The latter applies a restriction to the definition of edges in the grammar.

Specifically, edges must currently match this regexp: /^<?(-|=|\.|~|- |= |\.-|\.\.-){1,}>?$/, which I've gleaned
from the L<Graph::Easy> docs at L<Edges|http://bloodgate.com/perl/graph/manual/syntax.html#edges>.

Later, the allowable syntax will be exanded to accept special arrow heads, etc.

Also, since edges can have attributes, such attributes are another method of describing the desired edge's
characteristics. That is, besides using a string matching that regexp to specify what the edge looks like when plotted.

=head2 input_file([$cooked_file_name])

The [] indicate an optional parameter.

Get or set the name of the cooked file to read containing the tokens which has been output by L<Graph::Easy::Marpa::Lexer>.

=head2 items()

Returns a object of type L<Set::Array>, which is an arrayref of items output by the parser.

See the L</FAQ> for details.

See also run(), below.

=head2 logger([$logger_object])

Here, the [] indicate an optional parameter.

Get or set the logger object.

To disable logging, just set logger to the empty string.

This logger is passed to L<Graph::Easy::Marpa::Renderer::GraphViz2>.

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

=head2 output_file([$output_file_name])

Here, the [] indicate an optional parameter.

Get or set the name of the file to which the renderer will write to resultant graph.

This is how the plotted graph is actually created.

If no renderer is supplied, or no output file is supplied, nothing is written.

=head2 parsed_tokens_file([$token_file_name])

Here, the [] indicate an optional parameter.

Get or set the name of the file to write containing the tokens (items) output from L<Graph::Easy::Marpa::Parser>.

=head2 rankdir([$direction])

Here, the [] indicate an optional parameter.

Get or set the rankdir of the graph as a whole.

=head2 read_csv_file($file_name)

Read the named CSV file into ann arrayref of hashrefs.

=head2 renderer([$renderer_object])

Here, the [] indicate an optional parameter.

Get or set the value of the object which will do the rendering.

If an output file name is supplied, and a rendering object is also supplied, then this call is made:

	$self -> renderer -> run
	(
	format      => $self -> format,
	items       => [$self -> items -> print],
	logger      => $self -> logger,
	output_file => $file_name,
	);

This is how the plotted graph is actually created.

=head2 report()

Report, via the log, the list of items recognized in the cooked file.

=head2 report_items([$Boolean])

Here, the [] indicate an optional parameter.

Get or set the value which determines whether or not L</report()> is called.

=head2 run()

Runs the Marpa-based parser on the input_file.

Returns 0 for success and 1 for failure, or dies with an error message.

See t/attr.t, scripts/parse.pl and scripts/parse.sh.

The end result is an arrayref, accessible with the items() method, of hashrefs representing items
in the input stream.

The structure of this arrayref of hashrefs is discussed in the L</FAQ>.

=head2 tokens([$arrayref])

Here, the [] indicate an optional parameter.

Get or set an arrayref of tokens normally output by L<Graph::Easy::Marpa::Lexer>.

In some test files, this arrayref is constructed manually, and the 'input_file' is not used.

=head1 FAQ

=head2 How is the parsed graph stored in RAM?

See L<Graph::Easy::Marpa::Lexer/FAQ>.

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
