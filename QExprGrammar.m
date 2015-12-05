classdef QExprGrammar < handle
%ExprGrammar Simple expression grammar for expressions of the form 1-(bar+3)*power(2,3)
    properties (SetAccess = public)
    end
    methods
        function sym = numericalToken(this, value)
            function node = numericalNode(type, value)
                node = struct('type', 'numerical');
                node.value = str2double(value);
            end
            sym = struct('type', 'numerical');
            sym.nud = @() numericalNode('numerical', value);
        end

        function sym = identifierToken(this, name)
            function node = identifierNode(type, name)
                node = struct('type', 'identifier');
                node.name = name;
            end
            sym = struct('type', 'identifier', 'value', name);
            sym.nud = @() identifierNode('identifier', name);
            % Handle unit
            function node = unitNode(sym, left)
                node = struct('type', 'unit', 'value', left, 'unit', sym.value);
            end
            sym.lbp = 1;
            sym.led = @(left) unitNode(sym, left);
        end

        function sym = stringToken(this, value)
            function node = stringNode(type, value)
                node = struct('type', 'string');
                node.value = value;
            end
            sym = struct('type', 'string');
            sym.nud = @() stringNode('string', value);
        end

        function createSymbols(this, p)

            function node = binOpNode(sym, left, p)
                node = struct('type', sym.type, 'head', left, 'tail', p.expression(sym.lbp));
            end

            sym = struct('type', '+', 'lbp', 10);
            sym.led = @(left) binOpNode(sym, left, p);
            sym.nud = @() error('Parse:syntax', 'Illegal syntax');
            p.createSymbol(sym);

            sym = struct('type', '-', 'lbp', 10);
            sym.led = @(left) binOpNode(sym, left, p);
            sym.nud = @() error('Parse:syntax', 'Illegal syntax');
            p.createSymbol(sym);
            
            sym = struct('type', '*', 'lbp', 20);
            sym.led = @(left) binOpNode(sym, left, p);
            sym.nud = @() error('Parse:syntax', 'Illegal syntax');
            p.createSymbol(sym);
            
            sym = struct('type', '/', 'lbp', 20);
            sym.led = @(left) binOpNode(sym, left, p);
            sym.nud = @() error('Parse:syntax', 'Illegal syntax');
            p.createSymbol(sym);

            function v = advance1(p, type)
                v = p.expression(0);
                p.next(p, type);
            end

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
            function v = foo(p)
                v = p.expression(0);
                p.next(')');
            end
            sym.nud = @() {v=p.expression(0); p.next(')'); v}{end}; % MATLAB may need subsref
            % Needed in case '(' starts function argument
            sym.lbp = 150;
            sym.led = @(left) argList(p, left);
            p.createSymbol(sym);

            sym = struct('type', ')', 'lbp', 0);
            p.createSymbol(sym);

            sym = struct('type', ',', 'lbp', 0);
            p.createSymbol(sym);

        end
    end % methods
end % classdef

