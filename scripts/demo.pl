#!/usr/bin/env perl

use strict;
use warnings;

use File::Find;

use Getopt::Long;

use Graph::Easy::Marpa::Test;

use Pod::Usage;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
 \%option,
 'help',
 'input_file=i',
 'verbose',
) )
{
	pod2usage(1) if ($option{'help'});

	Graph::Easy::Marpa::Test -> new(%option) -> run;

	exit 1;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

parse.pl - Test Graph::Easy::Marpa.

=head1 SYNOPSIS

parse.pl [options]

	Options:
	-help
	-input_file 1 and up
	-verbose 0 or 1

All switches can be reduced to a single letter.

Exit value: 0.

=head1 OPTIONS

=over 4

=item -help

Print help and exit.

=item -imput_file 1 and up

Specify which data set to read. See data/intermediary.*.csv.

=item -verbose 0 or 1

Print more or less progress messages.

=back

=cut
