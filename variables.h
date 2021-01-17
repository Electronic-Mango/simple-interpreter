#pragma once

#include <iostream>
#include <map>
#include <set>
#include "types.h"

using namespace std;

class VariableContainer {
public:
    static void addVar(string variableName, number value) {
        storeVariableName(variableName);
        _numVariables.insert_or_assign(variableName, value);
    }

    static void addVar(string variableName, string value) {
        storeVariableName(variableName);
        _strVariables.insert_or_assign(variableName, value);
    }

    static number getVarNum(string variableName) {
        return _numVariables.contains(variableName) ? _numVariables.at(variableName) : 0;
    }

    static string getVarStr(string variableName) {
        return _strVariables.contains(variableName) ? _strVariables.at(variableName) : "";
    }

    static void printVar(string variableName) {
        if (_strVariables.contains(variableName)) {
            cout << getVarStr(variableName) << endl;
        } else if (_numVariables.contains(variableName)) {
            cout << getVarNum(variableName) << endl;
        } else {
            cout << "" << endl;
        }
    }

private:
    static void storeVariableName(string variableName) {
        if (_variableNames.contains(variableName)) {
            _numVariables.erase(variableName);
            _strVariables.erase(variableName);
        } else {
            _variableNames.insert(variableName);
        }
    }

    inline static set<string> _variableNames;
    inline static map<string, number> _numVariables;
    inline static map<string, string> _strVariables;
};
