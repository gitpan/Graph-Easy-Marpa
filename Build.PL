use Module::Build;

Module::Build -> new
(
 module_name    => 'Graph::Easy::Marpa',
 license        => 'artistic',
 dist_abstract  => 'Marpa-based parser for Graph::Easy',
 dist_author    => 'Ron Savage <ron@savage.net.au>',
 build_requires =>
 {
 	 Test::More => 0.94,
 	 Test::Pod  => 1.44,
 },
 configure_requires =>
 {
 	 Module::Build => 0.3800,
 },
 requires =>
 {
 	 Hash::FieldHash   => 0.10,
	 IO::File          => 1.14,
	 List::Compare     => 0.37,
	 Log::Handler      => 0.71,
	 Marpa             => 0.202000,
	 OpenOffice::OODoc => 2.125,
	 Perl6::Slurp      => 0.03,
	 Set::Array        => 0.23,
	 Set::FA           => 1.04,
	 Text::CSV_XS      => 0.80,
 },
) -> create_build_script();
