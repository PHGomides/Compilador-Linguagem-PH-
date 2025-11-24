all:
	flex AnalisadorLexico.l
	bison -d AnalisadorLexico.y
	clang++ -std=c++20 -g -O1 *.c -o cmp
	./cmp Funcional1.txt

clean:
	rm -f lex.yy.c AnalisadorLexico.tab.c AnalisadorLexico.tab.h cmp