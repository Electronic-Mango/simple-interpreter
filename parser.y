%{
    #include <cstdio>
    #include <iostream>
    #include <cstring>
    #include <map>
    #include <set>
    #include <functional>
    #include <memory>
    #include "functors.hh"

    using namespace std;

    extern FILE* yyin;
    extern int yylex();
    extern int yyparse();
    void yyerror(cstring s);
%}

%code requires {
    #include <functional>
    #include "functors.hh"
    using namespace std;
}

%union {
    number integer_value;
    cstring string_value;
    bool bool_value;
    action* statement;
}

%token <integer_value> NUM
%token <string_value> STRING
%token <string_value> IDENT
%token <bool_value> BOOL

%token PLUS MINUS MULT DIV MODULO
%token AND OR NOT
%token NUM_EQ LESS LESS_EQ GREATER GREATER_EQ NUM_NOT_EQ
%token STR_EQ STR_NOT_EQ

%token OPEN_BRACKET CLOSE_BRACKET COMMA

%token LENGTH POSITION SUBSTRING CONCATENATE

%token READINT READSTR

%token LINE_END

%token IF THEN ELSE

%token WHILE DO

%token ASSIGN

%token PRINT

%token BEGIN_INSTRUCTION END_INSTRUCTION

%token EXIT

%type <integer_value> num_expr
%type <string_value> str_expr
%type <bool_value> bool_expr

%type <statement> instruction
%type <statement> simple_instruction
%type <statement> output_stat
%type <statement> assign_stat
%type <statement> if_stat
%type <statement> while_stat

%start program

%%

num_expr : NUM
         | IDENT { $$ = VariableContainer::getVarNum($1); }
         | READINT { cin >> $$; }
         | MINUS num_expr { $$ = -$2; } // -1+2 jest traktowane jako -(1+2)
         | num_expr PLUS num_expr { $$ = $1 + $3; }
         | num_expr MINUS num_expr { $$ = $1 - $3; }
         | num_expr MULT num_expr { $$ = $1 * $3; }
         | num_expr DIV num_expr { $$ = $1 / $3; }
         | num_expr MODULO num_expr { $$ = $1 % $3; }
         | OPEN_BRACKET num_expr CLOSE_BRACKET  { $$ = $2; }
         | LENGTH OPEN_BRACKET str_expr CLOSE_BRACKET { $$ = string($3).size(); }
         | POSITION OPEN_BRACKET str_expr COMMA str_expr CLOSE_BRACKET {
               auto result = string($3).find($5);
               $$ = result == string::npos ? 0 : result + 1;
           }
         ;

str_expr : STRING
         | IDENT { $$ = VariableContainer::getVarStr($1); }
         | READSTR {
               string input;
               cin >> input;
               $$ = strdup(input.c_str());
           }
         | CONCATENATE OPEN_BRACKET str_expr COMMA str_expr CLOSE_BRACKET { $$ = string($3).append(string($5)).c_str(); }
         | SUBSTRING OPEN_BRACKET str_expr COMMA num_expr COMMA num_expr CLOSE_BRACKET {
               auto input = string($3);
               auto position = $5 - 1;
               auto length = $7;
               if (position < 0 || position >= input.size()) $$ = "";
               else $$ = input.substr(position, length).c_str();
           }
         ;

bool_expr : BOOL
          | OPEN_BRACKET bool_expr CLOSE_BRACKET { $$ = $2; }
          | NOT bool_expr { $$ = !$2; }
          | bool_expr AND bool_expr { $$ = $1 && $3; }
          | bool_expr OR bool_expr { $$ = $1 || $3; }
          | num_expr NUM_EQ num_expr { $$ = $1 == $3; }
          | num_expr LESS num_expr { $$ = $1 < $3; }
          | num_expr LESS_EQ num_expr { $$ = $1 <= $3; }
          | num_expr GREATER num_expr { $$ = $1 > $3; }
          | num_expr GREATER_EQ num_expr { $$ = $1 >= $3; }
          | num_expr NUM_NOT_EQ num_expr { $$ = $1 != $3; }
          | str_expr STR_EQ str_expr { $$ = string($1) == string($3); }
          | str_expr STR_NOT_EQ str_expr { $$ = string($1) != string($3); }
          ;

simple_instruction : BEGIN_INSTRUCTION instruction END_INSTRUCTION { $$ = $2; }
                   | assign_stat { $$ = $1; }
                   | if_stat { $$ = $1; }
                   | while_stat { $$ = $1; }
                   | output_stat { $$ = $1; }
                   | EXIT { return 0; }
                   ;

instruction : instruction LINE_END simple_instruction { $$ = CompoundInstrCallback::create($1, $3); }
            | simple_instruction { $$ = $1; }
            ;

assign_stat : IDENT ASSIGN num_expr { $$ = AssignVarCallback<number>::create($1, $3); }
            | IDENT ASSIGN str_expr { $$ = AssignVarCallback<cstring>::create($1, $3); }
            ;

if_stat : IF bool_expr THEN simple_instruction { $$ = IfCallback::create($2, $4, nullptr); }
        | IF bool_expr THEN simple_instruction ELSE simple_instruction {
              $$ = IfCallback::create($2, $4, $6);
          }
        ;

while_stat : WHILE bool_expr DO simple_instruction { $$ = WhileCallback::create($2, $4); }
           | DO simple_instruction WHILE bool_expr { $$ = DoWhileCallback::create($2, $4); }
           ;

output_stat : PRINT OPEN_BRACKET IDENT CLOSE_BRACKET {
                  $$ = PrintVarCallback::create($3);
              }
            | PRINT OPEN_BRACKET num_expr CLOSE_BRACKET {
                  $$ = PrintExprCallback<number>::create($3);
              }
            | PRINT OPEN_BRACKET str_expr CLOSE_BRACKET {
                  $$ = PrintExprCallback<string>::create($3);
              }
            | PRINT OPEN_BRACKET CLOSE_BRACKET {
                  $$ = PrintExprCallback<string>::create("");
              }
            ;

program : instruction { (*$1)(); }
        ;

%%

int main(int argc, char* argv[]) {
    if (argc < 2) {
        cout << "Podaj plik to uruchomienia jako argument!" << endl;
        return -1;
    }
    yyin = fopen(argv[1], "r");
    if (!yyin) {
        cout << "Nie można otworzyć pliku " << argv[1] << "!" << endl;
        return -1;
    }
    do {
        yyparse();
    } while (!feof(yyin));
}

void yyerror(cstring s) {
    cout << "Błąd parsowania: " << s << endl;
    exit(-1);
}