package Graph::Easy::Marpa;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use Graph::Easy::Marpa::Parser;
use Graph::Easy::Marpa::Renderer::GraphViz2;

use Log::Handler;

use Moo;

has description =>
(
	default  => sub{return ''},
	is       => 'rw',
#	isa      => 'Str',
	required => 0,
);

has dot_input_file =>
(
	default  => sub{return ''},
	is       => 'rw',
#	isa      => 'Str',
	required => 0,
);

has format =>
(
	default  => sub{return 'svg'},
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

has output_file =>
(
	default  => sub{return ''},
	is       => 'rw',
#	isa      => 'Str',
	required => 0,
);

has rankdir =>
(
	default  => sub{return 'TB'},
	is       => 'rw',
#	isa      => 'Str',
	required => 0,
);

has renderer =>
(
	default  => sub{return ''},
	is       => 'rw',
#	isa      => 'Str',
	required => 0,
);

has report_tokens =>
(
	default  => sub{return 0},
	is       => 'rw',
#	isa      => 'Int',
	required => 0,
);

has token_file =>
(
	default  => sub{return ''},
	is       => 'rw',
#	isa      => 'Str',
	required => 0,
);

our $VERSION = '2.04';

# --------------------------------------------------

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

} # End of BUILD.

# --------------------------------------------------

sub log
{
	my($self, $level, $s) = @_;

	$self -> logger -> log($level => $s) if ($self -> logger);

} # End of log.

# --------------------------------------------------

sub run
{
	my($self)   = @_;
	my($parser) = Graph::Easy::Marpa::Parser -> new
	(
		description   => $self -> description,
		input_file    => $self -> input_file,
		logger        => $self -> logger,
		maxlevel      => $self -> maxlevel,
		minlevel      => $self -> minlevel,
		report_tokens => $self -> report_tokens,
		token_file    => $self -> token_file,
	);
	my($result) = $parser -> run;

	$self -> logger -> log(debug => "Result of parser: $result (0 is success)") if ($self -> logger);

	if ($result == 0)
	{
		$result = Graph::Easy::Marpa::Renderer::GraphViz2 -> new
		(
			dot_input_file => $self -> dot_input_file,
			'format'       => $self -> format,
			logger         => $self -> logger,
			maxlevel       => $self -> maxlevel,
			minlevel       => $self -> minlevel,
			output_file    => $self -> output_file,
			rankdir        => $self -> rankdir,
		) -> run(items => $parser -> items);

		$self -> logger -> log(debug => "Result of renderer: $result (0 is success)") if ($self -> logger);
	}

	# Return 0 for success and 1 for failure.

	return $result;

} # End of run.

# --------------------------------------------------

1;

=pod

=head1 NAME

Graph::Easy::Marpa - A Marpa-based parser for Graph::Easy::Marpa-style Graphviz files

=head1 Synopsis

=head2 Sample Code

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use Graph::Easy::Marpa;

	use Getopt::Long;

	use Pod::Usage;

	# -----------------------------------------------

	my($option_parser) = Getopt::Long::Parser -> new();

	my(%option);

	if ($option_parser -> getoptions
	(
		\%option,
		'description=s',
		'dot_input_file=s',
		'format=s',
		'help',
		'input_file=s',
		'logger=s',
		'maxlevel=s',
		'minlevel=s',
		'output_file=s',
		'rankdir=s',
		'report_tokens=i',
		'token_file=s',
	) )
	{
		pod2usage(1) if ($option{'help'});

		# Return 0 for success and 1 for failure.

		exit Graph::Easy::Marpa -> new(%option) -> run;
	}
	else
	{
		pod2usage(2);
	}

This is shipped as C<scripts/parse.pl>, although the shipped version has built-in help.

Run 'perl -Ilib scripts/parse.pl -h' for sample demos.

=head2 Sample output

