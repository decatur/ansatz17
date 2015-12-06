classdef Parser < handle
%Parser Simple and fast scanner and parser.
%Usage:
%   p = ExprParser();
%   [ast, parseError] = p.parse('1+2*3')

%   p = ExprParser();
%   [ast, parseError] = p.parse('1+2*3')
%
% COPYRIGHT Wolfgang Kuehn 2015 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz17.


    properties (SetAccess = public)
        token
        tokens
        index
        sentence
        symbols
        pattern
    end

    methods (SetAccess = public)

function init(this)
    this.symbols = struct();
    this.createSymbols(this);

    % Concat all quoted symbol types
    opPattern = strjoin(cellfun(@(sym) ['\' sym.type], struct2cell(this.symbols), 'UniformOutput', false), '');
    identifierPattern = '[a-z_][a-z0-9_]*';
    stringPattern = '[^"]*';
    numberPattern = '\d+(\.\d*)?(e\d+)?';

    this.pattern = sprintf('(?<identifier>%s)|(?<op>[%s])|"(?<string>%s)"|(?<number>%s)', identifierPattern, opPattern, stringPattern, numberPattern);
end

function left = expression(this, rbp)
    
    t = this.token;
    this.next();
    left = t.nud();
    assert(isfield(this.token, 'lbp'), 'At %s', this.token.type);
    while rbp < this.token.lbp
        t = this.token;
        this.next();
        left = t.led(left);
    end
end

function next(this, varargin)
% Advance to next token. The optional second argument is an expected token type for the current token.
    if nargin == 2
        assert(strcmp(this.token.type, varargin{1}));
    end
    if this.index > length(this.tokens)
        error('Parse:terminate', 'Expression terminated %s', this.sentence);
    end
    this.token = this.tokens{this.index};
    this.index = this.index + 1;
end

function createSymbol(this, sym)
    key = sprintf('%x', uint8(sym.type));
    this.symbols.(key) = sym;
end

function [tokens, parseError] = tokenize(this, in)
    %tokenize Splits a string into a sequence of tokens.
    %
    % Example:
    %   [tokens, parseError] = p.tokenize('foo 33 +bar"123m23" 1.34')

    function sym = symbol(s)
        key = sprintf('%x', uint8(s));
        sym = this.symbols.(key);
    end

    tokens = {};
    parseError = [];
    s = strtrim(in);

    while ~isempty(s)
        [S, E, TE, M, T, NM, SP] = regexp(s, this.pattern, 'ignorecase', 'once');
        
        
        if isempty(S) || S ~= 1
            parseError = sprintf('Syntax error at ...%s', s);
            break;
        end

        token = T{1};

        if ~isempty(NM.op)
            token = symbol(token);
        elseif ~isempty(NM.number)
            token = this.numericalToken(NM.number);
        elseif ~isempty(NM.string)
            token = this.stringToken(NM.string);
        elseif ~isempty(NM.identifier)
            token = this.identifierToken(NM.identifier);
        else
            parseError = sprintf('Invalid token: %s', token);
        end

        s = strtrim(SP{2});
        
        tokens{end+1} = token;
    end

    end_token = struct('type', '(end)', 'lbp', 0);

    tokens{end+1} = end_token;
end

function parseError = parse(this, sentence)
% Parameters:
%   sentence    The sentence to parse
%
% Returns:
%   parseError  An error string if a parse error has occured, otherwise empty
%

    if isempty(this.symbols)
        this.init()
    end

    [this.tokens, parseError] = this.tokenize(sentence);

    if length(this.tokens) == 1 || ~isempty(parseError)
        return;
    end

    this.index = 1;
    this.next();
    
    try
        this.expression(0);
    catch e
        parseError = e.message;
    end

end 

end % public methods

methods (SetAccess = private)
end % private methods

end % Parser
