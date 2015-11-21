function [out, symbols, parseError] = tokenize(in)
%tokenize Splits a string into a sequence of tokens.
%
% Example: 
%   [out, symbols, parseError] = tokenize('foo 33 +bar"123m23" 1.34')

[S, E, ~, ~, tokens, NM, SP] = regexp(in, '[a-z_][a-z0-9_]*|[\+\-\*/\(\),]|"[^"]*"|\d+(\.\d*)?(e\d+)?', 'ignorecase');

out = '';
symbols = struct;

% Check for lexical errors
for k=1:length(SP)
    if ~isempty(strtrim(SP{k}))
        if k==1
            start = 1;
        else
            start = E(k-1)+1;
        end
        parseError = sprintf('Syntax error at ...%s', in(start:end));
        return
    end
end

for k=1:length(S)
    name = num2str(k);
    symbols.(name) = in(S(k):E(k));
    out = [out ' ' name];
end

out = strtrim(out);

end
