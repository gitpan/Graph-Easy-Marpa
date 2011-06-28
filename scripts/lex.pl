#!/usr/bin/env perl

use strict;
use warnings;

use Graph::Easy::Marpa::Lexer;

use Getopt::Long;

use Pod::Usage;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
 \%option,
 'cooked_file=s',
 'description=s',
 'help',
 'input_file=s',
 'maxlevel=s',
 'minlevel=s',
 'report_items=i',
 'report_stt=i',
 'stt_file=s',
 'type=s',
) )
{
	pod2usage(1) if ($option{'help'});

	# Return 0 for success and 1 for failure.

	exit Graph::Easy::Marpa::Lexer -> new(%option) -> run;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

lex.pl - Run Graph::Easy::Marpa::Lexer.

=head1 SYNOPSIS

lex.pl [options]

	Options:
	-cooked_file aCookedFileName
	-description graphDescription
	-help
	-input_file aRawFileName
	-maxlevel logOption1
	-minlevel logOption2
	-report_items 0 or 1
	-report_stt 0 or 1
	-stt_file sttFileName
	-type csv or ods

All switches can be reduced to a single letter (except min and max).

Exit value: 0 for success, 1 for failure. Die upon error.

Typical usage:

	perl -Ilib scripts/lex.pl -stt data/default.stt.csv -t csv -d '[node]{color:blue}'

	perl -Ilib scripts/lex.pl -stt data/default.stt.csv -t csv -max debug -d '[node]{color:blue}'

	perl -Ilib scripts/lex.pl -stt data/default.stt.csv -t csv -min error -max debug -d '[node]{color:blue}'

Complex graphs work too: -g '[node.1]{a:b;c:d}<->{e:f;}<=>{g:h}[node.2]{i:j}===[node.3]{k:l}'

	perl -Ilib scripts/lex.pl -stt data/default.stt.csv -t csv -i data/edge.01.raw

	perl -Ilib scripts/lex.pl -stt data/default.stt.csv -t csv -i data/node.04.raw -c node.04.cooked
	diff node.04.cooked data/node.04.cooked

You can use scripts/lex.sh to simplify this process:

	scripts/lex.sh data/node.04.raw data/node.04.cooked

=head1 OPTIONS

=over 4

=item -cooked_file aCookedFileName

The name of a CSV file of cooked tokens to write. This file can be input to the parser.

The default value is '', meaning no output file will be written.

=item -description graphDescription

Specify a graph description string for the DFA to process.

You are strongly encouraged to surround this string with '...' to protect it from your shell.

See also the -input_file option to read the description from a file.

The -description option takes precedence over the -input_file option.

There is no default value.

=item -help

Print help and exit.

=item -input_file aRawFileName

Read the graph description string from a file.

See also the -description option to read the graph description from the command line.

The whole file is slurped in as 1 graph.

The first lines of the file can start with /\s*#/, and will be discarded as comments.

The -description option takes precedence over the -input_file option.

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

=item -report_items 0 or 1

Report the items recognised by the state machine.

The default value is 0.

=item -report_stt 0 or 1

Call Set::FA::Element.report(). Set min and max log levels to 'info' for this.

The default value is 0.

=item -stt_file sttFileName

Specify which file contains the state transition table.

Default: data/default.stt.ods.

The type of this file must be specified by the -type option.

There is no default value.

=item -type cvs or ods

Specify the type of the stt_file: csv for CSV or ods for Open Office Calc spreadsheet.

Default: csv.

This option must be used with the -stt_file option.

=back

=cut
