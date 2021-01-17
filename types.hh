#pragma once

#include <functional>

using namespace std;

typedef signed long int number;
typedef const char* cstring;
typedef function<void()> action;
template <class T> using valueEval = function<T()>;