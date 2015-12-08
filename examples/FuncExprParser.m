classdef FuncExprParser < ExprParser
% %Usage:
%   p = FuncExprParser();
%   [ast, parseError] = p.parse('1+sin(2*3)')
    
    methods (Access = private)

        function node = argList(this, left)
            % Parse argument list of function call
            node = struct('type', 'funccall', 'head', left);
            node.tail = {};

            if ~strcmp(this.token.type, ')')
                while true
                    node.tail{end+1} = this.expression(0);
                    if ~strcmp(this.token.type, ',')
                        break;
                    end
                    this.next(',');
                end
            end

            this.next(')');
        end

    end

    methods (Access = public)

        function addGrammar(this)
            addGrammar@ExprParser(this, this);

            sym = this.symbol('(');
            sym.lbp = 150;
            sym.led = @(left) this.astNode(this.argList(left));
            this.createSymbol(sym);

            sym = struct('type', ',', 'lbp', 0);
            this.createSymbol(sym);

        end

    end % methods
end % classdef

