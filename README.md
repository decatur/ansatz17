This is a fast, extensible, yet simple parser for GNU Octave and MATLAB®.
It is a single file solution with about 200 lines of code.

# Requirements
GNU Octave version minimum 4.0 or MATLAB about version 2008 (verified for 2013b).

# Dependencies
There are no dependencies.

# Related Work
* See Quantity Expression Parser extension at https://github.com/decatur/ansatz19
* There is a [much more komplex parser for MATLAB](http://www.cs.dartmouth.edu/~mckeeman/cs48/lectures/01_lecture.html)

# Simple Expression Example
```
addpath('examples');
p = ExprParser();
[ast, parseError] = p.parse('1+2*3');
Evaluator(ast).exec()
ans = 7
```

# Usage

# Provided Sample Grammars

## ExprParser

The class `ExprParser` extends `Parser` to support numbers, variables, strings, the binary operations `+, -, *, /`
and the prefix `-` and `+` operations.

```
p = ExprParser();
[ast, parseError] = p.parse('x+2*3');
scope = struct('x', 1);
Evaluator(ast).exec(scope)
ans = 7
```

## FuncExprParser

The class 'FuncExprParser' extends `ExprParser` to also support function calls.

```
p = FuncExprParser();
[ast, parseError] = p.parse('power(sin(x),2) + power(cos(x),2)');
scope = struct('x', 1.5);
Evaluator(ast).exec(scope)
ans = 1
```

## AST Explained

The parser emits an Abstract Syntax Tree (AST). It's not really a tree, but a Directed Acyclic Graph.
On this AST you can, for example,
* evaluate (as an example see test/evalExpr.m)
* validate
* compile

The emitted AST is 
```
ast = p.parse('1.2+3.14')
  [1] = struct
      type = numerical
      value =  1.2
  [2] = struct
      type = numerical
      value =  3.14
  [3] = struct
      type = +
      head =  1
      tail =  2

```
returns a cell array with three nodes. A reference is expressed as an integer pointing to the referenced index.
We will denote the reference to index `I` by `$I`.

### Binary operations
```
prettyPrintAST(p.parse('1.2 + 3.14'))
```
| Index | Rule | Head | Tail |
|-------|------|------|------|
| $1 |  numerical | value: 1.2 |
| $2 |  numerical | value: 3.14 |
| $3 |          + | head: $1 | tail: $2 |

### Binary identifiers

```
prettyPrintAST(p.parse('3.14 + foo'))
```

| Index | Rule | Head | Tail |
|-------|------|------|------|
| $1 |  numerical | value: 3.14 |
| $2 | identifier | name: foo |
| $3 |          + | head: $1 | tail: $2 |

### Function Calls

```
prettyPrintAST(p.parse('power(2, 3)'))
```

| Index | Rule | Head | Tail |
|-------|------|------|------|
| $1 | identifier | name: power |
| $2 |  numerical | value: 2 |
| $3 |  numerical | value: 3 |
| $4 |   funccall | head: $1 | tail: $2, $3  |

### Prefix Operations

```
prettyPrintAST(p.parse('-3'))
```

| Index | Rule | Head | Tail |
|-------|------|------|------|
| $1 |  numerical | value: 3 |
| $2 |     uminus | value: 1 |
```

# Implementation Design

The parser is of the top-down operator precedence variety based on ideas by Vaughan Pratt, see 
http://effbot.org/zone/simple-top-down-parsing.htm or
http://javascript.crockford.com/tdop/tdop.html

TODO: Explain Advantage, disadvantage...

Code must run on both Octave and MATLAB. The former does not support handles to nested functions at least up to version 4.0.
As a workaround we use anonymous functions instead.
The scanner/tokenizer instantiates tokens, which in turn implement parser logic.

# Limitations Octave (as of 4.0)

* Cannot create handle to nested function
* No closures (read/write access to scoped variables)
* Nested functions to methods do not share method scope, not even read only.
