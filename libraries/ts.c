#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stddef.h>

#include "ts.h"

char *inicat = "TGLR";
struct reg * top = NULL;

struct reg *busq(char *id) {
  struct reg *p = top;

  while (p!=NULL && strcmp(p->id, id)!=0) 
    p=p->sig;

  return p;
}

struct reg *buscat(char *id, enum categ cat) {
  struct reg *p = busq(id); 

  if (p!=NULL && p->cat==cat)
    return p;
  else 
    return NULL;
}

struct reg *ins(char *id, enum categ cat) {
  if (busq(id)!=NULL) 
    yyerror("-1: nombre ya definido");

  struct reg *p = (struct reg *)malloc(sizeof(struct reg));
  p->id=id; 
  p->cat=cat; 
  p->sig = top;
  top = p;

  return p;
}

void inst(char *id, int tam) {
  struct reg *p = ins(id, tipo);
  p->tip=NULL;
  p->tam=tam;
}

struct reg *insvr(char *id, enum categ cat, struct reg *tp, int dir) {
  struct reg *p = ins(id, cat);
  p->tip=tp;
  p->dir=dir;

  return p;
}

void finbloq() {
  while (top!=NULL && top->cat!=rut) {
    struct reg *p = top->sig;
    free(top->id); free(top); top=p;
  }
}

void dump(const char* s) {
  printf("  DUMP: %s\n", s);
  
  struct reg *p = top;

  while (p!=NULL) {
    printf("0x%x %c %s", (int)p, inicat[p->cat], p->id);
    
    if (p->cat==tipo) 
      printf(" %d\n", p->tam);
    else {
      printf(" %s", p->tip->id);
      if (p->cat==varg) printf(" 0x%x\n", p->dir);
      if (p->cat==varl) printf(" %d\n", p->dir);
      if (p->cat==rut) printf(" L_%d\n", p->dir);
    }
    p=p->sig;
  }
}
