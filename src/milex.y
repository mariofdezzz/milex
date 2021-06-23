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

enum categ gl = varg;

int sm = 0x12000;
int fm;
int et = 0;
int eb = -2;
int ec = -2;

struct reg *voidp;
struct reg *rp = NULL;

void inits() {
  inst("void", 0);
  voidp = top;
  inst("bool", 4);
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
%token <id> IDENTIF IDREAL IDENTERO IDLOGICO

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
%token <symbol> FOR
%token <symbol> WHILE

%token <symbol> BREAK
%token <symbol> CONTINUE
%token <symbol> RETURN
%token <symbol> PRINT
%token <symbol> PRINTLN

// %type <exp> aritmetico
// %type <exp> real
// %type <exp> expr
%type <rp> expresion
%type <symbol> tipo
%type <symbol> id
// %type <entero> if
%type <rp> exp-funcion
%type <rp> incdec
%type <entero> params-uso
%type <entero> params-declaracion

/* Precedencia */
%left AND OR
%nonassoc IGUAL DESIGUAL '<' '>' MNIG MYIG
%left '+' '-'
%left '*' '/' '%'
%right POTENCIA
%left '!' INCREMENTO DECREMENTO
%left '.'

%%
programa:
  | declaracion programa
  | '{'
      {
        fprintf(obj, "L 0:\tR7=0x%x;\n", sm);
      }
    bloque
      {
        fprintf(obj, "\tGT(-2);\n");
      }
    '}'
  ;

bloque:
    sentencia bloque
  | sentencia
  ;

sentencia:
    declaracion
  | asg-variable
  | est-control
  | sen-especial
  | exp-funcion
  | print
  | incdec
      {
        if ($1->id[0] == 'f')
          fprintf(obj, "\tR7=R7+8;\n");
        else
          fprintf(obj, "\tR7=R7+4;\n");
      }
  ;

sentbloq:
    sentencia
  | '{' bloque '}'
  ;

declaracion:
    dcl-variable
  | dcl-funcion
  ;

est-control:
    if
  | while
  | for
  ;

dcl-variable:
    tipo IDENTIF
      { // Cambiar IDENTIF por id
        struct reg *t = buscat($1, tipo);

        int d;
		    if (gl==varg) d = sm -= t->tam;
        else d = fm -= t->tam;

        if (t!=NULL && t!=voidp) {
          insvr($2, gl, t, d);

		      if (t->id[0] == 'f')
            fprintf(obj, "\tR7=R7-8;\n");
          else
            fprintf(obj, "\tR7=R7-4;\n");
        }
        else yyerror("1.1: tipo inexistente");
      }
  ;

dcl-funcion:
    tipo IDENTIF '('
      {
        rp = buscat($1, tipo);

        if (rp == NULL) yyerror("1.2: tipo de retorno inexistente"); 
        else {
          struct reg *p = insvr($2, rut, rp, ++et); 
          gl = varl;
          fm = 0;
          fprintf(obj, "L %d:\tR6=R7;\n", p->dir);
        }
        gl=varl;
      } 
    ')' '{' bloque '}'
      {
        rp = NULL;
        dump($2);
        finbloq();
        gl=varg;
        fprintf(obj, "\tR7=R6;\n\tR6=P(R7+4);\n\tR5=P(R7);\n\tGT(R5);\n");
      }
  | tipo IDENTIF '('
      {
        rp = buscat($1, tipo);

        if (rp==NULL) yyerror("1.2: tipo de retorno inexistente"); 
        else {
          struct reg *p = insvr($2, rut, rp, ++et); 
          gl = varl;
          fm = 0;
          fprintf(obj, "L %d:\tR6=R7;\n", p->dir);
        }
        gl=varl;
      }
    params-declaracion ')' '{' bloque '}'
      { // Incluir el return, parametros, recusividad
        rp = NULL;
        dump($2);
        finbloq();
        gl=varg;
        fprintf(obj, "\tR7=R6;\n\tR6=P(R7+4);\n\tR5=P(R7);\n\tGT(R5);\n");
      }
  ;

params-declaracion:
    tipo IDENTIF
      {
        struct reg *t = buscat($1, tipo);
        $$ = 8 + t->tam;

        int d = fm + 8;

        if (t!=NULL && t!=voidp)
          insvr($2, varl, t, d);
        else
          yyerror("1.1: tipo inexistente");
      }
  | tipo IDENTIF ',' params-declaracion 
      {
        struct reg *t = buscat($1, tipo);
        $$ = $4 + t->tam;
        
        int d = fm + $4;
        
        if (t!=NULL && t!=voidp)
          insvr($2, varl, t, d);
        else
          yyerror("1.1: tipo inexistente");
      }
  ;

asg-variable:
    id
      {
        struct reg *p = buscat($1, varl);

        if (p!=NULL) {
          $<rp>$ = p;
          fprintf(obj, "\tR7=R7-4;\n\tR0=R6%d;\n\tP(R7)=R0;\n", p->dir);
        } else {
          p = buscat($1,varg);

          if (p!=NULL) {
            $<rp>$ = p;
            fprintf(obj, "\tR7=R7-4;\n\tP(R7)=0x%x;\n", p->dir);
          } 
          else 
            yyerror("2.1: variable no declarada"); 
        }
      }
    '=' expresion
      {
        struct reg *t = $4;

        if (t->id[0] == $<rp>2->tip->id[0])
          if (t->id[0] == 'f')
            fprintf(obj, "\tRR0=D(R7);\n\tR1=P(R7+8);\n\tD(R1)=RR0;\n\tR7=R7+12;\n"); // !!
          else
            fprintf(obj, "\tR0=I(R7);\n\tR1=P(R7+4);\n\tI(R1)=R0;\n\tR7=R7+8;\n");
        else
          yyerror("1.3: tipos no compatibles");
      }
  | tipo IDENTIF
      {
        // Declaracion
        struct reg *t = buscat($1, tipo);
        $<rp>$ = t;

        int d;
		    if (gl==varg) d = sm -= t->tam;
        else d = fm -= t->tam;

        if (t!=NULL && t!=voidp) {
          insvr($2, gl, t, d);

		      if (t->id[0] == 'f')
            fprintf(obj, "\tR7=R7-8;\n");
          else
            fprintf(obj, "\tR7=R7-4;\n");
        }
        else yyerror("1.1: tipo inexistente");


        // Asignacion
        if (gl==varg)
          fprintf(obj, "\tR7=R7-4;\n\tP(R7)=0x%x;\n", d);
        else
          fprintf(obj, "\tR7=R7-4;\n\tR0=R6%d;\n\tP(R7)=R0;\n", d);
      }
    '=' expresion
      {
        struct reg *t = $5;

        if (t->id[0] == $<rp>3->id[0])
          if (t->id[0] == 'f')
            fprintf(obj, "\tRR0=D(R7);\n\tR1=P(R7+8);\n\tD(R1)=RR0;\n\tR7=R7+12;\n");
          else
            fprintf(obj, "\tR0=I(R7);\n\tR1=P(R7+4);\n\tI(R1)=R0;\n\tR7=R7+8;\n");
        else
          yyerror("1.3: tipos no compatibles");
      }
  ;

if:
    IF '(' expresion ')'
      {
        if ($3->id[0] != 'b')
          yyerror("1.4: se espera una expresion logica");

        $<entero>$ = ++et;
        fprintf(
          obj, 
          "\tR0=I(R7);\n\tR7=R7+4;\n\tIF(!R0) GT(%d);\n",
          et
        );
      }
    sentbloq else
  ;

else: 
      {
        fprintf(obj, "L %d:\n", $<entero>-1);
      }
  | ELSE
      {
        $<entero>$ = ++et;
        fprintf(obj, "\tGT(%d);\nL %d:\n", $<entero>$, $<entero>-1);
      }
    sentbloq 
      {
        fprintf(obj, "L %d:\n", $<entero>2);
      }
  ;

while:
    WHILE
      {
        $<entero>$ = ec;
        ec = ++et;
        fprintf(obj, "L %d:\n", et);
      }
    '(' expresion ')'
      {
        if ($4->id[0] != 'b')
          yyerror("1.4: se espera una expresion logica");

        $<entero>$ = eb;
        eb = ++et;
        fprintf(obj, "\tR0=I(R7);\n\tIF(!R0) GT(%d);\n", eb);
      }
    sentbloq
      {
        fprintf(obj, "GT(%d);\n\tL %d:\t", ec, eb);
        ec = $<entero>2;
        eb = $<entero>6;
      }
  ;

for: 
    FOR '(' asg-variable ';'
      { // Ampliar tipo de sentencias que caben aqui
        $<entero>$ = ++et;
        fprintf(obj, "L %d:\n", et);
      }
    expresion
      {
        if ($6->id[0] != 'b')
          yyerror("1.4: se espera una expresion logica");

        $<entero>$ = eb;
        eb = ++et;
        fprintf(obj, "\tR0=I(R7);\n\tR7=R7+4;\n\tIF(!R0) GT(%d);\n", et);
      }
    ';'
      {
        et = et + 2;
        $<entero>$ = ec;
        ec = et;
        fprintf(obj, "\tGT(%d);\nL %d:\n", et - 1, et);
      }
    end-for ')'
      {
        fprintf(obj, "\tGT(%d);\nL %d:\n", $<entero>5, et - 1);
      }
    sentbloq
      {
        fprintf(obj, "\tGT(%d);\nL %d:\n", ec, eb);
        eb = $<entero>7;
        ec = $<entero>9;
      }
  ;

end-for:
    asg-variable
  | incdec
      {
        if ($1->id[0] == 'f')
          fprintf(obj, "\tR7=R7+8;\n");
        else
          fprintf(obj, "\tR7=R7+4;\n");
      }
  ;

print:
    PRINT '(' expresion ')'
      {
        struct reg *t = $3;
        ++et;

        if (t->id[0] == 'f')
          fprintf(obj, "\tR5=%d;\n\tGT(printd);\nL %d:\tR7=R7+8;\n", et, et);
        else
          fprintf(obj, "\tR5=%d;\n\tGT(print);\nL %d:\tR7=R7+4;\n", et, et);
      }
  | PRINTLN '(' expresion ')'
      {
        struct reg *t = $3;
        ++et;

        if (t->id[0] == 'f')
          fprintf(obj, "\tR5=%d;\n\tGT(printlnd);\nL %d:\tR7=R7+8;\n", et, et);
        else
          fprintf(obj, "\tR5=%d;\n\tGT(println);\nL %d:\tR7=R7+4;\n", et, et);
          
      }
  ;

exp-funcion: 
    IDENTIF '(' ')'
      {
        $$ = buscat($1, rut);
        
        if ($$==NULL) 
          yyerror("2.2: rutina no declarada"); 
        else {
          ++et;
          fprintf(
            obj, 
            "\tR7=R7-8;\n\tP(R7+4)=R6;\n\tP(R7)=%d;\n\tGT(%d);\nL %d:\tR7=R7+8;\n", 
            et, $$->dir, et
          );
        }
      }
  | IDENTIF '(' params-uso ')'
      {
        $$ = buscat($1, rut);

        if ($$==NULL) 
          yyerror("2.2: rutina no declarada"); 
        else {
          ++et;
          fprintf(
            obj, 
            "\tR7=R7-8;\n\tP(R7+4)=R6;\n\tP(R7)=%d;\n\tGT(%d);\nL %d:\tR7=R7+%d;\n", 
            et, $$->dir, et, 8 + $3
          );
        }
      }
  ;

params-uso:
    expresion
      {
        $$ = $1->tam;
      }
  | expresion ',' params-uso
      {
        $$ = $1->tam + $3;
      }
  ;

expresion:
    expresion '+' expresion
      {
        $$ = $1;
        
        if ($1->id[0] != $3->id[0])
          yyerror("1.3: tipos no compatibles");
        else {
          if ($1->id[0] == 'f')
            fprintf(obj, "\tRR0=D(R7);\n\tRR1=D(R7+8);\n\tRR0=RR1+RR0;\n\tR7=R7+8;\n\tD(R7)=RR0;\n");
          else if ($1->id[0] == 'i')
            fprintf(obj, "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1+R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n");
          else
            yyerror("1.5: operador no compatible");
        }
      }
  | expresion '-' expresion
      {
        $$ = $1;
        
        if ($1->id[0] != $3->id[0])
          yyerror("1.3: tipos no compatibles");
        else {
          if ($1->id[0] == 'f')
            fprintf(obj, "\tRR0=D(R7);\n\tRR1=D(R7+8);\n\tRR0=RR1-RR0;\n\tR7=R7+8;\n\tD(R7)=RR0;\n");
          else if ($1->id[0] == 'i')
            fprintf(obj, "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1-R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n");
          else
            yyerror("1.5: operador no compatible");
        }
      }
  | expresion '*' expresion
      {
        $$ = $1;
        
        if ($1->id[0] != $3->id[0])
          yyerror("1.3: tipos no compatibles");
        else {
          if ($1->id[0] == 'f')
            fprintf(obj, "\tRR0=D(R7);\n\tRR1=D(R7+8);\n\tRR0=RR1*RR0;\n\tR7=R7+8;\n\tD(R7)=RR0;\n");
          else if ($1->id[0] == 'i')
            fprintf(obj, "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1*R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n");
          else
            yyerror("1.5: operador no compatible");
        }
      }
  | expresion '/' expresion
      {
        $$ = $1;
        
        if ($1->id[0] != $3->id[0])
          yyerror("1.3: tipos no compatibles");
        else {
          if ($1->id[0] == 'f')
            fprintf(obj, "\tRR0=D(R7);\n\tRR1=D(R7+8);\n\tRR0=RR1/RR0;\n\tR7=R7+8;\n\tD(R7)=RR0;\n");
          else if ($1->id[0] == 'i')
            fprintf(obj, "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1/R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n");
          else
            yyerror("1.5: operador no compatible");
        }
      }
  | expresion '%' expresion
      {
        $$ = $1;
        
        if ($1->id[0] != $3->id[0])
          yyerror("1.3: tipos no compatibles");
        else {
          if ($1->id[0] == 'f')
            fprintf(obj, "\tRR0=D(R7);\n\tRR1=D(R7+8);\n\tRR0=RR1%cRR0;\n\tR7=R7+8;\n\tD(R7)=RR0;\n", '%');
          else if ($1->id[0] == 'i')
            fprintf(obj, "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1%cR0;\n\tR7=R7+4;\n\tI(R7)=R0;\n", '%');
          else
            yyerror("1.5: operador no compatible");
        }
      }
  | '-' expresion
      {
        $$ = $2;
        
        if ($2->id[0] == 'f')
          fprintf(obj, "\tRR0=D(R7);\n\tRR0=-RR0;\n\tD(R7)=RR0;\n");
        else if ($2->id[0] == 'i')
          fprintf(obj, "\tR0=I(R7);\n\tR0=-R0;\n\tI(R7)=R0;\n");
        else
          yyerror("1.5: operador no compatible");
      }
  | expresion '<' expresion
      {
        $$ = buscat("bool", tipo);
        
        if ($1->id[0] != $3->id[0])
          yyerror("1.3: tipos no compatibles");
        else {
          if ($1->id[0] == 'f')
            fprintf(obj, "\tRR0=D(R7);\n\tRR1=D(R7+8);\n\tR0=RR1<RR0;\n\tR7=R7+12;\n\tI(R7)=R0;\n");
          else if ($1->id[0] == 'i')
            fprintf(obj, "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1<R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n");
          else
            yyerror("1.5: operador no compatible");
        }
      }
  | expresion '>' expresion
      {
        $$ = buscat("bool", tipo);
        
        if ($1->id[0] != $3->id[0])
          yyerror("1.3: tipos no compatibles");
        else {
          if ($1->id[0] == 'f')
            fprintf(obj, "\tRR0=D(R7);\n\tRR1=D(R7+8);\n\tR0=RR1>RR0;\n\tR7=R7+12;\n\tI(R7)=R0;\n");
          else if ($1->id[0] == 'i')
            fprintf(obj, "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1>R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n");
          else
            yyerror("1.5: operador no compatible");
        }
      }
  | expresion MNIG expresion
      {
        $$ = buscat("bool", tipo);
        
        if ($1->id[0] != $3->id[0])
          yyerror("1.3: tipos no compatibles");
        else {
          if ($1->id[0] == 'f')
            fprintf(obj, "\tRR0=D(R7);\n\tRR1=D(R7+8);\n\tR0=RR1<=RR0;\n\tR7=R7+12;\n\tI(R7)=R0;\n");
          else if ($1->id[0] == 'i')
            fprintf(obj, "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1<=R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n");
          else
            yyerror("1.5: operador no compatible");
        }
      }
  | expresion MYIG expresion
      {
        $$ = buscat("bool", tipo);
        
        if ($1->id[0] != $3->id[0])
          yyerror("1.3: tipos no compatibles");
        else {
          if ($1->id[0] == 'f')
            fprintf(obj, "\tRR0=D(R7);\n\tRR1=D(R7+8);\n\tR0=RR1>=RR0;\n\tR7=R7+12;\n\tI(R7)=R0;\n");
          else if ($1->id[0] == 'i')
            fprintf(obj, "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1>=R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n");
          else
            yyerror("1.5: operador no compatible");
        }
      }
  | expresion IGUAL expresion
      {
        $$ = buscat("bool", tipo);
        
        if ($1->id[0] != $3->id[0])
          yyerror("1.3: tipos no compatibles");
        else {
          if ($1->id[0] == 'f')
            fprintf(obj, "\tRR0=D(R7);\n\tRR1=D(R7+8);\n\tR0=RR1==RR0;\n\tR7=R7+12;\n\tI(R7)=R0;\n");
          else if ($1->id[0] == 'i')
            fprintf(obj, "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1==R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n");
          else
            yyerror("1.5: operador no compatible");
        }
      }
  | expresion DESIGUAL expresion
      {
        $$ = buscat("bool", tipo);
        
        if ($1->id[0] != $3->id[0])
          yyerror("1.3: tipos no compatibles");
        else {
          if ($1->id[0] == 'f')
            fprintf(obj, "\tRR0=D(R7);\n\tRR1=D(R7+8);\n\tR0=RR1!=RR0;\n\tR7=R7+12;\n\tI(R7)=R0;\n");
          else if ($1->id[0] == 'i')
            fprintf(obj, "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1!=R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n");
          else
            yyerror("1.5: operador no compatible");
        }
      }
  | expresion AND expresion
      {
        $$ = $1;
        
        if ($1->id[0] != $3->id[0])
          yyerror("1.3: tipos no compatibles");
        else {
          if ($1->id[0] == 'b')
            fprintf(obj, "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1&&R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n");
          else
            yyerror("1.5: operador no compatible");
        }
      }
  | expresion OR expresion
      {
        $$ = $1;
        
        if ($1->id[0] != $3->id[0])
          yyerror("1.3: tipos no compatibles");
        else {
          if ($1->id[0] == 'b')
            fprintf(obj, "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1||R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n");
          else
            yyerror("1.5: operador no compatible");
        }
      }
  | '!' expresion
      {
        $$ = $2;

        if ($2->id[0] == 'b')
          fprintf(obj, "\tR0=I(R7);\n\tR0=!R0;\n\tI(R7)=R0;\n");
        else
          yyerror("1.5: operador no compatible");
      }
  | '(' expresion ')'
      {
        $$ = $2;
      }
  | ENTERO
      { 
        $$ = buscat("int", tipo);
        fprintf(obj, "\tR7=R7-4;\n\tI(R7)=%d;\n", $1);
      }
  | REAL
      {
        $$ = buscat("float", tipo);
        fprintf(obj, "\tR7=R7-8;\n\tD(R7)=%.15f;\n", $1);
      }
  | LOGICO                          
      {
        $$ = buscat("bool", tipo);
        fprintf(obj, "\tR7=R7-4;\n\tI(R7)=%d;\n", $1);
      }
  | IDENTERO
      {
        struct reg *p = buscat($1, varl);

        if (p!=NULL) {
          $$ = p->tip;
          
          if (p->dir < 0)
            fprintf(obj, "\tR0=I(R6%d);\n\tR7=R7-4;\n\tI(R7)=R0;\n", p->dir);
          else
            fprintf(obj, "\tR0=I(R6+%d);\n\tR7=R7-4;\n\tI(R7)=R0;\n", p->dir);
        } else {
          p = buscat($1,varg);
          $$ = p->tip;

          if (p!=NULL) 
            fprintf(obj, "\tR0=I(0x%x);\n\tR7=R7-4;\n\tI(R7)=R0;\n", p->dir);
          else 
            yyerror("2.1: variable no declarada"); 
        }
      }
  | IDREAL
      {
        struct reg *p = buscat($1, varl);

        if (p!=NULL) {
          $$ = p->tip;
          
          if (p->dir < 0)
            fprintf(obj, "\tRR0=D(R6%d);\n\tR7=R7-8;\n\tD(R7)=RR0;\n", p->dir);
          else
            fprintf(obj, "\tRR0=D(R6+%d);\n\tR7=R7-8;\n\tD(R7)=RR0;\n", p->dir);
        } else {
          p = buscat($1,varg);
          $$ = p->tip;
          
          if (p!=NULL) // añadir variante +
            fprintf(obj, "\tRR0=D(0x%x);\n\tR7=R7-8;\n\tD(R7)=RR0;\n", p->dir);
          else 
            yyerror("2.1: variable no declarada"); 
        }
      }
  | IDLOGICO
      { 
        struct reg *p = buscat($1, varl);

        if (p!=NULL) {
          $$ = p->tip;
          
          if (p->dir < 0)
            fprintf(obj, "\tR0=I(R6%d);\n\tR7=R7-4;\n\tI(R7)=R0;\n", p->dir);
          else
            fprintf(obj, "\tR0=I(R6+%d);\n\tR7=R7-4;\n\tI(R7)=R0;\n", p->dir);
        } else {
          p = buscat($1,varg);
          $$ = p->tip;

          if (p!=NULL) 
            fprintf(obj, "\tR0=I(0x%x);\n\tR7=R7-4;\n\tI(R7)=R0;\n", p->dir);
          else 
            yyerror("2.1: variable no declarada"); 
        }
      }
  | incdec
      { // Mover codigo a asg-variable retornando en $$ el tamaño de tipo
        $$ = $1;
      }
  | exp-funcion
      {
        $$ = $1->tip;

        if ($1->tip != voidp)
          if ($1->tip->id[0] == 'f')
            fprintf(obj, "\tR7=R7-8;\n\tD(R7)=RR0;\n");
          else
            fprintf(obj, "\tR7=R7-4;\n\tI(R7)=R0;\n");
        else
          yyerror("3.1: rutina void no invocable en expresion");
      }
  ;

incdec:
   INCREMENTO IDENTERO
      {
        $$ = buscat("int", tipo);

        // Se busca la variable
        struct reg *p = buscat($2, varl);

        if (p!=NULL) 
          if (p->dir < 0)
            fprintf(obj, "\tR0=I(R6%d);\n\tR1=R6%d;\n", p->dir, p->dir);
          else
            fprintf(obj, "\tR0=I(R6+%d);\n\tR1=R6+%d;\n", p->dir, p->dir);
        else {
          p = buscat($1,varg);

          if (p!=NULL)
            fprintf(obj, "\tR0=I(0x%x);\n\tR1=0x%x;\n", p->dir, p->dir);
          else 
            yyerror("2.1: variable no declarada"); 
        }

        // Se modifica la variable
        fprintf(
          obj, 
          "\tR0=R0+1;\n\tR7=R7-4;\n\tI(R7)=R0;\n\tI(R1)=R0;\n"
        );
      }
  | IDENTERO INCREMENTO
      {
        $$ = buscat("int", tipo);
        
        // Se busca la variable
        struct reg *p = buscat($1, varl);

        if (p!=NULL) 
          if (p->dir < 0)
            fprintf(obj, "\tR0=I(R6%d);\n\tR1=R6%d;\n", p->dir, p->dir);
          else
            fprintf(obj, "\tR0=I(R6+%d);\n\tR1=R6+%d;\n", p->dir, p->dir);
        else {
          p = buscat($1,varg);

          if (p!=NULL)
            fprintf(obj, "\tR0=I(0x%x);\n\tR1=0x%x;\n", p->dir, p->dir);
          else 
            yyerror("2.1: variable no declarada"); 
        }

        // Se modifica la variable
        fprintf(
          obj, 
          "\tR7=R7-4;\n\tI(R7)=R0;\n\tR0=R0+1;\n\tI(R1)=R0;\n"
        );
      }
  | DECREMENTO IDENTERO
      {
        $$ = buscat("int", tipo);
        
        // Se busca la variable
        struct reg *p = buscat($2, varl);

        if (p!=NULL) 
          if (p->dir < 0)
            fprintf(obj, "\tR0=I(R6%d);\n\tR1=R6%d;\n", p->dir, p->dir);
          else
            fprintf(obj, "\tR0=I(R6+%d);\n\tR1=R6+%d;\n", p->dir, p->dir);
        else {
          p = buscat($1,varg);

          if (p!=NULL)
            fprintf(obj, "\tR0=I(0x%x);\n\tR1=0x%x;\n", p->dir, p->dir);
          else 
            yyerror("2.1: variable no declarada"); 
        }

        // Se modifica la variable
        fprintf(
          obj, 
          "\tR0=R0-1;\n\tR7=R7-4;\n\tI(R7)=R0;\n\tI(R1)=R0;\n"
        );
      }
  | IDENTERO DECREMENTO
      {
        $$ = buscat("int", tipo);
        
        // Se busca la variable
        struct reg *p = buscat($1, varl);

        if (p!=NULL) 
          if (p->dir < 0)
            fprintf(obj, "\tR0=I(R6%d);\n\tR1=R6%d;\n", p->dir, p->dir);
          else
            fprintf(obj, "\tR0=I(R6+%d);\n\tR1=R6+%d;\n", p->dir, p->dir);
        else {
          p = buscat($1,varg);

          if (p!=NULL)
            fprintf(obj, "\tR0=I(0x%x);\n\tR1=0x%x;\n", p->dir, p->dir);
          else 
            yyerror("2.1: variable no declarada"); 
        }

        // Se modifica la variable
        fprintf(
          obj, 
          "\tR7=R7-4;\n\tI(R7)=R0;\n\tR0=R0-1;\n\tI(R1)=R0;\n"
        );
      }
  | INCREMENTO IDREAL
      {
        $$ = buscat("float", tipo);
        
        // Se busca la variable
        struct reg *p = buscat($2, varl);

        if (p!=NULL) 
          if (p->dir < 0)
            fprintf(obj, "\tRR0=D(R6%d);\n\tR1=R6%d;\n", p->dir, p->dir);
          else
            fprintf(obj, "\tRR0=D(R6+%d);\n\tR1=R6+%d;\n", p->dir, p->dir);
        else {
          p = buscat($2,varg);

          if (p!=NULL)
            fprintf(obj, "\tRR0=D(0x%x);\n\tR1=0x%x;\n", p->dir, p->dir);
          else 
            yyerror("2.1: variable no declarada"); 
        }

        // Se modifica la variable
        fprintf(
          obj, 
          "\tRR0=RR0+1;\n\tR7=R7-8;\n\tD(R7)=RR0;\n\tD(R1)=RR0;\n"
        );
      }
  | IDREAL INCREMENTO
      {
        $$ = buscat("float", tipo);
        
        // Se busca la variable
        struct reg *p = buscat($1, varl);

        if (p!=NULL) 
          if (p->dir < 0)
            fprintf(obj, "\tRR0=D(R6%d);\n\tR1=R6%d;\n", p->dir, p->dir);
          else
            fprintf(obj, "\tRR0=D(R6+%d);\n\tR1=R6+%d;\n", p->dir, p->dir);
        else {
          p = buscat($1,varg);

          if (p!=NULL)
            fprintf(obj, "\tRR0=D(0x%x);\n\tR1=0x%x;\n", p->dir, p->dir);
          else 
            yyerror("2.1: variable no declarada"); 
        }

        // Se modifica la variable
        fprintf(
          obj, 
          "\tR7=R7-8;\n\tD(R7)=RR0;\n\tRR0=RR0+1;\n\tD(R1)=RR0;\n"
        );
      }
  | DECREMENTO IDREAL
      {
        $$ = buscat("float", tipo);
        
        // Se busca la variable
        struct reg *p = buscat($2, varl);

        if (p!=NULL) 
          if (p->dir < 0)
            fprintf(obj, "\tRR0=D(R6%d);\n\tR1=R6%d;\n", p->dir, p->dir);
          else
            fprintf(obj, "\tRR0=D(R6+%d);\n\tR1=R6+%d;\n", p->dir, p->dir);
        else {
          p = buscat($2,varg);

          if (p!=NULL)
            fprintf(obj, "\tRR0=D(0x%x);\n\tR1=0x%x;\n", p->dir, p->dir);
          else 
            yyerror("2.1: variable no declarada"); 
        }

        // Se modifica la variable
        fprintf(
          obj, 
          "\tRR0=RR0-1;\n\tR7=R7-8;\n\tD(R7)=RR0;\n\tD(R1)=RR0;\n"
        );
      }
  | IDREAL DECREMENTO
      {
        $$ = buscat("float", tipo);
        
        // Se busca la variable
        struct reg *p = buscat($1, varl);

        if (p!=NULL) 
          if (p->dir < 0)
            fprintf(obj, "\tRR0=D(R6%d);\n\tR1=R6%d;\n", p->dir, p->dir);
          else
            fprintf(obj, "\tRR0=D(R6+%d);\n\tR1=R6+%d;\n", p->dir, p->dir);
        else {
          p = buscat($1,varg);

          if (p!=NULL)
            fprintf(obj, "\tRR0=D(0x%x);\n\tR1=0x%x;\n", p->dir, p->dir);
          else 
            yyerror("2.1: variable no declarada"); 
        }

        // Se modifica la variable
        fprintf(
          obj, 
          "\tR7=R7-8;\n\tD(R7)=RR0;\n\tRR0=RR0-1;\n\tD(R1)=RR0;\n"
        );
      }
  ;

sen-especial:
    BREAK
      {
        fprintf(obj, "\tGT(%d);\n", eb);
      }
  | CONTINUE
      {
        fprintf(obj, "\tGT(%d);\n", ec);
      }
  | return
  ;

return:
    RETURN ';'
      {
        if (rp != NULL)
          if (rp == voidp)
            fprintf(obj, "\tR7=R6;\n\tR6=P(R7+4);\n\tR5=P(R7);\n\tGT(R5);\n");
          else
            yyerror("3.2: rutina tiene que retornar valor");
        else
          yyerror("3.3: rutina void no puede retornar valor");
      }
  | RETURN expresion
      {
        if (rp != NULL)
          if (rp != voidp) {
            if (rp->id[0] != $2->id[0])
              yyerror("3.4: se retorna un tipo no esperado");
            else
              if (rp->id[0] == 'f')
                fprintf(obj, "\tRR0=D(R7);\n\tR7=R7+8;\n");
              else
                fprintf(obj, "\tR0=I(R7);\n\tR7=R7+4;\n");
            
            fprintf(obj, "\tR7=R6;\n\tR6=P(R7+4);\n\tR5=P(R7);\n\tGT(R5);\n");
          } 
          else
            yyerror("3.2: rutina tiene que retornar valor");
        else
          yyerror("3.3: rutina void no puede retornar valor");
      }
  ;

id:
    IDENTERO  { $$ = $1; }
  | IDREAL    { $$ = $1; }
  | IDLOGICO  { $$ = $1; }
  | IDENTIF   { $$ = $1; /*declaracion + asignacion => identif todavia no esta en la tabla*/ }
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
