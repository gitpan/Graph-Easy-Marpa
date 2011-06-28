#!/bin/bash

echo Contents of $1:
cat $1
echo ----------------------------
echo Output of parser:
perl -Ilib scripts/parse.pl -i $1 -r 1
