#pragma once

#include <iostream>
#include <map>
#include <set>
#include "types.hh"

using namespace std;

class VariableContainer {
public:
    static void addVar(string variableName, number value) {
        storeVariableName(variableName);
        numVariables.insert_or_assign(variableName, value);
    }

    static void addVar(string variableName, string value) {
        storeVariableName(variableName);
        strVariables.insert_or_assign(variableName, value);
    }

    static number getVarNum(string variableName) {
        return numVariables.contains(variableName) ? numVariables.at(variableName) : 0;
    }

    static string getVarStr(string variableName) {
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
    inline static map<string, string> strVariables;
};
