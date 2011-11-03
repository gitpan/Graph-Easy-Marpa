package Graph::Easy::Marpa::Utils;

use strict;
use warnings;

use File::Basename; # For basename().
use File::Spec;

use Hash::FieldHash ':all';

use Perl6::Slurp;

our $VERSION = '1.06';

# ------------------------------------------------

sub get_files
{
	my($self, $format) = @_;
	my($dir_name)      = 'html';

	opendir(INX, $dir_name);
	my(@file) = sort grep{/$format$/} readdir INX;
	closedir INX;

	my(%file);

	for my $file_name (@file)
	{
		$file{basename($file_name, ".$format")} = $file_name;
	}

	return %file;

} # End of get_files.

# -----------------------------------------------

sub _init
{
	my($self, $arg) = @_;
	$self = from_hash($self, $arg);

	return $self;

} # End of _init.

# -----------------------------------------------

sub new
{
	my($class, %arg) = @_;
	my($self)        = bless {}, $class;
	$self            = $self -> _init(\%arg);

	return $self;

}	# End of new.

# -----------------------------------------------

1;

=pod

=head1 NAME

L<Graph::Easy::Marpa::Utils> - Some utils to generate the demo page, and to simplify testing

=head1 Synopsis

See scripts/generate.index.pl and t/test.t.

Note: scripts/generate.index.pl outputs to a temporary directory. You'll need to patch it if
you wish to save the output.

See: L<http://savage.net.au/Perl-modules/html/graph.easy.marpa/index.html>.

=head1 Description

Some utils to simplify testing.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

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

=head2 Calling new()

C<new()> is called as C<< my($obj) = Graph::Easy::Marpa::Utils -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Graph::Easy::Marpa::Utils>.

Key-value pairs accepted in the parameter list:

=over 4

=item o (none)

=back

=head1 Thanks

Many thanks are due to the people who chose to make L<Graphviz|http://www.graphviz.org/> Open Source.

And thanks to L<Leon Brocard|http://search.cpan.org/~lbrocard/>, who wrote L<GraphViz>, and kindly gave me co-maint of the module.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Machine-Readable Change Log

The file CHANGES was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Graph::Easy::Marpa>.

=head1 Author

L<Graph::Easy::Marpa> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2011.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2011, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
