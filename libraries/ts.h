enum categ { tipo, varg, varl, rut};
extern char *inicat;

extern struct reg {
  char *id; 
  enum categ cat;  
  union {
    int tam;
    struct {
      struct reg *tip;
      int dir;
    };
  };
  struct reg *sig;
} *top;

struct reg *busq(char *id);
struct reg *buscat(char *id, enum categ cat);
struct reg *ins(char *id, enum categ cat);
void inst(char *id, int tam);
struct reg *insvr(char *id, enum categ cat, struct reg *tp, int dir);
void finbloq();
void dump(const char* s);
