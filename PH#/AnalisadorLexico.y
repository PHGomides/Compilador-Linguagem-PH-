
%{
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <stdlib.h>
int yyerror(const char *s);
int yylex(void);
int errorc = 0;

typedef struct {
    char *nome;
    int token;
} simbolo;

struct syntaticno{
     int id;
     char *label;
     simbolo *sim;
     float constvalue;
     int qtdfilhos;
     struct syntaticno *filhos[1];
};
typedef struct syntaticno syntaticno;

int simbolo_qtd = 0;
simbolo tabela_simbolos[100];
simbolo *simbolo_novo(char *nome, int token);
simbolo *simbolo_existe(char *nome);
syntaticno *novo_syntaticno(char *labeL, int filhos);
void debug(syntaticno *root);
   

%}

%define parse.error verbose

%union {
    char *nome;
    int valor_int;
    float valor_float;
    struct syntaticno *no;
}

%token TOK_PRINT TOK_INT TOK_FLT TOK_IDENT
%token TOK_LET

%left '+' '-'
%left '*' '/'

%type <nome> TOK_IDENT
%type <valor_int> TOK_INT
%type <valor_float> TOK_FLT
%type <no> program stmts stmt declaracao atribuicao comando_print tipo_unidade fator_unidade expr term factor

%start program

%%

program : stmts     { if (errorc > 0) 
                         printf("Compilação finalizada com %d erros\n", errorc); 
                    else 
                         printf("Compilação finalizada sem erros\n");
                         syntaticno *root = novo_syntaticno("STMTS", 1);
                         root->filhos[0] = $1;
                         debug(root);
                    }
        ;

stmts :          { $$ = NULL; }
      | stmts stmt { 
                 if ($1 == NULL) 
                     $$ = $2; 
                 else {
                     $$ = novo_syntaticno("stmts", 2);
                               $$->filhos[0] = $1;
                               $$->filhos[1] = $2;
                 }
               }
      ;


stmt : declaracao {$$ = $1;}
     | atribuicao {$$ = $1;}
     | comando_print {$$ = $1;}
     ;


/* ANOTAÇÃO: "let velocidade : m\s = 40;" Dessa forma a minha linguagem define a unidade de media da variavel*/
/* OBJETIVO: Linguagem fazer o tratamento de operações considerando unidade de medida*/

declaracao : TOK_LET TOK_IDENT ':' tipo_unidade '=' expr ';' {
                 syntaticno *var_node = novo_syntaticno("IDENT", 0);
                 simbolo *s = simbolo_existe($2);
                 if (!s) 
                     s = simbolo_novo($2, TOK_IDENT);
                 var_node->sim = s;
                 
                 $$ = novo_syntaticno("LET", 3);
                 $$->filhos[0] = var_node;
                 $$->filhos[1] = $4;
                 $$->filhos[2] = $6;
               }
           ;

atribuicao : TOK_IDENT '=' expr ';' {
                 syntaticno *var_node = novo_syntaticno("IDENT", 0);
                 var_node->sim = simbolo_existe($1);
                 if (!var_node->sim) yyerror("Variavel nao declarada");
                 
                 $$ = novo_syntaticno("=", 2);
                 $$->filhos[0] = var_node;
                 $$->filhos[1] = $3;
             }
           ;

comando_print : TOK_PRINT expr ';' {
                         $$ = novo_syntaticno("PRINT", 1); 
                         $$->filhos[0] = $2; 
                        }
              ;

tipo_unidade : fator_unidade  {$$ = $1;}
             | tipo_unidade '*' fator_unidade {
                         $$ = novo_syntaticno("*", 2); 
                         $$->filhos[0] = $1; 
                         $$->filhos[1] = $3;
                        }
             | tipo_unidade '/' fator_unidade {
                         $$ = novo_syntaticno("/", 2); 
                         $$->filhos[0] = $1; 
                         $$->filhos[1] = $3;
                        }
             ;

