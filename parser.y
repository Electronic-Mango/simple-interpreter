%{
    #include <iostream>
    #include <functional>
    #include "callbacks.h"
    #include "variables.h"
    #include "types.h"

    using namespace std;

    extern FILE* yyin;
    extern int yylex();
    extern int yyparse();
    extern int lineNumber;

    void yyerror(cstring error);
%}

%code requires {
    #include "callbacks.h"
    #include "variables.h"
    #include "types.h"
    using namespace std;
}

%union {
    number integer_value;
    cstring string_value;
    bool bool_value;
    action* statement;
    valueEval<number>* numEval;
    valueEval<string>* strEval;
    valueEval<bool>* boolEval;
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
%token LINE_END

%token LENGTH POSITION SUBSTRING CONCATENATE
%token READINT READSTR

%token BEGIN_INSTRUCTION END_INSTRUCTION
%token IF THEN ELSE
%token WHILE DO
%token ASSIGN
%token PRINT
%token EXIT

%type <numEval> num_expr
%type <strEval> str_expr
%type <boolEval> bool_expr
%type <statement> instruction
%type <statement> simple_instruction
%type <statement> output_stat
%type <statement> assign_stat
%type <statement> if_stat
%type <statement> while_stat

%start program

%%

num_expr : NUM {
               number val = $1;
               $$ = ExprEvalCb<number>::create([=](){ return val; });
           }
         | IDENT {
               string val = string($1);
               $$ = ExprEvalCb<number>::create([=](){ return VariableContainer::getVarNum(val); });
               free((char*) $1);
           }
         | READINT {
               $$ = ExprEvalCb<number>::create([=](){
                   number input;
                   cin >> input;
                   return input;
               });
           }
         | MINUS num_expr {
               valueEval<number> numEval = *$2;
               $$ = ExprEvalCb<number>::create([=](){ return numEval() * -1; });
           }
         | num_expr PLUS num_expr {
               valueEval<number> numEval1 = *$1;
			   valueEval<number> numEval2 = *$3;
               $$ = ExprEvalCb<number>::create([=](){ return numEval1() + numEval2(); });
           }
         | num_expr MINUS num_expr {
               valueEval<number> numEval1 = *$1;
			   valueEval<number> numEval2 = *$3;
               $$ = ExprEvalCb<number>::create([=](){ return numEval1() - numEval2(); });
           }
         | num_expr MULT num_expr {
               valueEval<number> numEval1 = *$1;
			   valueEval<number> numEval2 = *$3;
               $$ = ExprEvalCb<number>::create([=](){ return numEval1() * numEval2(); });
           }
         | num_expr DIV num_expr {
               valueEval<number> numEval1 = *$1;
			   valueEval<number> numEval2 = *$3;
               $$ = ExprEvalCb<number>::create([=](){ return numEval1() / numEval2(); });
           }
         | num_expr MODULO num_expr {
               valueEval<number> numEval1 = *$1;
			   valueEval<number> numEval2 = *$3;
               $$ = ExprEvalCb<number>::create([=](){ return numEval1() % numEval2(); });
           }
         | OPEN_BRACKET num_expr CLOSE_BRACKET {
               valueEval<number> numEval = *$2;
               $$ = ExprEvalCb<number>::create([=](){ return numEval(); });
           }
         | LENGTH OPEN_BRACKET str_expr CLOSE_BRACKET {
               valueEval<string> strEval = *$3;
               $$ = ExprEvalCb<number>::create([=](){ return strEval().size(); });
           }
         | POSITION OPEN_BRACKET str_expr COMMA str_expr CLOSE_BRACKET {
               valueEval<string> strEval1 = *$3;
			   valueEval<string> strEval2 = *$5;
               $$ = ExprEvalCb<number>::create([=](){
                   size_t result = strEval1().find(strEval2());
                   return result == string::npos ? 0 : result + 1;
               });
           }
         ;

str_expr : STRING {
           string val = string($1);
           $$ = ExprEvalCb<string>::create([=](){ return val; });
           free((char*) $1);
       }
         | IDENT {
               string val = string($1);
               $$ = ExprEvalCb<string>::create([=](){ return VariableContainer::getVarStr(val); });
               free((char*) $1);
           }
         | READSTR {
               $$ = ExprEvalCb<string>::create([=](){
                   string input;
                   getline(cin, input);
                   return input;
               });
           }
         | CONCATENATE OPEN_BRACKET str_expr COMMA str_expr CLOSE_BRACKET {
               valueEval<string> strEval1 = *$3;
			   valueEval<string> strEval2 = *$5;
               $$ = ExprEvalCb<string>::create([=](){
                  string str1 = strEval1();
                  string str2 = strEval2();
                  return str1.append(str2);
               });
           }
         | SUBSTRING OPEN_BRACKET str_expr COMMA num_expr COMMA num_expr CLOSE_BRACKET {
               valueEval<string> valEval = *$3;
			   valueEval<number> posEval = *$5;
			   valueEval<number> lenEval = *$7;
               $$ = ExprEvalCb<string>::create([=](){
                   string input = valEval();
                   number position = posEval() - 1;
                   number length = lenEval();
                   if (position < 0 || position >= input.size()) return string();
                   else return input.substr(position, length);
               });
           }
         ;

bool_expr : BOOL {
                bool val = $1;
                $$ = ExprEvalCb<bool>::create([=](){ return val; });
            }
          | OPEN_BRACKET bool_expr CLOSE_BRACKET {
                valueEval<bool> boolEval = *$2;
                $$ = ExprEvalCb<bool>::create([=](){ return boolEval(); });
            }
          | NOT bool_expr {
                valueEval<bool> boolEval = *$2;
                $$ = ExprEvalCb<bool>::create([=](){ return !(boolEval()); });
            }
          | bool_expr AND bool_expr {
                valueEval<bool> boolEval1 = *$1;
				valueEval<bool> boolEval2 = *$3;
                $$ = ExprEvalCb<bool>::create([=](){ return boolEval1() && boolEval2(); });
            }
          | bool_expr OR bool_expr {
                valueEval<bool> boolEval1 = *$1;
				valueEval<bool> boolEval2 = *$3;
                $$ = ExprEvalCb<bool>::create([=](){ return boolEval1() || boolEval2(); });
            }
          | num_expr NUM_EQ num_expr {
                valueEval<number> numEval1 = *$1;
				valueEval<number> numEval2 = *$3;
                $$ = ExprEvalCb<bool>::create([=](){ return numEval1() == numEval2(); });
            }
          | num_expr LESS num_expr {
                valueEval<number> numEval1 = *$1;
				valueEval<number> numEval2 = *$3;
                $$ = ExprEvalCb<bool>::create([=](){ return numEval1() < numEval2(); });
            }
          | num_expr LESS_EQ num_expr {
                valueEval<number> numEval1 = *$1;
				valueEval<number> numEval2 = *$3;
                $$ = ExprEvalCb<bool>::create([=](){ return numEval1() <= numEval2(); });
            }
          | num_expr GREATER num_expr {
                valueEval<number> numEval1 = *$1;
				valueEval<number> numEval2 = *$3;
                $$ = ExprEvalCb<bool>::create([=](){ return numEval1() > numEval2(); });
            }
          | num_expr GREATER_EQ num_expr {
                valueEval<number> numEval1 = *$1;
				valueEval<number> numEval2 = *$3;
                $$ = ExprEvalCb<bool>::create([=](){ return numEval1() >= numEval2(); });
            }
          | num_expr NUM_NOT_EQ num_expr {
                valueEval<number> numEval1 = *$1;
				valueEval<number> numEval2 = *$3;
                $$ = ExprEvalCb<bool>::create([=](){ return numEval1() != numEval2(); });
            }
          | str_expr STR_EQ str_expr {
                valueEval<string> strEval1 = *$1;
				valueEval<string> strEval2 = *$3;
                $$ = ExprEvalCb<bool>::create([=](){ return strEval1() == strEval2(); });
            }
          | str_expr STR_NOT_EQ str_expr {
                valueEval<string> strEval1 = *$1;
				valueEval<string> strEval2 = *$3;
                $$ = ExprEvalCb<bool>::create([=](){ return strEval1() != strEval2(); });
            }
          ;

simple_instruction : BEGIN_INSTRUCTION instruction END_INSTRUCTION { $$ = $2; }
                   | assign_stat { $$ = $1; }
                   | if_stat { $$ = $1; }
                   | while_stat { $$ = $1; }
                   | output_stat { $$ = $1; }
                   | EXIT { $$ = CbAction::create<ExitCb>(); }
                   ;

instruction : instruction simple_instruction LINE_END { $$ = CbAction::create<CompoundInstrCb>($1, $2); }
            | simple_instruction LINE_END { $$ = $1; }
            ;

assign_stat : IDENT ASSIGN num_expr { $$ = CbAction::create<AssignVarCb<number>>($1, $3); free((char*) $1); }
            | IDENT ASSIGN str_expr { $$ = CbAction::create<AssignVarCb<string>>($1, $3); free((char*) $1); }
            ;

if_stat : IF bool_expr THEN simple_instruction { $$ = CbAction::create<IfCb>($2, $4, nullptr); }
        | IF bool_expr THEN simple_instruction ELSE simple_instruction { $$ = CbAction::create<IfCb>($2, $4, $6); }
        ;

while_stat : WHILE bool_expr DO simple_instruction { $$ = CbAction::create<WhileCb>($2, $4); }
           | DO simple_instruction WHILE bool_expr { $$ = CbAction::create<DoWhileCb>($2, $4); }
           ;

output_stat : PRINT OPEN_BRACKET IDENT CLOSE_BRACKET { $$ = CbAction::create<PrintVarCb>($3); free((char*) $3); }
            | PRINT OPEN_BRACKET str_expr CLOSE_BRACKET { $$ = CbAction::create<PrintExprCb<string>>($3); }
            | PRINT OPEN_BRACKET num_expr CLOSE_BRACKET { $$ = CbAction::create<PrintExprCb<number>>($3); }
            | PRINT OPEN_BRACKET CLOSE_BRACKET { $$ = CbAction::create<PrintNewLineCb>(); }
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
    Callback::clearExtent();
}

void yyerror(cstring error) {
    cout << "Błąd parsowania: " << error << endl;
    cout << "W linii: " << lineNumber << endl;
    exit(-1);
}
