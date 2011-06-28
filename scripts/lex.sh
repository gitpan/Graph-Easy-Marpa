#!/bin/bash

echo Contents of $1:
cat $1
echo ----------------------------
echo Output of lexer:
perl -Ilib scripts/lex.pl -stt data/default.stt.csv -t csv -i $1 -c $2
echo ----------------------------
echo Contents of $2:
cat $2
echo ----------------------------
