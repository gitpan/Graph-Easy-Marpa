#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny 'capture';

use File::Spec;

use Graph::Easy::Marpa::Lexer;

use Perl6::Slurp; # For slurp().

use Try::Tiny;

# -----------

my($data_dir_name) = 'data';
my($html_dir_name) = 'html';

opendir(INX, $data_dir_name) || die "Can't opendir($data_dir_name): $!";
my(@cooked_name) = map{File::Spec -> catfile($data_dir_name, $_)} sort grep{/cooked$/} readdir INX;
closedir INX;

my($script) = File::Spec -> catfile('scripts', 'parse.pl');

my(@cooked_file);
my($image_name);
my($stdout, $stderr);

for my $cooked_name (@cooked_name)
{
	@cooked_file = slurp($cooked_name, {chomp => 1});
	($image_name = $cooked_name) =~ s/cooked$/svg/;
	$image_name  =~ s/$data_dir_name/$html_dir_name/;

	print "Processing $cooked_name => $image_name. \n";

	try
	{
		($stdout, $stderr) = capture{system $^X, '-Ilib', $script, '-i', $cooked_name, '-o', $image_name};

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
}
