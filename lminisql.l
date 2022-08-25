%{
#include "pminisql.tab.h"
#include <stdio.h>
#include <stdarg.h>
#include <string.h>

void yyerror(char *s, ...);

int old_state;

%}

%x COMMENT
%s BTWMODE
%option noyywrap

%%

"CREATE" | create  { return CREATE; }
DROP   | drop    { return DROP; }
SELECT | select  { return SELECT; }
INSERT | insert  { return INSERT; }
VALUES | values  { return VALUES; }
DELETE | delete  { return DELETE; }
"TABLE"  | "table"   { return TABLE; }
INDEX  | index   { return INDEX; }
UNIQUE | unique  { return UNIQUE; }
FROM   | from    { return FROM; }
WHERE  | where   { return WHERE; }
INTO   | into    { return INTO; }
IN     | in      { return IN; }
ON     | on      { return ON; }

AND    | and     { return AND; }
OR     | or      { return OR; }
NOT    | not     { return NOT; }

PRIMARY | primary  { return PRIMARY; }
KEY    | key     { return KEY; }

"CHAR"   | "char"    { return CHAR; }
INT    | "int"     { return INT; }
FLOAT  | float   { return FLOAT; }

QUIT   | quit    { return QUIT; }
EXECFILE | execfile { return EXECFILE; }

-?[0-9]+                { yylval.intval = atoi(yytext); return INTNUM; }
-?[0-9]+"."[0-9]* |
-?"."[0-9]+       |
-?[0-9]+E[-+]?[0-9]+ |
-?[0-9]+"."[0-9]*E[-+]?[0-9]+ |
-?.[0-9]+E[-+]?[0-9]+   { yylval.floatval = atof(yytext); return APPROXNUM; }

TRUE                 { yylval.intval = 1; return BOOL; }
UNKNOWN              { yylval.intval = -1; return BOOL; }
FALSE                { yylval.intval = 0; return BOOL; }

'(\\.|''|[^'\n])*' |
\"(\\.|\"\"|[^"\n"])*\"  { yylval.strval = strdup(yytext); return STRING; }

'(\\.|[^'\n'])*$         { yyerror("unterminated string %s", yytext); }
\"(\\.|[^"\n"])*$        { yyerror("unterminated string %s", yytext); }

X'[0-9A-F]+' |
0X[0-9A-F]+              { yylval.strval = strdup(yytext); return STRING; }

B'[01]+'     |
0B[01]+                  { yylval.strval = strdup(yytext); return STRING; }

[-+&~|&/%*(),.;!]        { return yytext[0]; }
"&&"                     { return ANDOP; }
"||"                     { return OR; }

"="                 { yylval.subtok = 1; return COMPARISON; }
"<"                 { yylval.subtok = 2; return COMPARISON; }
"<="                { yylval.subtok = 3; return COMPARISON; }
">"                 { yylval.subtok = 4; return COMPARISON; }
">="                { yylval.subtok = 5; return COMPARISON; }
"!="                { yylval.subtok = 6; return COMPARISON; }

[A-Za-z][A-Za-z0-9_]*    { printf("name"); yylval.strval = strdup(yytext); return NAME; }
`[^`/\\.\n]+             { yylval.strval = strdup(yytext + 1); 
                           yylval.strval[yyleng-2] = 0;
                           return NAME;
                         }
`[^'\n]*$                { yyerror("unterminated quoted name %s", yytext); }

%%

main(void) {
    yylex();
    printf("we are here");
    return 0;
}