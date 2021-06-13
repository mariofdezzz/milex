
F = tests/ejts.f
O = dist/obj.q.c

all: dist/milex $(F)
	dist/milex tests/ejgc.f $(O) 2>dist/output

debug: dist/milex $(F)
	./dist/milex $(F) 2>dist/output

clean:
	rm -f dist/*

comp dist/milex: dist/milex.tab.c dist/lex.yy.c
	gcc -g -o dist/milex libraries/ts.c dist/milex.tab.c dist/lex.yy.c

flex dist/lex.yy.c: src/milex.l dist/milex.tab.h
	flex -o dist/lex.yy.c src/milex.l

bison dist/milex.tab.c: src/milex.y libraries/ts.c libraries/ts.h
	bison -b dist/milex -dvt src/milex.y
