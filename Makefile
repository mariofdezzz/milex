# make milex	[genera] lexico desde milex.l
# make F=n.x	[genera] y ejecuta lexico sobre n.x; via stdin: make<n.x

all: milex $(F)
	./milex $(F)

# milex: milex.l milex.y
# 	bison -d milex.y
# 	flex milex.l
# 	gcc -o milex milex.tab.c lex.yy.c -lm
# 	make clean

# debug: milex.l milex.y
# 	bison -dvt milex.y
# 	flex milex.l
# 	gcc -o milex milex.tab.c lex.yy.c -lm
# 	make clean

clean:
	rm -f lex.yy.c milex.tab.c milex.tab.h

clean-all:
	rm -f lex.yy.c milex milex.tab.c milex.tab.h milex.output

ts: milex.tab.c lex.yy.c
	gcc -o milex ts.c milex.tab.c lex.yy.c

lex.yy.c: milex.l milex.tab.h
	flex milex.l

milex.tab.c: milex.y ts.c ts.h
	bison -dvt milex.y


# "No rule to make target" T si no encuentra ni puede crear T.
# Por supuesto, no regenera milex si no es necesario.
