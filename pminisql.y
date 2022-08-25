/*
 * Parser for minisql
 * 2022/08/24 cindy Liu
 */

%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>

void yyerror(char *s, ...);
void emit(char *s, ...);

%}

%union {
    int intval;
    double floatval;
    char *strval;
    int subtok;
}

/* declare tokens */
%token <strval> NAME
%token <strval> STRING
%token <intval> INTNUM
%token <intval> BOOL
%token <floatval> APPROXNUM

%left OR
%left ANDOP
%nonassoc IN
%left NOT '!'
%left '|'
%left '&'
%left '+' '-'
%left '*' '/'
%left <subtok> COMPARISON

%token CREATE
%token DROP
%token SELECT
%token INSERT
%token VALUES
%token DELETE
%token TABLE
%token INDEX
%token UNIQUE
%token FROM
%token WHERE
%token INTO
%token IN
%token ON
%token QUIT
%token EXECFILE

%token CHAR
%token INT
%token FLOAT

%token PRIMARY
%token KEY

%type <intval> select_opts select_expr_list
%type <intval> val_list opt_val_list
%type <intval> table_references
%type <intval> delete_opts delete_list
%type <intval> insert_opts insert_vals insert_vals_list
%type <intval> column_atts data_type create_col_list
%type <intval> opt_temporary column_list

%start stmt_list

%%

stmt_list: stmt ';'     { printf("at the start"); emit("STMT_START"); }
| stmt_list stmt ';'
;

stmt: create_table_stmt { emit("STMT"); }
;

create_table_stmt: CREATE opt_temporary TABLE NAME '(' create_col_list ')'
                        { emit("CREATE %d %d %d %s", $2, $4, $6, $4); free($4); }
;

opt_temporary:          { $$ = 0; }
;

create_col_list: create_definition 
                        { $$ = 1; }
| create_col_list ',' create_definition
                        { $$ = $1 + 1; }
;

create_definition: PRIMARY KEY '(' column_list ')'
                        { emit("PRIMARYKEY %d", $4); }
| INDEX '(' column_list ')'         { emit("KEY %d", $3); }
| NAME data_type column_atts        { emit("STARTCOL"); }
;

column_list: NAME
| NAME column_list
;

column_atts:            { $$ = 0; }
| column_atts UNIQUE    { emit("ATTR UNIQUEKEY"); }
;

data_type: INT          { $$ = 10000; }
| FLOAT                 { $$ = 20000; }
| CHAR '(' INTNUM ')'   { $$ = 30000 + $3; }
;

stmt: drop_stmt         { emit("STMT"); }
;

drop_stmt: DROP TABLE NAME  { emit("DROPTABLE"); }
;

stmt: select_stmt       { emit("STMT"); }
;

select_stmt: SELECT select_opts select_expr_list
                        { emit("SELECTNODATA %d %d", $2, $3); }
| SELECT select_opts select_expr_list
  FROM table_references
  opt_where             { emit("SELECT %d %d %d", $2, $3, $5); }
;

table_references: table_references  { $$ = 1; }
| table_references ',' table_references { $$ = $1 + 1; }
;

table_references: table_factor
;

table_factor:
NAME opt_as_alias       { emit("TABLE %s", $1); free($1); }
;

select_opts:            { $$ = 0; }
;

select_expr_list: select_expr       { $$ = 1; }
| select_expr_list ',' select_expr  { $$ = $1 + 1; }
| '*'                   { emit("SELECTALL"); $$ = 1; }

select_expr: expr opt_as_alias ;

stmt: delete_stmt       { emit("STMT"); }
;

delete_stmt: DELETE delete_opts FROM NAME opt_where
                        { emit("DELETEONE %d %s", $2, $4); free($4); }
;

delete_stmt: DELETE delete_opts delete_list FROM table_references opt_where
                        { emit("DELETEMULTI %d %d %d", $2, $3, $5); }

delete_list: NAME opt_dot_star      { emit("TABLE %s", $1); free($1); $$ = 1; }
| delete_list ',' NAME opt_dot_star { emit("TABLE %s", $3); free($3); $$ = $1 + 1; }
;

opt_dot_star: 
| '.' | '*';

delete_opts: 
;

stmt: insert_stmt       { emit("STMT"); }
;

insert_stmt: INSERT insert_opts opt_into NAME
             opt_col_names
             VALUES insert_vals_list 
                        { emit("INSERTVALS %d %d %s", $2, $7, $4); free($4); }
;

insert_opts:            { $$ = 0; }
;

opt_into: INTO
;

opt_col_names: 
| '(' column_list ')'   { emit("INSERTCOLS %d", $2); }

insert_vals_list: '(' insert_vals ')' 
                        { emit("VALUES %d", $2); $$ = 1; }
| insert_vals_list ',' '(' insert_vals ')' 
                        { emit("VALUES %d", $4); $$ = $1 + 1; }
;

insert_vals: expr       { $$ = 1; }
| insert_vals ',' expr  { $$ = $1 + 1; }
;

opt_as_alias: 
| NAME                 { emit("ALIAS %s", $1); free($1); }
;

opt_where:
| WHERE expr            { emit("WHERE"); }

val_list: expr { $$ = 1; }
| expr ',' val_list { $$ = 1 + $3; }
;

opt_val_list: { $$ = 0; }
| val_list
;

expr: expr '+' expr     { emit("ADD"); }
| expr '-' expr         { emit("SUB"); }
| expr '*' expr         { emit("MUL"); }
| expr '/' expr         { emit("DIV"); }
| expr ANDOP expr       { emit("AND"); }
| expr OR expr          { emit("OR"); }
| expr '|' expr         { emit("BITOR"); }
| expr '&' expr         { emit("BITAND"); }
| NOT expr              { emit("NOT"); }
| '!' expr              { emit("NOT"); }
| expr COMPARISON expr  { emit("CMP %d", $2==1? "left": "right"); }
| expr COMPARISON '(' select_stmt ')'  { emit("CMPSELECT %d", $2); }
;

expr: NAME              { emit("NAME %s", $1); free($1); }
| NAME '.' NAME         { emit("FIELDNAME %s.%s", $1, $3); free($1); free($3); }
| STRING                { emit("STRING %s", $1); free($1); }
| INTNUM                { emit("NUMBER %d", $1); }
| APPROXNUM             { emit("FLOAT %g", $1); }
| BOOL                  { emit("BOOL %d", $1); }
;

%%

void emit(char *s, ...)
{
    extern yylineno;

    printf("we are here\n");

    va_list ap;
    va_start(ap, s);

    printf("rpn: ");
    vfprintf(stdout, s, ap);
    printf("\n");
}

yyerror(char *s)
{
    extern yylineno;
    va_list ap;
    va_start(ap, s);

    fprintf(stderr, "%d: error: \n", yylineno);
    vfprintf(stderr, s, ap);
    fprintf(stderr, "\n");
}

int main(int argc, char **argv) 
{
    extern FILE *yyin;

    if (argc > 1 && !strcmp(argv[1], "-d")) {
        yydebug = 1;
        argc--;
        argv++;
    }
    if (argc > 1 && (yyin = fopen(argv[1], "r")) == NULL) {
        perror(argv[1]);
        exit(1);
    }
    if (!yyparse()) {
        printf("SQL parse worked\n");
    }
    else {
        printf("SQL parse failed\n");
    }
    return 0;
}
