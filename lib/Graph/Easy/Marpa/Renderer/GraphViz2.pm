package Graph::Easy::Marpa::Renderer::GraphViz2;

use strict;
use warnings;

use GraphViz2;

use Hash::FieldHash ':all';

fieldhash my %class          => 'class';
fieldhash my %dot_input_file => 'dot_input_file';
fieldhash my %format         => 'format';
fieldhash my %graph          => 'graph';
fieldhash my %logger         => 'logger';
fieldhash my %maxlevel       => 'maxlevel';
fieldhash my %minlevel       => 'minlevel';
fieldhash my %output_file    => 'output_file';
fieldhash my %rankdir        => 'rankdir';

our $VERSION = '1.11';

# --------------------------------------------------

sub dump_items
{
	my($self, $items) = @_;

	for my $i (0 .. $#$items)
	{
		print "@{[$i + 1]}: ", join(', ', map{"$_ => $$items[$i]{$_}"} sort keys %{$$items[$i]}), ". \n";
	}

	print '-' x 20, "\n";

} # End of dump_items.

# --------------------------------------------------

sub find_first_edge_or_node
{
	my($self, $items) = @_;

	my($type);

	for my $i (0 .. $#$items)
	{
		if ($$items[$i]{type} eq 'edge')
		{
			$type = 'edge';

			last;
		}
		elsif ($$items[$i]{type} eq 'node')
		{
			$type = 'node';

			last;
		}
	}

	if ($type eq 'edge')
	{
		# Add an invisible node at the start.

		unshift @$items,
		{
			name  => 'label',
			type  => 'attribute',
			value => '',
		};

		unshift @$items,
		{
			name  => 'color',
			type  => 'attribute',
			value => 'invis',
		};

		unshift @$items,
		{
			name => 'dummy.prefix.node',
			type => 'node',
		};
	}

} # End of find_first_edge_or_node.

# --------------------------------------------------

sub find_last_edge_or_node
{
	my($self, $items) = @_;

	my($i);
	my($type);

	for my $j (0 .. $#$items)
	{
		$i = $#$items - $j;

		if ($$items[$i]{type} eq 'edge')
		{
			$type = 'edge';

			last;
		}
		elsif ($$items[$i]{type} eq 'node')
		{
			$type = 'node';

			last;
		}
	}

	if ($type eq 'edge')
	{
		# Add an invisible node at the end.

		push @$items,
		{
			name => 'dummy.suffix.node',
			type => 'node',
		};

		push @$items,
		{
			name  => 'color',
			type  => 'attribute',
			value => 'invis',
		};

		push @$items,
		{
			name  => 'label',
			type  => 'attribute',
			value => '',
		};
	}

} # End of find_last_edge_or_node.

# --------------------------------------------------

sub _get_attributes
{
	my($self, $type, $item, $option) = @_;

	my($next_item);

	for my $i (0 .. $#$item)
	{
		$next_item = $$item[$i];

		last if ($$next_item{type} ne 'attribute');

		$$option{$$next_item{name} } = $$next_item{value};
	}

	# 1: If one of the attributes is a class, get the class attributes.
	# The value in the %$option hash will be the subclass name.
	#
	# 2: If there is no subclass, the item still inherits the class attributes, if any.

	my($class)      = $self -> class;
	my($class_name) = $$option{class};

	if ($class_name)
	{
		# Ensure we don't pass 'class' as an attribute to 'dot'.

		delete $$option{class};

		# Does the subclass exist?

		my($name)  = "$type.$class_name";
		my($attr)  = $$class{$name};

		if ($attr)
		{
			$self -> log(debug => "Processing subclass attributes for '$name'");

			$self -> _get_subclass_attributes($attr, $option);
		}
	}

	# Does the class exist?

	my($attr)  = $$class{$type};

	if ($attr)
	{
		$self -> log(debug => "Processing class attributes for '$type'");

		$self -> _get_subclass_attributes($attr, $option);
	}

} # End of _get_attributes;

# --------------------------------------------------

sub _get_subclass_attributes
{
	my($self, $attribute, $option) = @_;

	# Ensure we don't overwrite any attributes already defined.

	for my $key (keys %$attribute)
	{
		$$option{$key} = $$attribute{$key} if (! defined $$option{$key});
	}

} # End of _get_subclass_attributes.

# --------------------------------------------------

sub _get_subgraph_attributes
{
	my($self, $i, $item_list) = @_;
	my($name)  = $$item_list[$i]{name};
	my($found) = 0;

	my(%attributes);
	my($item);
	my($k);

	# Loop over remaining items.

	for my $j ( ($i + 1) .. $#$item_list)
	{
		$item = $$item_list[$j];

		# Find the end of this subgraph.

		if ( ($$item{type} eq 'pop_subgraph') && ($$item{name} eq $name) )
		{
			# Find all the attributes for this subgraph.

			$k = $j;

			while ( ($k < $#$item_list) && ($$item_list[$k + 1]{type} eq 'attribute') )
			{
				$k++;

				$found = 1;

				$self -> _get_attributes('group', [$$item_list[$k] ], \%attributes);
			}

			last if ($found);
		}
	}

	return {%attributes};

} # End of _get_subgraph_attributes.

# --------------------------------------------------

sub _init
{
	my($self, $arg)       = @_;
	$$arg{dot_input_file} ||= '';    # Caller can set.
	$$arg{format}         ||= 'svg'; # Caller can set.
	my($user_logger)      = defined($$arg{logger}); # Caller can set (e.g. to '').
	$$arg{logger}         = $user_logger ? $$arg{logger} : Log::Handler -> new;
	$$arg{maxlevel}       ||= 'debug'; # Caller can set.
	$$arg{minlevel}       ||= 'error'; # Caller can set.
	$$arg{output_file}    ||= '';      # Caller can set.
	$$arg{rankdir}        ||= 'TB';    # Caller can set.
	$self                 = from_hash($self, $arg);

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

	$self -> logger -> $level($s) if ($self -> logger);

} # End of log.

# --------------------------------------------------

sub log_hashref
{
	my($self, $title, $hashref) = @_;

	$self -> log(debug => $title);

	for my $key (sort keys %$hashref)
	{
		$self -> log(debug => "$key => " . ($$hashref{$key} ? $$hashref{$key} : 'undef') );
	}

} # End of log_hashref.

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

			$self -> _get_attributes('edge', [@item[$i + 1 .. $#item] ], \%option);
			$self -> graph -> add_edge(from => $item[0]{name}, to => $item[$#item]{name}, %option);
		}
	}

} # End of _process_node_range.

# --------------------------------------------------

sub run
{
	my($self, %arg)     = @_;
	my($dot_input_file) = $arg{dot_input_file} || $self -> dot_input_file;
	my($format)         = $arg{format} || $self -> format;
	my(@item)           = @{$arg{items} };
	my($output_file)    = $arg{output_file} || $self -> output_file;

	# Scan the input looking for classes. If they're present,
	# move them into a hash keyed by class name.

	$self -> log(debug => '-' x 50);

	my(%class);
	my($item);
	my($name);
	my($value);

	while ($item[0]{type} eq 'class_name')
	{
		$item         = shift @item;
		$name         = $$item{name};
		$class{$name} = {};

		# Gobble up the attributes.

		while ($item[0]{type} eq 'attribute')
		{
			$item                        = shift @item;
			$class{$name}{$$item{name} } = $$item{value};
		}
	}

	# We move the class hash into an attribute of the object,
	# so that it's available in methods.

	$self -> class(\%class);
	$self -> log_hashref("Class: $_. Attributes:", $class{$_}) for sort keys %class;

	# Now that we know the classes, we can init the graph.

	$self -> graph
		(
		 GraphViz2 -> new
		 (
		  edge    => $class{edge}   || {color => 'grey'},
		  global  => $class{global} || {directed => 1},
		  graph   => $class{graph}  || {rankdir => $self -> rankdir},
		  logger  => $self -> logger,
		  node    => $class{node} || {shape => 'oval'},
		  verbose => 0,
		 )
		);

	# If the first edge/node is a edge, add a node before it,
	# so the edge processor has a node on either side of each edge.

	$self -> find_first_edge_or_node(\@item);

	# If the last edge/node is a edge, add a node after it,
	# so the edge processor has a node on either side of each edge.

	$self -> find_last_edge_or_node(\@item);

	# Process all nodes.

	my(%option);

	for my $i (0 .. $#item)
	{
		$item   = $item[$i];
		$name   = $$item{name};
		%option = ();

		$self -> log(debug => "Start processing $$item{type} '$name'");

		if ($$item{type} eq 'push_subgraph')
		{
			$self -> graph -> push_subgraph
				(
				 graph => $self -> _get_subgraph_attributes($i, \@item),
				 name  => $name,
				);
		}
		elsif ($$item{type} eq 'pop_subgraph')
		{
			$self -> graph -> pop_subgraph();
		}
		elsif ($$item{type} eq 'node')
		{
			# Process all attributes owned by this node.

			$option{name} = $name;

			$self -> _get_attributes('node', [@item[$i + 1 .. $#item] ], \%option);
			$self -> graph -> add_node(%option);
		}
	}

	# Process all edges. This means, for each node:
	# o Find the next node.
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

				# See above: If the graph ends with an edge, there will be a fake 'next' node.

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

	$self -> log(debug => '-' x 50);

	$self -> graph -> run(format => $format, output_file => $output_file);

	if ($dot_input_file)
	{
		open(OUT, '>', $dot_input_file);
		print OUT $self -> graph -> dot_input;
		close OUT;
	}

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

=item o dot_input_file => $file_name

Specify the name of a file that the rendering engine can write to, which will contain the input
to dot (or whatever). This is good for debugging.

Default: ''.

If '', the file will not be created.

=item o format => $format

This is the format of the output file.

The default is 'svg'.

You can also pass this value into L</run(%arg)>.

The value passed in to run() takes precedence over the value passed in to new().

=item o logger => $logger_object

Specify a logger object.

To disable logging, just set logger to the empty string.

The default value is an object of type L<Log::Handler>.

=item o maxlevel => $level

This option is only used if L<Graph::Easy::Marpa:::Lexer> or L<Graph::Easy::Marpa::Parser>
create an object of type L<Log::Handler>. See L<Log::Handler::Levels>.

The default 'maxlevel' is 'info'. A typical choice is 'debug'.

=item o minlevel => $level

This option is only used if L<Graph::Easy::Marpa:::Lexer> or L<Graph::Easy::Marpa::Parser>
create an object of type L<Log::Handler>. See L<Log::Handler::Levels>.

The default 'minlevel' is 'error'.

No lower levels are used.

=item o output_file => $file_name

Specify the name of the output file to write.

The default value is ''.

You can also pass this value into L</run(%arg)>.

The value passed in to run() takes precedence over the value passed in to new().

=item o rankdir => $direction

$direction must be one of: LR or RL or TB or BT.

Specify the rankdir of the graph as a whole.

The default value is: 'TB' (top to bottom).

=back

=head1 Methods

=head2 dot_input_file([$file_name])

Here, the [] indicate an optional parameter.

Get or set the name of the file into which the rendering engine will write to input to dot (or whatever).

You can pass 'dot_input_file' as a key into new() and run().

The value passed in to run() takes precedence over the value passed in to new().

=head2 format([$format])

Here, the [] indicate an optional parameter.

Get or set the format of the output file.

You can pass 'format' as a key into new() and run().

The value passed in to run() takes precedence over the value passed in to new().

=head2 logger([$logger_object])

Here, the [] indicate an optional parameter.

Get or set the logger object.

To disable logging, just set logger to the empty string.

You can pass 'logger' as a key into new() and run().

The value passed in to run() takes precedence over the value passed in to new().

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

=head2 output_file([$file_name])

Here, the [] indicate an optional parameter.

Get or set the name of the output file.

The default is ''.

You can pass 'output_file' as a key into new() and run().

The value passed in to run() takes precedence over the value passed in to new().

=head2 rankdir([$direction])

Here, the [] indicate an optional parameter.

Get or set the rankdir of the graph as a whole.

The default is 'TB' (top to bottom).

=head2 run(%arg)

Renders a set of items as an image, using L<GraphViz2>.

Keys and values in %arg are:

=over 4

=item o format => $format

The format (e.g. 'svg') to pass to the rendering engine.

The value passed in to run() takes precedence over the value passed in to new().

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

=item o logger => $logger_object

=item o output_file => $file_name

This is where the output of 'dot' will be written.

=back

=head1 FAQ

=head2 What are the defaults for GraphViz2?

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
