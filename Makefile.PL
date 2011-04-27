use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
 ($] ge '5.005') ?
 (
  AUTHOR   => 'Ron Savage (ron@savage.net.au)',
  ABSTRACT => 'Proof-of-concept Marpa-based parser for Graph::Easy',
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
	 FindBin              => 1.50,
	 IO::File             => 1.14,
	 Marpa                => 0.202000,
 	 Moose                => 1.21,
 	 namespace::autoclean => 0.09,
 	 Test::More           => 0.94,
 	 Test::Pod            => 1.44,
	 Text::CSV_XS         => 0.80,
 },
 VERSION_FROM => 'lib/Graph/Easy/Marpa.pm',
);
