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
class PrintExprCallback {
public:
    static action* create(T value) {
        auto printer = new PrintExprCallback<T>(value);
        return &(printer->_action);
    }

private:
    PrintExprCallback(T value) {
        _action = [value](){ cout << value << endl; };
    }

    action _action;
};

class PrintVarCallback {
public:
    static action* create(string name) {
        auto printer = new PrintVarCallback(name);
        return &(printer->_action);
    }

private:
    PrintVarCallback(string name) {
        _action = [name](){
            VariableContainer::printVar(name);
        };
    }

    action _action;
};

template <class T>
class AssignVarCallback {
public:
    static action* create(string varName, T varValue) {
        auto assigner = new AssignVarCallback<T>(varName, varValue);
        return &(assigner->_action);
    }

private:
    AssignVarCallback(string varName, T varValue) {
        _action = [varName, varValue]() {
            VariableContainer::addVar(varName, varValue);
        };
    }

    action _action;
};

class IfCallback {
public:
    static action* create(bool condition, action* trueFunction, action* falseFunction) {
        auto handler = new IfCallback(condition, trueFunction, falseFunction);
        return &(handler->_action);
    }

private:
    IfCallback(bool condition, action* trueFunction, action* falseFunction) {
        _action = [condition, trueFunction, falseFunction]() {
            if (condition) {
                (*trueFunction)();
            } else {
                if (falseFunction != nullptr) (*falseFunction)();
            }
        };
    }

    action _action;
};

class WhileCallback {
public:
    static action* create(bool condition, action* instruction) {
        auto handler = new WhileCallback(condition, instruction);
        return &(handler->_action);
    }

private:
    WhileCallback(bool condition, action* instruction) {
        _action = [condition, instruction]() {
            while(condition) {
                (*instruction)();
            }
        };
    }

    action _action;
};

class DoWhileCallback {
public:
    static action* create(action* instruction, bool condition) {
        auto handler = new DoWhileCallback(instruction, condition);
        return &(handler->_action);
    }

private:
    DoWhileCallback(action* instruction, bool condition) {
        _action = [instruction, condition]() {
            do {
                (*instruction)();
            } while (condition);
        };
    }

    action _action;
};

class CompoundInstrCallback {
public:
    static action* create(action* firstAction, action* secondAction) {
        auto handler = new CompoundInstrCallback(firstAction, secondAction);
        return &(handler->_action);
    }

private:
    CompoundInstrCallback(action* firstAction, action* secondAction) {
        _action = [firstAction, secondAction]() {
            (*firstAction)();
            (*secondAction)();
        };
    }

    action _action;
};