#!/bin/bash

echo Contents of $1:
cat $1
echo ----------------------------
echo Output of lexer:
perl -Ilib scripts/lex.pl -i $1 -c $2
echo ----------------------------
echo Contents of $2:
cat $2
echo ----------------------------
