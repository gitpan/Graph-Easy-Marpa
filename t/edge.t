use Test::More;

# ------------------------------------------------

BEGIN{ use_ok('Graph::Easy::Marpa::Parser'); }

my($parser) = Graph::Easy::Marpa::Parser -> new;

my(@edge);
my(@token);

for my $prefix ('', '<')
{
for my $edge ('-', '=', '.', '~', '.-', '..-', '- ', '= ')
{
for my $i (1 .. 2)
{
for my $suffix ('', '>')
{
	push @edge, $prefix . $edge x $i . $suffix;
}
}
}
}

my($count) = 0;

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

	ok($parser -> run(\@token) eq 'OK', "[N.$count]$edge");
}

done_testing;
