classdef ExprParser < Parser
% 
%Usage:
%   p = ExprParser();
%   [ast, parseError] = p.parse('1+2*3')
%
% COPYRIGHT Wolfgang Kuehn 2015-2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz17.

    properties (SetAccess = public)
        ast
    end
    
    methods
        
        function ref = astNode(this, node)
            this.ast{end+1} = node;
            ref = length(this.ast);
        end

        function node = numericalNode(this, value)
            node = struct('type', 'numerical');
            node.value = str2double(value);
            %node.f = @(ast, vars) node.value;
        end

        function sym = numericalToken(this, value)
            sym = struct('type', 'numerical', 'value', value);
            sym.nud = @() this.astNode(this.numericalNode(value));
        end

        function node = identifierNode(this, value)
            node = struct('type', 'identifier');
            node.value = value;
        end

        function sym = identifierToken(this, value)
            sym = struct('type', 'identifier', 'value', value);
            sym.nud = @() this.astNode(this.identifierNode(value));
        end

        function sym = stringToken(this, value)
            % Strip delimiters
            value = value(2:end-1);
            function node = stringNode(type, value)
                node = struct('type', 'string');
                node.value = value;
            end
            sym = struct('type', 'string', 'value', value);
            sym.nud = @() this.astNode(stringNode('string', value));
        end

        function addGrammar(this)
            function node = binOpNode(type, lbp, left, p)
                node = struct('type', type, 'head', left, 'tail', p.expression(lbp));
                %node.f = @(ast, vars) ast{node.head}.value + ast{node.tail}.value;
            end

            sym = struct('type', '+', 'lbp', 10);
            sym.led = @(left) this.astNode(binOpNode('plus', sym.lbp, left, this));
            sym.nud = @() {v=this.expression(30); this.astNode(struct('type', 'uplus', 'value', v))}{end};
            this.createSymbol(sym);

            sym = struct('type', '-', 'lbp', 10);
            sym.led = @(left) this.astNode(binOpNode('minus', sym.lbp, left, this));
            sym.nud = @() {v=this.expression(30); this.astNode(struct('type', 'uminus', 'value', v))}{end};
            this.createSymbol(sym);
            
            sym = struct('type', '*', 'lbp', 20);
            sym.led = @(left) this.astNode(binOpNode('times', sym.lbp, left, this));
            sym.nud = @() error('Parse:syntax', 'Illegal syntax');
            this.createSymbol(sym);
            
            sym = struct('type', '/', 'lbp', 20);
            sym.led = @(left) this.astNode(binOpNode('divide', sym.lbp, left, this));
            sym.nud = @() error('Parse:syntax', 'Illegal syntax');
            this.createSymbol(sym);

            % Grouping operator
            sym = struct('type', '(');
            sym.nud = @() {v=this.expression(0); this.next(')'); v}{end}; % MATLAB may need subsref
            this.createSymbol(sym);

            sym = struct('type', ')', 'lbp', 0);
            this.createSymbol(sym);
        end

        function [ast, parseError] = parse(this, sentence)
        % Returns:
        %   ast         Linked list of nodes representing an Abstract Syntax Tree
        %
        % Method overrides Parser.parse() to return the emitted AST.

            this.ast = {};
            parseError = parseInternal(this, sentence);
            ast = this.ast;
        end

    end
end

