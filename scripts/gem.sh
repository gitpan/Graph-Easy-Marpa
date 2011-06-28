#!/bin/bash

perl -Ilib scripts/gem.pl -i data/$1.raw -c $1.cooked -t $1.items -o $1.svg


