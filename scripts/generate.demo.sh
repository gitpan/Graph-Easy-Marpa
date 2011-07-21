#!/bin/bash

if [ -z $1 ] ; then
	echo Usage: generate.demo.sh image.type
fi

perl -Ilib scripts/generate.demo.pl html

# Fix up graph.15.png, where we must use png:gd as the format

if [ "$1" = "png" ] ; then
	echo Processing graph.15 specially for $1

	perl -Ilib scripts/parse.pl -f png:gd -i data/graph.15.cooked -o html/graph.15.png
fi
