%{
    #include "parser.tab.h"
%}

%%
"+"  { return ADD; }
"-"  { return SUB; }
"*"  { return MUL; }
"/"  { return DIV; }
[0-9]+  { return NUMBER; }
\n   { return EOL; }
[\t ]   { }
.    { printf("Mystery character %s\n", yytext); }

%%