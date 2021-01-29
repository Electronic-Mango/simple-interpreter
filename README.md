# Simple interpreter


## Introduction
This simple interpreter was written as student assignment.

In this project I've prepared a working interpreter of language described in project's requirements.
Built program allows running (interpreting) prepared file with source code.
More complex instructions (`if-else`, `while-do`, etc.) work as expected.


## Required tools
I've created this project using `Flex (v2.6.4)`, `Bison (v3.7.4)` and `g++ (v9.3.0)`.

In project, I've used C++20. To use it you can compile project with `-std=c+2a` flag.

To simplify building the interpreter I've prepared simple `Makefile`.


## Usage
To build the interpreter you can just use added `Makefile` (it's prepared for Linux).

To generate all required files and finally compile the project just run:
```
make
```
Created executable will be called `interpreter`.

To interpret a file with source code run pass it as argument to created executable:
```
./interpreter <source file name>
```
You can also clean all generated/compiled files by:
```
make clean
```


## Files structure
Solution is split into multiple files:
* `scanner-specification.l` scanner specification, contains all used symbols/keywords.
Parser works by just tokens to recognize keywords, their definitions are in scanner specification itself.

* `parser.y` parser specification.

* `types.h` header containing all typedefs used in the project (e.g.: type number – signed long int).

* `variables.h` header containing class storing all variables used by interpreted program.
It also contains methods for adding and reading variables.

* `callbacks.h` header containing callbacks used for creating program's execution tree.

* `Makefile`

* `test.file` example file with source code

* Other files are generated when project is being built.


## The way it works
Interpreter's way of working is based on callbacks.
I've prepared two callback types:
* `action` representing some operation to be executed, which doesn't require arguments and doesn't return value.
An example can be `if-else` construction, where, depending on condition, on of two action will be executed.
This callback type is used as attributes of nonterminals which are associated with operations
and not with variables or values.

* `valueEval` operation used for evaluating a value of some type, either variable or literal.
Values also have to be handled by callbacks, as parsing is too early - program could evaluate attributes
in blocks of code which are limited by conditions.

During parsing interpreter is preparing a tree of these callbacks. This tree is actually just callbacks nested within
each other.

Program is being interpreted by just executing root callback, which will execute all nested callbacks.


## Variable types
### Number
`Number` type is based on `signed long int` in decimal format.

When user provides larger value it will be limited to either LONG_MAX or LONG_MIN.

During mathematical operations `number` regular overflows or underflows can happen.


### String
`String` is a string of characters between `"`.

All characters are allowed, except `"`, `\n` and `\r`.

