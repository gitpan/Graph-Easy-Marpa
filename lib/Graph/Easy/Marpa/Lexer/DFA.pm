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
fieldhash my %verbose    => 'verbose';

our $myself; # Is a copy of $self for functions called by Set::FA::Element.
our $VERSION = '1.12';

# --------------------------------------------------
# Ensure each anonymous node has (at least) these attributes:
# o color: 'invis'.
# o label: ''.

sub check_anonymous_nodes
{
	my($self) = @_;
	my(@item) = $self -> items -> print;
	my(%fix)  =
	(
		color => 'invis',
		label => '',
	);

	# Loop over all items.

	my($i) = 0;

	my(@attribute);
	my(%found);
	my($item);
	my($last_i);
	my(@new_item);

	while ($i <= $#item)
	{
		# 1: Find the anonymous nodes.

		$item = $item[$i];

		push @new_item, $item;

		if ( ($$item{type} ne 'node') || ($$item{name} ne '') )
		{
			$i++;

			next;
		}

		# 2: Collect the anonymous node's attributes, if any.
		# Warning: $last_i must be set to $i, and not some arbitrary
		# value such as - 1, because of the $i = $last_i + 1 at the end,
		# which matters when [] has no attributes, and we never enter this loop.

		@attribute = ();
		$last_i    = $i;

		for (my $j = $i + 1; $j <= $#item; $j++)
		{
			$item = $item[$j];

			last if ($$item{type} ne 'attribute');

			$last_i = $j;

			push @attribute, $item;
		}

		# 3: Check for attributes color and label.

		%found = ();

		for (my $j = 0; $j <= $#attribute; $j++)
		{
			for my $key (keys %fix)
			{
				$found{$key} = $j if ($attribute[$j]{name} eq $key);
			}
		}

		# 4: Update attributes.
		# o If present, overwrite.
		# o If absent, fabricate.

		for my $key (keys %fix)
		{
			# We need defined because the index in $found{$key} may be 0.

			if (defined $found{$key})
			{
				$attribute[$found{$key}]{value} = $fix{$key};
			}
			else
			{
				# Setting count = 1 does not matter because the caller
				# (the lexer) calls the renumber_items() method.

				push @attribute,
				{
					count => 1,
					name  => $key,
					type  => 'attribute',
					value => $fix{$key},
				};
			}
		}

		# 5: Add the attributes to the array of new items.

		push @new_item, @attribute;

		# 6: Skip the previous attribute(s).

		$i = $last_i + 1;
	}

	$self -> items(Set::Array -> new(@new_item) );

} # End of check_anonymous_nodes.

# --------------------------------------------------

sub check_class_attributes
{
	my($self) = @_;
	my(@item) = $self -> items -> print;

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

} # End of check_class_attributes.

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
	# Probably don't need this, since a class can't end a graph.

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

	# Anonymous node must be invisible.

	$self -> check_anonymous_nodes;

	# Classes must have attributes.

	$self -> check_class_attributes;

} # End of _clean_up.

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
	$$arg{verbose}    ||= 0;  # Caller can set.
	$self             = from_hash($self, $arg);
	$myself           = $self;

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
		type  => 'pop_subgraph',
		value => '',
	});

	$myself -> group('');

} # End of pop_group.

# --------------------------------------------------

sub _process_graph
{
	my($self) = @_;

	my($result) = 1 - $self -> dfa -> accept($self -> graph_text);

	if ($result)
	{
		$self -> log(error => "Error: The final state '@{[$self -> dfa -> current]}' is not an accepting state");
	}
	else
	{
		$self -> _clean_up;
	}

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
		  verbose     => $self -> verbose,
		 )
		);

	$self -> dfa -> report if ($self -> report_stt);

	# Return 0 for success and 1 for failure.

	return $self -> _process_graph;

} # End of run.

# --------------------------------------------------
# Warning: This is a function.

