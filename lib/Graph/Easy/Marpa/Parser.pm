package Graph::Easy::Marpa::Parser;

use strict;
use warnings;

use Marpa;

use Moose;

has attrs =>
(
 default  => sub{return []},
 is       => 'rw',
 isa      => 'ArrayRef',
 required => 0,
);

has attr_name =>
(
 default  => '',
 is       => 'rw',
 isa      => 'Str',
 required => 0,
);

has items =>
(
 default  => sub{return []},
 is       => 'rw',
 isa      => 'ArrayRef',
 required => 0,
);

has node_name =>
(
 default  => '',
 is       => 'rw',
 isa      => 'Str',
 required => 0,
);

has verbose =>
(
 default  => 0,
 is       => 'rw',
 isa      => 'Int',
 required => 0,
);

use namespace::autoclean;

# $myself is a copy of $self for use by functions called by Marpa.

our $myself;

our $VERSION = '0.51';

# --------------------------------------------------

sub BUILD
{
	my($self) = @_;
	$myself   = $self;

} # End of BUILD.

# --------------------------------------------------

sub add_globals
{
	my($self)    = @_;
	my($itemref) = $self -> items;
	my(%found)   =
		(
		 edge => 0,
		 node => 0,
		);

	my($name, %name);

	for my $item (@$itemref)
	{
		# Check for duplicate node names.

		$name = $$item{name};

		if (! $name{$name})
		{
			$name{$name} = 0;
		}

		if ( (++$name{$name} > 1) && ($$item{type} eq 'node') && ($name ne '') )
		{
			die "Duplicate node name '$name' detected";
		}

		# Check for global edge and node.

		if ($name eq '_')
		{
			for my $type (qw/edge node/)
			{
				if ($$item{type} eq "global_$type")
				{
					$found{$type} = 1;
				}
			}
		}
	}

	if ($found{edge} == 0)
	{
		unshift @$itemref,
		{
			name   => '_',
			type   => 'global_edge',
		};

		$self -> items($itemref);
	}

	if ($found{node} == 0)
	{
		unshift @$itemref,
		{
			name   => '_',
			type   => 'global_node',
		};

		$self -> items($itemref);
	}

} # End of add_globals.

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
	my($attr) =
	{
		name  => $myself -> attr_name,
		type  => 'attr',
		value => $t1,
	};

	my(@attr) = @{$myself -> attrs};

	push @attr, $attr;

	$myself -> attrs([@attr]);

	return $t1;

} # End of attr_value_id.

# --------------------------------------------------
# This is a function, not a method.

sub edge_id
{
	my(undef, $t1, undef, $t2)  = @_;

	# This regexp defines what is and isn't allowed for edge syntax.

	if ($t1 !~ /^<?(-|=|\.|~|- |= |\.-|\.\.-){1,}>?$/)
	{
		die "Unexpected edge syntax: '$t1'";
	}

	# Add edge to the item list.

	my($edge) =
	{
		name => $t1,
		type => 'edge',
	};

	$myself -> items([@{$myself -> items}, $edge]);

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

	$myself -> items([@{$myself -> items}, @{$myself -> attrs}]);
	$myself -> attrs([]);

	return '';

} # End of end_attribute.

# --------------------------------------------------
# This is a function, not a method.

sub end_node
{
	my(undef, $t1, undef, $t2)  = @_;

	# $t1 will be ']'.
	# Add node to the item list.

	my($node) =
	{
		name => $myself -> node_name,
		type => 'node',
	};

	$myself -> items([@{$myself -> items}, $node]);

	return '';

} # End of end_node.

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
				  rhs => [qw/node_statement comma/],
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

sub log
{
	my($self, $s) = @_;
	$s ||= '';

	if ($self -> verbose)
	{
		print "$s\n";
	}

} # End of log.

# --------------------------------------------------
# This is a function, not a method.

sub node_name_id
{
	my(undef, $t1, undef, $t2)  = @_;

	$myself -> node_name($t1);

	return $t1;

} # End of node_name_id.

# --------------------------------------------------

sub run
{
	my($self, $token, $grammar) = @_;
	$grammar ||= $self -> grammar;

	my($recognizer) = Marpa::Recognizer -> new({grammar => $grammar});

	$recognizer -> tokens($token);

	my($result) = $recognizer -> value;
	$result     = $result ? ${$result} : 'Parse failed';
	$result     = $result ? $result    : 'OK';

	# If all went well, add the global node and edge if the user did not.

	if ($result eq 'OK')
	{
		$self -> add_globals;
	}
	else
	{
		die $result;
	}

	return $result;

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

__PACKAGE__ -> meta -> make_immutable;

1;

=pod

=head1 NAME

L<Graph::Easy::Marpa::Parser> - Proof-of-concept Marpa-based parser for Graph::Easy

=head1 Synopsis

For sample code, see scripts/demo.pl, t/attr.t and t/edge.t.

For more details, see L<Graph::Easy::Marpa>.

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
[e.g. verbose()]):

=over 4

=item o verbose

Takes either 0 (the default) or 1.

If 0, nothing is printed.

If 1, nothing is printed, yet.

See scripts/demo.pl and L<Graph::Easy::Marpa::Test>.

=back

=head1 Methods

=head2 add_globals()

The special items, global_node and global_edge, are added to the arrayref of items if the user
did not supply them. See the L<Graph::Easy::Marpa/FAQ> for details, and in particular the discussion
under the question "How are graphs stored in RAM (by Graph::Easy::Marpa::Parser)?".

add_globals() is called automatically near the end of run().

=head2 attrs([$new_arrayref])

The [] indicate an optional parameter.

Returns an arrayref of hashrefs, 1 hashref for each attribute belonging to the 'current' node or
edge. See the L<Graph::Easy::Marpa/FAQ> for details.

This arrayref is reset to [] as soon as the current attributes are transferred into the arrayref
managed by the items() method.

If called as attrs([...]), set the arrayref of hashrefs to the parameter.

=head2 attr_name([$name])

The [] indicate an optional parameter.

Sets or returns the 'current' attribute's name, during the parse of each attribute definition attached to
either a node or an edge.

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

=head2 items([$new_arrayref])

The [] indicate an optional parameter.

Returns an arrayref of items. See the L<Graph::Easy::Marpa/FAQ> for details.

If called as items([...]), set the arrayref of hashrefs to the parameter.

See also run(), below.

=head2 log($s)

If new() was called as new() or new(verbose => 0), do nothing.

If new() was called as new(verbose => 1), print the string $s.

=head2 node_name([$name])

The [] indicate an optional parameter.

Sets or returns the 'current' node's name, after the parse of each node definition.

=head2 run($token, [$grammar])

Returns 'OK' or dies with an error message.

The [] indicate an optional parameter.

$token is an arrayref of tokens, to be consumed by the L<Marpa> parser.

See L<Graph::Easy::Marpa::Test>, scripts/demo.pl, and data/intermediary.*.csv, for samples.

$grammar is the grammar to be used by L<Marpa>. It defaults to the return value of grammar().

Purpose: Run the L<Marpa> parser, using @$token and $grammar.

The end result is an arrayref, accessible with the items() method, of hashrefs representing items
in the input stream.

The structure of this arrayref of hashrefs is discussed in the L<Graph::Easy::Marpa/FAQ>.

=head2 verbose([0 or 1])

The [] indicate an optional parameter.

Get or set the value of the verbose option.

=head1 Machine-Readable Change Log

The file CHANGES was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Graph::Easy::Marpa>.

=head1 Author

L<Graph::Easy::Marpa::Parser> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2011.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2011, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
