#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;

use Graph::Easy::Marpa::Parser;

use Pod::Usage;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
 \%option,
 'dot_input_file=s',
 'format=s',
 'help',
 'input_file=s',
 'maxlevel=s',
 'minlevel=s',
 'output_file=s',
 'rankdir=s',
 'report_items=i',
) )
{
	pod2usage(1) if ($option{'help'});

	exit Graph::Easy::Marpa::Parser -> new(%option) -> run;
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
	-dot_input_file aDotInputFileName
	-format outputGraphFormat
	-help
	-input_file inFileName
	-maxlevel logOption1
	-minlevel logOption2
	-output_file aDotOutputFile
	-rankdir LR or RL or TB or BT
	-report_items 0 or 1
	-tokenFile aTokenFileName

Exit value: 0 for success, 1 for failure. Die upon error.

Typical usage:

	cat data/node.05.cooked
	perl -Ilib scripts/parse.pl -i data/node.05.cooked

You can use scripts/parse.sh to simplify this process:

	scripts/parse.sh data/node.05.cooked

=head1 OPTIONS

=over 4

=item -dot_input_file aDotInputFileName

Specify the name of a file that the rendering engine can write to, which will contain the input
to dot (or whatever). This is good for debugging.

Default: ''.

If '', the file will not be created.

=item -format outputGraphFormat

The format (e.g. 'svg') to pass to the rendering engine.

=item -help

Print help and exit.

=item -input_file inFileName

Specify which data set to read.

Typical names are data/graph.14.cooked etc.

There is no default value.

=item -maxlevel logOption1

This option affects Log::Handler.

See the Log::handler docs.

The default maxlevel is 'info'. Another typical value is 'debug'.

=item -minlevel logOption2

This option affects Log::Handler.

See the Log::handler docs.

The default minlevel is 'error'.

No lower levels are used.

=item o -output_file aDotOutputFile

A file to which the output from dot is written.

If not specified (the default), the graph is not saved.

The default is ''.

=item -rankdir LR or RL or TB or BT

Specify the rankdir of the graph as a whole.

Default: TB (top to bottom).

=item -report_items 0 or 1

Report the items recognized in the cooked file.

The default value is 0.

=item o -tokenFile aTokenFileName

The list of tokens generated by the parser will be written to this file.

If not specified (the default), the tokens are not saved.

The default is ''.

=back

=cut
