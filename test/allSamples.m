% COPYRIGHT Wolfgang Kuehn 2015-2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz17.

addpath('examples');
scope = struct('x', 1);

%---------------
% ExprParser
%---------------
p = ExprParser();
[ast, parseError] = p.parse('x+2*3');
y = ExprEvaluator(ast).exec(scope)  % y = 7


%---------------
% FuncExprParser
%---------------
p = FuncExprParser();
[ast, parseError] = p.parse('power(sin(x),2) + power(cos(x),2)');
scope = struct('x', 1.2345);
y = ExprEvaluator(ast).exec(scope)   % y = 1

