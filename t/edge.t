use Test::More;

use Try::Tiny;

# ------------------------------------------------

BEGIN{ use_ok('Graph::Easy::Marpa::Parser'); }

my(@edge);
my(@token);

for my $edge ('--', '->')
{
	push @edge, $edge;
}

# Start $count at 1 because of use_ok() above.

my($count) = 1;

my($expect);
my($result);

for my $edge (@edge)
{
	$count++;

	@token =
	(
	 ['left_bracket',  '['],
	 ['node_name_id',  "N.$count"],
	 ['right_bracket', ']'],
	 ['edge_id',       $edge],
	);

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

	ok(defined($result) && defined($expect) && ($result == $expect), "[N.$count]$edge");
}

print "# Internal test count: $count. \n";

done_testing($count);