sub save_attribute_name
{
	my($dfa)                = @_;
	my($attribute_name)     = $dfa -> match;
	$attribute_name         =~ s/:$//;
	my($param)              = $myself -> param;
	$$param{attribute_name} =
	{
		count => $myself -> _count,
		match => trim($attribute_name),
	};

	$myself -> param($param);
	$myself -> log(debug => "save_attribute_name($$param{attribute_name}{match})");

} # End of save_attribute_name.

# --------------------------------------------------
# Warning: This is a function.

sub save_attribute_value
{
	my($dfa)                  = @_;
	my($attribute_value)      = $dfa -> match;
	$attribute_value          =~ s/;?}$//;
	my($param)                = $myself -> param;
	$$param{attribute_value}  =
	{
		count => $myself -> _count,
		match => trim($attribute_value),
	};

	$myself -> param($param);
	$myself -> log(debug => "save_attribute_value($$param{attribute_value}{match})");

} # End of save_attribute_value.

# --------------------------------------------------
# Warning: This is a function.

sub save_class_attribute_name
{
	my($dfa)                      = @_;
	my($attribute_name)           = $dfa -> match;
	$attribute_name               =~ s/:$//;
	my($param)                    = $myself -> param;
	$$param{class_attribute_name} =
	{
		count => $myself -> _count,
		match => trim($attribute_name),
	};

	$myself -> param($param);
	$myself -> log(debug => "save_class_attribute_name($$param{class_attribute_name}{match})");

} # End of save_class_attribute_name.

# --------------------------------------------------
# Warning: This is a function.

sub save_class_attribute_value
{
	my($dfa)                        = @_;
	my($attribute_value)            = $dfa -> match;
	$attribute_value                =~ s/;?}$//;
	my($param)                      = $myself -> param;
	$$param{class_attribute_value}  =
	{
		count => $myself -> _count,
		match => trim($attribute_value),
	};

	$myself -> param($param);
	$myself -> log(debug => "save_class_attribute_value($$param{class_attribute_value}{match})");

} # End of save_class_attribute_value.

# --------------------------------------------------
# Warning: This is a function.

sub save_class_name
{
	my($dfa)   = @_;
	my($match) = trim($dfa -> match);

	# Did we actually detect a class name? For instance, the graph might have started with [ ].

	if ($match =~ /[a-z][a-z0-9_]*/)
	{
		my($param)          = $myself -> param;
		my($previous_match) = $$param{class}{match};

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
		$myself -> log(debug => "save_class_name($$param{class}{match})");
	}
	else
	{
		$myself -> log(debug => "save_class_name()");
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
	$myself -> log(debug => "save_edge_name($$param{edge}{match})");

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
	$myself -> log(debug => "save_group_name($$param{group}{match})");

} # End of save_group_name.

# --------------------------------------------------
# Warning: This is a function.

sub save_node_name
{
	my($dfa)   = @_;
	my($match) = trim($dfa -> match);
	$match     =~ s/]$//;

	# The anonymous node.

	if ($match eq ']')
	{
		$match = '';
	}

	$myself -> log(debug => "save_node_name($match)");

	my($param)    = $myself -> param;
	$$param{node} =
	{
		count => $myself -> _count,
		match => $match,
	};

	$myself -> param($param);

} # End of save_node_name.

# --------------------------------------------------
# By this time the code in both validate_attribute_value() and
# validate_class_attribute_value() has the 1st attribute's name
# and a string containing the attribute's value.
# Unfortunately, this string may also contain further attribute
# 'name;value' pairs, so here we split the string on ';' chars,
# and then reassemble any HTML entities which are in our list
# of acceptable entities (amp, gt, lt and quot).

sub splitter
{
	my($self, $s) = @_;
	my(@s)        = split(/;/, $s);
	my($finished) = 0;

	my($i);
	my($last);

	while (! $finished)
	{
		$i        = 0;
		$finished = 1;
		$last     = $#s;

		while ($i < $last)
		{
			if ($s[$i] =~ /&(amp|gt|lt|quot)$/)
			{
				splice(@s, $i, 2, "$s[$i];$s[$i + 1]");

				$finished = 0;

				last;
			}
			else
			{
				$i++;
			}
		}
	}

	return @s;

} # End of splitter.

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

