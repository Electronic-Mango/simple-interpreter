%{
    #include <cstdio>
    #include <iostream>
    #include <cstring>
	#include "parser.tab.h"

    using namespace std;

    extern int yylex();
%}

%option noyywrap

NUM [0-9]+
STRING \".*\"
IDENT [A-Za-z][A-Za-z0-9]*
BOOL (true|false)

%%

"+" { return PLUS; }
"-" { return MINUS; }
"*" { return MULT; }
"/" { return DIV; }
"%" { return MODULO; }

"and" { return AND; }
"or"  { return OR; }
"not" { return NOT; }

"="  { return NUM_EQ; }
"<"  { return LESS; }
"<=" { return LESS_EQ; }
">"  { return GREATER; }
">=" { return GREATER_EQ; }
"<>" { return NUM_NOT_EQ; }
"==" { return STR_EQ; }
"!=" { return STR_NOT_EQ; }

"(" { return OPEN_BRACKET; }
")" { return CLOSE_BRACKET; }
"," { return COMMA; }

"length"      { return LENGTH; }
"position"    { return POSITION; }
"substring"   { return SUBSTRING; }
"concatenate" { return CONCATENATE; }

"readint" { return READINT; }
"readstr" { return READSTR; }

"if"   { return IF; }
"then" { return THEN; }
"else" { return ELSE; }

"while" { return WHILE; }
"do"    { return DO; }

"print" { return PRINT; }

":=" { return ASSIGN; }

"begin" { return BEGIN_INSTRUCTION; }
"end"   { return END_INSTRUCTION; }

";" { return LINE_END; }

"exit" { return EXIT; }

{NUM} {
	yylval.integer_value = atoi(yytext);
	return NUM;
}

{STRING} {
	string input = string(yytext);
	string content = input.substr(1, input.size() - 2);
    yylval.string_value = strdup(content.c_str());
    return STRING;	
}

{BOOL} {
	yylval.bool_value = string(yytext) == "true";
	return BOOL;
}

{IDENT} {
    yylval.string_value = strdup(yytext);
    return IDENT;	
}

[ \t\n] ;

%%
