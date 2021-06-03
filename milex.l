%{
#include "milex.tab.h"
#include <stdio.h>

int numlin = 1;

void cpystr() {
    yylval.symbol=(char*) malloc(sizeof(char) * (strlen(yytext) + 1));
    strcpy(yylval.symbol, yytext);
}
%}

letra   [a-zA-Z]
digito  [0-9]
letdig  {letra}|{digito}

%option noyywrap
%%
{digito}+               {yylval.entero=atoi(yytext); return ENTERO;}
{digito}*"."{digito}+   {yylval.real=atof(yytext); return REAL;}
{digito}+"."{digito}*   {yylval.real=atof(yytext); return REAL;}
"true"|"false"          {yylval.entero = yytext[0] == 'f' ? 0 : 1; return LOGICO;}
\"([^"]|(\*+[^"\/]))*\"     {cpystr(); return CADENA;}
\'([^'']|(\*+[^'\/]))*\'    {cpystr(); return CADENA;}
"int"                   {  yylval.symbol = strdup(yytext); return INT; }
"float"                 {  yylval.symbol = strdup(yytext); return FLOAT; }
"bool"                  {  yylval.symbol = strdup(yytext); return BOOL; }
"string"                {  yylval.symbol = strdup(yytext); return STRING; }
"struct"                {  yylval.symbol = strdup(yytext); return STRUCT; }
"void"                  {  yylval.symbol = strdup(yytext); return VOID; }
("int"|"float"|"bool"|"string")"[]"     {  yylval.symbol = strdup(yytext); return ARRAY; }
"if"                    { return IF; }
"else"                  { return ELSE; }
"switch"                { return SWITCH; }
"case"                  { return CASE; }
"default"               { return DEFAULT; }
"for"                   { return FOR; }
"in"                    { return IN; }
"while"                 { return WHILE; }
"break"                 { return BREAK; }
"continue"              { return CONTINUE; }
"return"                { return RETURN; }
"new"                   { return NEW; }
"print"                 { return PRINT; }
"println"               { return PRINTLN; }
{letra}({letdig}|[-_])* { yylval.symbol = strdup(yytext); return IDENTIF; }
"++"                    {return INCREMENTO;}
"--"                    {return DECREMENTO;}
"**"                    {return POTENCIA;}
"&&"                    {return AND;}
"||"                    {return OR;}
"<="                    {return MNIG;}
">="                    {return MYIG;}
"=="                    {return IGUAL;}
"!="                    {return DESIGUAL;}
[-+=*/%<>!.]            {return yytext[0];}
[;:,(){}[\]]            {return yytext[0];}
\n                      {numlin++; return yytext[0];} 
[ \t]                           {}
"//".*                          {}
"/*"([^*]|(\*+[^*/]))*\*+"/"    {}
.                       {yyerror("Error lexico");}
<<EOF>>                 {return 0; /* por defecto */}
%%
