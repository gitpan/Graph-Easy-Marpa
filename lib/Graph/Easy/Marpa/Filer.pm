package Graph::Easy::Marpa::Filer;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use File::Basename; # For basename().

use Moo;

our $VERSION = '2.01';

# ------------------------------------------------

sub get_files
{
	my($self, $dir_name, $type) = @_;

	opendir(INX, $dir_name);
	my(@file) = sort grep{/$type$/} readdir INX;
	closedir INX;

	my(%file);

	for my $file_name (@file)
	{
		$file{basename($file_name, ".$type")} = $file_name;
	}

	return %file;

} # End of get_files.

# -----------------------------------------------

1;

=pod

=head1 NAME

L<Graph::Easy::Marpa::Filer> - Some utils to simplify testing

=head1 Synopsis

See L<Graph::Easy::Marpa/Synopsis>.

See t/tokens.t.

=head1 Description

Some utils to simplify testing.

End-users do not need to call the methods in this module.

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

C<new()> is called as C<< my($obj) = Graph::Easy::Marpa::Filer -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Graph::Easy::Marpa::Filer>.

Key-value pairs accepted in the parameter list:

=over 4

=item o (none)

=back

=head1 Methods

=head2 get_files($dir_name, $type)

Returns a list of files from the given $dir_name, whose type (extension) matches $type.

See t/tokens.t.

=head1 Thanks

Many thanks are due to the people who chose to make L<Graphviz|http://www.graphviz.org/> Open Source.

And thanks to L<Leon Brocard|http://search.cpan.org/~lbrocard/>, who wrote L<GraphViz>, and kindly gave me co-maint of the module.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

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