sub validate_attribute_name
{
	my($dfa)            = @_;
	my($param)          = $myself -> param;
	my($attribute_name) = $$param{attribute_name}{match};

	# Do the real work in validate_attribute_value.

	$myself -> log(debug => "validate_attribute_name($attribute_name)");

} # End of validate_attribute_name.

# --------------------------------------------------
# Warning: This is a function.

sub validate_attribute_value
{
	my($dfa)                 = @_;
	my($param)               = $myself -> param;
	my($attribute_name)      = trim($$param{attribute_name}{match});
	my($attribute_value)     = trim($$param{attribute_value}{match});
	$$param{attribute_name}  = {};
	$$param{attribute_value} = {};

	$myself -> param($param);
	$myself -> log(debug => "validate_attribute_value($attribute_value)");

	my(@value) = $myself -> splitter($attribute_value);

	if ( ($#value % 2) < 0)
	{
		die "Error: Syntax error in attribute: $attribute_name: $attribute_value";
	}

	# Must allow for a value of 0.

	$attribute_value = trim(defined($_ = shift(@value) ) ? $_ : '');
	my(%attribute)   = ($attribute_name || '' => $attribute_value);
	@value           = map{split(/\s*:\s*/)} @value;

	if ($#value >= 0)
	{
		if ( ($#value % 2) == 0)
		{
			die 'Error: Syntax error in attribute: ' . join(': ', @value);
		}

		# Must allow for a value of 0.

		%attribute = (%attribute, map{trim(defined($_) ? $_ : '')} @value);
	}

	my($key);
	my($value);

	for my $key (keys %attribute)
	{
		$value = $attribute{$key};
		$value =~ s/^(["'])(.+)\1$/$2/ if (defined $value);

		# Must allow for a value of 0.

		if (! ($key && defined($value) ) )
		{
			die "Error: Syntax error in attribute '$key' => '$value'";
		}

		# Allow labels to be empty strings.

		if ( ($key ne 'label') && (length($value) == 0) )
		{
			die "Error: Syntax error in attribute '$key' => '$value'";
		}

		$myself -> items -> push
		({
			count => $myself -> _count,
			name  => $key,
			type  => 'attribute',
			value => $value,
		});
	}

} # End of validate_attribute_value.

# --------------------------------------------------
# Warning: This is a function.

sub validate_class_attribute_name
{
	my($dfa)            = @_;
	my($param)          = $myself -> param;
	my($attribute_name) = $$param{class_attribute_name}{match};

	# Do the real work in validate_attribute_value.

	$myself -> log(debug => "validate_class_attribute_name($attribute_name)");

} # End of validate_class_attribute_name.

# --------------------------------------------------
# Warning: This is a function.

sub validate_class_attribute_value
{
	my($dfa)                       = @_;
	my($param)                     = $myself -> param;
	my($attribute_name)            = trim($$param{class_attribute_name}{match});
	my($attribute_value)           = trim($$param{class_attribute_value}{match});
	$$param{class_attribute_name}  = {};
	$$param{class_attribute_value} = {};

	$myself -> param($param);
	$myself -> log(debug => "validate_class_attribute_value($attribute_value)");

	my(@value) = $myself -> splitter($attribute_value);

	if ( ($#value % 2) < 0)
	{
		die "Error: Syntax error in class attribute: $attribute_name: $attribute_value";
	}

	# Must allow for a value of 0.

	$attribute_value = trim(defined($_ = shift(@value) ) ? $_ : '');
	my(%attribute)   = ($attribute_name || '' => $attribute_value);
	@value           = map{split(/\s*:\s*/)} @value;

	if ($#value >= 0)
	{
		if ( ($#value % 2) == 0)
		{
			die 'Error: Syntax error in attribute: ' . join(': ', @value);
		}

		# Must allow for a value of 0.

		%attribute = (%attribute,  map{trim(defined($_) ? $_ : '')} @value);
	}

	my($key);
	my($value);

	for my $key (keys %attribute)
	{
		$value = $attribute{$key};
		$value =~ s/^(["'])(.+)\1$/$2/ if (defined $value);

		# Must allow for a value of 0.

		if (! ($key && defined($value) && (length($value) > 0) ) )
		{
			die "Error: Syntax error in class attribute '$key' => '$value'";
		}

		$myself -> items -> push
		({
			count => $myself -> _count,
			name  => $key,
			type  => 'class_attribute',
			value => $value,
		});
	}

} # End of validate_class_attribute_value.

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
		 edge   => 1,
		 global => 1,
		 graph  => 1,
		 group  => 1,
		 node   => 1,
		);
	my($valid_name) = join('|', sort keys %valid_name);

	if ($class !~ /^$valid_name(\.[a-z]+)?$/)
	{
		die "Error: Syntax error in class name '$class'. Must be one of: $valid_name";
	}

	$myself -> log(debug => "validate_class_name ($class)");
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
	my($dfa)        = @_;
	my($param)      = $myself -> param;
	my($edge)       = $$param{edge}{match};
	$$param{edge}   = {};
	my($valid_edge) = '->|--';

	if ($edge !~ /^$valid_edge$/)
	{
		die "Error: Syntax error in edge name '$edge'. Must be one of: $valid_edge";
	}

	$myself -> param($param);
	$myself -> log(debug => "validate_edge_name($edge)");
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
	my($dfa)         = @_;
	my($param)       = $myself -> param;
	my($group)       = $$param{group}{match};
	$$param{group}   = {};
	my($valid_group) = '[a-zA-Z_.][a-zA-Z_0-9. ]*';

	if ($group !~ /^$valid_group$/)
	{
		die "Error: Syntax error in group name '$group'. Must match: $valid_group";
	}

	$myself -> param($param);
	$myself -> log(debug => "validate_group_name($group)");
	$myself -> items -> push
	({
		count => $myself -> _count,
		name  => $group,
		type  => 'push_subgraph',
		value => '',
	});

} # End of validate_group_name.

# --------------------------------------------------
# Warning: This is a function.

sub validate_node_name
{
	my($dfa)        = @_;
	my($param)      = $myself -> param;
	my($node)       = $$param{node}{match};
	$$param{node}   = {};
	my($valid_node) = '[a-zA-Z_0-9. ]+';

	# We have to allow for the anonymous node, which has had any spaces trimmed.

	if ($node !~ /^(?:$valid_node|)$/)
	{
		die "Error: Syntax error in node name '$node'. Must match: $valid_node";
	}

	$myself -> param($param);
	$myself -> log(debug => "validate_node_name($node)");

	$myself -> items -> push
	({
		count => $myself -> _count,
		name  => $node,
		type  => 'node',
		value => '',
	});

} # End of validate_node_name.

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

Default: ''.

=item o logger => $logger

Specify a logger object to use.

Default: ''.

=item o report_stt => $Boolean

Get or set the value which determines whether or not to report the parsed state transition table (STT).

Default: 0.

=item o state => $state

Specify the state transition table.

There is no default. The code dies if a value is not supplied.

=item o start => $start_state_name

Specify the name of the start state.

There is no default. The code dies if a value is not supplied.

=item o verbose => $Boolean

Specify the verbosity level when calling L<Set::FA::Element>.

Default: 0.

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

=head2 log($level, $s)

Calls $self -> logger -> $level($s).

=head2 logger([$logger_object])

Here, the [] indicate an optional parameter.

Get or set the logger object.

To disable logging, just set logger to the empty string.

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

=head2 run()

Runs the state machine.

Afterwards, you call L</items()> to retrieve the arrayref of results.

=head2 verbose([$Boolean])

Here, the [] indicate an optional parameter.

Get or set the verbosity level when calling L<Set::FA::Element>.

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