fator_unidade : TOK_IDENT { simbolo *s = simbolo_existe($1);
                     if (!s) 
                         s = simbolo_novo($1, TOK_IDENT);
                     $$ = novo_syntaticno("IDENT", 0);
                     $$->sim = s;
                    }
              | '(' tipo_unidade ')' { 
                         $$ = novo_syntaticno("()", 1); 
                         $$->filhos[0] = $2; 
                         }
              ;


expr : expr '+' term {
               $$ = novo_syntaticno("+", 2); 
               $$->filhos[0] = $1; 
               $$->filhos[1] = $3;
               }
     | expr '-' term {
               $$ = novo_syntaticno("-", 2); 
               $$->filhos[0] = $1; 
               $$->filhos[1] = $3;
               }
     | term {$$ = $1;}
     ;

term : term '*' factor {
               $$ = novo_syntaticno("*", 2); 
               $$->filhos[0] = $1; 
               $$->filhos[1] = $3;
               }
     | term '/' factor {
               $$ = novo_syntaticno("/", 2); 
               $$->filhos[0] = $1; 
               $$->filhos[1] = $3;
               }
     | factor       {$$ = $1;}
     ;

factor : '(' expr ')' { 
               $$ = novo_syntaticno("()", 1); 
               $$->filhos[0] = $2; 
               }
       | TOK_INT { 
               $$ = novo_syntaticno("INT", 0);
               $$->constvalue = $1;
               }
       | TOK_FLT {
               $$ = novo_syntaticno("FLOAT", 0);
               $$->constvalue = $1;
               }
       | TOK_IDENT { simbolo *s = simbolo_existe($1);
                     if (!s) 
                         s = simbolo_novo($1, TOK_IDENT);
                     $$ = novo_syntaticno("IDENT", 0);
                     $$->sim = s;
                    }
       ;

%%

int yywrap(void) {
    return 1;
}

int yyerror(const char *s) {
     errorc++; 
     printf("Erro: %d: %s\n", errorc, s);
    return 1;
}

simbolo *simbolo_novo(char *nome, int token) {
     tabela_simbolos[simbolo_qtd].nome = nome;
     tabela_simbolos[simbolo_qtd].token = token;
     simbolo *result = &tabela_simbolos[simbolo_qtd];
     simbolo_qtd++;
     return result;
}

simbolo *simbolo_existe(char *nome) {
     for (int i = 0; i < simbolo_qtd; i++) {
         if (strcmp(tabela_simbolos[i].nome, nome) == 0) {
             return &tabela_simbolos[i];
         }
     }
     return NULL;
}

syntaticno *novo_syntaticno(char *label, int filhos) {
     static int nid = 0;
     int s = sizeof(syntaticno);
     if (filhos > 1)
         s += sizeof(syntaticno*) * (filhos - 1);
     syntaticno  *n = (syntaticno*)calloc(1, s);
     n->id = nid++;
     n->label = label;
     n->qtdfilhos = filhos;
     return n;
}

void print_tree(syntaticno *n) {
     if (n->sim)
          printf("\tn%d [label=\"%s\"];\n", n->id, n->sim->nome);
     else if (strcmp(n->label, "INT") == 0)
          printf("\tn%d [label=\"%g\"];\n", n->id, n->constvalue);
     else if (strcmp(n->label, "FLOAT") == 0)
          printf("\tn%d [label=\"%g\"];\n", n->id, n->constvalue);
     else
          printf("\tn%d [label=\"%s\"];\n", n->id, n->label);

     for (int i = 0; i < n->qtdfilhos; i++) 
         print_tree(n->filhos[i]);
     for (int i = 0; i < n->qtdfilhos; i++) 
          printf("\tn%d -- n%d;\n", n->id, n->filhos[i]->id);
}

void debug(syntaticno *no) {
     printf("Símbolos:\n");
     for (int i = 0; i < simbolo_qtd; i++) {
         printf("Nome: %s, Token: %d\n", tabela_simbolos[i].nome, tabela_simbolos[i].token);
     }
     printf("\nÁrvore Sintática Abstrata:\n");
     printf("graph prog {\n");
     print_tree(no);
     printf("}\n");
}


int main() {
     yyparse();
}