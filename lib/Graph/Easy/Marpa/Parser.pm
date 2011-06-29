package Graph::Easy::Marpa::Parser;

use strict;
use warnings;

use Graph::Easy::Marpa::Renderer::GraphViz2;

use Hash::FieldHash ':all';

use IO::File;

use Log::Handler;

use Marpa;

use Set::Array;

use Text::CSV_XS;

fieldhash my %attrs        => 'attrs';
fieldhash my %attr_name    => 'attr_name';
fieldhash my %format       => 'format';
fieldhash my %input_file   => 'input_file';
fieldhash my %items        => 'items';
fieldhash my %logger       => 'logger';
fieldhash my %maxlevel     => 'maxlevel';
fieldhash my %minlevel     => 'minlevel';
fieldhash my %node_name    => 'node_name';
fieldhash my %output_file  => 'output_file';
fieldhash my %renderer     => 'renderer';
fieldhash my %report_items => 'report_items';
fieldhash my %token_file   => 'token_file';
fieldhash my %tokens       => 'tokens';

# $myself is a copy of $self for use by functions called by Marpa.

our $myself;
our $VERSION = '0.91';

# --------------------------------------------------
# This is a function, not a method.

sub attr_name_id
{
	my(undef, $t1, undef, $t2)  = @_;

	$myself -> attr_name($t1);

	return $t1;

} # End of attr_name_id.

# --------------------------------------------------
# This is a function, not a method.

