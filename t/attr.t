use Test::More;

use Try::Tiny;

# ------------------------------------------------

BEGIN{ use_ok('Graph::Easy::Marpa::Parser'); }

my(@attr, %attr);
my(@name);
my(@token);

$attr{background} = 'green';

push @attr, {%attr};

$attr{border} = 'bold';

push @attr, {%attr};

$attr{class} = 'fancy';

push @attr, {%attr};

$attr{fill} = 'red';

push @attr, {%attr};

$attr{label} = 'edge.label';

push @attr, {%attr};

$attr{shape} = 'circle';

push @attr, {%attr};

$attr{style} = 'broad';

push @attr, {%attr};

$attr{'text-wrap'} = 10;

push @attr, {%attr};

# Start $count at 1 because of use_ok() above.

my($count) = 1;

my($expect);
my($result);

for my $attr (@attr)
{
	$count++;

	@name  = ();
	@token =
	(	
	 ['left_bracket',  '['],
	 ['node_name_id',  "N.$count"],
	 ['right_bracket', ']'],
	 ['left_brace',    '{'],
	  );

	for my $key (sort keys %$attr)
	{
		push @name, "$key:$$attr{$key};";

		push @token,
		 ['attr_name_id',  $key],
	 	 ['colon',         ':'],
	 	 ['attr_value_id', $$attr{$key}],
		 ['semi_colon',    ';'];
	 }

	 push @token,
	 ['right_brace',   '}'],
	 ['edge_id',       '--'];

	$expect = $result = undef;

	try
	{
		# Return 0 for success and 1 for failure.
		# If the parser dies, it won't set $expect.
		# If the parser detects an error, or works, it will set $expect.

		$expect = $result = Graph::Easy::Marpa::Parser -> new(tokens => [@token]) -> run;
	}
	catch
	{
		$expect = $result = 1;
	};

	ok(defined($result) && defined($expect) && ($result == $expect), "[N.$count]{" . join('', @name) . '}');
}

done_testing($count);
