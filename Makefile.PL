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
	 Marpa                => 0.202000,
 	 Moose                => 0.98,
 	 namespace::autoclean => 0.09,
 },
 VERSION_FROM => 'lib/Graph/Easy/Marpa.pm',
);
