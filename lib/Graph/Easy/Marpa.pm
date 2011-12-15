package Graph::Easy::Marpa;

use strict;
use warnings;

use Graph::Easy::Marpa::Lexer;
use Graph::Easy::Marpa::Parser;
use Graph::Easy::Marpa::Renderer::GraphViz2;

use Hash::FieldHash ':all';

use Log::Handler;

fieldhash my %cooked_file        => 'cooked_file';
fieldhash my %description        => 'description';
fieldhash my %dot_input_file     => 'dot_input_file';
fieldhash my %format             => 'format';
fieldhash my %input_file         => 'input_file';
fieldhash my %items              => 'items';
fieldhash my %lexer              => 'lexer';
fieldhash my %logger             => 'logger';
fieldhash my %maxlevel           => 'maxlevel';
fieldhash my %minlevel           => 'minlevel';
fieldhash my %output_file        => 'output_file';
fieldhash my %parsed_tokens_file => 'parsed_tokens_file';
fieldhash my %parser             => 'parser';
fieldhash my %rankdir            => 'rankdir';
fieldhash my %renderer           => 'renderer';
fieldhash my %report_items       => 'report_items';
fieldhash my %report_stt         => 'report_stt';
fieldhash my %stt_file           => 'stt_file';
fieldhash my %timeout            => 'timeout';
fieldhash my %type               => 'type';

our $VERSION = '1.07';

# --------------------------------------------------

