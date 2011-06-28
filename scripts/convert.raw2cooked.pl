#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny 'capture';

use File::Spec;

use Graph::Easy::Marpa::Lexer;

use Try::Tiny;

# -----------

my($dir_name) = 'data';

opendir(INX, $dir_name) || die "Can't opendir($dir_name): $!";
my(@raw_name) = map{File::Spec -> catfile($dir_name, $_)} sort grep{/raw$/} readdir INX;
closedir INX;

my($script) = File::Spec -> catfile('scripts', 'lex.pl');
my($stt)    = File::Spec -> catfile($dir_name, 'default.stt.csv');

my($cooked_name);
my($stdout, $stderr);

for my $raw_name (@raw_name)
{
	($cooked_name = $raw_name) =~ s/raw$/cooked/;

	print "$raw_name => $cooked_name. \n";

	try
	{
		($stdout, $stderr) = capture{system $^X, '-Ilib', $script, '-stt', $stt, '-t', 'csv', '-i', $raw_name, '-c', $cooked_name};

		if ($stderr)
		{
			print "STDERR: $stderr. \n";
		}
		else
		{
			#print "Result: $stdout. \n";
		}
	}
	catch
	{
		print "Died: $_. \n";
	};
}
