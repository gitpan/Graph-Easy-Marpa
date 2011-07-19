#!/bin/bash

perl -Ilib scripts/gem.pl -c $1.cooked -dot $1.dot -i data/$1.raw -o $1.svg -p $1.items -report_items 1 -max debug $2 $3
