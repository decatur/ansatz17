You found a simple, non-recursive, shift-reduce, bottom-up parser generator for GNU Octave or MATLAB®.
It is a single file solution with 200 lines of code and no dependencies.

# Restrictions
The test cases run successfully with GNU Octave 3.8.2 and MATLAB 2013b.
Older versions may break the code.

As far as I know there is one [much more potent parser in MATLAB](http://www.cs.dartmouth.edu/~mckeeman/cs48/lectures/01_lecture.html), admitting I could not make it work for me.


# Usage
```
[ast, parseError] = parseLR(sentence, grammar)
```

## Parameters
```
sentence    The sentence to parse
grammar     The grammar rules to apply
```
## Returns
```
ast         Abstract syntax tree as a linear lists of reductions
parseError  An error string if a parse error has occured
```
# Examples
```
ast = parseLR('1+2-3', {'plus->left+right', 'minus->left-right'})
  [1,1] =
      op = plus
      left =  1
      right =  2

  [1,2] =
      op = minus
      left = {1}  % Or $1 as a shortcut
      right =  3
```
returns a cell array with two reductions. A reference is expressed as a singlular cell pointing to the referenced index. We will say `$1` (as a shortcut for `{1}`) references node `1`.
```
addpath('test')
prettyPrintAST(ast)
```
| Index | Rule | Property A | Property B |
|---|---|---|---|
| 1 | plus | left: 1 | right: 2 |
| 2 | minus | left: $1 | right: 3 |

```
prettyPrintAST(parseLR('foo+1+foo', {'plus->left+right', 'minus->left-right'}))
```
| Index | Rule | Property A | Property B |
|---|---|---|---|
| 1 | id | name: foo |
| 2 | plus | left: $1 | right: 1 |
| 3 | plus | left: $2 | right: $1 |


For a simple arithmetical expression parser see test.m
