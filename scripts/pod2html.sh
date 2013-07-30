#!/bin/bash

DEST=$DR/Perl-modules/html/Graph/Easy

pod2html.pl -i lib/Graph/Easy/Marpa.pm                    -o $DEST/Marpa.html
pod2html.pl -i lib/Graph/Easy/Marpa/Actions.pm            -o $DEST/Marpa/Actions.html
pod2html.pl -i lib/Graph/Easy/Marpa/Config.pm             -o $DEST/Marpa/Config.html
pod2html.pl -i lib/Graph/Easy/Marpa/Parser.pm             -o $DEST/Marpa/Parser.html
pod2html.pl -i lib/Graph/Easy/Marpa/Utils.pm              -o $DEST/Marpa/Utils.html
pod2html.pl -i lib/Graph/Easy/Marpa/Renderer/GraphViz2.pm -o $DEST/Marpa/Renderer/GraphViz2.html
