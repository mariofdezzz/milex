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

struct reg *voidp;
struct reg *rp;

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

dcl-funcion:
    tipo IDENTIF '(' ')' '{'
      {
        $<rp>$ = buscat($1, tipo);
        rp = $<rp>$;

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
      { // Incluir el return, parametros, recusividad
        dump($2);
        finbloq();
        gl=varg;
        fprintf(obj, "\tR7=R6;\n\tR6=P(R7+4);\n\tR5=P(R7);\n\tGT(R5);\n");
      }
  | tipo IDENTIF '(' params-declaracion ')' '{' bloque '}'
    {
      // TODO
    }
  ;

params-declaracion:
    tipo IDENTIF
  | tipo IDENTIF ',' params-declaracion
  ;

asg-variable:
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
    '=' expresion
      {
        struct reg *t = $4;

        if (t->id[0] == 'f')
          fprintf(obj, "\tRR0=D(R7);\n\tR1=P(R7+8);\n\tD(R1)=RR0;\n\tR7=R7+16;\n");
        else
          fprintf(obj, "\tR0=I(R7);\n\tR1=P(R7+4);\n\tI(R1)=R0;\n\tR7=R7+4;\n");
      }
  | tipo IDENTIF
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
    '=' expresion
      {
        struct reg *t = $5;

        if (t->id[0] == 'f')
          fprintf(obj, "\tRR0=D(R7);\n\tR1=P(R7+8);\n\tD(R1)=RR0;\n\tR7=R7+16;\n");
        else
          fprintf(obj, "\tR0=I(R7);\n\tR1=P(R7+4);\n\tI(R1)=R0;\n\tR7=R7+4;\n");
      }
  ;

if:
    IF '(' logico ')'
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

while:
    WHILE
      {
        $<entero>$ = ++et;
        fprintf(obj, "L %d:\n", et);
      }
    '(' logico ')'
      {
        $<entero>$ = ++et;
        fprintf(obj, "\tR0=I(R7);\n\tIF(!R0) GT(%d);\n", $<entero>$);
      }
    sentbloq
      {
        fprintf(obj, "GT(%d);\n\tL %d:\t", $<entero>2, $<entero>6);
      }
  ;

for: 
    FOR '(' asg-variable ';'
      { // Ampliar tipo de sentencias que caben aqui
        $<entero>$ = ++et;
        fprintf(obj, "L %d:\n", et);
      }
    logico
      {
        $<entero>$ = ++et;
        fprintf(obj, "\tR0=I(R7);\n\tIF(!R0) GT(%d);\n", $<entero>$);
      }
    ';'
      {
        et = et + 2;
        $<entero>$ = et;
        fprintf(obj, "\tGT(%d);\nL %d:\n", et - 1, et);
      }
    asg-variable ')'
      {
        fprintf(obj, "\tGT(%d);\nL %d:\n", $<entero>5, et - 1);
      }
    sentbloq
      {
        fprintf(obj, "\tGT(%d);\nL %d:\n", $<entero>9, $<entero>7);
      }
  ;

print:
    PRINT '(' prn-expresion ')'
      {
        ++et;
        fprintf(obj, "\tR5=%d;\n\tGT(print);\nL %d:\tR7=R7+4;\n", et, et); 
      }
  | PRINTLN '(' prn-expresion ')'
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

prn-expresion:
    entero
  | logico
  | exp-funcion
  ;

exp-funcion: 
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
        // TODO
      }
  ;

params-uso:
    IDENTIF
  | IDENTIF ',' params-uso
  ;

expresion:
    entero
      { // Mover codigo a asg-variable retornando en $$ el tamaño de tipo
        $$ = buscat("int", tipo);
      }
  | real
      {
        $$ = buscat("float", tipo);
      }
  | logico
      {
        $$ = buscat("bool", tipo);
      }
  | exp-funcion
  ;

