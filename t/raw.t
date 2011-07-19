use File::Slurp;

use Sort::Naturally;

use Test::More;

use Try::Tiny;

# ------------------------------------------------

BEGIN{ use_ok('Graph::Easy::Marpa::Lexer'); }

# Determine test file names.

my(@file) = map{"data/$_"} nsort grep{/raw/} read_dir('data');

# Start $count at 1 because of use_ok() above.

my($count) = 1;

my($expect);
my($result);

for my $file (@file)
{
	$count++;

	$expect = $result = undef;

	try
	{
		# Return 0 for success and 1 for failure.
		# If the lexer dies, it won't set $expect.
		# If the lexer detects an error, or works, it will set $expect.

		$expect = $result = Graph::Easy::Marpa::Lexer -> new(input_file => $file, maxlevel => 'error') -> run;
	}
	catch
	{
		$expect = $result = 1;
	};

	ok(defined($result) && defined($expect) && ($result == $expect), "Processed $file");
}

done_testing($count);
