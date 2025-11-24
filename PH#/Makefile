all:
	flex AnalisadorLexico.l
	bison -d AnalisadorLexico.y
	clang++ -std=c++20 -g -O1 -x c++ *.c -o cmp
	./cmp teste.txt

clean:
	rm -f lex.yy.c AnalisadorLexico.tab.c AnalisadorLexico.tab.h cmp