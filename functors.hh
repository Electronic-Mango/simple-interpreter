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
class ExprPrinter {
public:
    static action* preparePrinterFuncPtr(T value) {
        auto printer = new ExprPrinter<T>(value);
        return &(printer->_printerFunction);
    }

private:
    ExprPrinter(T value) {
        _printerFunction = [value](){ cout << value << endl; };
    }

    action _printerFunction;
};

class VariablePrinter {
public:
    static action* prepareVarPrinterFuncPtr(string name) {
        auto printer = new VariablePrinter(name);
        return &(printer->_printerFunction);
    }

private:
    VariablePrinter(string name) {
        _printerFunction = [name](){
            VariableContainer::printVar(name);
        };
    }

    action _printerFunction;
};

template <class T>
class Assigner {
public:
    static action* prepareAssigner(string varName, T varValue) {
        auto assigner = new Assigner<T>(varName, varValue);
        return &(assigner->_variableAssigningFunction);
    }

private:
    Assigner(string varName, T varValue) {
        _variableAssigningFunction = [varName, varValue]() {
            VariableContainer::addVar(varName, varValue);
        };
    }

    action _variableAssigningFunction;
};

class IfHandler {
public:
    static action* prepareIfHandler(bool condition, action* trueFunction, action* falseFunction) {
        auto handler = new IfHandler(condition, trueFunction, falseFunction);
        return &(handler->_ifFunction);
    }

private:
    IfHandler(bool condition, action* trueFunction, action* falseFunction) {
        _ifFunction = [condition, trueFunction, falseFunction]() {
            if (condition) {
                (*trueFunction)();
            } else {
                if (falseFunction != nullptr) (*falseFunction)();
            }
        };
    }

    action _ifFunction;
};

class CompoundInstrHandler {
public:
    static action* prepareCompoundInstrHandler(action* firstAction, action* secondAction) {
        auto handler = new CompoundInstrHandler(firstAction, secondAction);
        return &(handler->_compoundAction);
    }

private:
    CompoundInstrHandler(action* firstAction, action* secondAction) {
        _compoundAction = [firstAction, secondAction]() {
            (*firstAction)();
            (*secondAction)();
        };
    }

    action _compoundAction;
};