package Graph::Easy::Marpa::Test;

use strict;
use warnings;

use FindBin;

use Graph::Easy::Marpa::Parser;

use IO::File;

use Text::CSV_XS;

use Moose;

has input_file =>
(
 default  => 1,
 is       => 'rw',
 isa      => 'Int',
 required => 0,
);

has verbose =>
(
 default  => 0,
 is       => 'rw',
 isa      => 'Int',
 required => 0,
);

use namespace::autoclean;

our $VERSION = '0.50';

# --------------------------------------------------

sub BUILD
{
	my($myself) = @_;

} # End of BUILD.

# --------------------------------------------------

sub log
{
	my($self, $s) = @_;
	$s ||= '';

	if ($self -> verbose)
	{
		print "$s\n";
	}

} # End of log.

# -----------------------------------------------

sub read_csv_file
{
	my($self, $file_name) = @_;
	my($csv) = Text::CSV_XS -> new({allow_whitespace => 1});
	my($io)  = IO::File -> new($file_name, 'r');

	$csv -> column_names($csv -> getline($io) );

	return $csv -> getline_hr_all($io);

} # End of read_csv_file.

# --------------------------------------------------

sub run
{
	my($self) = @_;
	my($file) = $self -> input_file;
	my($path) = "$FindBin::Bin/../data/intermediary.$file.csv";

	my(@token);

	for my $item (@{$self -> read_csv_file($path)})
	{
		push @token, [$$item{key}, $$item{value}];
	}

	my($marpa) = Graph::Easy::Marpa::Parser -> new(verbose => $self -> verbose);

	$marpa -> run(\@token);

	my(@item) = @{$marpa -> items};

	my($item);
	my($s);

	for my $i (0 .. $#item)
	{
		$item = $item[$i];
		$s    = join('', map{"$_: $$item{$_}. "} sort keys %$item);

		if ($$item{type} =~ /(?:edge|node)/)
		{
			$self -> log($s);
		}
		else
		{
			$self -> log("\t$s");
		}
	}

	return 'OK';

} # End of run.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

=pod

=head1 NAME

L<Graph::Easy::Marpa::Test> - Proof-of-concept Marpa-based parser for Graph::Easy

=head1 Synopsis

For sample code, see scripts/demo.pl, t/attr.t and t/edge.t.

For more details, see L<Graph::Easy::Marpa>.

=head1 Description

L<Graph::Easy::Marpa::Tst> provides a simple way to test L<Graph::Easy::Marpa::Parser>.

=head1 Installation

Install L<Graph::Easy::Marpa> as you would for any C<Perl> module:

Run:

	cpanm Graph::Easy::Marpa

or run:

	sudo cpan Graph::Easy::Marpa

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($tester) = Graph::Easy::Marpa::Test -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Graph::Easy::Marpa::Test>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. verbose()]):

=over 4

=item o input_file

Takes a number such as 1 (the default) and up.

If 1, process data/intermediary.1.csv.

If N, process data/intermediary.N.csv.

=item o verbose

Takes either 0 (the default) or 1.

If 0, nothing is printed.

If 1, nothing is printed, yet.

See scripts/demo.pl.

=back

=head1 Methods

=head2 input_file($n)

Specify the file number, 1 and up, of the intermediary file to be read in by read_csv_file().

For these intermediary files, see data/intermediary.*.csv.

run() calls input_file() automatically to retrieve the input file number specified in new().

=head2 log($s)

If new() was called as new() or new(verbose => 0), do nothing.

If new() was called as new(verbose => 1), print the string $s.

=head2 read_csv_file($file_name)

Returns an arrayref (1 element per line) of hashrefs after reading the CSV file called $file_name.

=head2 run()

Returns 'OK' or L<Graph::Easy::Marpa::Parser> dies with an error message.

Processes the input file specified in new().

=head2 verbose([0 or 1])

The [] indicate an optional parameter.

Get or set the value of the verbose option.

=head1 FAQ

=over 4

=item o Is there sample data I can examine?

Sure, see data/intermediary.*.csv. These files can be tested with:

	perl -Ilib scripts/demo.pl -v -s 1
	perl -Ilib scripts/demo.pl -v -s 2
	up to
	perl -Ilib scripts/demo.pl -v -s 12

See also:

	prove -Ilib -v t/intermediary.t

=back

See the L<Graph::Easy::Marpa/FAQ> for details.

=head1 Machine-Readable Change Log

The file CHANGES was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Graph::Easy::Marpa>.

=head1 Author

L<Graph::Easy::Marpa::Parser> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2011.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2011, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
