classdef QtyExprParser < FuncExprParser
%
%Usage:
%   p = QtyExprParser();
%   [ast, parseError] = p.parse('2kg + 1kg');
%   evalExpr(ast)                   -> 3 kilogram
%
%   ast = p.parse('2m / (t s)');
%   scope = struct('t', 5);
%   evalExpr(ast, scope)           -> 0.4 meter/second

    properties (SetAccess = public)
    end
    methods

        
        function qty = parseUnits(this)
            qty = Qty(1);
            qty.numerator = {this.token.value};
            this.next();

            while this.token.type == '/' || this.token.type == '*'
                type = this.token.type;
                this.next();
                
                if ~strcmp(this.token.type, 'unit')
                    break;
                end

                if type == '*'
                    qty.numerator{end+1} = this.token.value;
                else
                    qty.denominator{end+1} = this.token.value;
                end

                this.next();
            end
        end

        function node = numericalNode(this, value)
        % Overloads function in ExprParser class.
            node = struct('type', 'numerical');
            node.value = str2double(value);

            if strcmp(this.token.type, 'identifier')
                qty = this.parseUnits();
                node = struct('type', 'qty', 'value', this.astNode(node), 'unit', qty);
            else
                
            end
        end

        function node = identifierNode(this, value)
        % Overloads function in ExprParser class.
            if strcmp(this.token.type, 'identifier')
                qty = this.parseUnits();
                node = struct('type', 'qty', 'value', value, 'unit', qty);
            else
                node = struct('type', 'identifier');
                node.value = value;
            end
        end

    end
end
