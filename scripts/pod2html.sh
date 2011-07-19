#!/bin/bash

pod2html.pl -i lib/Graph/Easy/Marpa.pm                    -o $DR/marpa/Marpa.html
pod2html.pl -i lib/Graph/Easy/Marpa/Lexer.pm              -o $DR/marpa/Lexer.html
pod2html.pl -i lib/Graph/Easy/Marpa/Parser.pm             -o $DR/marpa/Parser.html
pod2html.pl -i lib/Graph/Easy/Marpa/Utils.pm              -o $DR/marpa/Utils.html
pod2html.pl -i lib/Graph/Easy/Marpa/Lexer/DFA.pm          -o $DR/marpa/DFA.html
pod2html.pl -i lib/Graph/Easy/Marpa/Renderer/GraphViz2.pm -o $DR/marpa/GraphViz2.html
