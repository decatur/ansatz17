classdef ExprEvaluator
%Evaluates an AST against a variable scope.
%
% Usage:
%   p = ExprParser();
%   [ast, parseError] = p.parse('x+2*3');
%   etor = ExprEvaluator(ast);
%   scope = struct('x', 1);
%   etor.exec(scope);       % 
%
% COPYRIGHT Wolfgang Kuehn 2015-2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz17.

properties (SetAccess = public)
    ast
    scope
end

methods (Access = public)

    function this = ExprEvaluator(ast)
        this.ast = ast;
    end

    function value = numerical(this, node)
        value = node.value;
    end

    function value = identifier(this, node)
        if isfield(this.scope, node.value)
            value = this.scope.(node.value);
        else
            % This is a function identifier
            value = node.value;
        end
    end

    function value = plus(this, node)
        value = this.ast{node.head}.value + this.ast{node.tail}.value;
    end

    function value = minus(this, node)
        value = this.ast{node.head}.value - this.ast{node.tail}.value;
    end

    function value = uminus(this, node)
        value = -this.ast{node.value}.value;
    end

    function value = uplus(this, node)
        value = this.ast{node.value}.value;
    end

    function value = times(this, node)
        value = this.ast{node.head}.value * this.ast{node.tail}.value;
    end

    function value = divide(this, node)
        value = this.ast{node.head}.value / this.ast{node.tail}.value;
    end

    function value = funccall(this, node)
        % Dereference argument list
        args = cellfun(@(elem) this.ast{elem}.value, node.tail, 'UniformOutput', false);
        value = feval(this.ast{node.head}.value, args{:});
    end

    function result = exec(this, scope)

        if length(this.ast) == 0
            result = [];
            return;
        end

        if nargin == 1
            this.scope = struct;
        else
            this.scope = scope;
        end

        for k=1:length(this.ast)
            node = this.ast{k};
            this.ast{k}.value = this.(node.type)(node);
        end

        result = this.ast{end}.value;

    end

end % methods

end % classdef