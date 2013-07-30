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
my(%dot_files)     = Graph::Easy::Marpa::Filer -> new -> get_files($data_dir_name, 'dot');

my(@dot_file);
my($image_name);
my($stdout, $stderr);

for my $dot_name (sort values %dot_files)
{
	$dot_name    = File::Spec -> catfile($data_dir_name, $dot_name);
	($image_name = $dot_name) =~ s/dot$/svg/;
	$image_name  =~ s/$data_dir_name/$html_dir_name/;

	print "Processing $dot_name => $image_name. \n";

	try
	{
		($stdout, $stderr) = capture{system 'dot', '-Tsvg', $dot_name};

		if ($stderr)
		{
			print "STDERR: $stderr\n";
		}
		else
		{
			open(OUT, '>', $image_name);
			binmode OUT;
			print OUT $stdout;
			close OUT;
		}
	}
	catch
	{
		print "Died: $_. \n";
	};
}
