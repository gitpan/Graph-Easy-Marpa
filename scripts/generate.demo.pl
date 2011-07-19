#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny 'capture';

use Date::Format;

use File::Remove 'remove';
use File::Spec;
use File::Temp;

use Graph::Easy::Marpa::Utils;

use Perl6::Slurp;

use Text::Xslate 'mark_raw';

use Try::Tiny;

# -----------

# Output to ./html when re-generating the demo files to be shipped.
# End-users will not be writing to the distro's dir.
# The EXLOCK option is for BSD-based systems.
# Edit this line if you wish to save the output files.

my($html_dir_name) = shift || File::Temp -> newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
my($data_dir_name) = 'data';

opendir(INX, $data_dir_name) || die "Can't opendir($data_dir_name): $!";
my(@raw_name) = sort grep{/raw$/} readdir INX;
closedir INX;

my($script) = File::Spec -> catfile('scripts', 'gem.pl');

my($cooked_name);
my($html_name);
my($name);
my($stdout, $stderr);

for my $raw_name (@raw_name)
{
	print "Processing $raw_name. \n";

	$name         = File::Spec -> catfile($data_dir_name, $raw_name);
	($cooked_name = $name) =~ s/raw$/cooked/;
	$html_name    = File::Spec -> catfile($html_dir_name, $raw_name);
	$html_name    =~ s/raw$/svg/;

	try
	{
		($stdout, $stderr) = capture{system $^X, '-Ilib', $script, '-i', $name, '-c', $cooked_name, '-o', $html_name};

		if ($stderr)
		{
			print "STDERR: $stderr";

			remove $html_name;
		}
		else
		{
			print "Result: $stdout";

			# Delete 'empty' files.

			if (-e $html_name && -s $html_name == 571)
			{
				remove $html_name;
			}
		}
	}
	catch
	{
		print "Died: $_. \n";
	};
}

my(%svg_file) = Graph::Easy::Marpa::Utils -> new -> get_svg_files;

my($line, @line);
my($svg_name);

for my $key (sort keys %svg_file)
{
	$name           = "$data_dir_name/$key.raw";
	$line           = slurp $name;
	@line           = split(/\n/, $line);
	$svg_file{$key} =
	{
		input  => $name,
		output => "$html_dir_name/$key.svg",
		raw    => join('<br />', @line),
		title  => $line[0],
	};
}

my(@key)        = sort grep{defined} keys %svg_file;
my($templater)  = Text::Xslate -> new
(
  input_layer => '',
  path        => 'html',
);
my($count) = 0;
my($index) = $templater -> render
(
 'graph.easy.index.tx',
 {
	 data =>
		 [
		  map
		  {
			  {
				  count  => ++$count,
				  input  => mark_raw($svg_file{$_}{input}),
				  output => mark_raw($svg_file{$_}{output}),
				  raw    => mark_raw($svg_file{$_}{raw}),
				  svg    => "./$_.svg",
				  title  => mark_raw($svg_file{$_}{title}),
			  }
		  } @key
		 ],
	 date_stamp => time2str('%Y-%m-%d %T', time),
	 version    => $Graph::Easy::Marpa::Utils::VERSION,
 }
);
my($file_name) = File::Spec -> catfile($html_dir_name, 'index.html');

open(OUT, '>', $file_name);
print OUT $index;
close OUT;

print "Wrote: $file_name to $html_dir_name/. \n";
