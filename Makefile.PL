use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
 ($] ge '5.005') ?
 (
  AUTHOR   => 'Ron Savage (ron@savage.net.au)',
  ABSTRACT => 'A Marpa-based parser for Graph::Easy-style Graphviz files',
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
	 Capture::Tiny         => 0.11,
	 Data::Section::Simple => 0.02,
	 Date::Format          => 2.24,
	 File::Basename        => 2.78,
	 File::Remove          => 1.49,
	 File::Slurp           => 9999.19,
	 File::Spec            => 3.33,
	 File::Temp            => 0.22,
	 Getopt::Long          => 2.38,
	 GraphViz2             => 1.09,
 	 Hash::FieldHash       => 0.10,
	 IO::File              => 1.14,
	 List::Compare         => 0.37,
	 List::Cycle           => 1.00,
	 Log::Handler          => 0.71,
	 Marpa::R2             => 2.003,
	 Module::Load          => 0.18,
	 #OpenOffice::OODoc    => 2.125, # Optionally used in Lexer.pm.
	 Perl6::Slurp          => 0.03,
	 Pod::Usage            => 1.36,
	 Set::Array            => 0.23,
	 Set::FA::Element      => 1.08,
	 Sort::Naturally       => 1.02,
 	 Test::More            => 0.94,
 	 Test::Pod             => 1.44,
	 Text::CSV_XS          => 0.80,
	 Text::Xslate          => 1.4001,
	 Try::Tiny             => 0.09,
 },
 VERSION_FROM => 'lib/Graph/Easy/Marpa.pm',
);
