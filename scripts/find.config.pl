#!/usr/bin/env perl

use strict;
use warnings;

use File::HomeDir;

use Path::Tiny; # For path().

# --------------

my($module)      = 'Graph::Easy::Marpa';
my($module_dir)  = $module;
$module_dir      =~ s/::/-/g;
my($config_name) = '.htgraph.easy.marpa.conf';
my($path)        = path(File::HomeDir -> my_dist_config($module_dir), $config_name);

print "Using: File::HomeDir -> my_dist_config('$module_dir', '$config_name'): \n";
print "Found: $path\n";
