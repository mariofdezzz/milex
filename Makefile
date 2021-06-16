
F = test/ejgc.f
O = dist/obj.q.c

# Comands
all run: $(O) dist/iq
	cd dist && ./iq obj.q.c

debug: dist/milex $(F)
	dist/milex $(F) $(O) 2>dist/.output

clean:
	rm -f dist/*
	rm -f dist/.[A-Za-z]*

# Helpers
$(O): dist/milex $(F)
	dist/milex $(F) $(O) 2>/dev/null

comp dist/milex: dist/ts.c dist/milex.tab.c dist/lex.yy.c 
	gcc -g -o dist/milex dist/ts.c dist/milex.tab.c dist/lex.yy.c

flex dist/lex.yy.c: src/milex.l dist/milex.tab.h
	flex -o dist/lex.yy.c src/milex.l

bison dist/milex.tab.c: src/milex.y dist/ts.h dist/Qlib.h
	bison -b dist/milex -dvt src/milex.y

IQ = IQ.o
V = Q-v3.7.3

iq dist/iq: dist/$(IQ) dist/Qlib.c dist/Qlib.h dist/Q.h 
	gcc -no-pie -o dist/iq dist/$(IQ) dist/Qlib.c

dist/$(IQ) dist/Q.h: $(V)/*
	cp $(V)/* dist/

dist/Qlib.c dist/Qlib.h dist/ts.c dist/ts.h: libraries/*
	cp libraries/* dist/
