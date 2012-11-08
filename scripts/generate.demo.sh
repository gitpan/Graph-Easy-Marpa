#!/bin/bash

perl -Ilib scripts/raw2cooked.pl
perl -Ilib scripts/cooked2svg.pl

# Fix up graph.15.png, where we must use png:gd as the format for some unknown reason.

if [ "$1" = "png" ] ; then
	perl -Ilib scripts/parse.pl -f png:gd -i data/graph.15.cooked -o html/graph.15.png
fi

perl -Ilib scripts/generate.demo.pl
