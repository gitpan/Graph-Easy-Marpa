use Graph::Easy::Marpa::Filer;

use Sort::Naturally;

use Test::More;

use Try::Tiny;

# ------------------------------------------------

BEGIN{ use_ok('Graph::Easy::Marpa::Parser'); }

# Determine test file names.

my(%file) = Graph::Easy::Marpa::Filer -> new -> get_files('data', 'ge');

# Start $count at 1 because of use_ok() above.

my($count) = 1;

my($expect);
my($result);

for my $file (sort keys %file)
{
	$count++;

	$expect = $result = undef;

	try
	{
		# Return 0 for success and 1 for failure.
		# If the parser dies, it won't set $expect.
		# If the parser detects an error, or works, it will set $expect.

		$expect = $result = Graph::Easy::Marpa::Parser -> new(input_file => $file) -> run;
	}
	catch
	{
		$expect = $result = 1;
	};

	ok(defined($result) && defined($expect) && ($result == $expect), "Processed $file");
}

done_testing($count);
