This is a simple and fast parser for GNU Octave or MATLAB®.
It is a single file solution with about 200 lines of code and no dependencies.

The test cases run successfully with GNU Octave 3.8.2 and MATLAB 2013b.
Older versions may break the code.

The parser emits an Abstract Syntax Tree (AST). It's not really a tree, but a Directed Acyclic Graph.
On this AST you can, for example,
* evaluate (as an example see test/evalExpr.m)
* validate
* compile

As far as I know there is one [much more potent parser in MATLAB](http://www.cs.dartmouth.edu/~mckeeman/cs48/lectures/01_lecture.html), admitting I could not make it work for me.

# Usage
```
[ast, parseError] = parse(sentence)
```

## Parameters
```
sentence    The sentence to parse
```
## Returns
```
ast         Linked list of nodes representing an Abstract Syntax Tree
            
parseError  An error string if a parse error has occured
```

# Examples
```
ast = parse('1.2+3.14')
  [1,1] =
      type = numerical
      value =  1.2
  [1,2] =
      type = numerical
      value =  3.14
  [1,3] =
      type = +
      head =  1
      tail =  2

```
returns a cell array with three nodes. A reference is expressed as an integer pointing to the referenced index.
We will denote the reference to index `I` by `$I`.
```
addpath('test')
prettyPrintAST(parse('1.2+3.14'))
```
| Index | Rule | Head | Tail |
|-------|------|------|------|
| $1 |  numerical | value: 1.2 |
| $2 |  numerical | value: 3.14 |
| $3 |          + | head: $1 | tail: $2 |

```
prettyPrintAST(parse('3.14+foo'))
```

| Index | Rule | Head | Tail |
|-------|------|------|------|
| $1 |  numerical | value: 3.14 |
| $2 | identifier | name: foo |
| $3 |          + | head: $1 | tail: $2 |

```
prettyPrintAST(parse('power(2, 2)'))
```

| Index | Rule | Head | Tail |
|-------|------|------|------|
| $1 | identifier | name: power |
| $2 |  numerical | value: 2 |
| $3 |  numerical | value: 2 |
| $4 |   funccall | head: $1 | tail: $2, $3,  |


# Implementation Design

The parser is of the top-down operator precedence variety based on ideas by Vaughan Pratt, see 
http://effbot.org/zone/simple-top-down-parsing.htm or
http://javascript.crockford.com/tdop/tdop.html

TODO: Explain Advantage, disadvantage...

Code must run on both Octave and MATLAB. The former may not support handles to nested functions.
As a workaround we use anonymous functions instead.
The scanner/tokenizer instantiates tokens, which in turn implement parser logic.
This woefull fact prevents us from making the tokenizer a top-level function.
