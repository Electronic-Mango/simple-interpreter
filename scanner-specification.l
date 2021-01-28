%{
    #include <cstdio>
    #include <iostream>
    #include <cstring>
    #include "parser.tab.h"

    extern int yylex();

    int lineNumber = 0;
%}

%option noyywrap

NUM [0-9]+
VALID_STRING_CHAR [A-Za-z0-9]
INVALID_STRING_CHAR [^A-Za-z0-9"]
STRING {VALID_STRING_CHAR}*
IDENT [A-Za-z][A-Za-z0-9]*
BOOL (true|false)

%x STRING_MATCHING

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
    yylval.integer_value = strtol(yytext, nullptr, 10);
    return NUM;
}

["] { BEGIN(STRING_MATCHING); }

<STRING_MATCHING>{STRING}["] {
    string input = string(yytext);
    string content = input.substr(0, input.size() - 1);
    yylval.string_value = strdup(content.c_str());
    BEGIN(INITIAL);
    return STRING;
}

<STRING_MATCHING>({VALID_STRING_CHAR}*{INVALID_STRING_CHAR}+{VALID_STRING_CHAR}*)+ {
    cout << "Błąd parsowania wartości typu string w linii: " << ++lineNumber << "!" << endl;
    cout << "Nieoczekiwana wartość:" << endl << yytext << endl;
    exit(-1);
}

{BOOL} {
    yylval.bool_value = string(yytext) == "true";
    return BOOL;
}

{IDENT} {
    yylval.string_value = strdup(yytext);
    return IDENT;
}

[\n] { ++lineNumber; }

[ \t] ;

%%
