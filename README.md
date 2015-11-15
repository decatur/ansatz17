Simple non-recursive, shift-reduce, bottom-up parser generator for Octave or MATLAB®.

# Usage:
```
[stack, parseError] = parseLR(sentence, grammar)
```

## Parameters
```
sentence    The sentence to parse
grammar     The grammar rules to apply
```
## Returns
```
stack       Lists of reductions
parseError  An error string if a parse error has occured
```
# Examples
```
ast = parseLR('1+2-3', {'plus->a+b', 'minus->a-b'})
```
returns a cell array with two reductions. A reference is expressed as a singlular cell pointing to the referenced index. In our case `stack{2}.a{1}` points at reduction `1`.
```
disp(ast)
addpath('test')
prettyPrintAST(ast)
```


```
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
```


| 1 | plus | a: 1 | b: 2 |
| 2 | minus | a: ->1 | b: 3 |


For a simple arithmetical expression parser see test.m
