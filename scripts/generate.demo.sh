#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ] ; then
	echo Usage: generate.demo.sh dir image.type
	exit
fi

perl -Ilib scripts/generate.demo.pl $1 $2

# Fix up graph.15.png, where we must use png:gd as the format for some unknown reason.

if [ "$2" = "png" ] ; then
	echo Processing graph.15 specially for $2

	perl -Ilib scripts/parse.pl -f png:gd -i data/graph.15.cooked -o html/graph.15.png
fi
