Simple non-recursive, shift-reduce, bottom-up parser generator for Octave or MATLAB®.
This is a single file solution with 200 lines of code and no dependencies.

If `ansatz17` does not suit you, you'll find much more potent parser [elsewhere](http://www.cs.dartmouth.edu/~mckeeman/cs48/lectures/01_lecture.html).

# Restrictions
Currently MATLAB is not supported.

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
ast = parseLR('1+2-3', {'plus->a+b', 'minus->a-b'})
```
returns a cell array with two reductions. A reference is expressed as a singlular cell pointing to the referenced index. In our case `stack{2}.a{1}` points at node `1`.
```
disp(ast)
  [1,1] =
      op = plus
      a =  1
      b =  2

  [1,2] =
      op = minus
      a = 
      {
        [1,1] =  1
      }
      b =  3
      
addpath('test')
prettyPrintAST(ast)
```
| Index | Category | Property A | Property B |
|---|---|---|---|
| 1 | plus | a: 1 | b: 2 |
| 2 | minus | a: ->1 | b: 3 |

```
prettyPrintAST(parseLR('foo+1+foo', {'plus->a+b', 'minus->a-b'}))
```
| Index | Category | Property A | Property B |
|---|---|---|---|
| 1 | id | name: foo |
| 2 | plus | a: ->1 | b: 1 |
| 3 | plus | a: ->2 | b: ->1 |


For a simple arithmetical expression parser see test.m
