function [ast, parseError] = parse(sentence)
%parse Simple and fast scanner and parser.
%
% Example:
%   ast = parse('1+2*3')
%
% Parameters:
%   sentence    The sentence to parse
%
% Returns:
%   ast         Lists of reductions
%   parseError  An error string if a parse error has occured
%
% Tests are in test()
% See http://effbot.org/zone/simple-top-down-parsing.htm
%
% Implementation Design:
% Code must run on both Octave and MATLAB. The former may not support handles to nested functions.
% As a workaround we use anonymous functions instead.
% The scanner/tokenizer instanceiates tokens, which in turn implement parser logic.
% This woefull fact prevents us from making the tokenizer a top-level function.
%
% COPYRIGHT Wolfgang Kühn 2015 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz17.

    function left = expression(rbp)
        t = token;
        token = next();
        left = t.nud();
        while rbp < token.lbp
            t = token;
            token = next();
            left = t.led(left);
        end
    end

    function t = numerical_token(value)
        t = struct('type', 'numerical');
        t.value = str2double(value);
        t.nud = @() t.value;
    end

    function t = string_token(value)
        t = struct('type', 'string');
        t.value = value;
        t.nud = @() t.value;
    end

    function t = identifier_token(value)
        t = struct('type', 'identifier');
        t.value = value;
        ast{end+1} = struct('type', 'identifier', 'name', value);
        ref = { length(ast) };
        t.nud = @() ref;
    end

    function ref = newHeadTailNode(type, left)
        s = struct('type', type);
        s.head = left;
        s.tail = expression(10);
        ast{end+1} = s;
        ref = { length(ast) };
    end

    function t = operator_bin_token(op, lbp)
        t = struct('type', op);
        t.lbp = lbp;
        t.led = @(left) newHeadTailNode(op, left);
        t.nud = @() error('Parse:syntax', 'Illegal syntax');
    end

    function v = expect(type)
        v = expression(0);
        assert(strcmp(token.type, type));
        token = next();
    end

    function t = operator_opengroup_token()
        t = struct('type', '(');
        t.nud= @() expect(')');
    end

    function t = operator_closegroup_token()
        t = struct('type', ')');
        t.lbp = 0;
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
        [S, E, TE, M, T, NM, SP] = regexp(s, '(?<identifier>[a-z_][a-z0-9_]*)|(?<op>[\+\-\*/\(\),])|"(?<string>[^"]*)"|(?<number>\d+(\.\d*)?(e\d+)?)', 'ignorecase', 'once');
        
        
        if isempty(S) || S ~= 1
            parseError = sprintf('Syntax error at ...%s', s);
            break;
        end

        token = T{1};

        if token == '+' || token == '-'
            token = operator_bin_token(token, 10);
        elseif token == '*' || token == '/'
            token = operator_bin_token(token, 20);
        elseif token == '('
            token = operator_opengroup_token();
        elseif token == ')'
            token = operator_closegroup_token();
        elseif ~isempty(NM.number)
            token = numerical_token(NM.number);
        elseif ~isempty(NM.string)
            token = string_token(NM.string);
        elseif ~isempty(NM.identifier)
            token = identifier_token(NM.identifier);
        else
            error('Invalid token: %s', token)
        end

        s = strtrim(SP{2});
        
        tokens{end+1} = token;
    end

    end_token = struct;
    end_token.lbp = 0;

    tokens{end+1} = end_token;

    end

    function t = next()
        if index > length(tokens)
            error('Parse:terminate', 'Expression terminated');
        end
        t = tokens{index};
        index = index + 1;
    end

    ast = {};

    [tokens, parseError] = tokenizer(sentence);
    index = 1;
    token = next();

    if length(tokens) == 1
        % Empty input
        return;
    end

    if length(tokens) == 2 && ...
        ( strcmp(token.type, 'numerical') || strcmp(token.type, 'string') )
        % Single literal input.
        ast = token.value;
        return;
    end
    
    try
        expression(0);
    catch e
        parseError = e;
    end
end

