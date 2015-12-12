classdef QtyExprParser < FuncExprParser
%
%Usage:
%   p = QtyExprParser();
%   ast = p.parse('2kg + 1kg');
%   evalExpr(ast)                   -> 3 kilogram
%
%   ast = p.parse('2m / (T s)');
%   evalExpr(ast, struct('T', 5))   -> 0.4 meter/second

    properties (SetAccess = public)
    end
    methods

        
        function node = parseUnits(this, left, firstUnit)
            qty = Qty(1);
            qty.numerator = {firstUnit.value};

            while this.token.type == '/' || this.token.type == '*'
                type = this.token.type;
                this.next();
                
                if ~strcmp(this.token.type, 'unit')
                    this.previous();
                    break;
                    %error('Unit expected, found %s', this.token.value);
                end

                if type == '*'
                    qty.numerator{end+1} = this.token.value;
                else
                    qty.denominator{end+1} = this.token.value;
                end

                this.next();
            end

            node = struct('type', 'qty', 'value', left, 'unit', qty);
        end

        function sym = identifierToken(this, value)
            function node = identifierNode(type, value)
                node = struct('type', 'identifier');
                node.value = value;
                %node.f = @(ast, vars) vars.(value);
            end
            if strcmp(value, 'kg') || strcmp(value, 'm') || strcmp(value, 's')
                sym = struct('type', 'unit', 'value', value, 'lbp', 1000);
                sym.led = @(left) this.astNode(this.parseUnits(left, sym));
            else
                sym = struct('type', 'identifier', 'value', value);
                sym.nud = @() this.astNode(identifierNode('identifier', value));
            end
        end

        function addGrammar(this, p)
            addGrammar@FuncExprParser(this);
        end

    end
end
