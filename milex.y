%{
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
// #include <stdbool.h>
// #include <iostream>
#include <string.h>

extern FILE *yyin;   /* declarado en lexico */
extern int numlin;   /* lexico le da valores */
int yydebug=1;       /* modo debug si -t */
void yyerror(char*); 

double resto(double a, double b);
%}

%union { 
  double real; 
  int entero;
  double* array;
  char* symbol;
}
%token <entero> ENTERO
%token <real> REAL
%token <entero> LOGICO
%token <symbol> CADENA
%token <symbol> IDENTIF

%token <symbol> INT
%token <symbol> FLOAT
%token <symbol> BOOL
%token <symbol> STRING
%token <symbol> STRUCT
%token <symbol> VOID
%token <symbol> ARRAY

%token <symbol> INCREMENTO
%token <symbol> DECREMENTO
%token <symbol> POTENCIA
%token <symbol> AND
%token <symbol> OR
%token <symbol> MYIG
%token <symbol> MNIG
%token <symbol> IGUAL
%token <symbol> DESIGUAL

%token <symbol> IF
%token <symbol> ELSE
%token <symbol> SWITCH
%token <symbol> CASE
%token <symbol> DEFAULT
%token <symbol> FOR
%token <symbol> IN
%token <symbol> WHILE

%token <symbol> BREAK
%token <symbol> CONTINUE
%token <symbol> RETURN
%token <symbol> NEW
%token <symbol> PRINT
%token <symbol> PRINTLN

// %type <real> asignacion
// %type <real> declaracion
// %type <real> aritmetico
// %type <entero> condicion
// %type <symbol> string
// %type <array> iterable
// %type <array> array

/* Precedencia */
%left AND OR
%nonassoc IGUAL DESIGUAL '<' '>' MNIG MYIG
%left '+' '-'
%left '*' '/' '%'
%right POTENCIA
%left '!' INCREMENTO DECREMENTO

%%
bloque:
    '\n'              {}
  | '\n' bloque       {}
  | sentencia         {}
  | sentencia bloque  {}
  ;

sentencia:
    expresion           {}
  | if                  {}
  | switch              {}
  | for                 {}
  | for-in              {}
  | while               {}
  | print               {}
  | funcion-uso         {}
  | funcion-declaracion {}
  | BREAK               {}
  | CONTINUE            {}
  | RETURN              {}
  | RETURN expresion    {}
  | error               {printf("en sentencia\n");}
  ;

sentbloq: sentencia | '{' bloque '}' ;

expresion:
    asignacion            {}
  | declaracion           {/*printf("%f\n", $1);*/}
  | error                 {printf("en expresion\n");}
  ;

aritmetico:
    aritmetico '+' aritmetico       {/*$$ = $1 + $3;*/}
  | aritmetico '-' aritmetico       {/*$$ = $1 - $3;*/}
  | aritmetico '*' aritmetico       {/*$$ = $1 * $3;*/}
  | aritmetico '/' aritmetico       {/*$$ = $1 / $3;*/}
  | aritmetico '%' aritmetico       {/*$$ = resto($1, $3);*/}
  | aritmetico POTENCIA aritmetico  {/*$$ = pow($1, $3);*/}
  | '-' aritmetico                  {/*$$ = -$2;*/}
  | aritmetico INCREMENTO           {/*$$ = $1 + 1;*/}
  | aritmetico DECREMENTO           {/*$$ = $1 - 1;*/}
  | '(' aritmetico ')'              {/*$$ = $2;*/}
  | array '.' IDENTIF               {/*if(strcmp($3, "length") != 0) yyerror("Propiedad inesperada\n");*/}
  | REAL                            {/*$$ = $1;*/}
  | ENTERO                          {/*$$ = $1;*/}
  | IDENTIF
  ;

condicion:
    aritmetico '<' aritmetico       {/*$$ = $1 < $3 ? 1 : 0;*/}
  | aritmetico MNIG aritmetico      {/*$$ = $1 <= $3 ? 1 : 0;*/}
  | aritmetico '>' aritmetico       {/*$$ = $1 > $3 ? 1 : 0;*/}
  | aritmetico MYIG aritmetico      {/*$$ = $1 >= $3 ? 1 : 0;*/}
  | aritmetico IGUAL aritmetico     {/*$$ = $1 == $3 ? 1 : 0;*/}
  | aritmetico DESIGUAL aritmetico  {/*$$ = $1 != $3 ? 1 : 0;*/}
  | condicion AND condicion         {/*$$ = $1 && $3 ? 1 : 0;*/}
  | condicion OR condicion          {/*$$ = $1 || $3 ? 1 : 0;*/}
  | '!' condicion                   {/*$$ = ++$2 % 2;*/}
  | '(' condicion ')'               {/*$$ = $2;*/}
  | LOGICO                          {/*$$ = $1;*/}
  | IDENTIF
  ;

