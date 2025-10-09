all:
	flex AnalisadorLexico.l
	bison -d AnalisadorLexico.y
	gcc AnalisadorLexico.tab.c lex.yy.c -o cmp
	./cmp Funcional1.txt
	./cmp Funcional2.txt
	./cmp Funcional3.txt
	./cmp NAOFuncional1.txt
	./cmp NAOFuncional2.txt
	./cmp NAOFuncional3.txt