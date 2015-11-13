Simple non-recursive, shift-reduce, bottom-up parser generator for MATLAB®.

# Usage:
```
parseLR('1+2-3', {'plus->a+b', 'minus->a-b'})
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
For a simple arithmetical expression parser see test.m