string:
    string '+' string
  | string '+' aritmetico
  | string '+' condicion
  | string '+' array
  | aritmetico '+' string
  | condicion '+' string
  | array '+' string
  | CADENA              {}
  | IDENTIF
  ;

array: 
    array '+' array   {}
  | '[' iterable ']'  {}
  | '[' ']'           {}
  | NEW INT '[' ENTERO ']'
  | NEW FLOAT '[' ENTERO ']'
  | NEW BOOL '[' ENTERO ']'
  | NEW STRING '[' ENTERO ']'
  | IDENTIF
  ;

struct-bloque:
    '\n'
  | '\n' struct-bloque
  | struct-elem
  | struct-elem espacio-vacio
  | struct-elem ',' struct-bloque  {}
  ;

espacio-vacio:
    '\n'
  | '\n' espacio-vacio
  ;

struct-elem:
    INT IDENTIF     {}
  | FLOAT IDENTIF   {}
  | BOOL IDENTIF    {}
  | STRING IDENTIF  {}
  ;

iterable: 
    aritmetico ',' iterable   {}
  | aritmetico                {}
  ;

tipo: 
    INT
  | FLOAT
  | BOOL
  | STRING
  | ARRAY
  | STRUCT
  | VOID
;

asignacion:
    IDENTIF '=' aritmetico      {}
  | IDENTIF '=' condicion       {}
  | IDENTIF '=' string          {/*printf("%s\n", $1);*/}
  | IDENTIF '=' array           {}
  | IDENTIF '=' '{' struct-bloque '}'   {}
  ;

declaracion:
    tipo IDENTIF '=' aritmetico     {/*$$ = (int) $4;*/}
  | tipo IDENTIF '=' condicion      {}
  | tipo IDENTIF '=' string         {}
  | tipo IDENTIF '=' array          {}
  | tipo IDENTIF '=' '{' struct-bloque '}'  {}
  ;

if:
    IF '(' condicion ')' sentbloq
  | IF '(' condicion ')' sentbloq ELSE sentbloq
  ;

switch:
    SWITCH '(' aritmetico ')' '{' espacio-vacio switch-bloque '}'       {}
  | SWITCH '(' string ')' '{' espacio-vacio switch-bloque '}'     {}
  ;

switch-bloque:
    switch-case
  | switch-case switch-bloque
  ;

switch-case:
    CASE aritmetico ':' bloque  {/* se pueden identificadores?? */}
  | CASE string ':' bloque
  | DEFAULT ':' bloque
  ;

for: 
    FOR '(' for-inicial ';' for-condicion ';' for-final ')' sentbloq
  ;

for-inicial:
    '\n' for-inicial
  | expresion
  ;
for-condicion:
    '\n' for-condicion
  | condicion
  ;
for-final:
    '\n' for-final
  | expresion
  ;

for-in:
    FOR '(' IDENTIF IN array ')' sentbloq
  | FOR '(' IDENTIF IN IDENTIF ')' sentbloq
  ;

while:
    WHILE '(' condicion ')' sentbloq
  ;

print:
    PRINT '(' print-expresion ')'
  | PRINTLN '(' print-expresion ')'
  ;

print-expresion:
    '\n'
  | '\n' print-expresion
  | aritmetico
  | condicion
  | string
  | array
  | funcion-uso
  ;

funcion-uso: 
    IDENTIF '(' ')'
  | IDENTIF '(' params-uso ')'
  ;

params-uso:
    '\n'
  | '\n' params-uso
  | IDENTIF
  | IDENTIF espacio-vacio
  | IDENTIF ',' params-uso
  ;

funcion-declaracion:
    tipo IDENTIF '(' ')' '{' bloque '}'
  | tipo IDENTIF '(' params-declaracion ')' '{' bloque '}'
  ;

params-declaracion:
    '\n'
  | '\n' params-declaracion
  | tipo IDENTIF
  | tipo IDENTIF espacio-vacio
  | tipo IDENTIF ',' params-declaracion
  ;
%%

int main(int argc, char** argv) {
  if (argc>1) yyin=fopen(argv[1],"r");
  yyparse();
}

void yyerror(char* mens) {
  printf("Error en linea %i: %s ", numlin, mens);
}

void yywrap() {}

// Funciones propias
double resto(double a, double b) {
  double res = a < 0 ? -a : a;
  double b_ = b < 0 ? -b : b;

  while (res >= 0) {
    res = res - b_;
  }
  return res + b_;
}

// char* strConcat(char* a, char* b) {
//   char* res = (char*) malloc(sizeof(char) * (strlen(a) + strlen(b) - 1)); //-2+1

//   strcpy(res, a.substr(0, strlen(a) - 2))
//   strcpy(res, b.substr(0, strlen(b) - 2))

//   return res;
// }