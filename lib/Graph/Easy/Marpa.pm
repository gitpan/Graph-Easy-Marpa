package Graph::Easy::Marpa;

use strict;
use warnings;

our $VERSION = '0.51';

# --------------------------------------------------

1;

=pod

=head1 NAME

L<Graph::Easy::Marpa> - Proof-of-concept Marpa-based parser for Graph::Easy

=head1 Synopsis

Modules:

=over 4

=item o Graph::Easy::Marpa

The current module, which documents the set of modules.

This module currently has no methods.

=item o Graph::Easy::Marpa::Formatter

To be written.

This is the layout engine which determines where in space (on a 2-D plane) each node and edge appears.

=item o Graph::Easy::Marpa::Lexer

To be written.

Will read a L<Graph::Easy> graph definition and output a representation of that graph in an intermediary language.

=item o Graph::Easy::Marpa::Parser

Already written. See L<Graph::Easy::Marpa::Parser>.

Accepts a graph definition in the intermediary language and builds a data structure representing the graph.

This data structure is then used by Graph::Easy::Marpa::Formatter to layout the nodes and edges, suitable for outputting in some format, such as SVG.

=item o Graph::Easy::Marpa::Test

Already written. See L<Graph::Easy::Marpa::Test>.

Simplifies testing.

=item o Graph::Easy::Marpa::Writer

To be written.

Will accept the output of Graph::Easy::Marpa::Formatter and output the graph in the format requested by the user.

=back

=head1 Description

L<Graph::Easy::Marpa> provides a L<Marpa>-based parser for L<Graph::Easy>-style graph definitions.

It does not provide any graph output capability, yet. That's right - the module does no more
than parse its input, at this stage.

Note: L<Graph::Easy::Marpa::Parser> doesn't really read L<Graph::Easy> definitions directly. For that, a lexer will one day be
written. Instead, it takes as input an intermediary language in a form acceptable to L<Marpa>. Obviously then
the lexer's goal will be to read graph definitions in the L<Graph::Easy> format and output them in this
intermediary language, for direct input into this module. That explains why this distro is only at V 0.50.

For this intermediary language, see data/intermediary.*.csv.

For sample code, see L<Graph::Easy::Marpa::Parser>, scripts/demo.pl, t/attr.t and t/edge.t.

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

This module, Graph::Easy::Marpa is never used directly. Use L<Graph::Easy::Marpa::Parser> instead.

See L<Graph::Easy::Marpa::Parser>, scripts/demo.pl, t/attr.t and t/edge.t.

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

One day, this module too will do such plotting.

=item o Why the delay?

Because I've only just started designing and coding this module. And in the process I've had to learn how to drive L<Marpa>.

=item o So what's a sample of a L<Graph::Easy> graph definition?

	[node_1] {color: red; style: circle} => {class: fancy;} [node_2] {color: green;}

=item o How are graphs stored in RAM (by L<Graph::Easy::Marpa::Parser>)?

As an array of hashrefs, where each hashref records information about one 'item' in the input stream.

Items are:

=over 4

=item o Nodes

A node definition of '[N]' would produce a hashref of:

	{
	name => 'N',
	type => 'node',
	}

A node can have a definition of '[]', which means it has no name. Such node are anonymous, and are
called invisible because while they take up space in the output stream, they have no printable or visible
characters in the output stream. See L<Graph::Easy> for details.

Node names are case-sensitive, and must be unique (except for anonymous nodes).

=item o Edges

An edge definition of '->' would produce a hashref of:

	{
	name => '->',
	type => 'edge',
	}

=item o Attributes

An attribute can belong to a node or an edge. An attribute definition of
'{color: red;}' would produce a hashref of:

	{
	name  => 'color',
	type  => 'attr',
	value => 'red',
	}

An attribute definition of '{color: red;shape: circle;}' will produce 2 hashrefs, i.e. 2 elements in the arrayref:

	{
	name  => 'color',
	type  => 'attr',
	value => 'red',
	}

	{
	name  => 'shape',
	type  => 'attr',
	value => 'circle',
	}

=item o Special items

There are 3 special items in the arrayref of items, all placeholders.

The first 2 contain the attributes you wish to assign to every node or edge by default.

They do not take up any place in the output stream, and you declare them (the first 2) in the input stream,
and assign attributes to them, in the same way you assign attributes to any other node or edge.

If you don't supply either of these 2 special items, the code creates them automatically. As you can see,
by default they have no attributes.

They are I<not> the same as the anonymous nodes mentioned above.

=over 4

=item o The global node

This node's name is '_' (a single underscore), and it looks like:

	{
	name => '_',
	type => 'global_node',
	}

=item o The global edge

This edge's name is '_' (a single underscore), and it looks like:

	{
	name => '_',
	type => 'global_edge',
	}

=item o The L<daisy-chain|http://en.wikipedia.org/wiki/Daisy-chain> item

This item indicates the graph definition contained 2 adjacent nodes, as in [node.1],[node.2],
which means any following attributes must be assigned to all nodes in the daisy-chain.

It looks like:

	{
	name => ',',
	type => 'daisy_chain',
	}

=back

=back

=item o How are attributes assigned to nodes and edges?

Since the scan of the input stream is linear, any attribute detected belongs to the nearest preceeding
node(s) or edge.

=item o Is there sample data I can examine?

Sure, see data/intermediary.*.csv. These files can be tested with:

	perl -Ilib scripts/demo.pl -v -s 1
	perl -Ilib scripts/demo.pl -v -s 2
	up to
	perl -Ilib scripts/demo.pl -v -s 12

See also:

	prove -Ilib -v t/

=item o But where did these files come from?

I manufactured them manually.

In future, a lexer will be written which reads pre-existing L<Graph::Easy> definitions and produces output
like data/*.csv, as long as (obviously) the definition conforms to the subset of L<Graph::Easy> definitions which
this module is able to parse. The intention is that that subset should be very large.

=item o And what do these files demonstrate?

=over 4

=item o intermediary.1.csv: An isolated node

Graph: [node.1]

=item o intermediary.2.csv: An isolated edge

Graph: ->

=item o intermediary.3.csv: An isolated node with attributes

Graph: [node.1]{color:green;}

=item o intermediary.4.csv: An isolated edge with attributes

Graph: ->{border:bold;}

=item o intermediary.5.csv: A node followed by an edge

Graph: [node.1]->

=item o intermediary.6.csv: An edge followed by a node

Graph: ->[node.1]

=item o intermediary.7.csv: A node with attributes followed by an edge

Graph: [node.1]{background:green;}->

=item o intermediary.8.csv: A node followed by an edge with attributes

Graph: [node.1]->{background:green;}

=item o intermediary.9.csv: An edge with attributes followed by a node

Graph: ->{background:green;}[node.1]

=item o intermediary.10.csv: An edge followed by an node with attributes

Graph: ->[node.1]{background:green;}

=item o intermediary.11.csv: A set of nodes

Graph: [node.1],[node.2],[node.3],[node.4]

=item o intermediary.12.csv: A set of nodes, with attributes, both before and after an edge, with attributes

Graph: [node.1],[node.2],[node.3]{border:bold;color:green;}-->{class:fancy;label:edge.label;text-wrap:10;}[node.4],[node.5]

=back

=item o What about the fact the Graph::Easy can read various other definition formats?

I have no plans to support such formats. Nevertheless, having written this module, it should be fairly
easy to produce derived classes which perform that sort of work.

=back

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