sub attr_value_id
{
	my(undef, $t1, undef, $t2)  = @_;

	$myself -> attrs -> push
	({
		name  => $myself -> attr_name,
		type  => 'attribute',
		value => $t1,
	});

	return $t1;

} # End of attr_value_id.

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

	# Add edge to the item list.

	$myself -> items -> push
	({
		name => $t1,
		type => 'edge',
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

	return '';

} # End of end_attribute.

# --------------------------------------------------
# This is a function, not a method.

sub end_node
{
	my(undef, $t1, undef, $t2)  = @_;

	# $t1 will be ']'.

	$myself -> items -> push
	({
		name => $myself -> node_name,
		type => 'node',
	});

	return '';

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

		if ($$item{type} =~ /(?:edge|node)/)
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
	my($grammar) = Marpa::Grammar -> new
		({
		 actions       => 'Graph::Easy::Marpa::Parser',
		 lhs_terminals => 0,
		 start         => 'graph_definition',
		 rules         =>
			 [
			  {   # Graph stuff.
				  lhs => 'graph_definition',
				  rhs => [qw/graph_sequence/],
			  },
			  {
				  lhs => 'graph_sequence', # 1 of 2.
				  rhs => [qw/node_definition/],
			  },
			  {
				  lhs => 'graph_sequence', # 2 of 2.
				  rhs => [qw/graph_sequence edge_definition node_definition/],
			  },
			  {   # Node stuff.
				  lhs => 'node_definition',
				  rhs => [qw/node_sequence/],
				  min => 0,
			  },
			  {
				  lhs => 'node_sequence', # 1 of 2.
				  rhs => [qw/node_statement/],
			  },
			  {
				  lhs => 'node_statement',
				  rhs => [qw/start_node node_name end_node attr_definition/],
			  },
			  {
				  lhs => 'node_sequence', # 2 of 2.
				  rhs => [qw/node_statement daisy_chain_node/],
			  },
			  {
				  lhs    => 'start_node',
				  rhs    => [qw/left_bracket/],
				  action => 'start_node',
			  },
			  {
				  lhs    => 'node_name',
				  rhs    => [qw/node_name_id/],
				  min    => 0,
				  action => 'node_name_id',
			  },
			  {
				  lhs    => 'end_node',
				  rhs    => [qw/right_bracket/],
				  action => 'end_node',
			  },
			  {   # Attribute stuff.
				  lhs => 'attr_definition',
				  rhs => [qw/attr_statement/],
				  min => 0,
			  },
			  {
				  lhs => 'attr_statement',
				  rhs => [qw/start_attribute attr_sequence end_attribute/],
			  },
			  {
				  lhs    => 'start_attribute',
				  rhs    => [qw/left_brace/],
				  action => 'start_attribute',
			  },
			  {
				  lhs => 'attr_sequence',
				  rhs => [qw/attr_declaration/],
				  min => 1,
			  },
			  {
				  lhs => 'attr_declaration',
				  rhs => [qw/attr_name colon attr_value attr_terminator/],
			  },
			  {
				  lhs    => 'attr_name',
				  rhs    => [qw/attr_name_id/],
				  min    => 1,
				  action => 'attr_name_id',
			  },
			  {
				  lhs    => 'attr_value',
				  rhs    => [qw/attr_value_id/],
				  min    => 1,
				  action => 'attr_value_id',
			  },
			  {
				  lhs => 'attr_terminator',
				  rhs => [qw/semi_colon/],
				  min => 1,
			  },
			  {
				  lhs    => 'end_attribute',
				  rhs    => [qw/right_brace/],
				  action => 'end_attribute',
			  },
			  {   # Edge stuff.
				  lhs    => 'edge_definition',
				  rhs    => [qw/edge_name attr_definition/],
			  },
			  {
				  lhs    => 'edge_name',
				  rhs    => [qw/edge_id/],
				  action => 'edge_id',
			  },
			 ],
		});

	$grammar -> precompute;

	return $grammar;

} # End of grammar;

# --------------------------------------------------

sub _init
{
	my($self, $arg)     = @_;
	$$arg{attrs}        = Set::Array -> new;
	$$arg{attr_name}    = '';
	$$arg{format}       ||= 'svg';
	$$arg{input_file}   ||= ''; # Caller can set.
	$$arg{items}        = Set::Array -> new;
	$$arg{logger}       = Log::Handler -> new;
	$$arg{maxlevel}     ||= 'debug'; # Caller can set.
	$$arg{minlevel}     ||= 'error'; # Caller can set.
	$$arg{node_name}    = '';
	$$arg{output_file}  ||= ''; # Caller can set.
	$$arg{renderer}     ||= Graph::Easy::Marpa::Renderer::GraphViz2 -> new;
	$$arg{report_items} ||= 0;  # Caller can set.
	$$arg{token_file}   ||= ''; # Caller can set.
	$$arg{tokens}       ||= []; # Caller can set.
	$self               = from_hash($self, $arg);
	$myself             = $self;

	$self -> logger -> add
		(
		 screen =>
		 {
			 maxlevel       => $self -> maxlevel,
			 message_layout => '%m',
			 minlevel       => $self -> minlevel,
		 }
		);

	return $self;

} # End of _init.

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
# This is a function, not a method.

sub node_name_id
{
	my(undef, $t1, undef, $t2)  = @_;

	$myself -> node_name($t1);

	return $t1;

} # End of node_name_id.

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
	my($self) = @_;

	my($tokens);

	if ($#{$self -> tokens} < 0)
	{
		for my $record (@{$self -> read_csv_file($self -> input_file)})
		{
			# Remove '...' surrounding edge, etc names.
			# Use .* not .+ to allow for anonymous nodes.

			$$record{value} =~ s/^'(.*)'$/$1/;

			push @$tokens, [$$record{key}, $$record{value}];
		}
	}
	else
	{
		$tokens = $self -> tokens;
	}

	my($recognizer) = Marpa::Recognizer -> new({grammar => $self -> grammar});

	$recognizer -> tokens($tokens);

	my($result) = $recognizer -> value;
	$result     = $result ? ${$result} : 'Parse failed';
	$result     = $result ? $result    : 0;

	die $result if ($result);

	$self -> report if ($self -> report_items);

	my($file_name) = $self -> token_file;

	if ($file_name)
	{
		$self -> _generate_item_file($file_name);
	}

	$file_name = $self -> output_file;

	if ($file_name && $self -> renderer)
	{
		$self -> renderer -> run(format => $self -> format, items => [$self -> items -> print], output_file => $file_name);
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

	$myself -> attr_name('');

	return '';

} # End of start_attribute.

# --------------------------------------------------
# This is a function, not a method.

sub start_node
{
	my(undef, $t1, undef, $t2)  = @_;

	# $t1 will be '['.

	$myself -> node_name('');

	return '';

} # End of start_node.

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

=item o format => $format_name

This is the format of the output file, to be created by the renderer.

Default is 'svg'.

=item o input_file => $csv_file_name

This is the name of the file to read containing the tokens (items) output from L<Graph::Easy::Marpa::Lexer>.

=item o maxlevel => $level

This option affects L<Log::Handler>. See L<Log::Handler::Levels>.

The default maxlevel is 'info'. A typical value is 'debug'.

=item o minlevel => $level

This option affects L<Log::Handler>. See L<Log::Handler::Levels>.

The default minlevel is 'error'.

No lower levels are used.

=item o output_file => $output_file_name

If an output file name is supplied, and a rendering object is also supplied, then this call is made:

	$self -> renderer -> run(format => $self -> format, items => [$self -> items -> print], output_file => $file_name);

This is how the plotted graph is actually created.

=item o renderer => $renderer_object

This is the object whose run() method will be called to render the result of parsing
the cooked file received from L<Graph::Easy::Marpa::Lexer>.

The format of the parameters passed to the renderer are documented in L<Graph::Easy::Marpa::Renderer::GraphViz2/run(%arg)>,
which is the default value for this object.

=item o report_items => $Boolean

Calls L</report()> to report, via the log, the items recognized in the cooked file.

=item o token_file => $token_file_name

This is the name of the file to write containing the tokens (items) output from L<Graph::Easy::Marpa::Parser>.

See also the input_file, above.

=item o tokens => $arrayref

This is an arrayref of tokens normally output by L<Graph::Easy::Marpa::Lexer>.

In some test files, this arrayref is constructed manually, and the 'input_file' is not used.

=back

=head1 Methods

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

=head2 items()

Returns a object of type L<Set::Array>, which is an arrayref of items output by the state machine.

See the L<Graph::Easy::Marpa/FAQ> for details.

These items are I<not> the same as the arrayref of items returned by the items() methods in
L<Graph::Easy::Marpa::DFA> and L<Graph::Easy::Marpa::Lexer>.

See also run(), below.

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

Report, via the log, the list of items recognized in the cooked file.

=head2 run()

Runs the Marpa-based parser on the input_file.

Returns 0 for success and 1 for failure, or dies with an error message.

See t/attr.t, scripts/parse.pl and scripts/parse.sh.

The end result is an arrayref, accessible with the items() method, of hashrefs representing items
in the input stream.

The structure of this arrayref of hashrefs is discussed in the L<Graph::Easy::Marpa/FAQ>.

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
