
F=tests/ejts.f

all: dist/milex $(F)
	./dist/milex $(F) 2>/dev/null

clean:
	rm -f dist/*

dist/milex: dist/milex.tab.c dist/lex.yy.c
	gcc -o dist/milex libraries/ts.c dist/milex.tab.c dist/lex.yy.c

dist/lex.yy.c: src/milex.l dist/milex.tab.h
	flex -o dist/lex.yy.c src/milex.l

dist/milex.tab.c: src/milex.y libraries/ts.c libraries/ts.h
	bison -b dist/milex -dvt src/milex.y
