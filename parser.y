%{
    #include <cstdio>
    #include <iostream>
    #include <cstring>
    #include <map>
    #include <set>
    #include <functional>
    #include <memory>

    using namespace std;

	typedef signed long int number;
	typedef const char* cstring;
    typedef function<void()> action;

    extern FILE* yyin;
    extern int yylex();
    extern int yyparse();
    void yyerror(cstring s);

    set<string> variableNames;
    map<string, number> numVariables;
    map<string, cstring> strVariables;

    void handleVariableName(string variableName) {
        if (variableNames.contains(variableName)) {
            numVariables.erase(variableName);
            strVariables.erase(variableName);
        } else {
            variableNames.insert(variableName);
        }
    }

    template <class T>
    struct ExprPrinter {
        T _value;
        action _printerFunction;

        static action* preparePrinterFuncPtr(T value) {
            auto printer = new ExprPrinter<T>(value);
            return printer->printerFunctionPtr();
        }

        ExprPrinter(T value) : _value(value) {
            _printerFunction = [this](){ cout << _value << endl; };
        }

        action* printerFunctionPtr() {
            return &_printerFunction;
        }
    };

    struct VariablePrinter {
        string _name;
        action _printerFunction;

        static action* prepareVarPrinterFuncPtr(string name) {
            auto printer = new VariablePrinter(name);
            return printer->printerFunctionPtr();
        }

        VariablePrinter(string name) : _name(name) {
            _printerFunction = [this](){
                if (strVariables.contains(_name)) {
                    cout << strVariables.at(_name) << endl;
                } else if (numVariables.contains(_name)) {
                    cout << numVariables.at(_name) << endl;
                } else {
                    cout << "" << endl;
                }
            };
        }

        action* printerFunctionPtr() {
            return &_printerFunction;
        }
    };
    
    template <class T>
    struct Assigner {
        string _varName;
        T _varValue;
        map<string, T>* _varCollection;
        action _variableAssigningFunction;

        static action* prepareAssigner(string varName, T varValue, map<string, T>* varCollection) {
            auto assigner = new Assigner<T>(varName, varValue, varCollection);
            return assigner->variableAssigningFunctionPtr();
        }
        
        Assigner(string varName, T varValue, map<string, T>* varCollection) : _varName(varName), _varValue(varValue), _varCollection(varCollection) {
            _variableAssigningFunction = [this]() {
                handleVariableName(_varName);
                _varCollection->insert_or_assign(_varName, _varValue);
            };
        }

        action* variableAssigningFunctionPtr() {
            return &_variableAssigningFunction;
        }
        
    };
    
    struct IfHandler {
        bool _condition;
        action* _trueFunction;
        action* _falseFunction;
        action _ifFunction;

        static action* prepareIfHandler(bool condition, action* trueFunction, action* falseFunction) {
            auto handler = new IfHandler(condition, trueFunction, falseFunction);
            return handler->ifFunctionPtr();
        }
        
        IfHandler(bool condition, action* trueFunction, action* falseFunction) : _condition(condition), _trueFunction(trueFunction), _falseFunction(falseFunction) {
            _ifFunction = [this]() {
                if (_condition) {
                    (*_trueFunction)();
                } else {
                    if (_falseFunction != nullptr) (*_falseFunction)();
                }
            };
        }

        action* ifFunctionPtr() {
            return &_ifFunction;
        }
    };
    
    struct CompoundInstrHandler {
        action* _firstAction;
        action* _secondAction;
        action _compoundAction;

        static action* prepareCompoundInstrHandler(action* firstAction, action* secondAction) {
            auto handler = new CompoundInstrHandler(firstAction, secondAction);
            return handler->compoundActionPtr();
        }
        
        CompoundInstrHandler(action* firstAction, action* secondAction) : _firstAction(firstAction), _secondAction(secondAction) {
            _compoundAction = [this]() {
                (*_firstAction)();
                (*_secondAction)();
            };
        }

        action* compoundActionPtr() {
            return &_compoundAction;
        }
    };
	
%}

%code requires {
	#include <functional>
	typedef signed long int number;
	typedef const char* cstring;
    typedef function<void()> action;
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
         | IDENT { $$ = numVariables.contains($1) ? numVariables.at($1) : 0; }
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
         | IDENT { $$ = strVariables.contains($1) ? strVariables.at($1) : ""; }
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

instruction : instruction LINE_END simple_instruction { $$ = CompoundInstrHandler::prepareCompoundInstrHandler($1, $3); }
            | simple_instruction { $$ = $1; }
            ;

assign_stat : IDENT ASSIGN num_expr { $$ = Assigner<number>::prepareAssigner($1, $3, &numVariables); }
            | IDENT ASSIGN str_expr { $$ = Assigner<cstring>::prepareAssigner($1, $3, &strVariables); }
            ;

if_stat : IF bool_expr THEN simple_instruction { $$ = IfHandler::prepareIfHandler($2, $4, nullptr); }
        | IF bool_expr THEN simple_instruction ELSE simple_instruction {
              $$ = IfHandler::prepareIfHandler($2, $4, $6);
          }
        ;

while_stat : WHILE bool_expr DO simple_instruction
           | DO simple_instruction WHILE bool_expr
           ;

output_stat : PRINT OPEN_BRACKET IDENT CLOSE_BRACKET {
                  $$ = VariablePrinter::prepareVarPrinterFuncPtr($3);
              }
            | PRINT OPEN_BRACKET num_expr CLOSE_BRACKET {
                  $$ = ExprPrinter<number>::preparePrinterFuncPtr($3);
              }
            | PRINT OPEN_BRACKET str_expr CLOSE_BRACKET {
                  $$ = ExprPrinter<string>::preparePrinterFuncPtr($3);
              }
            | PRINT OPEN_BRACKET CLOSE_BRACKET {
                  $$ = ExprPrinter<string>::preparePrinterFuncPtr("");
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