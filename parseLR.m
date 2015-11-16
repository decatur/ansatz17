function [stack, parseError] = parseLR(sentence, grammar)
%parseLR Simple Non-recursive, Shift-Reduce, Bottom-Up parser generator with one look ahead LR(1).
%
% Example:
%   ast = parseLR('1+2-3', {'plus->a+b', 'minus->a-b'})
%
% Parameters:
%   sentence    The sentence to parse
%   grammar     The grammar rules to apply
%
% Returns:
%   ast         Lists of reductions
%   parseError  An error string if a parse error has occured
%
% Tests are in test()
%
% COPYRIGHT Wolfgang Kühn 2015 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz17.

    function ref = createRef(index)
        ref = sprintf('_%d', index);
    end

    function value = unref(ref)
        if ischar(ref) && ref(1) == '_'
            value = { str2double(ref(2:end)) };
        else
            value = ref;
        end
    end

    function ref = pushStack(operation)
        stack{end+1} = operation;
        ref = createRef(length(stack));
    end

    function y = str4num(x)
        y = str2num(x); % TODO: Is there a better way to check for numeric string?
        if isempty(y)
            y = x;
        end
    end

parseError = [];
% TODO: rename s
s = sentence;

patterns = cell(1, length(grammar));

for k=1:length(grammar)
    parts = strsplit(grammar{k}, '\->', 'delimitertype', 'regularexpression'); % Octave \-> must be ->
    pattern = regexprep(parts{2}, '\s+', '');
    
    pattern = regexprep(pattern, '\+', '\\+');
    pattern = regexprep(pattern, '\-', '\\-');
    pattern = regexprep(pattern, '\*', '\\*');
    pattern = regexprep(pattern, '\(', '\\(');
    pattern = regexprep(pattern, '\)', '\\)');
    
    pattern = regexprep(pattern, 'list', '####');
    pattern = regexprep(pattern, '(\w+)', '(?<$1>\\w+)'); % Octave \w -> w
    pattern = regexprep(pattern, '####', '(?<list>(\\w+,)*(\\w+)?)');
    patterns{k} = struct('op', strtrim(parts{1}), 'pattern', pattern);
end

stack = {};
variables = struct;
j = 1;

[S, E, ~, ~, tokens, NM, SP] = regexp(s, '(\w+)|([\+\-\*/\(\),])|("[^"]*")');

if isempty(tokens)
    % Shortcut empty input sequence.
    return
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
        [S, ~, ~, ~, ~, NM, SP] = regexp(s, [patterns{k}.pattern '$'], 'once');
        if ~isempty(S)
            break
        end
    end
    
    if isempty(S)
        if j <= length(tokens)
            % Shift token
            token = tokens{j}{1};
            
            if token(1) == '"'
                token = pushStack(token(2:end-1));
            elseif isempty(str2num(token)) && ~isempty(regexp(token, '\w+', 'once'))
                % Note: i, NaN, InF, etc. are all numbers, not a token
                
                if ~isfield(variables, token)
                    operation = struct;
                    operation.op = 'id';
                    operation.name = token;
                    variables.(token) = 1+length(stack);
                    token = pushStack(operation);
                else
                    token = createRef(variables.(token));
                end
                
            end
            
            s = [s, token];
            j = j + 1;
            continue;
        else
            % Accept
            break;
        end
    end
    
    
    if strcmp(op, 'binaryPlus') || strcmp(op, 'binaryMinus')
        if j <= length(tokens) && strcmp(tokens{j}{1}, '*')
            s = [s, tokens{j}{1}];
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
    
    s = [SP{1}, pushStack(operation)];
end

%s
%stack
if length(tokens) == 1 && isempty(stack)
    % Input was a single numeric token, for exampel 13, or an operator.
    token = tokens{1}{1};
    num = str2num(token);
    % Shortcut single input token.
    if isempty(num)
        parseError = sprintf('Syntax error at ...%s', s);
        return
    end
    stack{1} = num;
elseif isempty(regexp(s, '^_\d+$', 'once'))
    stack = [];
    parseError = sprintf('Parse error: %s', s);
    return;
end


% Replace all string references by cell references, i.e. _123 by { 123 }.
for j=1:length(stack)
    op = stack{j};
    if ~isstruct(op); continue; end;
    
    fields = fieldnames(op);
    for k=1:length(fields)
        name = fields{k};
        if strcmp(name, 'op')
            continue;
        elseif strcmp(name, 'list')
            list = op.list;
            for l=1:length(list)
                list{l} = unref(list{l});
            end
            op.list = list;
        else
            op.(name) = unref(op.(name));
        end
    end
    
    
    stack{j} = op;
end

end

