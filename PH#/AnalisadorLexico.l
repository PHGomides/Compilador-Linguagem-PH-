%{
#include <stdio.h>
#include "AnalisadorLexico.tab.h"
%}

%option yylineno

%%
[ \t\r\n]       { }
"print"         { return TOK_PRINT; }
"let"           { return TOK_LET; }
"+"             { return '+'; }
"-"             { return '-'; }
"*"             { return '*'; }
"/"             { return '/'; }
":"             { return ':'; }
"("             { return '('; }
")"             { return ')'; }
";"             { return ';'; }
"="             { return '='; }
[0-9]+          { 
    yylval.valor_int = atoi(yytext);
    return TOK_INT; 
}
[0-9]+\.[0-9]+  { 
    yylval.valor_float = atof(yytext);
    return TOK_FLT; 
}
[a-zA-Z_][a-zA-Z_0-9]* { 
    yylval.nome = strdup(yytext);
    return TOK_IDENT; 
}

.               { printf("Caractere não presente no alfabeto %c\n", yytext[0] ); }
%%
