classdef QtyExprParser < FuncExprParser
%
% %Usage:
%   p = QtyExprParser();
%   [ast, parseError] = p.parse('1[g] + 2[kg]')

    properties (SetAccess = public)
    end
    methods

        function node = unitLed(this, left, unit)
            node = struct('type', 'quantity', 'value', left, 'unit', unit);
        end

        function sym = unitToken(this, value)
            function node = unitNode(type, value)
                node = struct('type', 'unit', 'value', value);
            end
            sym = struct('type', 'unit', 'value', value);
            sym.nud = @() unitNode('unit', value);
            sym.lbp = 100;
            sym.led = @(left) this.astNode(this.unitLed(left, value));
        end

        function addGrammar(this, p)
            addGrammar@FuncExprParser(this);
            % Match anything between [...]
            this.patterns.unit = '\[[^\]]*\]';
        end

    end
end

