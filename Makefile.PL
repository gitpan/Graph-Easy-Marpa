use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
 ($] ge '5.005') ?
 (
  AUTHOR   => 'Ron Savage (ron@savage.net.au)',
  ABSTRACT => 'Marpa-based parser for Graph::Easy',
    ) : (),
 clean =>
 {
	 FILES => 'blib/* Makefile MANIFEST Graph-Easy-Marpa-*'
 },
 dist =>
 {
	 COMPRESS => 'gzip',
	 SUFFIX   => 'gz'
 },
 DISTNAME  => 'Graph-Easy-Marpa',
 NAME      => 'Graph::Easy::Marpa',
 PL_FILES  => {},
 PREREQ_PM =>
 {
	 File::Basename    => 2.78,
	 File::Spec        => 3.33,
	 GraphViz2         => 1.06,
 	 Hash::FieldHash   => 0.10,
	 IO::File          => 1.14,
	 List::Compare     => 0.37,
	 Log::Handler      => 0.71,
	 Marpa             => 0.202000,
	 OpenOffice::OODoc => 2.125,
	 Perl6::Slurp      => 0.03,
	 Set::Array        => 0.23,
	 Set::FA           => 1.06,
 	 Test::More        => 0.94,
 	 Test::Pod         => 1.44,
	 Text::CSV_XS      => 0.80,
 },
 VERSION_FROM => 'lib/Graph/Easy/Marpa.pm',
);
