#pragma once

#include <iostream>
#include <functional>
#include <set>
#include "variables.h"
#include "types.h"

using namespace std;

class Callback {
public:
    virtual ~Callback() { }

    static void clearExtent() {
        for (auto cb = _callbacks.begin(); cb != _callbacks.end(); ++cb) {
            delete *cb;
        }
        _callbacks.clear();
    }

    static void addToExtent(Callback* cb) {
        _callbacks.insert(cb);
    }

private:
    inline static set<Callback*> _callbacks;
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

class CbAction : Callback {
public:
    virtual ~CbAction() { }

    template<class T, class... Args>
    static action* create(Args&& ... args) {
        auto callback = new T(forward<Args>(args)...);
        addToExtent(callback);
        return &(callback->_action);
    }

protected:
    action _action;
};

class ExitCb : public CbAction {
public:
    ExitCb() {
        _action = [](){ exit(0); };
    }
};

template <class T>
class PrintExprCb : public CbAction {
public:
    PrintExprCb(valueEval<T>* value) {
        _action = [value](){ cout << (*value)() << endl; };
    }
};

class PrintVarCb : public CbAction {
public:
    PrintVarCb(string name) {
        _action = [name](){
            VariableContainer::printVar(name);
        };
    }
};

class PrintNewLineCb : public CbAction {
public:
    PrintNewLineCb() {
        _action = [](){ cout << endl; };
    }
};

template <class T>
class AssignVarCb : public CbAction {
public:
    AssignVarCb(string varName, valueEval<T>* varValue) {
        _action = [varName, varValue]() {
            VariableContainer::addVar(varName, (*varValue)());
        };
    }
};

class IfCb : public CbAction {
public:
    IfCb(valueEval<bool>* condition, action* trueFunction, action* falseFunction) {
        _action = [condition, trueFunction, falseFunction]() {
            if ((*condition)()) {
                (*trueFunction)();
            } else {
                if (falseFunction != nullptr) (*falseFunction)();
            }
        };
    }
};

class WhileCb : public CbAction {
public:
    WhileCb(valueEval<bool>* condition, action* instruction) {
        _action = [condition, instruction]() {
            while((*condition)()) {
                (*instruction)();
            }
        };
    }
};

class DoWhileCb : public CbAction {
public:
    DoWhileCb(action* instruction, valueEval<bool>* condition) {
        _action = [instruction, condition]() {
            do {
                (*instruction)();
            } while ((*condition)());
        };
    }
};

class CompoundInstrCb : public CbAction {
public:
    CompoundInstrCb(action* firstAction, action* secondAction) {
        _action = [firstAction, secondAction]() {
            (*firstAction)();
            (*secondAction)();
        };
    }
};
