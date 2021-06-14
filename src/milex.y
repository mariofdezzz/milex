%{
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
// #include <stdbool.h>
// #include <iostream>
#include <string.h>
#include <stddef.h>

#include "../libraries/ts.h"
#include "Qlib.h"

extern FILE *yyin;   /* declarado en lexico */
extern int numlin;   /* lexico le da valores */
extern char *linfte;
int yydebug=1;       /* modo debug si -t */
void yyerror(char*); 

double resto(double a, double b);

enum categ gl = varg;

int sm = 0x12000;
int fm;
int et = 0;

struct reg *voidp;

void inits() {
  inst("void", 0);
  voidp = top;
  inst("bool", 1);
  inst("int", 4);
  inst("float", 8);
  // inst("string", 8);
  // inst("struct", 8);
}

FILE *obj;

%}

%union { 
  double real; 
  int entero;
  double* array;
  char* symbol;
  char* id;
  struct reg *rp;

  struct {
    char* tipo;
    int reg;
  } exp;
}
%token <entero> ENTERO
%token <real> REAL
%token <entero> LOGICO
%token <symbol> CADENA
%token <id> IDENTIF IDREAL IDENTERO IDLOGICO IDCADENA IDARRAY

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
%type <exp> aritmetico
// %type <exp> condicion
// %type <entero> asignables
// %type <symbol> string
// %type <array> iterable
// %type <array> array
%type <symbol> tipo
%type <symbol> id
%type <entero> if
%type <rp> funcion-uso

/* Precedencia */
%left AND OR
%nonassoc IGUAL DESIGUAL '<' '>' MNIG MYIG
%left '+' '-'
%left '*' '/' '%'
%right POTENCIA
%left '!' INCREMENTO DECREMENTO
%left '.' // array + array.length

%%
prog:
    '\n'
  | '\n' prog
  | '{' 
      {
        fprintf(obj, "L 0:\tR7=0x%x;\n", sm);
      }
    bloque '}' 
      {
        fprintf(obj, "\tGT(-2);\n");
      }
    prog
  | funcion-declaracion prog
  | declaracion prog
  ;

bloque:
    '\n'              {}
  | '\n' bloque       {}
  | sentencia         {}
  | sentencia bloque  {}
  | ret
      {
        if ($<rp>-2==voidp) // no funciona !
          yyerror("6: rutina void no puede retornar valor");
		    else 
          fprintf(obj, "\tR0=I(R7);\n\tR7=R7+4;\n");
      }
  ;

ret:
  | RETURN salto
  | RETURN '\n' bloque
  | RETURN expresion  {/*Expresion??*/}
  | RETURN expr salto
  | RETURN expresion '\n' bloque
  ;

salto:
    '\n'
  | '\n' salto
  ;

expr:
    aritmetico
  | condicion
  | funcion-uso
      {
        if ($1==voidp)
          yyerror("7: rutina void no invocable en expresion");
		    else 
          fprintf(obj, "\tR7=R7-4;\n\tI(R7)=R0;\n");
      }
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
  | error               {printf("en sentencia\n");}
  ;

sentbloq: sentencia | '{' bloque '}' ;

expresion:
    asignacion            {}
  | declaracion           {/*printf("%f\n", $1);*/}
  | error                 {printf("en expresion\n"); /* !! quitar todos */}
  ;

