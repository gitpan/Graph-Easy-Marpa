use Module::Build;

Module::Build -> new
(
 module_name    => 'Graph::Easy::Marpa',
 license        => 'artistic',
 dist_abstract  => 'Proof-of-concept Marpa-based parser for Graph::Easy',
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
	 FindBin              => 1.50,
	 IO::File             => 1.14,
	 Marpa                => 0.202000,
 	 Moose                => 1.21,
 	 namespace::autoclean => 0.09,
	 Text::CSV_XS         => 0.80,
 },
) -> create_build_script();
