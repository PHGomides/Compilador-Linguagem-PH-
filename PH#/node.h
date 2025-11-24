#include <vector>
#include <string>
#include <iostream>

extern int yylineno;

using namespace std;

class Program;

class Node {
protected:
    vector<Node*> children;
    int lineno;

public:
    Node() {
        lineno = yylineno;
    }

    int getLineNo() {
        return lineno;
    }

    void append(Node *n) {
        if (n != nullptr)
            children.push_back(n);
    }

    virtual string astLabel() {
        return "";
    }

    friend class Program;
};

// --- Literais ---

class Load: public Node {
protected:
    string name;
public:
    Load(string name) {
        this->name = name;
    }
    string astLabel() override {
        return "Load(" + name + ")";
    }
};

class ConstInteger: public Node {
protected:
    int value;
public:
    ConstInteger(int value) {
        this->value = value;
    }
    string astLabel() override {
        return "Int(" + to_string(value) + ")";
    }
};

class ConstDouble: public Node {
protected:
    double value;
public:
    ConstDouble(double value) {
        this->value = value;
    }
    string astLabel() override {
        return "Float(" + to_string(value) + ")";
    }
};

class ConstBool: public Node {
protected:
    bool value;
public:
    ConstBool(int value) {
        this->value = (value != 0);
    }
    string astLabel() override {
        return value ? "true" : "false";
    }
};

// --- Operações ---

class BinaryOp: public Node {
protected:
    string oper;
public:
    BinaryOp(Node *left, string oper, Node *right) {
        this->oper = oper;
        this->append(left);
        this->append(right);
    }
    string astLabel() override {
        return "Op(" + oper + ")";
    }
};

class UnaryOp: public Node {
protected:
    string oper;
public:
    UnaryOp(string oper, Node *child) {
        this->oper = oper;
        this->append(child);
    }
    string astLabel() override {
        return "Unary(" + oper + ")";
    }
};

// --- Comandos ---

class Store: public Node {
protected:
    string name;
public:
    Store(string name, Node *expr) {
        this->name = name;
        this->append(expr);
    }
    string astLabel() override {
        return "Store(" + name + ")";
    }
};

class Let: public Node {
protected:
    string name;
public:
    Let(string name, Node *unit, Node *expr) {
        this->name = name;
        this->append(unit); 
        this->append(expr);
    }
    string astLabel() override {
        return "Let(" + name + ")";
    }
};

class Print: public Node {
public:
    Print(Node *expr) {
        this->append(expr);
    }
    string astLabel() override {
        return "Print";
    }
};

class IfElse: public Node {
public:
    IfElse(Node *cond, Node *thenStmt, Node *elseStmt = nullptr) {
        this->append(cond);
        this->append(thenStmt);
        if (elseStmt) this->append(elseStmt);
    }
    string astLabel() override {
        return "If";
    }
};

class While: public Node {
public:
    While(Node *cond, Node *body) {
        this->append(cond);
        this->append(body);
    }
    string astLabel() override {
        return "While";
    }
};

class DoWhile: public Node {
public:
    DoWhile(Node *body, Node *cond) {
        this->append(body);
        this->append(cond);
    }
    string astLabel() override {
        return "DoWhile";
    }
};

class Block: public Node {
public:
    Block(Node *stmts) {
        this->append(stmts);
    }
    string astLabel() override {
        return "Block";
    }
};

class Stmts: public Node {
public:
    Stmts() {}
    Stmts(Node *stmt) {
        this->append(stmt);
    }
    string astLabel() override {
        return "stmts";
    }
};

class Program: public Node {
protected:
    void printAstRecursive(Node *n) {
        if (!n) return;
        cout << "N" << (long)(n) << "[label=\"" << n->astLabel() << "\"]" << "\n";
        for(Node *c : n->children) {
            if (c) {
                cout << "N" << (long)(n) << "--" << "N" << (long)(c) << "\n";
                printAstRecursive(c);
            }
        }
    }

public:
    Program(Node *stmts) {
        this->append(stmts);
    }

    void printAst() {
        cout << "graph {\n";
        cout << "N" << (long)(this) << "[label=\"Program\"]\n";
        if (!children.empty() && children[0]) {
            cout << "N" << (long)(this) << " -- " << "N" << (long)(children[0]) << "\n";
            printAstRecursive(children[0]);
        }
        cout << "}\n";
    }
};
