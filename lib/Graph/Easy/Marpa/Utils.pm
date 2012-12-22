package Graph::Easy::Marpa::Utils;

use strict;
use warnings;

use Config;

use Date::Simple;

use File::Basename; # For basename().
use File::Spec;

use Graph::Easy::Marpa::Config;

use Hash::FieldHash ':all';

use HTML::Entities::Interpolate;

use IO::File;

use Perl6::Slurp; # For slurp().

use Text::CSV_XS;
use Text::Xslate 'mark_raw';

fieldhash my %config => 'config';

our $VERSION = '1.12';

# ------------------------------------------------

sub generate_demo_environment
{
	my($self) = @_;

	my(@environment);

	# mark_raw() is needed because of the HTML tag <a>.

	push @environment,
	{left => 'Author', right => mark_raw(qq|<a href="http://savage.net.au/">Ron Savage</a>|)},
	{left => 'Date',   right => Date::Simple -> today},
	{left => 'OS',     right => 'Debian V 6'},
	{left => 'Perl',   right => $Config{version} };

	return \@environment;

} # End of generate_demo_environment.

# -----------------------------------------------

sub generate_demo_index
{
	my($self)          = @_;
	my($data_dir_name) = 'data';
	my($html_dir_name) = 'html';
	my(%image_file)    = $self -> get_files($html_dir_name, 'svg');

	my($line, @line);
	my($name);

	for my $key (sort keys %image_file)
	{
		$name           = "$data_dir_name/$key.raw";
		$line           = slurp $name;
		@line           = split(/\n/, $line);
		$image_file{$key} =
		{
			input  => $name,
			output => "$html_dir_name/$key.svg",
			raw    => join('<br />', map{$Entitize{$_} || ''} @line),
			title  => $line[0],
		};
	}

	my(@key)       = sort grep{defined} keys %image_file;
	my($config)    = $self -> config;
	my($templater) = Text::Xslate -> new
	(
		input_layer => '',
		path        => $$config{template_path},
	);
	my($count) = 0;
	my($index) = $templater -> render
	(
	'graph.easy.index.tx',
	{
		default_css     => "$$config{css_url}/default.css",
		data =>
			[
			map
			{
				{
					count  => ++$count,
					image  => "./$_.svg",
					input  => mark_raw($image_file{$_}{input}),
					output => mark_raw($image_file{$_}{output}),
					raw    => mark_raw($image_file{$_}{raw}),
					title  => mark_raw($image_file{$_}{title}),
				}
			} @key
			],
		environment     => $self -> generate_demo_environment,
		fancy_table_css => "$$config{css_url}/fancy.table.css",
		version         => $VERSION,
	}
	);
	my($file_name) = File::Spec -> catfile($html_dir_name, 'index.html');

	open(OUT, '>', $file_name);
	print OUT $index;
	close OUT;

	print "Wrote $file_name\n";

	# Return 0 for success and 1 for failure.

	return 0;

} # End of generate_demo_index.

# ------------------------------------------------

sub generate_stt_index
{
	my($self)          = @_;
	my(@heading)       = qw/Start Accept State Event Next Entry Exit Regexp Interpretation/;
	my($data_dir_name) = 'data';
	my($stt_file_name) = File::Spec -> catfile($data_dir_name, 'default.stt.csv');
	my($stt)           = $self -> read_csv_file($stt_file_name);

	my($column, @column);
	my(@row);

	for $column (@heading)
	{
		push @column, {td => $column};
	}

	push @row, [@column];

	for my $item (@$stt)
	{
		@column = ();

		for $column (@heading)
		{
			push @column, {td => mark_raw($$item{$column} || '.')};
		}

		push @row, [@column];
	}

	@column = ();

	for $column (@heading)
	{
		push @column, {td => $column};
	}

	push @row, [@column];

	my($config)    = $self -> config;
	my($templater) = Text::Xslate -> new
	(
		input_layer => '',
		path        => $$config{template_path},
	);
	my($html_dir_name) = 'html';
	my($file_name)     = File::Spec -> catfile($html_dir_name, 'stt.html');

	open(OUT, '>', $file_name) || die "Can't open(> $file_name): $!";
	print OUT $templater -> render
	(
	'stt.tx',
	{
		border          => 1,
		default_css     => "$$config{css_url}/default.css",
		environment     => $self -> generate_demo_environment,
		fancy_table_css => "$$config{css_url}/fancy.table.css",
		row             => [@row],
		summary         => 'STT',
		title           => 'State Transition Table for Graph::Easy::Marpa::Lexer',
		version         => $VERSION,
	},
	);
	close OUT;

	print "Wrote $file_name\n";

	# Return 0 for success and 1 for failure.

	return 0;

} # End of generate_stt_index.

# ------------------------------------------------

sub get_files
{
	my($self, $html_dir_name, $type) = @_;

	opendir(INX, $html_dir_name);
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

sub _init
{
	my($self, $arg) = @_;
	$$arg{config}   = Graph::Easy::Marpa::Config -> new -> config;
	$self           = from_hash($self, $arg);

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

sub read_csv_file
{
	my($self, $file_name) = @_;
	my($csv) = Text::CSV_XS -> new({allow_whitespace => 1});
	my($io)  = IO::File -> new($file_name, 'r');

	$csv -> column_names($csv -> getline($io) );

	return $csv -> getline_hr_all($io);

} # End of read_csv_file.

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
