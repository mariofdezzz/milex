#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stddef.h>

#include "ts.h"

char *inicat = "TGLR";
struct reg * top = NULL;

struct reg *busq(char *id) {
  struct reg *p = top;
  while (p!=NULL && strcmp(p->id, id)!=0) p=p->sig;
  return p;
}

struct reg *buscat(char *id, enum categ cat) {
  struct reg *p = busq(id); 
  if (p!=NULL && p->cat==cat) return p; else return NULL;
}

void ins(char *id, enum categ cat, struct reg *tp) {
  if (busq(id)!=NULL) yyerror("-1: nombre ya definido");
  struct reg *p = (struct reg *)malloc(sizeof(struct reg));
  p->id=id; p->cat=cat; p->tip=tp;
  p->sig = top;
  top = p;
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
    printf("0x%x %c %s %s\n", (int)p, inicat[p->cat], p->id, p->tip==NULL?"·":p->tip->id);
    p=p->sig;
  }
}
