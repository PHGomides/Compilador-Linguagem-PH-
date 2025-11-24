all:
	flex AnalisadorLexico.l
	bison -d AnalisadorLexico.y
	gcc AnalisadorLexico.tab.c lex.yy.c -o cmp
	./cmp Funcional1.txt