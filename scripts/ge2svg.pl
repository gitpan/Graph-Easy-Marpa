#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny 'capture';

use File::Spec;

use Graph::Easy::Marpa::Filer;

use Perl6::Slurp; # For slurp().

use Try::Tiny;

# -----------

my($data_dir_name) = 'data';
my($html_dir_name) = 'html';
my(%ge_files)      = Graph::Easy::Marpa::Filer -> new -> get_files($data_dir_name, 'ge');
my($script)        = File::Spec -> catfile('scripts', 'parse.pl');

my($dot_name);
my($expected_result);
my(@ge_file);
my($image_name);
my($stdout, $stderr);
my($token_name);

for my $ge_name (sort values %ge_files)
{
	$ge_name         = File::Spec -> catfile($data_dir_name, $ge_name);
	($image_name     = $ge_name) =~ s/ge$/svg/;
	$image_name      =~ s/$data_dir_name/$html_dir_name/;
	@ge_file         = slurp($ge_name, {chomp => 1});
	$expected_result = ($1 || '') if ($ge_file[0] =~ /(Error|OK)\.$/);

	print "Processing: $ge_name => $image_name. \n";
	print "$ge_file[0]\n";

	if (! $expected_result)
	{
		die "Typo in $ge_name. First line must end in /(Error|OK)\.\$/. ";
	}

	($dot_name   = $ge_name) =~ s/ge$/dot/;
	($token_name = $ge_name) =~ s/ge$/tokens/;

	try
	{
		($stdout, $stderr) = capture{system $^X, '-Ilib', $script, '-i', $ge_name, '-t', $token_name, '-dot', $dot_name, '-o', $image_name};

		if ($stderr)
		{
			print "STDERR: $stderr\n";
		}
		else
		{
			#print "Result: $stdout\n";
		}
	}
	catch
	{
		print "Died: $_. \n";
	};

	if ( ($expected_result eq 'OK') && ! -e $token_name)
	{
		die "Missing tokens file $token_name. ";
	}
}
