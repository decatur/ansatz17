function [out, symbols, parseError] = tokenize(in)
%tokenize Splits a string into a sequence of tokens.
%
% Example: 
%   [out, symbols, parseError] = tokenize('foo 33 +bar"123m23" 1.34')
%   [out, symbols, parseError] = tokenize('1+2*3')


out = '';
symbols = struct;
parseError = [];
s = in;
count = 1;

do
    [S, E, TE, M, T, NM, SP] = regexp(s, '(?<id>[a-z_][a-z0-9_]*)|(?<op>[\+\-\*/\(\),])|"(?<string>[^"]*)"|(?<number>\d+(\.\d*)?(e\d+)?)', 'ignorecase', 'once');
    
    
    if isempty(S) || S ~= 1
        parseError = sprintf('Syntax error at ...%s', s);
        break;
    end

    key = ['s' num2str(count)];
    token = T{1};

    if ~isempty(NM.id)
        symbols.(key) = { NM.id };
        token = key;
    elseif ~isempty(NM.string)
        symbols.(key) = NM.string;
        token = key;
    elseif ~isempty(NM.number)
        symbols.(key) = str2num(NM.number);
        token = key;
    end

    s = SP{2};
    count = count + 1;
    out = [out ' ' token];
until isempty(s)

