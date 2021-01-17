#pragma once

#include <iostream>
#include <functional>
#include "variables.hh"
#include "types.hh"

using namespace std;

class ExitCb {
public:
    static action* create() {
        auto callback = new ExitCb();
        return &(callback->_action);
    }

private:
    ExitCb() {
        _action = [](){ exit(0); };
    }

    action _action;
};

template <class T>
class ExprEvalCb {
public:
    static valueEval<T>* create(valueEval<T> evaluator) {
        auto callback = new ExprEvalCb<T>(evaluator);
        return &(callback->_evaluator);
    }

private:
    ExprEvalCb(valueEval<T> evaluator) : _evaluator(evaluator) { }

    valueEval<T> _evaluator;
};

template <class T>
class PrintExprCb {
public:
    static action* create(valueEval<T>* value) {
        auto callback = new PrintExprCb<T>(value);
        return &(callback->_action);
    }

private:
    PrintExprCb(valueEval<T>* value) {
        _action = [value](){ cout << (*value)() << endl; };
    }

    action _action;
};

class PrintVarCb {
public:
    static action* create(string name) {
        auto callback = new PrintVarCb(name);
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

class PrintNewLineCb {
public:
    static action* create() {
        auto callback = new PrintNewLineCb();
        return &(callback->_action);
    }

private:
    PrintNewLineCb() {
        _action = [](){ cout << endl; };
    }

    action _action;
};

template <class T>
class AssignVarCb {
public:
    static action* create(string varName, valueEval<T>* varValue) {
        auto callback = new AssignVarCb<T>(varName, varValue);
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

class IfCb {
public:
    static action* create(valueEval<bool>* condition, action* trueFunction, action* falseFunction) {
        auto callback = new IfCb(condition, trueFunction, falseFunction);
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

class WhileCb {
public:
    static action* create(valueEval<bool>* condition, action* instruction) {
        auto callback = new WhileCb(condition, instruction);
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

class DoWhileCb {
public:
    static action* create(action* instruction, valueEval<bool>* condition) {
        auto callback = new DoWhileCb(instruction, condition);
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

class CompoundInstrCb {
public:
    static action* create(action* firstAction, action* secondAction) {
        auto callback = new CompoundInstrCb(firstAction, secondAction);
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