
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
    double valor_float;
    struct syntaticno *no;
}

%token TOK_PRINT TOK_INT TOK_FLT TOK_IDENT
%token TOK_LET TOK_IF TOK_ELSE TOK_WHILE TOK_FOR TOK_DO
%token TOK_EQ TOK_NE TOK_LE TOK_GE TOK_AND TOK_OR


%type <nome> TOK_IDENT
%type <valor_int> TOK_INT
%type <valor_float> TOK_FLT
%type <no> program stmts declaracao atribuicao comando_print tipo_unidade fator_unidade
%type <no> expr expr_ou expr_e expr_igualdade expr_relacional expr_arit term unary factor
%type <no> bloco comando_do_while
%type <no> stmt stmt_completo stmt_incompleto comando_while_completo

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

stmts :              { $$ = NULL; }
      | stmts stmt   { 
                         if ($1 == NULL) 
                             $$ = $2;
                         else {
                             $$ = novo_syntaticno("stmts", 2);
                             $$->filhos[0] = $1;
                             $$->filhos[1] = $2;
                         }
                       }
      ;

stmt : stmt_incompleto { $$ = $1; }
     | stmt_completo   { $$ = $1; }
     ;

stmt_completo : atribuicao { $$ = $1; }
              | declaracao { $$ = $1; }
              | comando_print { $$ = $1; }
              | bloco { $$ = $1; }
              | comando_do_while { $$ = $1; }
              | comando_while_completo { $$ = $1; }
              | TOK_IF '(' expr ')' stmt_completo TOK_ELSE stmt_completo {
                    $$ = novo_syntaticno("IF", 3);
                    $$->filhos[0] = $3;
                    $$->filhos[1] = $5;
                    $$->filhos[2] = $7;
                }
              ;


stmt_incompleto : TOK_IF '(' expr ')' stmt {
                      $$ = novo_syntaticno("IF", 2);
                      $$->filhos[0] = $3;
                      $$->filhos[1] = $5;
                  }
                | TOK_IF '(' expr ')' stmt_completo TOK_ELSE stmt_incompleto {
                      $$ = novo_syntaticno("IF", 3);
                      $$->filhos[0] = $3;
                      $$->filhos[1] = $5;
                      $$->filhos[2] = $7;
                  }
                ;

bloco : '{' stmts '}' { $$ = $2; }
      ;


comando_while_completo : TOK_WHILE '(' expr ')' stmt_completo {
                            $$ = novo_syntaticno("WHILE", 2);
                            $$->filhos[0] = $3;
                            $$->filhos[1] = $5;
                         }
                       ;

comando_do_while : TOK_DO stmt TOK_WHILE '(' expr ')' ';' {
                       $$ = novo_syntaticno("DO_WHILE", 2);
                       $$->filhos[0] = $2;
                       $$->filhos[1] = $5;
                   }
                 ;

expr : expr_ou { $$ = $1; }
     ;

expr_ou : expr_ou TOK_OR expr_e   { 
                    $$ = novo_syntaticno("||", 2); 
                    $$->filhos[0] = $1; 
                    $$->filhos[1] = $3; 
                    }
        | expr_e  { $$ = $1; }
        ;


expr_e : expr_e TOK_AND expr_igualdade { 
                         $$ = novo_syntaticno("&&", 2); 
                         $$->filhos[0] = $1; 
                         $$->filhos[1] = $3; 
                         }
       | expr_igualdade  { $$ = $1; }
       ;


expr_igualdade : expr_igualdade TOK_EQ expr_relacional { 
                                        $$ = novo_syntaticno("==", 2); 
                                        $$->filhos[0] = $1; 
                                        $$->filhos[1] = $3; 
                                   }
               | expr_igualdade TOK_NE expr_relacional { 
                                        $$ = novo_syntaticno("!=", 2); 
                                        $$->filhos[0] = $1; 
                                        $$->filhos[1] = $3; 
                                   }
               | expr_relacional  { $$ = $1; }
               ;


expr_relacional : expr_arit '<' expr_arit    { 
                              $$ = novo_syntaticno("<", 2);  
                              $$->filhos[0] = $1; 
                              $$->filhos[1] = $3; 
                         }
                | expr_arit '>' expr_arit    { 
                              $$ = novo_syntaticno(">", 2);  
                              $$->filhos[0] = $1; 
                              $$->filhos[1] = $3; 
                         }
                | expr_arit TOK_LE expr_arit { 
                              $$ = novo_syntaticno("<=", 2); 
                              $$->filhos[0] = $1; 
                              $$->filhos[1] = $3; 
                         }
                | expr_arit TOK_GE expr_arit { 
                              $$ = novo_syntaticno(">=", 2); 
                              $$->filhos[0] = $1; 
                              $$->filhos[1] = $3; 
                         }
                | expr_arit  { $$ = $1; }
                ;


expr_arit : expr_arit '+' term { 
                         $$ = novo_syntaticno("+", 2); 
                         $$->filhos[0] = $1; 
                         $$->filhos[1] = $3; 
                    }
          | expr_arit '-' term { $$ = novo_syntaticno("-", 2); 
                         $$->filhos[0] = $1; 
                         $$->filhos[1] = $3; 
                    }
          | term  { $$ = $1; }
          ;

term : term '*' unary { 
               $$ = novo_syntaticno("*", 2); 
               $$->filhos[0] = $1; 
               $$->filhos[1] = $3; 
          }
     | term '/' unary { 
               $$ = novo_syntaticno("/", 2); 
               $$->filhos[0] = $1;
               $$->filhos[1] = $3; 
          }
     | unary { $$ = $1; }
     ;

unary : '!' unary { 
          $$ = novo_syntaticno("!", 1);  
          $$->filhos[0] = $2; 
     }
      | factor  { $$ = $1; }
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

                         /* DIFERENCIAL DA MINHA LINGUAGEM */
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

tipo_unidade : tipo_unidade '*' fator_unidade {
                                   $$ = novo_syntaticno("*", 2); 
                                   $$->filhos[0] = $1; 
                                   $$->filhos[1] = $3;            
                              }
             | tipo_unidade '/' fator_unidade { 
                                   $$ = novo_syntaticno("/", 2); 
                                   $$->filhos[0] = $1; 
                                   $$->filhos[1] = $3;                          
                              }
             | fator_unidade  { $$ = $1; }
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


int main(int argc, char *argv[]) {
    
    extern FILE *yyin;

    if (argc > 1) {
        yyin = fopen(argv[1], "r");

        if (yyin == NULL) {
            fprintf(stderr, "Erro na leitura do arquivo'%s'\n", argv[1]);
            return 1;
        }
    }

    yyparse();

    return 0;
}
