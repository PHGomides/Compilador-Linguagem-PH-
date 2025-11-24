#ifndef NODE_H
#define NODE_H

#include <vector>
#include <string>
#include <iostream>
#include <set>
#include <map>
#include <algorithm>

extern int yylineno;
extern char *build_file_name;
extern int errorcount;

using namespace std;

class Program;

// --- Classe Base Node ---
class Node
{
protected:
    vector<Node *> children;
    int lineno;

public:
    string computedUnit;

    Node()
    {
        lineno = yylineno;
        computedUnit = "";
    }

    virtual ~Node() {}

    int getLineNo() { return lineno; }

    void append(Node *n)
    {
        if (n != nullptr)
            children.push_back(n);
    }

    vector<Node *> &getChildren() { return children; }

    virtual string astLabel() { return ""; }
    virtual string getName() { return ""; }
    virtual string getOper() { return ""; }

    friend class Program;
};

// --- Classes Concretas ---

class Load : public Node
{
    string name;

public:
    Load(string name) : name(name) {}
    string astLabel() override { return "Load(" + name + ")"; }
    string getName() override { return name; }
};

class ConstInteger : public Node
{
    int value;

public:
    ConstInteger(int value) : value(value) {}
    string astLabel() override { return "Int(" + to_string(value) + ")"; }
};

class ConstDouble : public Node
{
    double value;

public:
    ConstDouble(double value) : value(value) {}
    string astLabel() override { return "Float(" + to_string(value) + ")"; }
};

class ConstBool : public Node
{
    bool value;

public:
    ConstBool(int value) : value(value != 0) {}
    string astLabel() override { return value ? "true" : "false"; }
};

class BinaryOp : public Node
{
    string oper;

public:
    BinaryOp(Node *left, string oper, Node *right) : oper(oper)
    {
        this->append(left);
        this->append(right);
    }
    string astLabel() override { return "Op(" + oper + ")"; }
    string getOper() override { return oper; }
};

class UnaryOp : public Node
{
    string oper;

public:
    UnaryOp(string oper, Node *child) : oper(oper)
    {
        this->append(child);
    }
    string astLabel() override { return "Unary(" + oper + ")"; }
    string getOper() override { return oper; }
};

class Store : public Node
{
    string name;

public:
    Store(string name, Node *expr) : name(name)
    {
        this->append(expr);
    }
    string astLabel() override { return "Store(" + name + ")"; }
    string getName() override { return name; }
};

class Let : public Node
{
    string name;

public:
    Let(string name, Node *unit, Node *expr) : name(name)
    {
        this->append(unit);
        this->append(expr);
    }
    string astLabel() override { return "Let(" + name + ")"; }
    string getName() override { return name; }
};

class Print : public Node
{
public:
    Print(Node *e) { append(e); }
    string astLabel() override { return "Print"; }
};
class IfElse : public Node
{
public:
    IfElse(Node *c, Node *t, Node *e = 0)
    {
        append(c);
        append(t);
        if (e)
            append(e);
    }
    string astLabel() override { return "If"; }
};
class While : public Node
{
public:
    While(Node *c, Node *b)
    {
        append(c);
        append(b);
    }
    string astLabel() override { return "While"; }
};
class DoWhile : public Node
{
public:
    DoWhile(Node *b, Node *c)
    {
        append(b);
        append(c);
    }
    string astLabel() override { return "DoWhile"; }
};
class Block : public Node
{
public:
    Block(Node *s) { append(s); }
    string astLabel() override { return "Block"; }
};
class Stmts : public Node
{
public:
    Stmts() {}
    Stmts(Node *s) { append(s); }
    string astLabel() override { return "stmts"; }
};

class Program : public Node
{
protected:
    void printAstRecursive(Node *n)
    {
        if (!n)
            return;
        cout << "N" << (long)(n) << "[label=\"" << n->astLabel() << "\"]" << "\n";
        for (Node *c : n->children)
        {
            if (c)
            {
                cout << "N" << (long)(n) << "--" << "N" << (long)(c) << "\n";
                printAstRecursive(c);
            }
        }
    }

public:
    Program(Node *stmts) { this->append(stmts); }
    void printAst()
    {
        cout << "graph {\n";
        cout << "N" << (long)(this) << "[label=\"Program\"]\n";
        if (!children.empty() && children[0])
        {
            cout << "N" << (long)(this) << " -- " << "N" << (long)(children[0]) << "\n";
            printAstRecursive(children[0]);
        }
        cout << "}\n";
    }
};

// --- VALIDACAO SEMANTICA ---

struct SymbolInfo
{
    string name;
    string unit;
    SymbolInfo(string n = "", string u = "") : name(n), unit(u) {}
};

class SemanticChecker
{
private:
    vector<map<string, SymbolInfo>> scopes;

    string extractUnitString(Node *unitNode)
    {
        if (!unitNode)
            return "";
        Load *load = dynamic_cast<Load *>(unitNode);
        if (load)
            return load->getName();
        BinaryOp *bin = dynamic_cast<BinaryOp *>(unitNode);
        if (bin)
        {
            string left = extractUnitString(bin->getChildren()[0]);
            string right = extractUnitString(bin->getChildren()[1]);
            return left + bin->getOper() + right;
        }
        return "";
    }

