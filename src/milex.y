%{
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <stddef.h>

#include "ts.h"
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
    struct reg *tipo;
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

%type <exp> aritmetico
%type <exp> real
%type <exp> expr
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
%left '.'

%%
prog:
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
    sentencia         {}
  | sentencia bloque  {}
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
    expresion
  | if
  | switch
  | for
  | for-in
  | while
  | print
  | funcion-uso
  | funcion-declaracion
  | BREAK
  | CONTINUE
  ;

sentbloq: sentencia | '{' bloque '}' ;

expresion:
    asignacion
  | declaracion
  ;

aritmetico:
    aritmetico '+' aritmetico
      {
        fprintf(
          obj, 
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1+R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
      }
  | aritmetico '-' aritmetico
      {
        fprintf(
          obj, 
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1-R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
      }
  | aritmetico '*' aritmetico
      {
        fprintf(
          obj, 
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1*R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
      }
  | aritmetico '%' aritmetico
      {
        fprintf(
          obj, 
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1%cR0;\n\tR7=R7+4;\n\tI(R7)=R0;\n",
          '%'
        );
      }
  | aritmetico POTENCIA aritmetico
  | '-' aritmetico
      {
        fprintf(
          obj, 
          "\tR0=I(R7);\n\tR0=-R0;\n\tI(R7)=R0;\n"
        );
      }
  | INCREMENTO aritmetico
      {
        fprintf(
          obj, 
          "\tR0=I(R7);\n\tR0=R0+1;\n\tI(R7)=R0;\n"
        );
      }
  | DECREMENTO aritmetico
      {
        fprintf(
          obj, 
          "\tR0=I(R7);\n\tR0=R0-1;\n\tI(R7)=R0;\n"
        );
      }
  | '(' aritmetico ')'
  | array '.' IDENTIF
  | ENTERO
      { 
        fprintf(obj, "\tR7=R7-4;\n\tI(R7)=%d;\n", $1);
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

real:
    real '+' real
      {
        fprintf(
          obj, 
          "\tRR0=D(R7);\n\tRR1=D(R7+8);\n\tRR0=RR1+RR0;\n\tR7=R7+8;\n\tD(R7)=RR0;\n"
        );
      }
  | real '-' real
      {
        fprintf(
          obj, 
          "\tRR0=D(R7);\n\tRR1=D(R7+8);\n\tRR0=RR1-RR0;\n\tR7=R7+8;\n\tD(R7)=RR0;\n"
        );
      }
  | real '*' real
      {
        fprintf(
          obj, 
          "\tRR0=D(R7);\n\tRR1=D(R7+8);\n\tRR0=RR1*RR0;\n\tR7=R7+8;\n\tD(R7)=RR0;\n"
        );
      }
  | real '/' real
      {
        fprintf(
          obj, 
          "\tRR0=D(R7);\n\tRR1=D(R7+8);\n\tRR0=RR1/RR0;\n\tR7=R7+8;\n\tD(R7)=RR0;\n"
        );
      }
  | aritmetico '/' aritmetico
      {
        fprintf(
          obj, 
          "\tRR0=I(R7);\n\tRR1=I(R7+4);\n\tRR0=RR1/RR0;\n\tD(R7)=RR0;\n"
        );
      }
  | real '%' real
      {
        fprintf(
          obj, 
          "\tRR0=D(R7);\n\tRR1=D(R7+8);\n\tRR0=RR1%cRR0;\n\tR7=R7+8;\n\tD(R7)=RR0;\n",
          '%'
        );
      }
  | real POTENCIA real
  | '-' real
      {
        fprintf(
          obj, 
          "\tRR0=D(R7);\n\tRR0=-RR0;\n\tD(R7)=RR0;\n"
        );
      }
  | INCREMENTO real
      {
        fprintf(
          obj, 
          "\tRR0=D(R7);\n\tRR0=RR0+1;\n\tD(R7)=RR0;\n"
        );
      }
  | DECREMENTO real
      {
        fprintf(
          obj, 
          "\tRR0=D(R7);\n\tRR0=RR0-1;\n\tD(R7)=RR0;\n"
        );
      }
  | '(' real ')'
  | REAL
      {
        fprintf(obj, "\tR7=R7-8;\n\tD(R7)=%lf;\n", $1);
      }
  | IDREAL
      {
        struct reg *p = buscat($1, varl);

        if (p!=NULL) 
          fprintf(obj, "\tRR0=D(R6%d);\n\tR7=R7-8;\n\tD(R7)=RR0;\n", p->dir);
        else {
          p = buscat($1,varg);

          if (p!=NULL) 
            fprintf(obj, "\tRR0=D(0x%x);\n\tR7=R7-8;\n\tD(R7)=RR0;\n", p->dir);
          else 
            yyerror("5: variable no declarada"); 
        }
      }
  ;

condicion:
    aritmetico '<' aritmetico
      {
        fprintf(
          obj,
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1<R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
      }
  | aritmetico MNIG aritmetico
    {
        fprintf(
          obj,
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1<=R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
    }
  | aritmetico '>' aritmetico
    {
        fprintf(
          obj,
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1>R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
    }
  | aritmetico MYIG aritmetico
    {
        fprintf(
          obj,
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1>=R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
    }
  | aritmetico IGUAL aritmetico
    {
        fprintf(
          obj,
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1==R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
    }
  | aritmetico DESIGUAL aritmetico
      {
        fprintf(
          obj,
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1!=R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
      }
  | real '<' real
      {
        fprintf(
          obj,
          "\tRR0=D(R7);\n\tRR1=D(R7+8);\n\tR0=RR1<RR0;\n\tR7=R7+12;\n\tI(R7)=R0;\n"
        );
      }
  | real MNIG real
    {
        fprintf(
          obj,
          "\tRR0=D(R7);\n\tRR1=D(R7+8);\n\tR0=RR1<=RR0;\n\tR7=R7+12;\n\tI(R7)=R0;\n"
        );
    }
  | real '>' real
    {
        fprintf(
          obj,
          "\tRR0=D(R7);\n\tRR1=D(R7+8);\n\tR0=RR1>RR0;\n\tR7=R7+12;\n\tI(R7)=R0;\n"
        );
    }
  | real MYIG real
    {
        fprintf(
          obj,
          "\tRR0=D(R7);\n\tRR1=D(R7+8);\n\tR0=RR1>=RR0;\n\tR7=R7+12;\n\tI(R7)=R0;\n"
        );
    }
  | real IGUAL real
    {
        fprintf(
          obj,
          "\tRR0=D(R7);\n\tRR1=D(R7+8);\n\tR0=RR1==RR0;\n\tR7=R7+12;\n\tI(R7)=R0;\n"
        );
    }
  | real DESIGUAL real
      {
        fprintf(
          obj,
          "\tRR0=D(R7);\n\tRR1=D(R7+8);\n\tR0=RR1!=RR0;\n\tR7=R7+12;\n\tI(R7)=R0;\n"
        );
      }
  | condicion AND condicion
      {
        fprintf(
          obj,
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1&&R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
      }
  | condicion OR condicion
      {
        fprintf(
          obj,
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1||R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
      }
  | '!' condicion
      {
        fprintf(
          obj,
          "\tR0=I(R7);\n\tR0=!R0;\n\tI(R7)=R0;\n"
        );
      }
  | '(' condicion ')'
  | LOGICO                          
      {
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
    IDENTERO  { $$ = $1; }
  | IDREAL    { $$ = $1; }
  | IDLOGICO  { $$ = $1; }
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
  ;

asignables:
    '=' aritmetico
      {
        fprintf(obj, "\tR0=I(R7);\n\tR1=P(R7+4);\n\tI(R1)=R0;\n\tR7=R7+8;\n");
      }
  | '=' real
      {
        fprintf(obj, "\tRR0=D(R7);\n\tR1=P(R7+8);\n\tD(R1)=RR0;\n\tR7=R7+12;\n");
      }
  | '=' condicion
      {
        fprintf(obj, "\tR0=I(R7);\n\tR1=P(R7+4);\n\tI(R1)=R0;\n\tR7=R7+8;\n");
      }
  | '=' string
  | '=' array
  | '=' '{' struct-bloque '}'
  ;

declaracion:
    tipo IDENTIF
      {
        // Declaracion
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


        // Asignacion
        if (gl==varg)
          // No ocurre nunca pq no existe declaracion + asignacion en global
          fprintf(obj, "\tR7=R7-4;\n\tP(R7)=0x%x;\n", d);
        else
          fprintf(obj, "\tR7=R7-4;\n\tR0=R6%d;\n\tP(R7)=R0;\n", d);
      }
    asignables
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
    sentbloq else
  ;

else: 
      {
        fprintf(obj, "L %d:\tR7=R7+4;\n", $<entero>-1);
      }
  | ELSE
      {
        $<entero>$ = ++et;
        fprintf(obj, "\tGT(%d);\nL %d:\n", $<entero>$, $<entero>-1);
      }
    sentbloq 
      {
        fprintf(obj, "L %d:\tR7=R7+4;\n", $<entero>2);
      }
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
    CASE aritmetico ':' bloque
  | CASE string ':' bloque
  | DEFAULT ':' bloque
  ;

for: 
    FOR '(' expresion ';'
      {
        $<entero>$ = ++et;
        fprintf(obj, "L %d:\n", et);
      }
    condicion ';'
      {
        $<entero>$ = ++et;
        fprintf(obj, "\tR0=I(R7);\n\tIF(!R0) GT(%d);\n", $<entero>$);
      }
    expresion ')'
    sentbloq
      {
        fprintf(obj, "GT(%d);\n\tL %d:\t", $<entero>5, $<entero>8);
      }
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
    PRINT '(' expr ')'
      {
        ++et;
        fprintf(obj, "\tR5=%d;\n\tGT(print);\nL %d:\tR7=R7+4;\n", et, et); 
      }
  | PRINTLN '(' expr ')'
      {
        ++et;
        fprintf(obj, "\tR5=%d;\n\tGT(println);\nL %d:\tR7=R7+4;\n", et, et);
          
      }
  | PRINT '(' real ')'
      {
        ++et;
        fprintf(obj, "\tR5=%d;\n\tGT(printd);\nL %d:\tR7=R7+4;\n", et, et); 
      }
  | PRINTLN '(' real ')'
      {
        ++et;
        fprintf(obj, "\tR5=%d;\n\tGT(printlnd);\nL %d:\tR7=R7+8;\n", et, et);
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
    IDENTIF
  | IDENTIF espacio-vacio
  | IDENTIF ',' params-uso
  ;

ret:
      {
        if ($<rp>-1 != voidp)
          yyerror("6: rutina tiene que retornar valor");
      }
  | RETURN
      {
        if ($<rp>-1 != voidp)
          yyerror("6: rutina tiene que retornar valor");
      }
  | RETURN expr
      {
        if ($<rp>-1 == voidp)
          yyerror("6: rutina void no puede retornar valor");
        else
          fprintf(obj, "\tR0=I(R7);\n\tR7=R7+4;\n");
      }
  ;

funcion-declaracion:
    tipo IDENTIF '(' ')' '{'
      {
        $<rp>$ = buscat($1, tipo);

        if ($<rp>$==NULL) yyerror("2: tipo inexistente"); 
        else {
          struct reg *p = insvr($2, rut, $<rp>$, ++et); 
          gl = varl;
          fm = 0;
          fprintf(obj, "L %d:\tR6=R7;\n", p->dir);
        }
        gl=varl;
      } 
    bloque ret '}'
      {
        dump($2);
        finbloq();
        gl=varg;
        fprintf(obj, "\tR7=R6;\n\tR6=P(R7+4);\n\tR5=P(R7);\n\tGT(R5);\n");
      }
  | tipo IDENTIF '(' params-declaracion ')' '{'
      {
        $<rp>$ = buscat($1, tipo);

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
    tipo IDENTIF
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
  dump("ERROR");
  fprintf(obj, "\n!!! error %s (lin %d) !!!\n\n", mens, numlin);
  fprintf(stderr, "Error %s (lin %d)\n", mens, numlin);
}

void yywrap() {}
