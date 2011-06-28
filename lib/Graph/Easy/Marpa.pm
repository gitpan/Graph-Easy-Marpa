package Graph::Easy::Marpa;

use strict;
use warnings;

use File::Spec;

use Graph::Easy::Marpa::Lexer;
use Graph::Easy::Marpa::Parser;
use Graph::Easy::Marpa::Renderer::GraphViz2;

use Hash::FieldHash ':all';

use Log::Handler;

fieldhash my %cooked_file  => 'cooked_file';
fieldhash my %description  => 'description';
fieldhash my %format       => 'format';
fieldhash my %input_file   => 'input_file';
fieldhash my %items        => 'items';
fieldhash my %lexer        => 'lexer';
fieldhash my %logger       => 'logger';
fieldhash my %maxlevel     => 'maxlevel';
fieldhash my %minlevel     => 'minlevel';
fieldhash my %output_file  => 'output_file';
fieldhash my %parser       => 'parser';
fieldhash my %renderer     => 'renderer';
fieldhash my %report_items => 'report_items';
fieldhash my %token_file   => 'token_file';

our $VERSION = '0.90';

# --------------------------------------------------

sub _init
{
	my($self, $arg)     = @_;
	$$arg{cooked_file}  ||= ''; # Caller can set.
	$$arg{description}  ||= ''; # Caller can set.
	$$arg{format}       ||= 'svg';
	$$arg{input_file}   ||= ''; # Caller can set.
	$$arg{lexer}        = '';
	$$arg{logger}       = Log::Handler -> new;
	$$arg{maxlevel}     ||= 'debug';# Caller can set.
	$$arg{minlevel}     ||= 'error'; # Caller can set.
	$$arg{output_file}  ||= ''; # Caller can set.
	$$arg{parser}       = '';
	$$arg{renderer}     ||= '';
	$$arg{report_items} ||= 0;  # Caller can set.
	$$arg{token_file}   ||= ''; # Caller can set.
	$self               = from_hash($self, $arg);

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

sub run
{
	my($self)  = @_;
	my($lexer) = Graph::Easy::Marpa::Lexer -> new
		(
		 cooked_file => $self -> cooked_file,
		 description => $self -> description,
		 input_file  => $self -> input_file,
		 maxlevel    => 'warning',
		 stt_file    => File::Spec -> catfile('data', 'default.stt.csv'),
		 type        => 'csv',
		);

	$lexer -> run;

	my($parser) = Graph::Easy::Marpa::Parser -> new
		(
		 format      => $self -> format,
		 input_file  => $self -> cooked_file,
		 output_file => $self -> output_file,
		 token_file  => $self -> token_file,
		);

	$parser -> run;

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
	 'maxlevel=s',
	 'minlevel=s',
	 'output_file=s',
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

This is shipped as scripts/gem.pl, although the shipped version has help built in.

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

See also the token_file key, below.

=item o description => '[node.1]<->[node.2]'

Specify a string for the graph definition.

You are strongly encouraged to surround this string with '...' to protect it from your shell.

See also the 'input_file' key to read the graph from a file.

The 'description' key takes precedence over the 'input_file' key.

=item o format => $format_name

This is the format of the output file, to be created by the renderer.

Default is 'svg'.

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

See also the cooked_file, above.

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
	perl -Ilib scripts/gem.pl -i data/$X.raw -c $X.cooked -t $X.items -o $X.svg
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

The attribute name must match /[a-z][a-z0-9_]*/.

=item o Attribute values

The attribute value must match /^["']?[^"';\s]["']?$/.

=back

=item o Classes

Class names must match /^(?:edge|graph|group|node|[a-z][a-z0-9_]*)$/.

=item o Daisy-chains

=over 4

=item o Edges

Edges can be daisy-chained by using a comma, ',', space, or attributes, '{...}', to separate them.

Hence both of these are valid: '<->,<=>{color:green}' and '<->{color:red}<=>{color:green}'.

=item o Nodes

Nodes can be daisy chained by juxtapostion, or by using the comma, ',', space, or attributes, '{...}', to separate them.

Hence all of these are valid: '[node.1][node.2]' and '[node.1],[node.2]' and '[node.1]{color:red}[node.2]'.

=back

=item o Edges

Specifically, edges must currently match this regexp: /^<?(-|=|\.|~|- |= |\.-|\.\.-){1,}>?$/, which I've gleaned
from the L<Graph::Easy> docs at L<Edges|http://bloodgate.com/perl/graph/manual/syntax.html#edges>.

=item o Events

These are part of the STT, but are not part of the L<Graph::Easy> language.

Their names must match /[a-zA-Z_][a-zA-Z_0-9.]*/.

=item o Nodes

Node names must match /[a-zA-Z_][a-zA-Z_0-9. ]*/.

=item o States

These are part of the STT, but are not part of the L<Graph::Easy> language.

Their names must match /[a-zA-Z_][a-zA-Z_0-9.]*/.

In the STT, this regexp applies to both the State name column ('C') and the Next state name column ('E').

=item o Subclass names

Subclass names must start with a class name, and must be separated from the class name with a fullstop, '.'.

The 4 special class names are listed above.

The subclass name itself must match /[a-z][a-z0-9_]*/.

Hence these are both valid: 'node.city' and 'edge.railway'.

=back

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

	[node_1]{color:red;style:circle}=>{class:fancy;}[node_2]{color:green;}

=item o How are graphs stored in RAM (by L<Graph::Easy::Marpa::Parser>)?

As an arrayref of hashrefs, where each hashref records information about one 'item' in the input stream.

Items are:

=over 4

=item o Nodes

A node definition of '[N]' would produce a hashref of:

	{
	count => $n,
	name  => 'N',
	type  => 'node',
	value => '',
	}

A node can have a definition of '[]', which means it has no name. Such node are anonymous, and are
called invisible because while they take up space in the output stream, they have no printable or visible
characters in the output stream. See L<Graph::Easy> for details.

Node names are case-sensitive, and must be unique (except for anonymous nodes).

Note: Items are numbered from 1 up, but some numbers are missing, since those values are used internally.

=item o Edges

An edge definition of '->' would produce a hashref of:

	{
	count => N,
	name  => '->',
	type  => 'edge',
	value => '',
	}

=item o Attributes

An attribute can belong to a node or an edge. An attribute definition of
'{color: red;}' would produce a hashref of:

	{
	count => N,
	name  => 'color',
	type  => 'attr',
	value => 'red',
	}

An attribute definition of '{color: red;shape: circle;}' will produce 2 hashrefs, i.e. 2 elements in the arrayref:

	{
	count => N,
	name  => 'color',
	type  => 'attr',
	value => 'red',
	}

	{
	count => N,
	name  => 'shape',
	type  => 'attr',
	value => 'circle',
	}

=item o Classes

There are various special items in the arrayref of items, all placeholders.

They contain the default values of attributes you wish to assign to every item of a particular type.

They do not take up any place in the output stream, and you declare them in the input stream,
and assign attributes to them, in the same way you assign attributes to any node or edge.

They are I<not> the same as the anonymous nodes mentioned above.

Classes can have subclasses.

=over 4

=item o The graph class

This class's name is 'graph', and it looks like:

	{
	count => N,
	name  => 'graph',
	type  => 'class',
	value => '',
	}

The attributes attached to this class apply to the graph as a whole.

=item o The group class

A group is a name given to a set of nodes.

This class's name is 'group', and it looks like:

	{
	count => N,
	name  => 'group',
	type  => 'class',
	value => '',
	}

The attributes attached to this class apply to each group.

=item o The node class

This node's name is 'node', and it looks like:

	{
	count => N,
	name  => 'node',
	type  => 'class',
	value => '',
	}

The attributes attached to this class apply to each node.

Attributes of a subclass of node, or belonging to a node, override the node class's attributes.

A subclass name for a node must start with 'node.', as in 'node.city'.

=item o The edge class

This class's name is 'edge', and it looks like:

	{
	count => N,
	name  => 'edge',
	type  => 'class',
	value => '',
	}

The attributes attached to this class apply to each edge.

Attributes of a subclass of edge, or belonging to an edge, override the edge class's attributes.

A subclass name for an edge must start with 'edge.', as in 'edge.road'.

=item o The L<daisy-chain|http://en.wikipedia.org/wiki/Daisy-chain> item

This item indicates the graph definition contained 2 adjacent nodes, as in '[node.1],[node.2]',
which means any following attributes must be assigned to all nodes in the daisy-chain.

It looks like:

	{
	count => N,
	name  => ',',
	type  => 'daisy_chain',
	value => '',
	}

=back

=back

=item o How are attributes assigned to nodes and edges?

Since the scan of the input stream is linear, any attribute detected belongs to the nearest preceeding
node(s) or edge.

=item o Is there sample data I can examine?

See data/*.raw and the corresponding data/*.csv.

*.raw are input for the lexer, and *.csv are output from the lexer.

Note: Some files contain deliberate mistakes. See above for instructions on running scripts/lex.pl and scripts/lex.sh.

=item o What about the fact the Graph::Easy can read various other definition formats?

I have no plans to support such formats. Nevertheless, having written these modules, it should be fairly
easy to derive classes which perform that sort of work.

=item o What's with the regexp for class names in data/default.stt.ods?

We can't use \w+ because 'graph{a:b}' matches that under Perl 5.12.2.

=item o How to I re-generate the web page of demos?

Patch scripts/generate.index.pl to use a permanent directory instead of calling File::Temp -> newdir(...).
Then, run it.

=back

=head1 TODO

=head2 Pass lexed graph definition from lexer to parser via RAM, not just via a disk file

This saves a bit of time, since then the lexer would not have to write a file,
and the parser would not have to read one.

=head2 Add an anonymous node at the end of the input, if necessary

This counteracts a buglet in the renderer, in that it doesn't plot edges unless followed by a node.
So, a graph with a trailing edge will not show that edge.

=head2 Proof-read all docs, specifically checking parameters for scripts and methods

Ensure docs for arrayref of items passed to the renderer is up-to-date.

=head2 Add a timeout on the lexer, not just on calling 'dot'

=head2 Use regexps from the STT to do more validation

=head2 Document difference in syntax compared with L<Graph::Easy>

Not in detail, probably.

=head2 Email AT&T about the link to Leon's code in their wiki

=head2 Implement classes and subclasses, and groups

=head2 Implement user-control of arrow shape

=head2 Implement user-control over the selection of rendering engine

This means the parser needs a graph type option, too.

=head2 Put data/default.stt.csv into the source code of the lexer

This saves a bit of time, since then the lexer would not have to read a separate file.

=head2 Allow logger objects to be provided in more places

Hence sub _init() would then read:

	$arg{logger} = defined($arg{logger}) ? $arg{logger} : Log::Handler -> new.

Then, the caller can use logger => '' to turn off logging.

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
