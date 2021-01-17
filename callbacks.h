#pragma once

#include <iostream>
#include <functional>
#include <set>
#include "variables.h"
#include "types.h"

using namespace std;

class Callback {
public:
    virtual ~Callback() {}

    static void clearExtent() {
        for (auto cb = callbacks.begin(); cb != callbacks.end(); ++cb) {
            delete *cb;
        }
        callbacks.clear();
    }

    static void addToExtent(Callback* cb) {
        callbacks.insert(cb);
    }

private:
    inline static set<Callback*> callbacks;
};

class ExitCb : public Callback {
public:
    static action* create() {
        auto callback = new ExitCb();
        addToExtent(callback);
        return &(callback->_action);
    }

private:
    ExitCb() {
        _action = [](){ exit(0); };
    }

    action _action;
};

template <class T>
class ExprEvalCb : public Callback {
public:
    static valueEval<T>* create(valueEval<T> evaluator) {
        auto callback = new ExprEvalCb<T>(evaluator);
        addToExtent(callback);
        return &(callback->_evaluator);
    }

private:
    ExprEvalCb(valueEval<T> evaluator) : _evaluator(evaluator) { }

    valueEval<T> _evaluator;
};

template <class T>
class PrintExprCb : public Callback {
public:
    static action* create(valueEval<T>* value) {
        auto callback = new PrintExprCb<T>(value);
        addToExtent(callback);
        return &(callback->_action);
    }

private:
    PrintExprCb(valueEval<T>* value) {
        _action = [value](){ cout << (*value)() << endl; };
    }

    action _action;
};

class PrintVarCb : public Callback {
public:
    static action* create(string name) {
        auto callback = new PrintVarCb(name);
        addToExtent(callback);
        return &(callback->_action);
    }

private:
    PrintVarCb(string name) {
        _action = [name](){
            VariableContainer::printVar(name);
        };
    }

    action _action;
};

class PrintNewLineCb : public Callback {
public:
    static action* create() {
        auto callback = new PrintNewLineCb();
        addToExtent(callback);
        return &(callback->_action);
    }

private:
    PrintNewLineCb() {
        _action = [](){ cout << endl; };
    }

    action _action;
};

template <class T>
class AssignVarCb : public Callback {
public:
    static action* create(string varName, valueEval<T>* varValue) {
        auto callback = new AssignVarCb<T>(varName, varValue);
        addToExtent(callback);
        return &(callback->_action);
    }

private:
    AssignVarCb(string varName, valueEval<T>* varValue) {
        _action = [varName, varValue]() {
            VariableContainer::addVar(varName, (*varValue)());
        };
    }

    action _action;
};

class IfCb : public Callback {
public:
    static action* create(valueEval<bool>* condition, action* trueFunction, action* falseFunction) {
        auto callback = new IfCb(condition, trueFunction, falseFunction);
        addToExtent(callback);
        return &(callback->_action);
    }

private:
    IfCb(valueEval<bool>* condition, action* trueFunction, action* falseFunction) {
        _action = [condition, trueFunction, falseFunction]() {
            if ((*condition)()) {
                (*trueFunction)();
            } else {
                if (falseFunction != nullptr) (*falseFunction)();
            }
        };
    }

    action _action;
};

class WhileCb : public Callback {
public:
    static action* create(valueEval<bool>* condition, action* instruction) {
        auto callback = new WhileCb(condition, instruction);
        addToExtent(callback);
        return &(callback->_action);
    }

private:
    WhileCb(valueEval<bool>* condition, action* instruction) {
        _action = [condition, instruction]() {
            while((*condition)()) {
                (*instruction)();
            }
        };
    }

    action _action;
};

class DoWhileCb : public Callback {
public:
    static action* create(action* instruction, valueEval<bool>* condition) {
        auto callback = new DoWhileCb(instruction, condition);
        addToExtent(callback);
        return &(callback->_action);
    }

private:
    DoWhileCb(action* instruction, valueEval<bool>* condition) {
        _action = [instruction, condition]() {
            do {
                (*instruction)();
            } while ((*condition)());
        };
    }

    action _action;
};

class CompoundInstrCb : public Callback {
public:
    static action* create(action* firstAction, action* secondAction) {
        auto callback = new CompoundInstrCb(firstAction, secondAction);
        addToExtent(callback);
        return &(callback->_action);
    }

private:
    CompoundInstrCb(action* firstAction, action* secondAction) {
        _action = [firstAction, secondAction]() {
            (*firstAction)();
            (*secondAction)();
        };
    }

    action _action;
};