    string computeBinaryUnit(string u1, string oper, string u2)
    {
        if (oper == "+" || oper == "-")
        {
            if (u1 == u2)
                return u1;
            if (u1 == "" && u2 == "")
                return "";
            return "ERROR_COMPATIBILITY";
        }
        if (oper == "*" || oper == "/")
        {
            if (u1 == "" && u2 == "")
                return "";
            if (u1 == "")
                return u2;
            if (u2 == "")
                return u1;
            return "(" + u1 + oper + u2 + ")";
        }
        if (oper == "<" || oper == ">" || oper == "==")
            return "";
        return "";
    }

public:
    SemanticChecker() { enterScope(); }

    void enterScope() { scopes.push_back(map<string, SymbolInfo>()); }
    void exitScope()
    {
        if (!scopes.empty())
            scopes.pop_back();
    }

    SymbolInfo *lookup(string name)
    {
        for (auto it = scopes.rbegin(); it != scopes.rend(); ++it)
        {
            if (it->count(name))
                return &((*it)[name]);
        }
        return nullptr;
    }

    bool declare(string name, string unit)
    {
        if (scopes.empty())
            return false;
        if (scopes.back().count(name))
            return false;
        scopes.back()[name] = SymbolInfo(name, unit);
        return true;
    }

    void check(Node *n)
    {
        if (!n)
            return;

        Block *block = dynamic_cast<Block *>(n);
        if (block)
            enterScope();

        Let *let = dynamic_cast<Let *>(n);
        if (let)
        {
            if (let->getChildren().size() > 1)
                check(let->getChildren()[1]);
        }
        else
        {
            for (Node *c : n->getChildren())
                check(c);
        }

        // --- LÓGICA DE VALIDAÇÃO E CÁLCULO DE UNIDADES ---

        Load *load = dynamic_cast<Load *>(n);
        if (load)
        {
            SymbolInfo *info = lookup(load->getName());
            if (info)
            {
                n->computedUnit = info->unit;
            }
            else
            {
                n->computedUnit = "";
            }
        }

        if (let)
        {
            string varName = let->getName();
            string unitStr = "";
            if (!let->getChildren().empty())
                unitStr = extractUnitString(let->getChildren()[0]);

            if (!declare(varName, unitStr))
            {
                // ERRO DE REDECLARAÇÃO
                cerr << "Erro Semantico na linha : " << let->getLineNo()
                     << " - Variavel '" << varName << "' ja foi declarada neste escopo.\n";
                errorcount++;
            }
            else
            {
                if (let->getChildren().size() > 1)
                {
                    string exprUnit = let->getChildren()[1]->computedUnit;
                    if (unitStr != "" && exprUnit != "" && unitStr != exprUnit)
                    {
                        // ERRO DE COMPATIBILIDADE NA INICIALIZAÇÃO
                        cerr << "Erro Semantico na linha : " << let->getLineNo()
                             << " - Unidades incompativeis na inicializacao de '" << varName
                             << "'. Esperado: " << unitStr << ", Encontrado: " << exprUnit << "\n";
                        errorcount++;
                    }
                }
            }
        }

        BinaryOp *bin = dynamic_cast<BinaryOp *>(n);
        if (bin && bin->getChildren().size() == 2)
        {
            string u1 = bin->getChildren()[0]->computedUnit;
            string u2 = bin->getChildren()[1]->computedUnit;
            string oper = bin->getOper();

            string res = computeBinaryUnit(u1, oper, u2);

            if (res == "ERROR_COMPATIBILITY")
            {
                // ERRO DE OPERAÇÃO INVÁLIDA
                cerr << "Erro Semantico na linha : " << bin->getLineNo()
                     << " - Operacao '" << oper << "' invalida entre unidades incompativeis: "
                     << (u1 == "" ? "(sem unidade)" : u1) << " e " << (u2 == "" ? "(sem unidade)" : u2) << "\n";
                errorcount++;
                n->computedUnit = "";
            }
            else
            {
                n->computedUnit = res;
            }
        }

        Store *store = dynamic_cast<Store *>(n);
        if (store && !store->getChildren().empty())
        {
            SymbolInfo *info = lookup(store->getName());
            if (!info)
            {
                // ERRO DE VARIÁVEL NÃO DECLARADA
                cerr << "Erro Semantico na linha : " << store->getLineNo()
                     << " - Atribuicao para variavel nao declarada '" << store->getName() << "'.\n";
                errorcount++;
            }
            else
            {
                string varUnit = info->unit;
                string exprUnit = store->getChildren()[0]->computedUnit;

                if (varUnit != "" && exprUnit != "" && varUnit != exprUnit)
                {
                    // ERRO DE COMPATIBILIDADE NA ATRIBUIÇÃO
                    cerr << "Erro Semantico na linha : " << store->getLineNo()
                         << " - Atribuicao incompativel para '" << store->getName()
                         << "'. Esperado: " << varUnit << ", Recebido: " << exprUnit << "\n";
                    errorcount++;
                }
                n->computedUnit = varUnit;
            }
        }

        if (load)
        {
            string vname = load->getName();

            if (!lookup(vname))
            {
                cerr << "Erro Semantico na linha : " << load->getLineNo()
                     << " - Variavel (ou unidade) '" << vname << "' nao declarada.\n";
                errorcount++;
            }
        }

        if (block)
            exitScope();
    }
};

#endif