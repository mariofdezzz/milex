# Makefile basico para no andar repitiendo comandos para generar,
# compilar y ejecutar. A ampliar para testear y en siguientes fases. 

# make milex	[genera] lexico desde milex.l
# make F=n.x	[genera] y ejecuta lexico sobre n.x; via stdin: make<n.x

all: milex $(F)
	./milex $(F)

milex: milex.l milex.y
	bison -d milex.y
	flex milex.l
	gcc -o milex milex.tab.c lex.yy.c -lm
	make clean

debug: milex.l milex.y
	bison -dvt milex.y
	flex milex.l
	gcc -o milex milex.tab.c lex.yy.c -lm
	make clean

clean:
	rm -f lex.yy.c milex.tab.c milex.tab.h

clean-all:
	rm -f lex.yy.c milex milex.tab.c milex.tab.h milex.output

# "No rule to make target" T si no encuentra ni puede crear T.
# Por supuesto, no regenera milex si no es necesario.
