%{
    #include <cstdio>
    #include <iostream>
    #include <cstring>
	#include <map>

    using namespace std;

    extern int yylex();
    extern int yyparse();
    void yyerror(const char *s);
	
	map<string, int> numVariables;
	map<string, const char *> strVariables;
%}

%union {
    signed long int integer_value;
    const char* string_value;
    bool bool_value;
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

%%

input : /* nic */
      | input line 
      ;
    
line : '\n'
     | simple_instruction
     | num_expr '\n' { cout << $1 << endl; }
     | str_expr '\n' { cout << $1 << endl; }
     | bool_expr '\n' { cout << boolalpha << $1 << endl; }
     ;

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
			 $$ = input.c_str();
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

simple_instruction : BEGIN_INSTRUCTION instruction END_INSTRUCTION
                   | assign_stat
                   | if_stat
                   | while_stat
                   | output_stat
                   | EXIT { return 0; }
                   ;

instruction : instruction LINE_END simple_instruction
            | simple_instruction
            ;

assign_stat : IDENT ASSIGN num_expr { numVariables.insert_or_assign($1, $3); }
            | IDENT ASSIGN str_expr { strVariables.insert_or_assign($1, $3); }
			;

if_stat : IF bool_expr THEN simple_instruction
        | IF bool_expr THEN simple_instruction ELSE simple_instruction
        ;

while_stat : WHILE bool_expr DO simple_instruction
           | DO simple_instruction WHILE bool_expr
		   ;

output_stat : PRINT OPEN_BRACKET IDENT CLOSE_BRACKET {
	              if (strVariables.contains($3)) cout << strVariables.at($3) << endl;
				  else if (numVariables.contains($3)) cout << numVariables.at($3) << endl;
				  else cout << "" << endl;
			  }
              | PRINT OPEN_BRACKET num_expr CLOSE_BRACKET { cout << $3 << endl; }
              | PRINT OPEN_BRACKET str_expr CLOSE_BRACKET { cout << $3 << endl; }
              | PRINT OPEN_BRACKET bool_expr CLOSE_BRACKET { cout << boolalpha << $3 << endl; }
              ;

program : instruction
        ;

%%

int main() {
    yyparse();
}

void yyerror(const char *s) {
    cout << "Parse error!  Message: " << s << endl;
    exit(-1);
}