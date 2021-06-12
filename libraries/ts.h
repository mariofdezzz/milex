enum categ { tipo, varg, varl, rut};
extern char *inicat;

extern struct reg {
  char *id; 
  enum categ cat;
  struct reg *tip;
  struct reg *sig;
} *top;

struct reg *busq(char *id);
struct reg *buscat(char *id, enum categ cat);
void ins(char *id, enum categ cat, struct reg *tp);
void finbloq();
void dump(const char* s);