aritmetico:
    aritmetico '+' aritmetico
      {
        /*$$ = $1 + $3;*/
        fprintf(
          obj, 
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1+R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
      }
  | aritmetico '-' aritmetico
      {
        /*$$ = $1 - $3;*/
        fprintf(
          obj, 
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1-R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
      }
  | aritmetico '*' aritmetico
      {
        /*$$ = $1 * $3;*/
        fprintf(
          obj, 
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1*R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
      }
  | aritmetico '/' aritmetico
      {
        /*$$ = $1 / $3;*/
        fprintf(
          obj, 
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1/R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
      }
  | aritmetico '%' aritmetico
      {
        /*$$ = $1 % $3;*/
        fprintf(
          obj, 
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1%R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
      }
  | aritmetico POTENCIA aritmetico  {/*$$ = pow($1, $3);*/}
  | '-' aritmetico
      {
        /*$$ = -$2;*/
        fprintf(
          obj, 
          "\tR0=I(R7);\n\tR0=-R0;\n\tI(R7)=R0;\n"
        );
      }
  | INCREMENTO aritmetico
      {
        /*$$ = $1 + 1;*/
        fprintf(
          obj, 
          "\tR0=I(R7);\n\tR0=R0+1;\n\tI(R7)=R0;\n"
        );
      }
  | DECREMENTO aritmetico
      {
        /*$$ = $1 - 1;*/
        fprintf(
          obj, 
          "\tR0=I(R7);\n\tR0=R0-1;\n\tI(R7)=R0;\n"
        );
      }
  | '(' aritmetico ')'              {/*$$ = $2; copia el struct*/}
  | array '.' IDENTIF               {/*if(strcmp($3, "length") != 0) yyerror("Propiedad inesperada\n");*/}
  | REAL                            {$$.reg = sm;/*$$ = $1;*/}
  | ENTERO
      { 
        fprintf(obj, "\tR7=R7-4;\n\tI(R7)=%d;\n", $1); 
        // $$.reg = NumeroRegistro;
      }
  | IDREAL
      {
        struct reg *p = buscat($1, varl);

        if (p!=NULL) 
          fprintf(obj, "\tR0=I(R6%d);\n\tR7=R7-4;\n\tP(R7)=R0;\n", p->dir);
        else {
          p = buscat($1,varg);
          if (p!=NULL) fprintf(obj, "\tR0=I(0x%x);\n\tR7=R7-4;\n\tP(R7)=R0;\n", p->dir);
          else yyerror("5: variable no declarada"); 
        }
      }
  | IDENTERO
      {
        struct reg *p = buscat($1, varl);

        if (p!=NULL) 
          fprintf(obj, "\tR0=I(R6%d);\n\tR7=R7-4;\n\tP(R7)=R0;\n", p->dir);
        else {
          p = buscat($1,varg);
          if (p!=NULL) fprintf(obj, "\tR0=I(0x%x);\n\tR7=R7-4;\n\tP(R7)=R0;\n", p->dir);
          else yyerror("5: variable no declarada"); 
        }
      }
  ;


condicion:
    aritmetico '<' aritmetico
      {
        /*$$ = $1 < $3 ? 1 : 0;*/
        fprintf(
          obj,
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1<R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
      }
  | aritmetico MNIG aritmetico
    {
      /*$$ = $1 <= $3 ? 1 : 0;*/
        fprintf(
          obj,
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1<=R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
    }
  | aritmetico '>' aritmetico
    {
      /*$$ = $1 > $3 ? 1 : 0;*/
        fprintf(
          obj,
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1>R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
    }
  | aritmetico MYIG aritmetico
    {
      /*$$ = $1 >= $3 ? 1 : 0;*/
        fprintf(
          obj,
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1>=R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
    }
  | aritmetico IGUAL aritmetico
    {
      /*$$ = $1 == $3 ? 1 : 0;*/
        fprintf(
          obj,
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1==R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
    }
  | aritmetico DESIGUAL aritmetico
      {
        /*$$ = $1 != $3 ? 1 : 0;*/
        fprintf(
          obj,
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1!=R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
      }
  | condicion AND condicion
      {
        /*$$ = $1 && $3 ? 1 : 0;*/
        fprintf(
          obj,
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1&&R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
      }
  | condicion OR condicion
      {
        /*$$ = $1 || $3 ? 1 : 0;*/
        fprintf(
          obj,
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1||R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
      }
  | '!' condicion
      {
        /*$$ = ++$2 % 2;*/
        fprintf(
          obj,
          "\tR0=I(R7);\n\tR0=!R0;\n\tI(R7)=R0;\n"
        );
      }
  | '(' condicion ')'
  | LOGICO                          
      {
        /*$$ = $1;*/
        fprintf(obj, "\tR7=R7-4;\n\tI(R7)=%d;\n", $1);
      }
  | IDLOGICO
      { 
        if (
          buscat($1, varg) == NULL && 
          buscat($1, varl)==NULL
        ) yyerror("5: variable no declarada"); 
      }
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
  | IDCADENA
      { 
        if (
          buscat($1, varg) == NULL && 
          buscat($1, varl)==NULL
        ) yyerror("5: variable no declarada"); 
      }
  ;

array: 
    array '+' array   {}
  | '[' iterable ']'  {}
  | '[' ']'           {}
  | NEW INT '[' ENTERO ']'
  | NEW FLOAT '[' ENTERO ']'
  | NEW BOOL '[' ENTERO ']'
  | NEW STRING '[' ENTERO ']'
  | IDARRAY
      { 
        if (
          buscat($1, varg) == NULL && 
          buscat($1, varl)==NULL
        ) yyerror("5: variable no declarada"); 
      }
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
    INT     {$$ = $1;}
  | FLOAT   {$$ = $1;}
  | BOOL    {$$ = $1;}
  | STRING  {$$ = $1;}
  | ARRAY   {$$ = $1;}
  | STRUCT  {$$ = $1;}
  | VOID    {$$ = $1;}
;

id:
    IDENTIF   { $$ = $1; }
  | IDENTERO  { $$ = $1; }
  | IDREAL    { $$ = $1; }
  ;

asignacion:
    id
      {
        struct reg *p = buscat($1, varl);

        if (p!=NULL) 
          fprintf(obj, "\tR7=R7-4;\n\tR0=R6%d;\n\tP(R7)=R0;\n", p->dir);
        else {
          p = buscat($1,varg);

          if (p!=NULL) 
            fprintf(obj, "\tR7=R7-4;\n\tP(R7)=0x%x;\n", p->dir);
          else 
            yyerror("3: variable no declarada"); 
        }
      }
    asignables      
      {
        fprintf(obj, "\tR0=I(R7);\n\tR1=P(R7+4);\n\tI(R1)=R0;\n\tR7=R7+8;\n");
      }
  ;

asignables:
    '=' aritmetico        {}
  | '=' condicion         {}
  | '=' string            {/*printf("%s\n", $1);*/}
  | '=' array
  | '=' '{' struct-bloque '}'
  ;

declaracion:
    tipo IDENTIF
      {
      }
    asignables
      {
        struct reg *t = buscat($1, tipo);

        int d;
		    if (gl==varg) d = sm -= t->tam;
        else d = fm -= t->tam;

        if (t!=NULL && t!=voidp) {
          struct reg *p = insvr($2, gl, t, d);
		      if (gl==varl) { // variable local
            fprintf(obj, "\tR7=R7-4;\n");
            fprintf(obj, "\tR7=R7-4;\n\tR0=R6%d;\n\tP(R7)=R0;\n", p->dir); // revisar
            fprintf(obj, "\tR0=I(R7);\n\tR1=P(R7+4);\n\tI(R1)=R0;\n\tR7=R7+8;\n");
          }
        }
        else yyerror("1: tipo inexistente");
      }
  | tipo IDENTIF
      {
        struct reg *t = buscat($1, tipo);

        int d;
		    if (gl==varg) d = sm -= t->tam;
        else d = fm -= t->tam;

        if (t!=NULL && t!=voidp) {
          insvr($2, gl, t, d);

		      if (gl==varl) 
            fprintf(obj, "\tR7=R7-4;\n");
        }
        else yyerror("1: tipo inexistente");
      }
  ;

if:
    IF '(' condicion ')'
      {
        $<entero>$ = ++et;
        fprintf(
          obj, 
          "\tR0=I(R7);\n\tIF(!R0) GT(%d);\n",
          et
        );
      }
    sentbloq
      {
        fprintf(obj, "L %d:\n", $<entero>5);
      }
    else
  ;

else: | ELSE sentbloq ;

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
  ;

while:
    WHILE
      {
        $<entero>$ = ++et;
        fprintf(obj, "L %d:\n", et);
      }
    '(' condicion ')'
      {
        $<entero>$ = ++et;
        fprintf(obj, "\tR0=I(R7);\n\tIF(!R0) GT(%d);\n", $<entero>$);
      }
    sentbloq
      {
        fprintf(obj, "GT(%d);\n\tL %d:\t", $<entero>2, $<entero>6);
      }
  ;

print:
    PRINT '(' print-expresion ')'
      { // eliminar print-expresion
        ++et;
        fprintf(obj, "\tR5=%d;\n\tGT(print);\nL %d:\tR7=R7+4;\n", et, et); 
      }
  | PRINTLN '(' expr ')'
      {
        ++et;
        fprintf(obj, "\tR5=%d;\n\tGT(println);\nL %d:\tR7=R7+4;\n", et, et); 
      }
  ;

print-expresion:
    '\n'
  | '\n' print-expresion
  | aritmetico
  | condicion
  | string
  | array
  | funcion-uso
      {
        if ($1==voidp)
          yyerror("7: rutina void no invocable en expresion");
		    else 
          fprintf(obj, "\tR7=R7-4;\n\tI(R7)=R0;\n");
      }
  ;

funcion-uso: 
    IDENTIF '(' ')'
      {
        $$ = buscat($1, rut);
        
        if ($$==NULL) 
          yyerror("4: rutina no declarada"); 
        else {
          ++et;
          fprintf(
            obj, 
            "\tR7=R7-8;\n\tP(R7+4)=R6;\n\tP(R7)=%d;\n\tGT(%d);\nL %d:\tR7=R7+8;\n", 
            et, $$->dir, et
          );
        }
        if (buscat($1, rut) == NULL) yyerror("4: rutina no declarada");
      }
  | IDENTIF '(' params-uso ')'
      {
        if (buscat($1, rut) == NULL) yyerror("4: rutina no declarada");
      }
  ;

params-uso:
    '\n'
  | '\n' params-uso
  | IDENTIF
  | IDENTIF espacio-vacio
  | IDENTIF ',' params-uso
  ;

funcion-declaracion:
    tipo IDENTIF '(' ')' '{'
      {
        // struct reg *t = buscat($1, tipo);
        $<rp>$ = buscat($1, tipo);

        // if (t!=NULL) ins($2, rut, t);
        if ($<rp>$==NULL) yyerror("2: tipo inexistente"); 
        else {
          struct reg *p = insvr($2, rut, $<rp>$, ++et); 
          gl = varl;
          fm = 0;
          fprintf(obj, "L %d:\tR6=R7;\n", p->dir);
        }
        gl=varl;
      } 
    bloque '}' 
      {
        dump($2);
        finbloq();
        gl=varg;
        fprintf(obj, "\tR7=R6;\n\tR6=P(R7+4);\n\tR5=P(R7);\n\tGT(R5);\n");
      }
  | tipo IDENTIF '(' params-declaracion ')' '{'
      { 
        // struct reg *t = buscat($1, tipo);
        $<rp>$ = buscat($1, tipo);

        // if (t!=NULL) ins($2, rut, t);
        if ($<rp>$==NULL) yyerror("2: tipo inexistente"); 
        else {
          struct reg *p = insvr($2, rut, $<rp>$, ++et); 
          gl = varl;
          fm = 0;
          fprintf(obj, "L %d:\tR6=R7;\n", p->dir);
        }
        gl=varl;
      } 
    bloque '}' 
      {
        dump($2);
        finbloq();
        gl=varg;
        fprintf(obj, "\tR7=R6;\n\tR6=P(R7+4);\n\tR5=P(R7);\n\tGT(R5);\n");
      }
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
  if (argc>2) obj=fopen(argv[2],"w");
  inits();
  dump("t.s. inicial");
  fprintf(obj, "#include \"Q.h\"\nBEGIN\n");
  yyparse();
  fprintf(obj, "END\n");
  fclose(obj);
  dump("t.s. final");
}

void yyerror(char* mens) {
  //yydebug = 1;
  dump("ERROR");
  // fprintf (stderr, "%s\n", s);
  //printf("Error en linea %i: %s \n", numlin, mens);
  fprintf(obj, "\n!!! error %s (lin %d) !!!\n\n", mens, numlin);
  fprintf(stderr, "Error %s (lin %d)\n", mens, numlin);
  //if (strcmp(mens, "syntax error")==0) exit(1);
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