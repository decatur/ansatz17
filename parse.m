function [ast, parseError] = parse(sentence, grammar)
%parse Simple and fast scanner and parser.
%
% Example:
%   [ast, parseError] = parse('1+2*3')
%
% Parameters:
%   sentence    The sentence to parse
%
% Returns:
%   ast         Linked list of nodes representing an Abstract Syntax Tree
%   parseError  An error string if a parse error has occured, otherwise empty
%
% COPYRIGHT Wolfgang Kühn 2015 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz17.

    function ref = addAstNode(node)
        ast{end+1} = node;
        ref = length(ast);
    end

    function left = expression(rbp)
        t = token;
        token = next();
        left = addAstNode(t.nud());
        token
        % TODO: Handle "structure has no member lbp"
        while rbp < token.lbp
            t = token;
            token = next();
            left = addAstNode(t.led(left));
        end

    end

    symbols = struct;

    function createSymbol(sym)
        key = sprintf('%d', double(sym.type));
        symbols.(key) = sym;
    end

    function sym = symbol(s)
        key = sprintf('%d', double(s));
        sym = symbols.(key);
    end

    function node = newNumericalNode(type, value)
        node = struct('type', 'numerical');
        node.value = str2double(value);
    end

    function ref = newStringNode(type, value)
        s = struct('type', 'numerical');
        s.value = value;
        ast{end+1} = s;
        ref = length(ast);
    end

    function ref = newIdentifierNode(type, name)
        s = struct('type', 'identifier');
        s.name = name;
        ast{end+1} = s;
        ref = length(ast);
    end

    function t = numerical_token(value)
        t = struct('type', 'numerical');
        t.nud = @() newNumericalNode('numerical', value);
    end

    function t = string_token(value)
        t = struct('type', 'string');
        t.nud = @() newStringNode('string', value);
    end

    function t = identifier_token(name)
        t = struct('type', 'identifier');
        t.nud = @() newIdentifierNode('identifier', name);
    end

    function v = advance1(type)
        v = expression(0);
        advance(type);
    end

    function advance(type)
        assert(strcmp(token.type, type));
        token = next();
    end

    function t = operator_opengroup_token()
        t = struct('type', '(');
        t.nud = @() advance1(')');
        t.led = @(left) foo(left);
        t.lbp = 150;
    end

    function t = operator_closegroup_token()
        t = struct('type', ')');
        t.lbp = 0;
    end

    function t = operator_comma_token()
        t = struct('type', ',');
        t.lbp = 0;
    end

    function ref = foo(left)
        s = struct('type', 'funccall');
        s.head = left;
        s.tail = {};

        if ~strcmp(token.type, ')')
            while true
                s.tail{end+1} = expression(0);
                if ~strcmp(token.type, ',')
                    break;
                end
                advance(',');
            end
        end
        advance(')');
        ast{end+1} = s;
        ref = length(ast);
    end

    function [tokens, parseError] = tokenizer(in)
        %tokenize Splits a string into a sequence of tokens.
        %
        % Example: 
        %   [out, symbols, identifiers, parseError] = tokenize('foo 33 +bar"123m23" 1.34')
        %   [out, symbols, identifiers, parseError] = tokenize('1+2*3')

        tokens = {};
        parseError = [];
        s = strtrim(in);

        while ~isempty(s)
            [S, E, TE, M, T, NM, SP] = regexp(s, '(?<identifier>[a-z_][a-z0-9_]*)|(?<op>[\+\-\*/\(\),])|\[(?<ref>[^\]]*)\]|"(?<string>[^"]*)"|(?<number>\d+(\.\d*)?(e\d+)?)', 'ignorecase', 'once');
            
            
            if isempty(S) || S ~= 1
                parseError = sprintf('Syntax error at ...%s', s);
                break;
            end

            token = T{1};

            if ~isempty(NM.op)
                token = symbol(token);
            elseif token == '('
                token = operator_opengroup_token();
            elseif token == ')'
                token = operator_closegroup_token();
            elseif token == ','
                token = operator_comma_token();
            elseif ~isempty(NM.number)
                token = numerical_token(NM.number);
            elseif ~isempty(NM.string)
                token = string_token(NM.string);
            elseif ~isempty(NM.identifier)
                token = identifier_token(NM.identifier);
            elseif ~isempty(NM.ref)
                token = identifier_token(NM.ref);
            else
                parseError = sprintf('Invalid token: %s', token);
            end

            s = strtrim(SP{2});
            
            tokens{end+1} = token;
        end

        end_token = struct('type', '(end)');
        end_token.lbp = 0;

        tokens{end+1} = end_token;
    end

    function t = next()
        if index > length(tokens)
            error('Parse:terminate', 'Expression terminated %s', sentence);
        end
        t = tokens{index};
        index = index + 1;
    end

    p = struct;
    p.createSymbol = @(sym) createSymbol(sym);
    p.expression = @(bp) expression(bp);
    grammar(p);

    ast = {};

    [tokens, parseError] = tokenizer(sentence);

    if length(tokens) == 1 || ~isempty(parseError)
        return;
    end

    index = 1;
    token = next();
    
    try
        expression(0);
    catch e
        parseError = e.message;
    end

    if ~isempty(parseError)
        ast = {};
    end


end

