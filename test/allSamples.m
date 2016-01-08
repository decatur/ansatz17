addpath('examples');
scope = struct('x', 1);

%---------------
% ExprParser
%---------------
p = ExprParser();
[ast, parseError] = p.parse('x+2*3');
evalExpr(ast, scope)


%---------------
% FuncExprParser
%---------------
p = FuncExprParser();
[ast, parseError] = p.parse('x+2*3-power(2,3)*(4-1)');
evalExpr(ast, scope)
scope.x = 18;
evalExpr(ast, scope)
