#pragma once

#include <cstdio>
#include <iostream>
#include <cstring>
#include <map>
#include <set>
#include <functional>
#include <memory>

using namespace std;

typedef signed long int number;
typedef const char* cstring;
typedef function<void()> action;

class VariableContainer {
public:
    static void addVar(string variableName, number value) {
        storeVariableName(variableName);
        numVariables.insert_or_assign(variableName, value);
    }

    static void addVar(string variableName, cstring value) {
        storeVariableName(variableName);
        strVariables.insert_or_assign(variableName, value);
    }

    static number getVarNum(string variableName) {
        return numVariables.contains(variableName) ? numVariables.at(variableName) : 0;
    }

    static cstring getVarStr(string variableName) {
        return strVariables.contains(variableName) ? strVariables.at(variableName) : "";
    }

    static void printVar(string variableName) {
        if (strVariables.contains(variableName)) {
            cout << getVarStr(variableName) << endl;
        } else if (numVariables.contains(variableName)) {
            cout << getVarNum(variableName) << endl;
        } else {
            cout << "" << endl;
        }
    }

private:
    static void storeVariableName(string variableName) {
        if (variableNames.contains(variableName)) {
            numVariables.erase(variableName);
            strVariables.erase(variableName);
        } else {
            variableNames.insert(variableName);
        }
    }

    inline static set<string> variableNames;
    inline static map<string, number> numVariables;
    inline static map<string, cstring> strVariables;
};

template <class T>
struct ExprPrinter {
    T _value;
    action _printerFunction;

    static action* preparePrinterFuncPtr(T value) {
        auto printer = new ExprPrinter<T>(value);
        return printer->printerFunctionPtr();
    }

    ExprPrinter(T value) : _value(value) {
        _printerFunction = [this](){ cout << _value << endl; };
    }

    action* printerFunctionPtr() {
        return &_printerFunction;
    }
};

class VariablePrinter {
public:
    static action* prepareVarPrinterFuncPtr(string name) {
        auto printer = new VariablePrinter(name);
        return &(printer->_printerFunction);
    }

private:
    VariablePrinter(string name) {
        _printerFunction = [=](){
            VariableContainer::printVar(name);
        };
    }

    action _printerFunction;
};

template <class T>
struct Assigner {
    string _varName;
    T _varValue;
    action _variableAssigningFunction;

    static action* prepareAssigner(string varName, T varValue) {
        auto assigner = new Assigner<T>(varName, varValue);
        return assigner->variableAssigningFunctionPtr();
    }

    Assigner(string varName, T varValue) : _varName(varName), _varValue(varValue) {
        _variableAssigningFunction = [this]() {
            VariableContainer::addVar(_varName, _varValue);
        };
    }

    action* variableAssigningFunctionPtr() {
        return &_variableAssigningFunction;
    }
    
};

struct IfHandler {
    bool _condition;
    action* _trueFunction;
    action* _falseFunction;
    action _ifFunction;

    static action* prepareIfHandler(bool condition, action* trueFunction, action* falseFunction) {
        auto handler = new IfHandler(condition, trueFunction, falseFunction);
        return handler->ifFunctionPtr();
    }
    
    IfHandler(bool condition, action* trueFunction, action* falseFunction) : _condition(condition), _trueFunction(trueFunction), _falseFunction(falseFunction) {
        _ifFunction = [this]() {
            if (_condition) {
                (*_trueFunction)();
            } else {
                if (_falseFunction != nullptr) (*_falseFunction)();
            }
        };
    }

    action* ifFunctionPtr() {
        return &_ifFunction;
    }
};

struct CompoundInstrHandler {
    action* _firstAction;
    action* _secondAction;
    action _compoundAction;

    static action* prepareCompoundInstrHandler(action* firstAction, action* secondAction) {
        auto handler = new CompoundInstrHandler(firstAction, secondAction);
        return handler->compoundActionPtr();
    }
    
    CompoundInstrHandler(action* firstAction, action* secondAction) : _firstAction(firstAction), _secondAction(secondAction) {
        _compoundAction = [this]() {
            (*_firstAction)();
            (*_secondAction)();
        };
    }

    action* compoundActionPtr() {
        return &_compoundAction;
    }
};