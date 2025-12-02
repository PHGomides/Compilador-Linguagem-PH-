all:
	flex AnalisadorLexico.l
	bison -d AnalisadorLexico.y
	clang++ -std=c++20 -g -O1 -x c++ *.c -o cmp
	./cmp valid1.txt
	./cmp valid2.txt
	./cmp valid3.txt
	./cmp syntax1.txt
	./cmp syntax2.txt
	./cmp syntax3.txt
	./cmp semantic1.txt
	./cmp semantic2.txt
	./cmp semantic3.txt


clean:
	rm -f lex.yy.c AnalisadorLexico.tab.c AnalisadorLexico.tab.h cmp