use strict;
use warnings;

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
	LICENSE   => 'artistic_2',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'Capture::Tiny'    => 0.11,
		'charnames'        => 0,
		'Config'           => undef,
		'Config::Tiny'     => 2.14,
		'Date::Simple'     => 3.03,
		'File::Basename'   => 2.78,
		'File::Copy'       => 2.21,
		'File::HomeDir'    => 0.99,
		'File::Spec'       => 3.33,
		'Getopt::Long'     => 2.38,
		'GraphViz2'        => 1.09,
		'HTML::Entities::Interpolate' => 1.04,
		'Log::Handler'     => 0.71,
		'Marpa::R2'        => 2.064000,
		'Moo'              => 1.002000,
		'open'             => 0,
		'Path::Tiny'       => 0.052,
		'Perl6::Slurp'     => 0.03,
		'Pod::Usage'       => 1.36,
		'Set::Array'       => 0.23,
		'Sort::Naturally'  => 1.02,
		'strict'           => 0,
		'Test::More'       => 0.94,
#		'Test::Pod'        => 1.45, # Make it optional. See t/pod.t
		'Text::CSV'        => 1.32,
		'Text::Xslate'     => 1.4001,
		'Try::Tiny'        => 0.09,
		'utf8'             => 0,
		'warnings'         => 0,
	},
	VERSION_FROM => 'lib/Graph/Easy/Marpa.pm',
);
