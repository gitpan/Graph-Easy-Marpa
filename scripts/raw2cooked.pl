#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny 'capture';

use File::Spec;

use Graph::Easy::Marpa::Lexer;

use Perl6::Slurp; # For slurp().

use Try::Tiny;

# -----------

my($dir_name) = 'data';

opendir(INX, $dir_name) || die "Can't opendir($dir_name): $!";
my(@raw_name) = map{File::Spec -> catfile($dir_name, $_)} sort grep{/raw$/} readdir INX;
closedir INX;

my($script) = File::Spec -> catfile('scripts', 'lex.pl');

my($cooked_name);
my($expected_result);
my(@raw_file);
my($stdout, $stderr);

for my $raw_name (@raw_name)
{
	print "Processing $raw_name. \n";

	@raw_file        = slurp($raw_name, {chomp => 1});
	$expected_result = ($1 || '') if ($raw_file[0] =~ /(Error|OK)\.$/);

	if (! $expected_result)
	{
		die "Typo in $raw_name. First line must end in /(Error|OK)\.\$/. ";
	}

	($cooked_name = $raw_name) =~ s/raw$/cooked/;

	try
	{
		($stdout, $stderr) = capture{system $^X, '-Ilib', $script, '-i', $raw_name, '-c', $cooked_name};

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

	if ( ($expected_result eq 'OK') && ! -e $cooked_name)
	{
		die "Missing cooked file $cooked_name. ";
	}
}
