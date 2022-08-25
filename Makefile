CC = cc -g
LEX = flex
YACC = bison
CFLAGS = -DYYDEBUG=1

PROGRAMS = minisql_parser

all: ${PROGRAMS}

minisql_parser: pminisql.tab.o lminisql.o
		${CC} -o $@ pminisql.tab.o lminisql.o

pminisql.tab.c pminisql.tab.h: pminisql.y
		${YACC} -vd pminisql.y

lminisql.c: lminisql.l
		${LEX} -o $*.c $<

lminisql.o: lminisql.c pminisql.tab.h

.SUFFIXES: .pgm .l .y .c

clean: 
		rm *.o *.c *.h *.output