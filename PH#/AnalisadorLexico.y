%{
#include "node.h"
int yylex(void);
int yyerror(const char *s);
extern int errorcount;
%}

%define parse.error verbose

%union {
    char *nome;
    int valor_int;
    float valor_float;
    Node *node;
}

%token TOK_PRINT TOK_INT TOK_FLT TOK_IDENT TOK_BOOL
%token TOK_LET TOK_IF TOK_ELSE TOK_WHILE TOK_FOR TOK_DO
%token TOK_EQ TOK_NE TOK_LE TOK_GE TOK_AND TOK_OR

%type <nome> TOK_IDENT
%type <valor_int> TOK_INT TOK_BOOL 
%type <valor_float> TOK_FLT
%type <node> program stmts stmt stmt_completo stmt_incompleto
%type <node> declaracao atribuicao comando_print bloco
%type <node> comando_do_while comando_while_completo
%type <node> expr expr_ou expr_e expr_igualdade expr_relacional expr_arit term unary factor
%type <node> tipo_unidade fator_unidade

%start program

%%

program : stmts { 
    if (errorcount == 0) {
        Program pg($1);
        pg.printAst();
    }
}
;

/* Lógica idêntica à do professor: Base (stmt) e Recursão (stmts stmt) */
stmts : stmt { 
          $$ = new Stmts($1); 
      }
      | stmts stmt { 
          $1->append($2); 
          $$ = $1; 
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
                    $$ = new IfElse($3, $5, $7);
                }
              ;

stmt_incompleto : TOK_IF '(' expr ')' stmt {
                      $$ = new IfElse($3, $5);
                  }
                | TOK_IF '(' expr ')' stmt_completo TOK_ELSE stmt_incompleto {
                      $$ = new IfElse($3, $5, $7);
                  }
                ;

bloco : '{' stmts '}' { $$ = new Block($2); }
      ;

comando_while_completo : TOK_WHILE '(' expr ')' stmt_completo {
                            $$ = new While($3, $5);
                         }
                       ;

comando_do_while : TOK_DO stmt TOK_WHILE '(' expr ')' ';' {
                       $$ = new DoWhile($2, $5);
                   }
                 ;

expr : expr_ou { $$ = $1; } ;

expr_ou : expr_ou TOK_OR expr_e { $$ = new BinaryOp($1, "||", $3); }
        | expr_e { $$ = $1; }
        ;

expr_e : expr_e TOK_AND expr_igualdade { $$ = new BinaryOp($1, "&&", $3); }
       | expr_igualdade { $$ = $1; }
       ;

expr_igualdade : expr_igualdade TOK_EQ expr_relacional { $$ = new BinaryOp($1, "==", $3); }
               | expr_igualdade TOK_NE expr_relacional { $$ = new BinaryOp($1, "!=", $3); }
               | expr_relacional { $$ = $1; }
               ;

expr_relacional : expr_arit '<' expr_arit { $$ = new BinaryOp($1, "<", $3); }
                | expr_arit '>' expr_arit { $$ = new BinaryOp($1, ">", $3); }
                | expr_arit TOK_LE expr_arit { $$ = new BinaryOp($1, "<=", $3); }
                | expr_arit TOK_GE expr_arit { $$ = new BinaryOp($1, ">=", $3); }
                | expr_arit { $$ = $1; }
                ;

expr_arit : expr_arit '+' term { $$ = new BinaryOp($1, "+", $3); }
          | expr_arit '-' term { $$ = new BinaryOp($1, "-", $3); }
          | term { $$ = $1; }
          ;

term : term '*' unary { $$ = new BinaryOp($1, "*", $3); }
     | term '/' unary { $$ = new BinaryOp($1, "/", $3); }
     | unary { $$ = $1; }
     ;

unary : '!' unary { $$ = new UnaryOp("!", $2); }
      | factor { $$ = $1; }
      ;

factor : '(' expr ')' { $$ = $2; }
       | TOK_INT { $$ = new ConstInteger($1); }
       | TOK_FLT { $$ = new ConstDouble($1); }
       | TOK_BOOL { $$ = new ConstBool($1); }
       | TOK_IDENT { $$ = new Load($1); }
       ;

declaracao : TOK_LET TOK_IDENT ':' tipo_unidade '=' expr ';' {
                 $$ = new Let($2, $4, $6);
           }
           ;

atribuicao : TOK_IDENT '=' expr ';' { $$ = new Store($1, $3); }
           ;

comando_print : TOK_PRINT expr ';' { $$ = new Print($2); }
              ;

tipo_unidade : tipo_unidade '*' fator_unidade { $$ = new BinaryOp($1, "*", $3); }
             | tipo_unidade '/' fator_unidade { $$ = new BinaryOp($1, "/", $3); }
             | fator_unidade { $$ = $1; }
             ;

fator_unidade : TOK_IDENT { $$ = new Load($1); }
              | '(' tipo_unidade ')' { $$ = $2; }
              ;

%%