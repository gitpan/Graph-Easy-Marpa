package Graph::Easy::Marpa::Lexer::DFA;

use strict;
use warnings;

use Hash::FieldHash ':all';

use Set::Array;
use Set::FA::Element;

fieldhash my %counter    => 'counter';
fieldhash my %dfa        => 'dfa';
fieldhash my %graph_text => 'graph_text';
fieldhash my %group      => 'group';
fieldhash my %items      => 'items';
fieldhash my %logger     => 'logger';
fieldhash my %param      => 'param';
fieldhash my %report_stt => 'report_stt';
fieldhash my %state      => 'state';
fieldhash my %start      => 'start';

our $myself; # Is a copy of $self for functions called by Set::FA::Element.
our $VERSION = '0.91';

# --------------------------------------------------

sub _clean_up
{
	my($self)  = @_;
	my($group) = $self -> group;

	if ($group)
	{
		die "Error: Group '$group' not closed";
	}

	# Clean up left-overs.

	my($param) = $self -> param;

	# Is there a class?

	if ($$param{class}{match})
	{
		validate_class_name($self -> dfa);
	}

	# Is there an edge?
	# Need this because edges don't have terminators.

	if ($$param{edge}{match})
	{
		validate_edge_name($self -> dfa);
	}

	# Classes must have attributes.

	my(@item) = @{$self -> items};

	my($name, $next_type);
	my($type);

	for my $i (0 .. $#item)
	{
		$name = $item[$i]{name};
		$type = $item[$i]{type};

		if ($type eq 'class')
		{
			if ($i == $#item)
			{
				die "Error: Class '$name' has no attributes";
			}
			else
			{
				$next_type = $item[$i + 1]{type};

				if ($next_type ne 'class_attribute')
				{
					die "Error: Class '$name' has no attributes";
				}
			}
		}
	}

} # End of _clean_up.

# --------------------------------------------------

sub _count
{
	my($self) = @_;

	return $self -> counter($self -> counter + 1);

} # End of _count.

# --------------------------------------------------

sub _init
{
	my($self, $arg)   = @_;
	$$arg{counter}    = 0;
	$$arg{dfa}        = '';
	$$arg{graph_text} = $$arg{graph_text} || die 'Error: No value supplied for graph_text';
	$$arg{group}      = '';
	$$arg{items}      = Set::Array -> new;
	$$arg{logger}     ||= ''; # Caller can set.
	$$arg{param}      = {attribute => {}, class => {}, class_attribute => {}, edge => {}, group => {}, node => {} };
	$$arg{report_stt} ||= 0;  # Caller can set.
	$$arg{state}      ||= $$arg{state} || die 'Error: No value supplied for state';
	$$arg{start}      ||= $$arg{start} || die 'Error: No value supplied for start';
	$self             = from_hash($self, $arg);
	$myself           = $self;

	return $self;

} # End of _init.

# --------------------------------------------------

sub new
{
	my($class, %arg) = @_;
	my($self)        = bless {}, $class;
	$self            = $self -> _init(\%arg);

	return $self;

}	# End of new.

# --------------------------------------------------
# Warning: This is a function.

sub pop_group
{
	my($dfa) = @_;

	if (! $myself -> group)
	{
		die "Error: Can't close group since we're not inside one";
	}

	$myself -> items -> push
	({
		count => $myself -> _count,
		name  => $myself -> group,
		type  => 'pop_group',
		value => '',
	});
	$myself -> group('');

} # End of pop_group.

# --------------------------------------------------

sub _process_graph
{
	my($self)  = @_;
	my($input) = $self -> graph_text;

	$self -> logger -> log(debug => "Graph: $input");

	my($result) = 1 - $self -> dfa -> accept($input);

	$self -> _clean_up;

	# Return 0 for success and 1 for failure.

	return $result;

} # End of _process_graph.

# --------------------------------------------------
# Warning: This is a function.

sub push_group
{
	my($dfa)   = @_;
	my($group) = $myself -> group;

	if ($group)
	{
		die "Error: Groups can't be nested. We're already inside group '$group'";
	}

} # End of push_group.

# --------------------------------------------------

sub run
{
	my($self)        = @_;
	my($state_stuff) = $self -> state;

	# Build structures required by Set::FA::Element.

	my(%actions, @accept);
	my($entry, $exit);
	my($item);
	my(@stt);
	my(@transitions);

	for my $state (keys %$state_stuff)
	{
		for my $event_index (0 .. $#{$$state_stuff{$state} })
		{
			if (! $actions{$state})
			{
				$actions{$state} = {};
			}

			$item  = ${$$state_stuff{$state} }[$event_index];
			$entry = $$item{entry};
			$exit  = $$item{exit};

			if ($entry)
			{
				$actions{$state}{entry} = [\&$entry, $entry];
			}

			if ($exit)
			{
				$actions{$state}{exit} = [\&$exit, $exit];
			}

			push @accept, $$item{accept} if ($$item{accept});
			push @stt, "['$state', '$$item{event}', '$$item{next_state}']";
			push @transitions, [$state, $$item{event}, $$item{next_state}];
		}
	}

=pod

	@stt           = sort @stt; # Format nicely as sample data for GraphViz2.
	my($stt_graph) = GraphViz2::Parse::STT -> new;

	$stt_graph -> create(stt => join("\n", @stt) );
	$stt_graph -> graph -> run(format => 'svg', output_file => 'graph.easy.svg');

=cut

	# Build and run the DFA.

	$self -> dfa
		(
		 Set::FA::Element -> new
		 (
		  accepting   => \@accept,
		  actions     => \%actions,
		  die_on_loop => 1,
		  logger      => $self -> logger,
		  start       => $self -> start,
		  transitions => \@transitions,
		 )
		);

	$self -> dfa -> report if ($self -> report_stt);

	# Return 0 for success and 1 for failure.

	return $self -> _process_graph;

} # End of run.

# --------------------------------------------------
# Warning: This is a function.

sub save_attribute
{
	my($dfa)           = @_;
	my($param)         = $myself -> param;
	$$param{attribute} =
	{
		count => $myself -> _count,
		match => trim($dfa -> match),
	};

	$myself -> param($param);
	$myself -> logger -> log(debug => "save_attribute($$param{attribute}{match})");

} # End of save_attribute.

# --------------------------------------------------
# Warning: This is a function.

sub save_class_attribute
{
	my($dfa)                 = @_;
	my($param)               = $myself -> param;
	$$param{class_attribute} =
	{
		count => $myself -> _count,
		match => trim($dfa -> match),
	};

	$myself -> param($param);
	$myself -> logger -> log(debug => "save_class_attribute($$param{class_attribute}{match})");

} # End of save_class_attribute.

# --------------------------------------------------
# Warning: This is a function.

sub save_class_name
{
	my($dfa)   = @_;
	my($match) = trim($dfa -> match);

	# Did we actually detect a class name? For instance, the graph might have started with [].

	if ($match =~ /[a-zA-Z_]+/)
	{
		my($param)            = $myself -> param;
		my($previous_match)   = $$param{class}{match};

		if ($previous_match)
		{
			$$param{class}{match} .= $match;
		}
		else
		{
			$$param{class} =
			{
				count => $myself -> _count,
				match => $match,
			};
		}

		$myself -> param($param);
		$myself -> logger -> log(debug => "save_class_name($$param{class}{match})");
	}
	else
	{
		$myself -> logger -> log(debug => "save_class_name()");
	}

} # End of save_class_name.

# --------------------------------------------------
# Warning: This is a function.

sub save_edge_name
{
	my($dfa)      = @_;
	my($param)    = $myself -> param;
	$$param{edge} =
	{
		count => $myself -> _count,
		match => trim($dfa -> match),
	};

	$myself -> param($param);
	$myself -> logger -> log(debug => "save_edge_name($$param{edge}{match})");

} # End of save_edge_name.

# --------------------------------------------------
# Warning: This is a function.

sub save_group_name
{
	my($dfa)   = @_;
	my($match) = trim($dfa -> match);
	$match     =~ s/:$//;

	# The empty group.

	if ($match eq ')')
	{
		die 'Error: Group has no name';
	}

	# Nested group.

	if ($myself -> group)
	{
		die "Error: Groups can't be nested";
	}

	$myself -> group($match);

	my($param)     = $myself -> param;
	$$param{group} =
	{
		count => $myself -> _count,
		match => $match,
	};

	$myself -> param($param);
	$myself -> logger -> log(debug => "save_group_name($$param{group}{match})");

} # End of save_group_name.

# --------------------------------------------------
# Warning: This is a function.

sub save_node_name
{
	my($dfa)   = @_;
	my($match) = trim($dfa -> match);

	# The anonymous node.

	if ($match eq ']')
	{
		$match = '';
	}

	$myself -> logger -> log(debug => "save_node_name($match)");

	my($param)    = $myself -> param;
	$$param{node} =
	{
		count => $myself -> _count,
		match => $match,
	};

	$myself -> param($param);

} # End of save_node_name.

# --------------------------------------------------
# Warning: This is a function.

sub trim
{
	my($s) = @_;
	$s =~ s/^\s+//;
	$s =~ s/\s+$//;

	return $s;

} # End of trim.

# --------------------------------------------------
# Warning: This is a function.

sub validate_attribute
{
	my($dfa)           = @_;
	my($param)         = $myself -> param;
	my($attribute)     = $$param{attribute}{match};
	$$param{attribute} = {};

	$myself -> param($param);
	$myself -> logger -> log(debug => "validate_attribute($attribute)");

	my($key);
	my($value);

	for my $key_value (split(/\s*;\s*/, $attribute) )
	{
		($key, $value) = split(/\s*:\s*/, $key_value);

		# The defined is to ensure we accept things like: 'width: 0'.

		if (! ($key && defined $value) )
		{
			die "Error: Syntax error in attribute '$attribute'";
		}

		$myself -> items -> push
		({
			count => $myself -> _count,
			name  => $key,
			type  => 'attribute',
			value => $value,
		});
	}

} # End of validate_attribute.

# --------------------------------------------------
# Warning: This is a function.

sub validate_class_attribute
{
	my($dfa)                 = @_;
	my($param)               = $myself -> param;
	my($attribute)           = $$param{class_attribute}{match};
	$$param{class_attribute} = {};

	$myself -> param($param);
	$myself -> logger -> log(debug => "validate_attribute($attribute)");

	my($key);
	my($value);

	for my $key_value (split(/\s*;\s*/, $attribute) )
	{
		($key, $value) = split(/\s*:\s*/, $key_value);

		if (! ($key && $value) )
		{
			die "Error: Syntax error in attribute '$attribute'";
		}

		$myself -> items -> push
		({
			count => $myself -> _count,
			name  => $key,
			type  => 'class_attribute',
			value => $value,
		});
	}

} # End of validate_class_attribute.

# --------------------------------------------------
# Warning: This is a function.

sub validate_class_name
{
	my($dfa)       = @_;
	my($param)     = $myself -> param;
	my($class)     = $$param{class}{match};
	$$param{class} = {};

	$myself -> param($param);

	my(%valid_name) =
		(
		 edge  => 1,
		 graph => 1,
		 group => 1,
		 node  => 1,
		);

	if (! $valid_name{$class})
	{
		die "Error: Syntax error in class name '$class'. Must be one of: " . join(', ', sort keys %valid_name);
	}

	$myself -> logger -> log(debug => "validate_class_name ($class)");
	$myself -> items -> push
	({
		count => $myself -> _count,
		name  => $class,
		type  => 'class',
		value => '',
	});

} # End of validate_class_name.

# --------------------------------------------------
# Warning: This is a function.

sub validate_edge_name
{
	my($dfa)      = @_;
	my($param)    = $myself -> param;
	my($edge)     = $$param{edge}{match};
	$$param{edge} = {};

	$myself -> param($param);
	$myself -> logger -> log(debug => "validate_edge_name($edge)");
	$myself -> items -> push
	({
		count => $myself -> _count,
		name  => $edge,
		type  => 'edge',
		value => '',
	});

} # End of validate_edge_name.

# --------------------------------------------------
# Warning: This is a function.

sub validate_group_name
{
	my($dfa)       = @_;
	my($param)     = $myself -> param;
	my($group)     = $$param{group}{match};
	$$param{group} = {};

	$myself -> param($param);
	$myself -> logger -> log(debug => "validate_group_name($group)");
	$myself -> items -> push
	({
		count => $myself -> _count,
		name  => $group,
		type  => 'group',
		value => '',
	});

} # End of validate_group_name.

# --------------------------------------------------
# Warning: This is a function.

sub validate_node_name
{
	my($dfa)      = @_;
	my($param)    = $myself -> param;
	my($node)     = $$param{node}{match};
	$$param{node} = {};

	$myself -> param($param);
	$myself -> logger -> log(debug => "validate_node_name($node)");

	$myself -> items -> push
	({
		count => $myself -> _count,
		name  => $node,
		type  => 'node',
		value => '',
	});

} # End of validate_node_name.

# --------------------------------------------------
# Warning: This is a function.

sub validate_subclass_name
{
	my($dfa)       = @_;
	my($param)     = $myself -> param;
	my($class)     = $$param{class}{match};
	$$param{class} = {};

	$myself -> param($param);
	$myself -> logger -> log(debug => "validate_subclass_name($class)");
	$myself -> items -> push
	({
		count => $myself -> _count,
		name  => $class,
		type  => 'subclass',
		value => '',
	});

} # End of validate_subclass_name.

# --------------------------------------------------

1;

=pod

=head1 NAME

L<Graph::Easy::Marpa::Lexer::DFA> - A Set::FA::Element-based lexer for Graph::Easy

=head1 Synopsis

See L<Graph::Easy::Marpa/Data and Script Interaction>.

=head1 Description

L<Graph::Easy::Marpa::Lexer::DFA> provides a L<Set:FA::Element>-based lexer for L<Graph::Easy>-style graph definitions.

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

C<new()> is called as C<< my($dfa) = Graph::Easy::Marpa::Lexer::DFA -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Graph::Easy::Marpa::Lexer::DFA>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. graph_text()]):

=over 4

=item o graph_text => $string

Specify a string for the graph definition.

=item o logger => $logger

Specify a logger object to use.

=item o report_stt => $Boolean

Get or set the value which determines whether or not to report the parsed state transition table (STT).

=item o state => $state

Specify the state transition table.

=item o start => $start_state_name

Specify the name of the start state.

=back

=head1 Methods

=head2 items()

Returns a object of type L<Set::Array>, which is an arrayref of items output by the state machine.

These items are I<not> the same as the arrayref of items returned by the items() method in
L<Graph::Easy::Marpa::Parser>, but they are the same as in L<Graph::Easy::Marpa::Lexer>.

Each element is a hashref with these keys:

=over 4

=item o name => $string

The name of the thing (attribute, class, edge, node or subclass) found.

=item o type => $string

The type of the name.

The value of $string is one of: attribute, class, class_attribute, edge, group, node, pop_group or subclass.

The code does not distinguish between attributes for a class, subclass, edge or node.

The value pop_group is for the ')' token at the end of the definition of a group.

=item o value => $string

The value, if the type is attribute or class_attribute.

=back

=head2 run()

Runs the state machine.

Afterwards, you call L</items()> to retrieve the arrayref of results.

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