entero:
    entero '+' entero
      {
        fprintf(
          obj, 
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1+R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
      }
  | entero '-' entero
      {
        fprintf(
          obj, 
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1-R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
      }
  | entero '*' entero
      {
        fprintf(
          obj, 
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1*R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
      }
  | entero '%' entero
      {
        fprintf(
          obj, 
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1%cR0;\n\tR7=R7+4;\n\tI(R7)=R0;\n",
          '%'
        );
      }
  | entero POTENCIA entero
  | '-' entero
      {
        fprintf(
          obj, 
          "\tR0=I(R7);\n\tR0=-R0;\n\tI(R7)=R0;\n"
        );
      }
  | INCREMENTO IDENTERO
      {
        // Se busca la variable
        struct reg *p = buscat($2, varl);

        if (p!=NULL) 
          fprintf(obj, "\tR0=I(R6%d);\n\tR1=R6%d;\n", p->dir, p->dir);
        else {
          p = buscat($1,varg);

          if (p!=NULL) // Revisar
            fprintf(obj, "\tR0=I(0x%x);\n\tR1=0x%x;\n", p->dir, p->dir);
          else 
            yyerror("3: variable no declarada"); 
        }

        // Se modifica la variable
        fprintf(
          obj, 
          "\tR0=R0+1;\n\tR7=R7-4;\n\tI(R7)=R0;\n\tI(R1)=R0;\n"
        );
      }
  | IDENTERO INCREMENTO
      {
        // Se busca la variable
        struct reg *p = buscat($1, varl);

        if (p!=NULL) 
          fprintf(obj, "\tR0=I(R6%d);\n\tR1=R6%d;\n", p->dir, p->dir);
        else {
          p = buscat($1,varg);

          if (p!=NULL) // Revisar
            fprintf(obj, "\tR0=I(0x%x);\n\tR1=0x%x;\n", p->dir, p->dir);
          else 
            yyerror("3: variable no declarada"); 
        }

        // Se modifica la variable
        fprintf(
          obj, 
          "\tR7=R7-4;\n\tI(R7)=R0;\n\tR0=R0+1;\n\tI(R1)=R0;\n"
        );
      }
  | DECREMENTO IDENTERO
      {
        // Se busca la variable
        struct reg *p = buscat($2, varl);

        if (p!=NULL) 
          fprintf(obj, "\tR0=I(R6%d);\n\tR1=R6%d;\n", p->dir, p->dir);
        else {
          p = buscat($1,varg);

          if (p!=NULL) // Revisar
            fprintf(obj, "\tR0=I(0x%x);\n\tR1=0x%x;\n", p->dir, p->dir);
          else 
            yyerror("3: variable no declarada"); 
        }

        // Se modifica la variable
        fprintf(
          obj, 
          "\tR0=R0-1;\n\tR7=R7-4;\n\tI(R7)=R0;\n\tI(R1)=R0;\n"
        );
      }
  | IDENTERO DECREMENTO
      {
        // Se busca la variable
        struct reg *p = buscat($1, varl);

        if (p!=NULL) 
          fprintf(obj, "\tR0=I(R6%d);\n\tR1=R6%d;\n", p->dir, p->dir);
        else {
          p = buscat($1,varg);

          if (p!=NULL) // Revisar
            fprintf(obj, "\tR0=I(0x%x);\n\tR1=0x%x;\n", p->dir, p->dir);
          else 
            yyerror("3: variable no declarada"); 
        }

        // Se modifica la variable
        fprintf(
          obj, 
          "\tR7=R7-4;\n\tI(R7)=R0;\n\tR0=R0-1;\n\tI(R1)=R0;\n"
        );
      }
  | '(' entero ')'
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
  | entero '/' entero
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

logico:
    entero '<' entero
      {
        fprintf(
          obj,
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1<R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
      }
  | entero MNIG entero
    {
        fprintf(
          obj,
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1<=R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
    }
  | entero '>' entero
    {
        fprintf(
          obj,
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1>R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
    }
  | entero MYIG entero
    {
        fprintf(
          obj,
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1>=R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
    }
  | entero IGUAL entero
    {
        fprintf(
          obj,
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1==R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
    }
  | entero DESIGUAL entero
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
  | logico AND logico
      {
        fprintf(
          obj,
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1&&R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
      }
  | logico OR logico
      {
        fprintf(
          obj,
          "\tR0=I(R7);\n\tR1=I(R7+4);\n\tR0=R1||R0;\n\tR7=R7+4;\n\tI(R7)=R0;\n"
        );
      }
  | '!' logico
      {
        fprintf(
          obj,
          "\tR0=I(R7);\n\tR0=!R0;\n\tI(R7)=R0;\n"
        );
      }
  | '(' logico ')'
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

sen-especial:
    BREAK
  | CONTINUE
  | return
  ;

return:
    RETURN
      {
        // TODO: + return expresion
      }
  ;

id:
    IDENTERO  { $$ = $1; }
  | IDREAL    { $$ = $1; }
  | IDLOGICO  { $$ = $1; }
  | IDENTIF   { $$ = $1; /*milex no encuentra -> a fuerza con esto*/ }
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
