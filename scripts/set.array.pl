#!/usr/bin/env perl

use strict;
use warnings;

use Set::Array;

# -------------

sub marine
{
	my($name, $u, $v, $x, $y) = @_;

	print "$name. v: $v. y: $y. \n";

} # End of marine.

# -------------

my($set) = Set::Array -> new('one', 'two', 'three', 'four', 'five');
my $a    = $set;
my($b)   = $set;
my $c    = $set -> compact;
my($d)   = $set -> compact;
my $e    = $set -> print;
my($f)   = $set -> print;

print "a: $a. b: $b. c: $c. d: $d. e: $e. f: $f. \n";

print 'c: ', join(', ', @$c), ". \n";

marine('a', u => $set, x => $a);
marine('b', u => $set, x => $b);
marine('c', u => $set -> compact, x => $c);
marine('d', u => $set -> compact, x => $d);
marine('e', u => $set -> print, x => $e);
marine('f', u => $set -> print, x => $f);
