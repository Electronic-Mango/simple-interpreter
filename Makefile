default:
	flex -l spec.l
	bison -dv parser.y 
	g++ -std=c++2a parser.tab.c lex.yy.c -lfl -o interpreter

clean:
	rm -rf lex.yy.c parser.output parser.tab.c parser.tab.h interpreter
