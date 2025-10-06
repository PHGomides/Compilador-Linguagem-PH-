%{
#include <stdio.h>
#include "AnalisadorLexico.tab.h"
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
[0-9]+\.[0-9]+  { 
    yylval.valor_float = atof(yytext);
    return TOK_FLT; 
}
[0-9]+          { 
    yylval.valor_int = atoi(yytext);
    return TOK_INT; 
}
[a-zA-Z_][a-zA-Z_0-9]* { 
    yylval.nome = strdup(yytext);
    return TOK_IDENT; 
}

.               { printf("Caractere não presente no alfabeto %c\n", yytext[0] ); }
%%