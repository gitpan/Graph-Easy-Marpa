#!/usr/bin/env perl

use strict;
use warnings;

use Graph::Easy::Marpa;

use Getopt::Long;

use Pod::Usage;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
	\%option,
	'description=s',
	'dot_input_file=s',
	'format=s',
	'help',
	'input_file=s',
	'logger=s',
	'maxlevel=s',
	'minlevel=s',
	'output_file=s',
	'rankdir=s',
	'report_tokens=i',
	'token_file=s',
) )
{
	pod2usage(1) if ($option{'help'});

	# Return 0 for success and 1 for failure.

	exit Graph::Easy::Marpa -> new(%option) -> run;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

parse.pl - Run Graph::Easy::Marpa::Parser.

=head1 SYNOPSIS

parse.pl [options]

	Options:
	-description graphDescription
	-dot_input_file aDotInputFileName
	-format ADotOutputImageFormat
	-help
	-input_file aGEFileName
	-logger a-Log::Handler-compatibleObject
	-maxlevel logOption1
	-minlevel logOption2
	-output_file aDotOutputFile
	-rankdir LR or RL or TB or BT
	-report_tokens 0 or 1
	-token_file aTokenFileName

Exit value: 0 for success, 1 for failure. Die upon error.

Typical usage:

	perl -Ilib scripts/parse.pl -de '[node]{color:blue}' -re 1

	perl -Ilib scripts/parse.pl -max debug -de '[node]{color:blue}' -re 1

	perl -Ilib scripts/parse.pl -min error -max debug -de '[node]{color:blue}' -re 1

	perl -Ilib scripts/parse.pl -i data/edge.01.ge -re 1

	perl -Ilib scripts/parse.pl -i data/node.04.ge -t node.04.tokens
	diff node.04.tokens data/node.04.tokens

You can use scripts/parse.sh to simplify this process:

	scripts/parse.sh data/node.04.ge data/node.04.tokens

Complex graphs work too. Try:

	perl -Ilib t/attr.t.

The renderer formats the parser's output into a dot file, and then runs dot on that file.

The renderer is only called if the parser ran successfully.

=head1 OPTIONS

=over 4

=item o -description graphDescription

Specify a graph description string to parse.

You are strongly encouraged to surround this string with '...' to protect it from your shell.

See also the -input_file option to read the description from a file.

The -description option takes precedence over the -input_file option.

Default: ''.

=item o -dot_input_file aDotInputFileName

Specify the name of the dot input file for the renderer to write.

The option is passed to the renderer.

If '', the file will not be saved.

Default: ''.

=item o -format ADotOutputImageFormat

Specify the type of file for dot to output.

The option is passed to the renderer.

The file's name is set by the output_file option.

Default: 'svg'.

=item o -help

Print help and exit.

=item o -input_file aGEFileName

Read the graph description string from a file.

See also the -description option to read the graph description from the command line.

The whole file is slurped in as 1 graph.

The first lines of the file can start with /\s*#/, and will be discarded as comments.

The -description option takes precedence over the -input_file option.

Default: ''.

=item o -logger a-Log::Handler-compatibleObject

A shell script cannot pass the logger to the parser, so this is just here as documentation.

The option is passed to the renderer.

=item o -maxlevel logOption1

This option affects Log::Handler.

The option is passed to the renderer.

See the Log::handler docs.

Default: 'info'.

Another typical value is 'debug'.

=item o -minlevel logOption2

This option affects Log::Handler.

The option is passed to the renderer.

See the Log::handler docs.

Default: 'error'.

No lower levels are used.

=item o -output_file aDotOutputFile

Specify the name of the file for dot to write, meaning this file is output by dot when
the renderer runs dot.

The option is passed to the renderer.

If '', no output file will be written.

Default: ''.

See also the format option.

=item o -rankdir LR or RL or TB or BT

Specify the rankdir value to pass to the renderer.

Typical values are 'TB' (top to bottom) and 'LR' (left to right).

Default: 'TB'.

=item o -report_tokens 0 or 1

Report the tokens recognised by the parser.

This is a neat list of what is optionally written if a -token_file is specified.

Default: 0.

=item o -token_file aTokenFileName

The name of a CSV file of parsed tokens to write.

This is a permanent copy of what is reported if the -report_tokens option is set to 1.

If '', no output file will be written.

Default: ''.

=back

=cut
