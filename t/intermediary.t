use Test::More;

# ------------------------------------------------

BEGIN{ use_ok('Graph::Easy::Marpa::Test'); }

for my $input_file (1 .. 12)
{
	my($result) = Graph::Easy::Marpa::Test -> new(input_file => $input_file) -> run;

	ok($result eq 'OK', "Processed data/intermediary.$input_file.csv");
}

done_testing;