Unpack the distro and copy html/*.html and html/*.svg to your web server's doc root directory.

Then, point your browser at 127.0.0.1/index.html.

Or, hit L<http://savage.net.au/Perl-modules/html/graph.easy.marpa/index.html>.

=head2 Modules

=over 4

=item o Graph::Easy::Marpa

The current module, which documents the set of modules.

It uses L<Graph::Easy::Marpa::Parser> and L<Graph::Easy::Marpa::Renderer::GraphViz2>, and 'dot', to
render a C<Graph::Easy::Marpa>-syntax file into a (by default) *.svg file.

See scripts/parse.pl and scripts/parse.sh.

=item o Graph::Easy::Marpa::Parser

See L<Graph::Easy::Marpa::Parser>.

Accepts a graph definition in the Graph::Easy::Marpa language and builds a data structure representing the graph.

See scripts/parse.pl and scripts/parse.sh.

=item o Graph::Easy::Marpa::Renderer::GraphViz2

This is the default renderer, and can output a dot file, suitable for inputting to the C<dot> program.

Also, it can use L<GraphViz2> to call C<dot> and write dot's output to yet another file.

=item o Graph::Easy::Marpa::Actions

This is a file of methods called by L<Marpa::R2> as callbacks, during the parse.

End-users have no need to call any of its methods.

=item o Graph::Easy::Marpa::Config

This manages the config file, which contains a HTML template used by C<scripts/generate.index.pl>.

End-users have no need to call any of its methods.

=item o Graph::Easy::Marpa::Filer

Methods to help with reading sets of files.

End-users have no need to call any of its methods.

=item o Graph::Easy::Marpa::Utils

Methods to help with testing and generating the demo page.

See L<http://savage.net.au/Perl-modules/html/graph.easy.marpa/index.html>.

End-users have no need to call any of its methods.

=back

=head1 Description

L<Graph::Easy::Marpa> provides a L<Marpa>-based parser for C<Graph::Easy::Marpa>-style graph definitions.

Such graph definitions are wrappers around Graphviz's L<DOT|http://www.graphviz.org/content/dot-language> language.
Therefore this module is a pre-processor for DOT files.

The default renderer mentioned above, L<Graph::Easy::Marpa::Renderer::GraphViz2>, can be used to convert the graph
into a image.

See L</Data Files and Scripts> for details.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

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

C<new()> is called as C<< my($parser) = Graph::Easy::Marpa -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Graph::Easy::Marpa>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. maxlevel()]):

=over 4

=item o description => $graph_description_string

Specify a string for the graph definition.

You are strongly encouraged to surround this string with '...' to protect it from your shell.

See also the I<input_file> key to read the graph from a file.

The I<description> key takes precedence over the I<input_file> key.

The value for I<description> is passed to L<Graph::Easy::Marpa::Parser>.

Default: ''.

=item o dot_input_file => $file_name

Specify the name of a file that the rendering engine can write to, which will contain the input
to dot (or whatever). This is good for debugging.

If '', the file will not be created.

The value for I<dot_input_file> is passed to L<Graph::Easy::Marpa::Renderer::GraphViz2>.

Default: ''.

=item o format => $format_name

This is the format of the output file, to be created by the renderer.

The value for I<format> is passed to L<Graph::Easy::Marpa::Renderer::GraphViz2>.

Default: 'svg'.

=item o input_file => $graph_file_name

Read the graph definition from this file.

See also the I<description> key to read the graph from the command line.

The whole file is slurped in as a single graph.

The first few lines of the file can start with /^\s*#/, and will be discarded as comments.

The I<description> key takes precedence over the I<input_file> key.

The value for I<input_file> is passed to L<Graph::Easy::Marpa::Parser>.

Default: ''.

=item o logger => $logger_object

Specify a logger object.

The default value triggers creation of an object of type L<Log::Handler> which outputs to the screen.

To disable logging, just set I<logger> to the empty string.

The value for I<logger> is passed to L<Graph::Easy::Marpa::Parser> and to L<Graph::Easy::Marpa::Renderer::GraphViz2>.

Default: undef.

=item o maxlevel => $level

This option is only used if an object of type L<Log::Handler> is created. See I<logger> above.

See also L<Log::Handler::Levels>.

The value for I<maxlevel> is passed to L<Graph::Easy::Marpa::Parser> and to L<Graph::Easy::Marpa::Renderer::GraphViz2>.

Default: 'info'. A typical value is 'debug'.

=item o minlevel => $level

This option is only used if an object of type L<Log::Handler> is created. See I<logger> above.

See also L<Log::Handler::Levels>.

The value for I<minlevel> is passed to L<Graph::Easy::Marpa::Parser> and to L<Graph::Easy::Marpa::Renderer::GraphViz2>.

Default: 'error'.

No lower levels are used.

=item o output_file => $output_file_name

If an output file name is supplied, and a rendering object is also supplied, then this call is made:

	$self -> renderer -> run(format => $self -> format, items => [$self -> items -> print], output_file => $file_name);

This is how the plotted graph is actually created.

The value for I<output_file> is passed to L<Graph::Easy::Marpa::Renderer::GraphViz2>.

Default: ''.

=item o rankdir => $direction

$direction must be one of: LR or RL or TB or BT.

Specify the rankdir of the graph as a whole.

The value for I<rankdir> is passed to L<Graph::Easy::Marpa::Renderer::GraphViz2>.

Default: 'TB'.

=item o renderer => $renderer_object

This is the object whose run() method will be called to render the result of parsing
the input graph.

The format of the parameters passed to the renderer are documented in L<Graph::Easy::Marpa::Renderer::GraphViz2/run(%arg)>,
which is the default value for this object.

Default: ''.

=item o report_tokens => $Boolean

Reports, via the log, the tokens recognized by the parser.

The value for I<report_tokens> is passed to L<Graph::Easy::Marpa::Parser>.

Default: 0.

=item o token_file => $token_file_name

This is the name of the file to write containing the tokens (items) output from L<Graph::Easy::Marpa::Parser>.

The value for I<token_file> is passed to L<Graph::Easy::Marpa::Parser>.

Default: 0.

=back

=head1 Data Files and Scripts

=head2 Overview of the Data Flow

The parser works like this:

=over 4

=item o You use the parser Graph::Easy::Marpa::Parser directly ...

Call C<< Graph::Easy::Marpa::Parser -> new(%options) >>.

=item o ... or, you use Graph::Easy::Marpa, which calls the parser and then the renderer

Call C<< Graph::Easy::Marpa -> new(%options) >>.

Of course, the renderer is only called if the parser exits without error.

=back

Details:

=over 4

=item o Input a graph definition

This comes from the I<description> parameter to new(), or is read from a file with the I<input_file> parameter.

See new(input_file => $graph_file_name) or new(description => $graph_string) above for details.

A definition looks like '[node.1]{a:b;c:d}->{e:f;}->{g:h}[node.2]{i:j}->[node.3]{k:l}'.

Here, node names are: node.1, node.2 and node.3.

Edge names are: '->' for directed graphs, or '--' for undirected graphs.

Nodes and edges can have attributes, very much like CSS. The attributes in this sample are meaningless,
and are just to demonstrate the syntax.

And yes, unlike the original L<Graph::Easy> syntax, you can use a series of edges between 2 nodes,
with different attributes, as above.

See L<http://www.graphviz.org/content/attrs> for a long list of the attributes available for Graphviz.

=item o Parse the graph

After the parser runs successfully, the parser object holds a L<Set::Array> object of tokens representing the graph.

See L<Graph::Easy::Marpa::Parser/How is the parsed graph stored in RAM?> for details.

=item o Output the parsed tokens

See new(token_file => $csv_file_name) above for details.

=item o Call the renderer

=back

=head2 Data and Script Interaction

Sample input files for the parser are in data/*.ge. Sample output files are in data/*.tokens.

=over 4

=item o scripts/parse.pl and scripts/parser.sh

These use L<Graph::Easy::Marpa::Parser>.

They run the parser on one *.ge input file, and produce an arrayref of items.

Run scripts/parse.pl -h for samples of how to drive it.

Try:

	cat data/node.05.ge
	perl -Ilib scripts/parse.pl -i data/node.05.ge -t data/node.05.tokens -re 1

You can use scripts/parse.sh to simplify this process:

	scripts/parse.sh data/node.05.ge data/node.05.tokens -re 1
	scripts/parse.sh data/subgraph.12.ge data/subgraph.12.tokens -re 1

=back

=head1 Methods

=head2 description([$graph_description_string])

Here, the [] indicate an optional parameter.

Get or set the string for the graph definition.

See also the input_file() method to read the graph from a file, below.

The value supplied to the description() method takes precedence over the value read from the input file.

=head2 dot_input_file([$file_name])

Here, the [] indicate an optional parameter.

Get or set the name of the file into which the rendering engine will write to input to dot (or whatever).

=head2 format([$format])

Here, the [] indicate an optional parameter.

Get or set the format of the output file, to be created by the renderer.

=head2 input_file([$graph_file_name])

Here, the [] indicate an optional parameter.

Get or set the name of the file to read the graph definition from.

See also the description() method.

The whole file is slurped in as a single graph.

The first few lines of the file can start with /^\s*#/, and will be discarded as comments.

The value supplied to the description() method takes precedence over the value read from the input file.

=head2 log($level, $s)

Calls $self -> logger -> log($level => $s) if ($self -> logger).

Up until V 1.11, this used to call $self -> logger -> $level($s), but the change was made to allow
simpler loggers, meaning they did not have to implement all the methods covered by $level().
See CHANGES for details. For more on log levels, see L<Log::Handler::Levels>.

=head2 logger([$logger_object])

Here, the [] indicate an optional parameter.

Get or set the logger object.

To disable logging, just set logger to the empty string.

This logger is passed to L<Graph::Easy::Marpa::Parser> and L<Graph::Easy::Marpa::Renderer::GraphViz2>.

=head2 maxlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

This option is only used if an object of type L<Log::Handler> is created. See L<Log::Handler::Levels>.

=head2 minlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

This option is only used if an object of type L<Log::Handler> is created. See L<Log::Handler::Levels>.

=head2 output_file([$output_file_name])

Here, the [] indicate an optional parameter.

Get or set the name of the file to which the renderer will write to resultant graph.

This is how the plotted graph is actually created.

If no renderer is supplied, or no output file is supplied, nothing is written.

=head2 rankdir([$direction])

Here, the [] indicate an optional parameter.

Get or set the rankdir of the graph as a whole.

The default is 'TB' (top to bottom).

=head2 renderer([$rendering_object])

Here, the [] indicate an optional parameter.

Get or set the rendering object.

This is the object whose run() method will be called to render the result of parsing the input file.

The format of the parameters passed to the renderer are documented in L<Graph::Easy::Marpa::Renderer::GraphViz2/run(%arg)>,
which is the default value for this object.

=head2 report_tokens([$Boolean])

Here, the [] indicate an optional parameter.

Get or set the flag to report, via the log, the items recognized in the tokens file.

Calls L<Graph::Easy::Marpa::Parser/report()> to do the reporting.

=head2 tokens_file([$token_file_name])

Here, the [] indicate an optional parameter.

Get or set the name of the file to write containing the tokens (items) output from L<Graph::Easy::Marpa::Parser>.

=head1 FAQ

=head2 Has anything changed moving from V 1.* to V 2.*?

Yes:

=over 4

=item o Input file naming

The test data files are shipped as data/*.ge.

Of course, you can use any input file name you wish.

=item o Output file naming

The output files of parsed tokens are shipped as data/*.tokens.

Of course, you can use any output file name you wish.

=item o Output files

The output files, data/*.dot, are now shipped.

=back

=head2 What is the homepage of Marpa?

L<http://jeffreykegler.github.io/Ocean-of-Awareness-blog/>.

=head2 How do I reconcile Marpa's approach with classic lexing and parsing?

I've included in
L<this article|http://savage.net.au/Ron/html/Conditional.preservation.of.whitespace.html#Constructing_a_Mental_Picture_of_Lexing_and_Parsing>
a section which is aimed at helping us think about this issue.

=head2 What is the purpose of this set of modules?

It's a complete re-write of L<Graph::Easy>, designed to make on-going support for the C<Graph::Easy::Marpa> language
much, much easier.

=head2 What are Graph::Easy::Marpa graphs?

In short, it means a text string containing a definition of a graph, using a cleverly designed language,
that can be used to describe the sort of graph you wish to plot. Then, L<Graph::Easy::Marpa> does the plotting
by calling L<Graph::Easy::Marpa::Renderer::GraphViz2>.

See L<Graph::Easy::Marpa::Parser/What is the Graph::Easy::Marpa language?>.

=head2 What do Graph::Easy::Marpa graph definitions look like?

	[node_1]{color: red; style: circle} -> {class: fancy;} [node_2]{color: green;}

=head2 How are graphs stored in RAM by the parser?

See L<Graph::Easy::Marpa::Parser/FAQ>.

=head2 How are attributes assigned to nodes and edges?

Since the scan of the input stream is linear, any attribute detected belongs to the nearest preceeding
node(s) or edge.

=head2 How are attributes assigned to groups?

The only attributes which can be passed to a subgraph (group) are those that 'dot' accepts under the 'graph'
part of a subgraph definition.

This means the attribute 'rank' cannot be passed, yet.

=head2 Is there sample data I can examine?

See data/*.ge and the corresponding data/*.tokens and html/*.svg.

Note: Some files contain deliberate mistakes. See above for scripts/parse.pl and scripts/parse.sh.

=head2 What about the fact the Graph::Easy can read various other definition formats?

I have no plans to support such formats. Nevertheless, having written these modules, it should be fairly
easy to derive classes which perform that sort of work.

=head2 How to I re-generate the web page of demos?

See scripts/generate.index.pl.

=head2 What are the defaults for GraphViz2, the default rendering engine?

	 GraphViz2 -> new
	 (
	  edge    => $class{edge}   || {color => 'grey'},
	  global  => $class{global} || {directed => 1},
	  graph   => $class{graph}  || {rankdir => $self -> rankdir},
	  logger  => $self -> logger,
	  node    => $class{node} || {shape => 'oval'},
	  verbose => 0,
	 )

where $class($name) is taken from the class declarations at the start of the input stream.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Thanks

Many thanks are due to the people who worked on L<Graph::Easy>.

Jeffrey Kegler wrote L<Marpa>, and has been helping me via private emails.

=head1 Repository

L<https://github.com/ronsavage/Graph-Easy-Marpa>

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