sub _init
{
	my($self, $arg)           = @_;
	$$arg{cooked_file}        ||= ''; # Caller can set.
	$$arg{description}        ||= ''; # Caller can set.
	$$arg{dot_input_file}     ||= ''; # Caller can set.
	$$arg{format}             ||= 'svg';
	$$arg{input_file}         ||= ''; # Caller can set.
	$$arg{lexer}              = '';
	my($user_logger)          = defined($$arg{logger}); # Caller can set (e.g. to '').
	$$arg{logger}             = $user_logger ? $$arg{logger} : Log::Handler -> new;
	$$arg{maxlevel}           ||= 'warning';# Caller can set.
	$$arg{minlevel}           ||= 'error'; # Caller can set.
	$$arg{output_file}        ||= ''; # Caller can set.
	$$arg{parsed_tokens_file} ||= ''; # Caller can set.
	$$arg{parser}             = '';
	$$arg{renderer}           ||= '';
	$$arg{report_items}       ||= 0;  # Caller can set.
	$$arg{report_stt}         ||= 0;  # Caller can set.
	$$arg{stt_file}           ||= ''; # Caller can set.
	$$arg{timeout}            ||= 3;  # Caller can set.
	$$arg{type}               ||= ''; # Caller can set.
	$self                     = from_hash($self, $arg);

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

sub run
{
	my($self)  = @_;
	my($lexer) = Graph::Easy::Marpa::Lexer -> new
		(
		 cooked_file  => $self -> cooked_file,
		 description  => $self -> description,
		 input_file   => $self -> input_file,
		 logger       => $self -> logger,
		 maxlevel     => $self -> maxlevel,
		 minlevel     => $self -> minlevel,
		 report_items => $self -> report_items,
		 report_stt   => $self -> report_stt,
		 stt_file     => $self -> stt_file,
		 timeout      => $self -> timeout,
		 type         => $self -> type,
		);

	# Return 0 for success and 1 for failure.

	my($result) = $lexer -> run;

	if ($result == 0)
	{
		$result = Graph::Easy::Marpa::Parser -> new
			(
			 dot_input_file     => $self -> dot_input_file,
			 'format'           => $self -> format,
			 input_file         => $self -> cooked_file,
			 logger             => $self -> logger,
			 maxlevel           => $self -> maxlevel,
			 minlevel           => $self -> minlevel,
			 output_file        => $self -> output_file,
			 parsed_tokens_file => $self -> parsed_tokens_file,
			 rankdir            => $self -> rankdir,
			 report_items       => $self -> report_items,
			 tokens             => $lexer -> tokens,
			) -> run;
	}
	else
	{
		$self -> log(warn => 'The lexer failed. The parser will not be run') if ($self -> logger);
	}

	# Return 0 for success and 1 for failure.

	return $result;

} # End of run.

# --------------------------------------------------

1;

=pod

=head1 NAME

L<Graph::Easy::Marpa> - A Marpa- and Set::FA::Element-based parser for Graph::Easy

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
	 'cooked_file=s',
	 'description=s',
	 'format=s',
	 'help',
	 'input_file=s',
	 'logger=s',
	 'maxlevel=s',
	 'minlevel=s',
	 'output_file=s',
	 'parsed_tokens_file=s',
	 'stt_file=s',
	 'type=s',
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

This is shipped as scripts/gem.pl, although the shipped version has built-in help.

See also scripts/lex.pl and scripts/parse.pl.

=head2 Sample output

Unpack the distro and copy html/*.html and html/*.svg to your web server's doc root directory.

Then, point your browser at 127.0.0.1/index.html.

Or, hit L<http://savage.net.au/Perl-modules/html/graph.easy.marpa/index.html>.

=head2 Modules

=over 4

=item o Graph::Easy::Marpa

The current module, which documents the set of modules.

It uses L<Graph::Easy::Lexer>, L<Graph::Easy::Parser> and L<Graph::Easy::Marpa::GraphViz2> to
render a L<Graph::Easy>-syntax file into a (by default) *.svg file.

See scripts/gem.pl and scripts/gem.sh.

=item o Graph::Easy::Marpa::Lexer

See L<Graph::Easy::Marpa::Lexer>.

Processes a raw L<Graph::Easy> graph definition and outputs a cooked representation of that graph in a language
which can be read by the parser.

See scripts/lex.pl and scripts/lex.sh.

=item o Graph::Easy::Marpa::Lexer::DFA

See L<Graph::Easy::Marpa::Lexer::DFA>.

Wraps L<Set::FA::Element>, which is what actually lexes the input L<Graph::Easy>-syntax graph definition.

=item o Graph::Easy::Marpa::Parser

See L<Graph::Easy::Marpa::Parser>.

Accepts a graph definition in the cooked language and builds a data structure representing the graph.

See scripts/parse.pl and scripts/parse.sh.

=item o Graph::Easy::Marpa::Utils

Code to help with testing.

=back

=head1 Description

L<Graph::Easy::Marpa> provides a L<Marpa>-based parser for L<Graph::Easy>-style graph definitions.

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

=item o cooked_file => $csv_file_name

This is the name of the file to write containing the tokens (items) output from L<Graph::Easy::Marpa::Lexer>.

This file can be input to L<Graph::Easy::Marpa::Parser>.

See also the 'parsed_tokens_file' key, below.

=item o description => $graph_description_string

Specify a string for the graph definition.

You are strongly encouraged to surround this string with '...' to protect it from your shell.

See also the 'input_file' key to read the graph from a file.

The 'description' key takes precedence over the 'input_file' key.

=item o dot_input_file => $file_name

Specify the name of a file that the rendering engine can write to, which will contain the input
to dot (or whatever). This is good for debugging.

Default: ''.

If '', the file will not be created.

=item o format => $format_name

This is the format of the output file, to be created by the renderer.

Default is 'svg'.

=item o input_file => $graph_file_name

Read the graph definition from this file.

See also the 'description' key to read the graph from the command line.

The whole file is slurped in as 1 graph.

The first lines of the file can start with /^\s*#/, and will be discarded as comments.

The 'description' key takes precedence over the 'input_file' key.

=item o logger => $logger_object

Specify a logger object.

To disable logging, just set logger to the empty string.

The default value is an object of type L<Log::Handler> which outputs to the screen.

This logger is passed to L<Graph::Easy::Marpa::Lexer>, L<Graph::Easy::Marpa::Lexer::DFA>,
L<Graph::Easy::Marpa::Parser> and L<Graph::Easy::Marpa::Renderer::GraphViz2>.

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

	$self -> renderer -> run(format => $self -> format, items => [$self -> items -> print], output_file => $file_name);

This is how the plotted graph is actually created.

=item o parsed_tokens_file => $token_file_name

This is the name of the file to write containing the tokens (items) output from L<Graph::Easy::Marpa::Parser>.

See also the 'cooked_file' key, above.

=item o renderer => $renderer_object

This is the object whose run() method will be called to render the result of parsing
the cooked file received from L<Graph::Easy::Marpa::Lexer>.

The format of the parameters passed to the renderer are documented in L<Graph::Easy::Marpa::Renderer::GraphViz2/run(%arg)>,
which is the default value for this object.

=item o report_items => $Boolean

Calls L<Graph::Easy::Marpa::Parser/report()> to report, via the log, the items recognized in the cooked file.

=item o stt_file => $stt_file_name

Specify which file contains the state transition table.

Default: ''.

The default value means the STT is read from the source code of Graph::Easy::Marpa::Lexer.

Candidate files are '', 'data/default.stt.csv' and 'data/default.stt.ods'.

The type of this file must be specified by the 'type' key.

=item o timeout => $seconds

Run the DFA for at most this many seconds.

Default: 3.

=item o type => $stt_file_type

Specify the type of the stt_file: '' for internal, csv for CSV, or ods for Open Office Calc spreadsheet.

Default is ''.

The default value means the STT is read from the source code of Graph::Easy::Marpa::Lexer.

This option must be used with the 'stt_file' key.

=back

=head1 Data Files and Scripts

=head2 Overview of the Data Flow

The lexer and the parser work like this:

=over 4

=item o L<Lexer|Graph::Easy::Marpa::Lexer> input

=over 4

=item o The State Transition Table (STT) file

The STT is stored outside the code (unlike the grammar for the cooked graph definition).

The current design ships the STT in 2 files, data/default.stt.ods and data/default.stt.csv.

*.ods is an Open Office Calc spreadsheet, and *.csv is a Comma-Separated Variable file.

This allows any user to change the STT as an experiment.

I work with the *.ods file, and export it to the *.csv file.

The program scripts/stt2html.pl converts the *.csv file to html for ease of display.

See new(stt_file => $stt_file_name, type => $stt_file_type) in L<Graph::Easy::Marpa::Lexer/Constructor_and_Initialization> for details.

=item o The raw L<Graph::Easy> Graph Definition

A definition looks like '[node.1]{a:b;c:d}<->{e:f;}<=>{g:h}[node.2]{i:j}===[node.3]{k:l}'.

Node names are: node.1, node.2 and node.3.

Edge names are: <->, <=> and ===.

And yes, unlike the original L<Graph::Easy> syntax, you can use a series of edges between 2 nodes,
as with <-> and <=> above.

Nodes and edges can have attributes, very much like CSS. The attributes in this sample are meaningless,
and are just to demonstrate the syntax.

The lexer can accept a graph definition in 2 ways:

See new(file => $graph_file_name) or new(graph => $graph_string) in L<Graph::Easy::Marpa::Lexer/Constructor_and_Initialization> for details.

=back

=item o L<Lexer|Graph::Easy::Marpa::Lexer> processing

Call the lexer as my($result) = Graph::Easy::Marpa::Lexer -> new(%options) -> run.

run() returns 0 for success and 1 for failure.

run() dies with an error message upon error.

=item o L<Lexer|Graph::Easy::Marpa::Lexer> output

The lexer writes a cooked graph definition to a file, using an intermediary language I invented just for this purpose.

The output file is in *.csv format. This file becomes input for the parser.

Of course, to exercise the parser, such files can be created manually.

See new(cooked => $csv_file_name) in L<Graph::Easy::Marpa::Lexer/Constructor_and_Initialization> for details.

=item o L<Parser|Graph::Easy::Marpa::Parser> input

=over 4

=item o The Grammar for the Cooked Graph Definition

The grammar is stored inside the code (unlike the STT).

This grammar is recognized by L<Marpa>, which is the basis of the parser. See L<Graph::Easy::Marpa::Parser/grammar()>.

=item o The Cooked Graph Definition

The *.csv file output by the lexer, or created manually, is the other input to the parser.

=back

=item o L<Parser|Graph::Easy::Marpa::Parser> processing

Call the parser as my($result) = Graph::Easy::Marpa::Parser -> new(%options) -> run.

run() returns 0 for success and 1 for failure.

run() dies with an error message upon error.

=item o L<Parser|Graph::Easy::Marpa::Parser> output

After the parser runs successfully, the parser object holds a L<Set::Array> object of tokens representing the graph.

An arrayref of items can be retrieved with the items() method in both the lexer and the parser.

The format of this array is documented below, in the L</FAQ>.

Later, a formatter will be written to position the tokens in space, for passing to a plotter just as 'dot'.

=back

=head2 Data and Script Interaction

Sample input files for the lexer are in data/*.raw. Sample output files from the lexer, which are also
input files for the parser, are in data/*.cooked.

=over 4

=item o scripts/lex.pl and scripts/lex.sh

These use L<Graph::Easy::Marpa::Lexer>.

They run the lexer on 1 *.raw input file, and produce an arrayref of items, and - optionally - 1 *.cooked output file.

Run scripts/lex.pl -h for samples of how to drive it.

Try:

	perl -Ilib scripts/lex.pl -stt data/default.stt.csv -t csv -i data/node.04.raw -c data/node.04.cooked
	cat data/node.04.raw
	cat data/node.04.cooked

	perl -Ilib scripts/lex.pl -stt data/default.stt.csv -t csv -i data/node.05.raw -c data/node.05.cooked
	cat data/node.04.raw
	cat data/node.04.cooked

You can use scripts/lex.sh to simplify this process:

	scripts/lex.sh data/node.05.raw data/node.05.cooked
	scripts/lex.sh data/graph.12.raw data/graph.12.cooked

=item o scripts/parse.pl and scripts/parser.sh

These use L<Graph::Easy::Marpa::Parser>.

They run the parser on 1 *.cooked input file, and produce an arrayref of items.

Run scripts/parse.pl -h for samples of how to drive it.

Try:

	cat data/node.05.cooked
	perl -Ilib scripts/parse.pl -i data/node.05.cooked

You can use scripts/parse.sh to simplify this process:

	scripts/parse.sh data/node.05.cooked
	scripts/parse.sh data/graph.12.cooked

=item o scripts/gem.pl and scripts/gem.sh

This uses L<Graph::Easy::Marpa> to combine calls to L<Graph::Easy::Marpa::Lexer> and L<Graph::Easy::Marpa::Parser>.

Run scripts/gem.pl -h for samples of how to drive it.

Try, using an environment variable for brevity:

	X=graph.13
	perl -Ilib scripts/gem.pl -i data/$X.raw -c $X.cooked -o $X.svg -p $X.items
	cat $X.cooked
	cat $X.items
	cat $X.svg

You can use scripts/gem.sh to simplify this process:

	X=graph.13
	scripts/gem.sh $X
	cat $X.cooked
	cat $X.items
	cat $X.svg

=back

=head2 The Subset of L<Graph::Easy> Graph Definitions Accepted by the Parser

Obviously, the STT in data/default.stt.ods and data/default.stt.csv defines precisely the currently acceptable
syntax for graph definitions.

So, this section gives a more casual explanation.

=over 4

=item o Attributes

=over 4

=item o Attribute names

The attribute name must match /^[a-z]+$/.

=item o Attribute values

The attribute value is any string up to the next ';' or '}'.

Attribute values may be quoted with "..." or '...'. These quotes are stripped.

=back

=item o Classes

Class + subclass names must match /^(edge|global|graph|group|node)(\.[a-z]+)?$/.

The name before the '.' is the class name.

'global' is used to specify whether you want a directed or undirected graph. The default is directed.

	global {directed: 1} [node.1] -> [node.2]

'graph' is used to specify the direction of the graph as a whole, and must be one of: LR or RL or TB or BT.
The default is TB.

	graph {rankdir: LR} [node.1] -> [node.2]

The name after the '.' is the subclass name. And if '.' is present, the subclass name must be present.
This means things like 'edge.' etc are syntax errors.

You use the subclass name in the attributes of an edge, a group or a node, whereas 'global' and 'graph'
appear only once, at the start of the input stream.

	node {shape: square} node.forest {color: green}
	[node.1] -> [node.2] {class: forest} -> [node.3] {shape: circle; color: blue}

Here, node.1 gets the default shape, square, and node.2 gets both shape square and color green. node.3
gets shape circle and color blue.

As always, specific attributes override class attributes.

=item o Daisy-chains

=over 4

=item o Edges

Edges must match /^(->|--)$/.

Edges can be daisy-chained by using a comma, ',', newline, space, or attributes, '{...}', to separate them.

Hence both of these are valid: '->,->{color:green}' and '->{color:red}->{color:green}'.

Edges can have attributes such as arrowhead, arrowtail, etc. See L<Graphviz|http://www.graphviz.org/content/attrs>

The edge is actually rendered, via the default renderer L<GraphViz2>, by L<Graphviz|http://www.graphviz.org/>.

Note: The syntax for edges is just a visual clue for the user. The directed 'v' undirected nature of the graph
depends on the value of the 'directed' attribute present (explicitly or implicitly) in the input stream.

The default is {directed: 1}. See data/class.global.01.raw for a case where we use {directed: 0} attached to
class 'global'.

=item o Groups

Groups can be daisy chained by juxtaposition, or by using a newline or space to separate them.

=item o Nodes

Nodes can be daisy chained by juxtaposition, or by using the comma, ',', newline, space, or attributes, '{...}', to separate them.

Hence all of these are valid: '[node.1][node.2]' and '[node.1],[node.2]' and '[node.1]{color:red}[node.2]'.

=back

=item o Events

These are part of the STT, but are not part of the L<Graph::Easy> language.

Their names must match /^[a-zA-Z_][a-zA-Z_0-9.]*$/.

=item o Groups

Group names must match /^[a-zA-Z_.][a-zA-Z_0-9. ]*$/.

=item o Nodes

Node names must match /^[a-zA-Z_0-9. ]+$/.

Since leading and trailing spaces are stripped, a single space can be used to represent the
anonymous node.

=item o States

These are part of the STT, but are not part of the L<Graph::Easy> language.

Their names must match /^[a-zA-Z_][a-zA-Z_0-9]*$/.

In the STT, this regexp applies to both the State name column ('C' in the spreadsheet data/default.stt.ods)
and the Next state name column ('E').

=back

=head1 Methods

=head2 cooked_file([$csv_file_name])

Here, the [] indicate an optional parameter.

Get or set the name of the file to write containing the tokens (items) output from L<Graph::Easy::Marpa::Lexer>.

See also the parsed_tokens_file() method, below.

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

The whole file is slurped in as 1 graph.

The first lines of the file can start with /^\s*#/, and will be discarded as comments.

The value supplied to the description() method takes precedence over the value read from the input file.

=head2 log($level, $s)

Calls $self -> logger -> $level($s).

=head2 logger([$logger_object])

Here, the [] indicate an optional parameter.

Get or set the logger object.

To disable logging, just set logger to the empty string.

This logger is passed to L<Graph::Easy::Marpa::Lexer>, L<Graph::Easy::Marpa::Lexer::DFA>,
L<Graph::Easy::Marpa::Parser> and L<Graph::Easy::Marpa::Renderer::GraphViz2>.

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

See also the cooked_file() method, above.

=head2 renderer([$rendering_object])

Here, the [] indicate an optional parameter.

Get or set the rendering object.

This is the object whose run() method will be called to render the result of parsing
the cooked file received from L<Graph::Easy::Marpa::Lexer>.

The format of the parameters passed to the renderer are documented in L<Graph::Easy::Marpa::Renderer::GraphViz2/run(%arg)>,
which is the default value for this object.

=head2 report_items([$Boolean])

Here, the [] indicate an optional parameter.

Get or set the flag to report, via the log, the items recognized in the cooked file.

Calls L<Graph::Easy::Marpa::Parser/report()> to do the reporting.

=head2 stt_file([$stt_file_name])

The [] indicate an optional parameter.

Get or set the name of the file containing the state transition table.

This option is used in conjunction with the type() option.

=head2 timeout($seconds)

The [] indicate an optional parameter.

Get or set the timeout for how long to run the DFA.

=head2 type([$type])

The [] indicate an optional parameter.

Get or set the value which determines what type of stt_file is read.

=head1 FAQ

=over 4

=item o What is the purpose of this set of modules?

It's the basis of a long-term project to formalize the way L<Graph::Easy> processes its graph definitions,
which in turn is meant to make on-going support for L<Graph::Easy> much easier.

=item o What are Graph::Easy graphs?

You really should read the L<Graph::Easy> docs.

In short, it means a text string containing a definition of a graph, using a cleverly designed language,
that can be used to describe the sort of graph you wish to plot. Then, L<Graph::Easy> does the plotting.
Here is a L<sample|http://bloodgate.com/perl/graph/manual/overview.html>.

=item o So what's a sample of a L<Graph::Easy> graph definition?

	[node_1]{color: red; style: circle} -> {class: fancy;} [node_2]{color: green;}

=item o How are graphs stored in RAM by the lexer and the parser?

See L<Graph::Easy::Marpa::Lexer/FAQ>.

=item o How are attributes assigned to nodes and edges?

Since the scan of the input stream is linear, any attribute detected belongs to the nearest preceeding
node(s) or edge.

=item o How are attributes assigned to groups?

The only attributes which can be passed to a subgraph (group) are those that 'dot' accepts under the 'graph'
part of a subgraph definition.

This means the attribute 'rank' cannot be passed, yet.

=item o Is there sample data I can examine?

See data/*.raw and the corresponding data/*.cooked and html/*.svg.

*.raw are input for the lexer, and *.cooked are output from the lexer.

Note: Some files contain deliberate mistakes. See above for instructions on running scripts/lex.pl and scripts/lex.sh.

=item o What about the fact the Graph::Easy can read various other definition formats?

I have no plans to support such formats. Nevertheless, having written these modules, it should be fairly
easy to derive classes which perform that sort of work.

=item o What's with the regexp for class names in data/default.stt.ods?

We can't use \w+ because 'graph{a:b}' matches that under Perl 5.12.2.

=item o How to I re-generate the web page of demos?

By default, scripts/generate.index.pl outputs to File::Temp -> newdir(...).
But by running it with a command line parameter, that value willl be used for the output directory.

=item o What are the defaults for GraphViz2, the default rendering engine?

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

=item o How can I switch from Marpa::XS to Marpa::PP?

Install Marpa::PP manually. It is not mentioned in Build.PL or Makefile.PL.

Patch Graph::Easy::Marpa::Parser (line 14) from Marpa::XS to Marpa:PP.

Run the tests which ship with this module.

I've tried this, and the tests all worked. Other tests I run also worked.

=back

=head1 TODO

=head2 Implement HTML-style labels

=head2 Use regexps from the STT to do more validation

At the moment, some validation is done in L<Graph::Easy::Marpa::Lexer::DFA> by manually copying
regexps from the STT to the subs validate_*().

=head1 Machine-Readable Change Log

The file CHANGES was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Thanks

Many thanks are due to the people who worked on L<Graph::Easy>.

Jeffrey Kegler wrote L<Marpa>, and has been helping me via private emails.

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
