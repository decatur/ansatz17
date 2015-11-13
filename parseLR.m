% COPYRIGHT Wolfgang Kühn 2015. You may do anything you like with 
% this file except remove or modify this copyright.

function [stack, parseError] = parseLR(sentence, grammar)
% Simple Non-recursive, Shift-Reduce, Bottom-Up parser generator with one look ahead LR(1).
%
% Usage:
%   parseLR('1+2-3', {'plus->a+b', 'minus->a-b'})
%
% Parameters:
%   sentence    The sentence to parse
%   grammar     The grammar rules to apply
%
% Returns:
%   stack       Lists of reductions
%   parseError  An error string if a parse error has occured
%
% Tests are in test()

function ref = pushStack(operation)
    stack{end+1} = operation;
    ref = ['_' num2str(length(stack))];
endfunction

function y = str4num(x)
    y = str2num(x);
    if isempty(y)
        y = x;
    end
endfunction

parseError = [];
% TODO: rename s
s = sentence;

patterns = cell(1, length(grammar));

for k=1:length(grammar)
    parts = strsplit(grammar{k}, "->", "delimitertype", "regularexpression");
    pattern = regexprep(parts{2}, '\s+', '');

    pattern = regexprep(pattern, '\+', '\+');
    pattern = regexprep(pattern, '\-', '\-');
    pattern = regexprep(pattern, '\*', '\*');
    pattern = regexprep(pattern, '\(', '\(');
    pattern = regexprep(pattern, '\)', '\)');

    pattern = regexprep(pattern, 'list', '####');
    pattern = regexprep(pattern, '(\w+)', '(?<$1>\w+)');
    pattern = regexprep(pattern, '####', '(?<list>(\w+,)*(\w+)?)');
    patterns{k} = struct('op', strtrim(parts{1}), 'pattern', pattern);
end

stack = {};
j = 1;

[S, E, TE, M, tokens, NM, SP] = regexp(s, '(\w+)|([\+\-\*/\(\),])|("[^"]*")');

if length(tokens) == 0
    % Shortcut empty input sequence.
    return
end

if length(tokens) == 1
    % Shortcut single input token.
    if isempty(regexp(tokens{1}{1}, '^\w+$'))
        parseError = sprintf('Syntax error at ...%s', s);
        return
    end
    stack{1} = str4num(tokens{1}{1});
    return;
end

% Check for lexical errors
for k=1:length(SP)
    if ~isempty(strtrim(SP{k}))
        if k==1
            start = 1;
        else
            start = E(k-1)+1;
        end
        parseError = sprintf('Syntax error at ...%s', s(start:end));
        return
    end
end

s = '';

while true

    %printf('s = %s\n', s);
    for k = 1:length(patterns)
        op = patterns{k}.op;
        % Always match right end. 
        %[patterns{k}.pattern '$']
        [S, E, TE, M, T, NM, SP] = regexp(s, [patterns{k}.pattern '$'], 'once');
        if ~isempty(S)
            break
        end
    end

    if isempty(S)
        if j <= length(tokens)
            % Shift token
            token = tokens{j}{1};

            if token(1) == '"'
                operation = struct;
                operation.op = 'quote';
                operation.right = token(2:end-1);
                token = pushStack(operation);
            end

            s = cstrcat(s, token);
            j = j + 1;
            continue;
        else
            % Accept
            break;
        end
    end


    if strcmp(op, 'binaryPlus') || strcmp(op, 'binaryMinus')
        if j <= length(tokens) && strcmp(tokens{j}{1}, '*')
            s = cstrcat(s, tokens{j}{1});
            j = j + 1;
            continue;
        end
    end

    % Reduce
    operation = struct;
    operation.op = op;

    fields = fieldnames(NM);
    for k=1:length(fields)
        name = fields{k};
        if strcmp(name, 'list')
            list = regexp(NM.list,'(\w+)', 'tokens');
            for l=1:length(list)
                list{l} = str4num(list{l}{1});
            end
            operation.list = list;
        else 
            operation.(name) = str4num(NM.(name));
        end
    end

    s = cstrcat(SP{1}, pushStack(operation));
end

%s
%stack

if isempty(regexp(s, '^_\d+$'))
    stack = [];
    parseError = sprintf('1Parse error: %s', s);
    return;
end

%stack

for j=1:length(stack)
    op = stack{j};

    fields = fieldnames(op);
    for k=1:length(fields)
        name = fields{k};
        if strcmp(name, 'op')
            continue;
        elseif strcmp(name, 'list')
            list = op.list;
            for l=1:length(list)
                item = list{l};
                if item(1) == '_'
                    list{l} = {str2num(item(2:end))};
                end
            end
            op.list = list;
        elseif op.(name)(1) == '_'
            op.(name) = {str2num(op.(name)(2:end))};
        end
    end

    
    stack{j} = op;
end


endfunction
