%{
#include "milex.tab.h"
#include <stdio.h>
#include <stdbool.h>
#include "ts.h"

int numlin = 0;
extern FILE *obj; 
char *linact;
bool prlin = false;

void cpystr() {
    yylval.symbol=(char*) malloc(sizeof(char) * (strlen(yytext) + 1));
    strcpy(yylval.symbol, yytext);
}
%}

letra   [a-zA-Z]
digito  [0-9]
letdig  {letra}|{digito}

%option noyywrap
%x LEELIN
%%
	if (numlin == 0) {
        BEGIN(LEELIN);
        numlin++;
    }
	if (prlin) { 
        fprintf(obj, "\t\t\t/\/ %d: %s\n", numlin, linact); 
	    free(linact);
        prlin = false; 
    }
<LEELIN>^.*	                { linact = strdup(yytext); prlin = true; yyless(0); BEGIN(INITIAL); }
<LEELIN>\n	                { numlin++; }
{digito}+                   { yylval.entero=atoi(yytext); return ENTERO; }
{digito}*"."{digito}+       { yylval.real=atof(yytext); return REAL; }
{digito}+"."{digito}*       { yylval.real=atof(yytext); return REAL; }
"true"|"false"              { yylval.entero = yytext[0] == 'f' ? 0 : 1; return LOGICO; }
\"([^"]|(\*+[^"\/]))*\"     { cpystr(); return CADENA; }
\'([^'']|(\*+[^'\/]))*\'    { cpystr(); return CADENA; }
"int"                       { yylval.symbol = strdup(yytext); return INT; }
"float"                     { yylval.symbol = strdup(yytext); return FLOAT; }
"bool"                      { yylval.symbol = strdup(yytext); return BOOL; }
"string"                    { yylval.symbol = strdup(yytext); return STRING; }
"struct"                    { yylval.symbol = strdup(yytext); return STRUCT; }
"void"                      { yylval.symbol = strdup(yytext); return VOID; }
"if"                        { return IF; }
"else"                      { return ELSE; }
"for"                       { return FOR; }
"while"                     { return WHILE; }
"break"                     { return BREAK; }
"continue"                  { return CONTINUE; }
"return"                    { return RETURN; }
"print"                     { return PRINT; }
"println"                   { return PRINTLN; }
{letra}({letdig}|[_])*      { 
                                yylval.symbol = strdup(yytext);
                                struct reg *p = buscat(yytext, varl);

                                if (p!=NULL) {
                                    switch(p->tip->id[0]) {
                                        case 'f': return IDREAL;
                                        case 'i': return IDENTERO;
                                        case 'b': return IDLOGICO;
                                    }
                                } else {
                                    p = buscat(yytext, varg);

                                    if (p!=NULL) {
                                        switch(p->tip->id[0]) {
                                            case 'f': return IDREAL;
                                            case 'i': return IDENTERO;
                                            case 'b': return IDLOGICO;
                                        }
                                    }
                                }
                                return IDENTIF;
                            }
"++"                        { return INCREMENTO; }
"--"                        { return DECREMENTO; }
"**"                        { return POTENCIA; }
"&&"                        { return AND; }
"||"                        { return OR; }
"<="                        { return MNIG; }
">="                        { return MYIG; }
"=="                        { return IGUAL; }
"!="                        { return DESIGUAL; }
[-+=*/%<>!.]                { return yytext[0]; }
[;:,(){}[\]]                { return yytext[0]; }
\n                          { numlin++; BEGIN(LEELIN);}  
[ \t]                       
"//".*                      
"/*"([^*]|(\*+[^*/]))*\*+"/"
.                           { printf("flex error: '%c'\n", yytext[0]); }
%%
