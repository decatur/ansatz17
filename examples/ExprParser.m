classdef ExprParser < Parser
%ExprGrammar Simple expression grammar for expressions of the form 1-(bar+3)*power(2,3)
    properties (SetAccess = public)
        ast
    end
    methods

        function obj = ExprGrammar()

        end
        
        function ref = astNode(this, node)
            this.ast{end+1} = node;
            ref = length(this.ast);
        end

        function sym = numericalToken(this, value)
            function node = numericalNode(type, value)
                node = struct('type', 'numerical');
                node.value = str2double(value);
            end
            sym = struct('type', 'numerical', 'value', value);
            sym.nud = @() this.astNode(numericalNode('numerical', value));
        end

        function sym = identifierToken(this, value)
            function node = identifierNode(type, value)
                node = struct('type', 'identifier');
                node.value = value;
            end
            sym = struct('type', 'identifier', 'value', value);
            sym.nud = @() this.astNode(identifierNode('identifier', value));
        end

        function sym = stringToken(this, value)
            function node = stringNode(type, value)
                node = struct('type', 'string');
                node.value = value;
            end
            sym = struct('type', 'string', 'value', name);
            sym.nud = @() this.astNode(stringNode('string', value));
        end

        function createSymbols(this, p)

            function node = binOpNode(sym, left, p)
                node = struct('type', sym.type, 'head', left, 'tail', p.expression(sym.lbp));
            end

            sym = struct('type', '+', 'lbp', 10);
            sym.led = @(left) this.astNode(binOpNode(sym, left, p));
            sym.nud = @() error('Parse:syntax', 'Illegal syntax');
            p.createSymbol(sym);

            sym = struct('type', '-', 'lbp', 10);
            sym.led = @(left) this.astNode(binOpNode(sym, left, p));
            sym.nud = @() error('Parse:syntax', 'Illegal syntax');
            p.createSymbol(sym);
            
            sym = struct('type', '*', 'lbp', 20);
            sym.led = @(left) this.astNode(binOpNode(sym, left, p));
            sym.nud = @() error('Parse:syntax', 'Illegal syntax');
            p.createSymbol(sym);
            
            sym = struct('type', '/', 'lbp', 20);
            sym.led = @(left) this.astNode(binOpNode(sym, left, p));
            sym.nud = @() error('Parse:syntax', 'Illegal syntax');
            p.createSymbol(sym);

            function node = argList(p, left)
                node = struct('type', 'funccall');
                node.head = left;
                node.tail = {};

                if ~strcmp(p.token.type, ')')
                    while true
                        node.tail{end+1} = p.expression(0);
                        if ~strcmp(p.token.type, ',')
                            break;
                        end
                        p.next(p, ',');
                    end
                end

                p.next(p, ')');
            end
        
            sym = struct('type', '(');
            % Needed in case '(' is opening group
            sym.nud = @() {v=p.expression(0); p.next(')'); v}{end}; % MATLAB may need subsref
            
            % Needed in case '(' starts function argument
            sym.lbp = 150;
            sym.led = @(left) this.astNode(argList(p, left));
            p.createSymbol(sym);

            sym = struct('type', ')', 'lbp', 0);
            p.createSymbol(sym);

            sym = struct('type', ',', 'lbp', 0);
            p.createSymbol(sym);

        end

        function [ast, parseError] = parse(this, sentence)
        % Returns:
        %   ast         Linked list of nodes representing an Abstract Syntax Tree
        %
        % Method overrides Parser.parse() to return the emitted AST.

            this.ast = {};
            [~, parseError] = parse@Parser(this, sentence);
            ast = this.ast;
        end

    end % methods
end % classdef

