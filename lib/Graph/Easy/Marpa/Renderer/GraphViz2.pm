package Graph::Easy::Marpa::Renderer::GraphViz2;

use strict;
use warnings;

use GraphViz2;

use Hash::FieldHash ':all';

fieldhash my %format   => 'format';
fieldhash my %graph    => 'graph';
fieldhash my %logger   => 'logger';
fieldhash my %maxlevel => 'maxlevel';
fieldhash my %minlevel => 'minlevel';

our $VERSION = '0.90';

# --------------------------------------------------

sub _get_attributes
{
	my($self, $item, $option) = @_;

	my($next_item);

	for my $i (0 .. $#$item)
	{
		$next_item = $$item[$i];

		last if ($$next_item{type} ne 'attribute');

		$$option{$$next_item{name} } = $$next_item{value};
	}

} # End of _get_attributes;

# --------------------------------------------------

sub _init
{
	my($self, $arg) = @_;
	$$arg{format}   ||= 'svg';
	$$arg{logger}   = Log::Handler -> new;
	$$arg{maxlevel} ||= 'debug';# Caller can set.
	$$arg{minlevel} ||= 'error'; # Caller can set.

	# Must be after the above to get the logger.

	$$arg{graph} = GraphViz2 -> new
		(
		 edge   => {color => 'grey'},
		 global => {directed => 1},
		 graph  => {rankdir => 'TB'},
		 logger => $$arg{logger},
		 node   => {shape => 'oval'},
	);
	$self = from_hash($self, $arg);

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

sub _process_node_range
{
	my($self, @item) = @_;

	$self -> log(debug => "Node range => $item[0]{name} => $item[$#item]{name}");

	my($item);
	my(%option);

	for my $i (0 .. $#item)
	{
		$item   = $item[$i];
		%option = ();

		if ($$item{type} eq 'edge')
		{
			# Process all attributes owned by this edge.

			$self -> _get_attributes([@item[$i + 1 .. $#item] ], \%option);
			$self -> graph -> add_edge(from => $item[0]{name}, to => $item[$#item]{name}, %option);
		}
	}

} # End of _process_node_range.

# --------------------------------------------------

sub run
{
	my($self, %arg) = @_;
	my(@item) = @{$arg{items} };

	# Process all nodes.

	my($item);
	my($name);
	my(%option);

	for my $i (0 .. $#item)
	{
		$item   = $item[$i];
		%option = ();

		if ($$item{type} eq 'node')
		{
			# Process all attributes owned by this node.

			$name         = $$item{name};
			$option{name} = $name;

			$self -> _get_attributes([@item[$i + 1 .. $#item] ], \%option);
			$self -> graph -> add_node(%option);
		}
	}

	# Process all edges. This means, for each node:
	# o Find the next node, if any.
	# o Find all the edges between these 2 nodes.

	my($i) = - 1;

	my($j);
	my($next_item);

	while ($i < $#item)
	{
		$i++;

		$item = $item[$i];

		if ($$item{type} eq 'node')
		{
			$j = $i;

			while ($j < $#item)
			{
				$j++;

				$next_item = $item[$j];

				# TODO: If the graph ends with an edge, there will not be a 'next' node.

				if ($$next_item{type} eq 'node')
				{
					$self -> _process_node_range(@item[$i .. $j]);

					# Drop out of loop.

					$i = $j - 1;
					$j = $#item;
				}
			}
		}
	}

	$self -> graph -> run(format => $self -> format, output_file => $arg{output_file});

	# Return 0 for success and 1 for failure.
	
	return 0;

} # End of run.

# --------------------------------------------------

1;

=pod

=head1 NAME

L<Graph::Easy::Marpa::Renderer::GraphViz2> - This is the default rendering engine for Graph::Easy::Marpa

=head1 Synopsis

See L<Graph::Easy::Marpa/Synopsis>.

=head1 Description

L<Graph::Easy::Marpa::Renderer> provides a L<GraphViz2>-based renderer for L<Graph::Easy>-style graph definitions.

This module is the default rendering engine for L<Graph::Easy::Marpa>.

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

C<new()> is called as C<< my($parser) = Graph::Easy::Marpa::Renderer::GraphViz2 -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Graph::Easy::Marpa::Renderer::GraphViz2>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. maxlevel()]):

=over 4

=item o (None)

=back

=head1 Methods

=head2 run(%arg)

Renders a set of items as an image, using L<GraphViz2>.

Keys and values in %arg are:

=over 4

=item o format => $format

The format (e.g. 'svg') to pass to the rendering engine.

=item o items => $arrayref

This arrayref, passed from L<Graph::Easy::Marpa::Parser> is the result of lexing and parsing the
L<Graph::Easy>-style graph definition (raw) file.

Each element of this arrayref is a hashref with these key-value pairs:

=over 4

=item o count => $integer

=item o name => $string

=item o type => $string

=item o value => $string

=back

=item o output_file => $file_name

This is where the output of 'dot' will be written.

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
