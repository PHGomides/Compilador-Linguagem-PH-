%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <iostream>
#include "node.h"
#include "AnalisadorLexico.tab.h"

int yyerror(const char *s);

char *build_file_name;
int contagemErros = 0;
%}

%option yylineno

%%
[ \t\r\n]       { }
"print"         { return TOK_PRINT; }
"let"           { return TOK_LET; }
"if"            { return TOK_IF; }  
"else"          { return TOK_ELSE; }
"while"         { return TOK_WHILE; }
"for"           { return TOK_FOR; }
"do"            { return TOK_DO; } 
"+"             { return '+'; }
"-"             { return '-'; }
"*"             { return '*'; }
"/"             { return '/'; }
":"             { return ':'; }
"("             { return '('; }
")"             { return ')'; }
"{"             { return '{'; }
"}"             { return '}'; }
";"             { return ';'; }
"="             { return '='; }
"=="            { return TOK_EQ; }
"!="            { return TOK_NE; }
"<"             { return '<'; }
">"             { return '>'; }
"<="            { return TOK_LE; }
">="            { return TOK_GE; }
"&&"            { return TOK_AND; }
"||"            { return TOK_OR; }
"!"             { return '!'; }
"true"          { yylval.valor_int = 1; return TOK_BOOL; } 
"false"         { yylval.valor_int = 0; return TOK_BOOL; } 

[0-9]+          { yylval.valor_int = atoi(yytext); return TOK_INT; }
[0-9]+\.[0-9]+  { yylval.valor_float = atof(yytext); return TOK_FLT; }
[a-zA-Z_][a-zA-Z_0-9]* { yylval.nome = strdup(yytext); return TOK_IDENT; }

. { 
    fprintf(stderr, "Erro Lexico na linha %d: Caractere invalido '%c'\n", yylineno, yytext[0]);
    contagemErros++;
}
%%

int yywrap() { return 1; }

int yyerror(const char *s) {
    fprintf(stderr, "Erro Sintatico na linha %d: %s\n", yylineno, s);
    contagemErros++;
    return 1;
}

int main(int argc, char *argv[]) {
    if (argc <= 1) {
        fprintf(stderr, "Uso: %s arquivo_fonte\n", argv[0]);
        return 1;
    }
    build_file_name = argv[1];
    yyin = fopen(build_file_name, "r");
    if (yyin == NULL) {
        fprintf(stderr, "Erro fatal: Nao foi possivel abrir o arquivo %s.\n", build_file_name);
        return 1;
    }

    printf("Iniciando compilacao de: %s\n", build_file_name);
    
    yyparse();

    if (yyin) fclose(yyin);

    printf("\n----------------------------------\n");
    if (contagemErros == 0) {
        printf("SUCESSO: O codigo foi compilado sem erros.\n");
    } else {
        printf("FALHA: Encontrados %d erro(s) durante a compilacao.\n", contagemErros);
    }
    printf("----------------------------------\n");

    return contagemErros;
}