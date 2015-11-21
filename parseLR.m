function [ast, parseError] = parseLR(sentence, grammar)
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
        if ischar(ref) && ref(1) == 's'
            v = symbols.(ref);
            if isnumeric(v) || ischar(v)
                value = v;
            else
                value = ref;
            end
        elseif ischar(ref) && ref(1) == '_'
            value = { str2double(ref(2:end)) };
        else
            value = ref;
        end
    end

    function ref = pushStack(operation)
        ast{end+1} = operation;
        ref = createRef(length(ast));
    end

    function y = str4num(x)
        y = str2num(x); % TODO: Is there a better way to check for numeric string?
        if isempty(y)
            y = x;
        end
    end

[s, symbols, parseError] = tokenize(sentence);

if ~isempty(parseError)
    return
end

patterns = cell(1, length(grammar));

for k=1:length(grammar)
    parts = strsplit(grammar{k}, '\->', 'delimitertype', 'regularexpression');
    pattern = regexprep(parts{2}, '\s+', '');
    
    pattern = regexprep(pattern, '\+', '\\+');
    pattern = regexprep(pattern, '\-', '\\-');
    pattern = regexprep(pattern, '\*', '\\*');
    pattern = regexprep(pattern, '\(', '\\(');
    pattern = regexprep(pattern, '\)', '\\)');
    
    pattern = regexprep(pattern, 'list', '####');
    pattern = regexprep(pattern, '(\w+)', '\\s*(?<$1>\\w+)\\s*');
    %pattern = regexprep(pattern, '####', '(?<list>(\\w+,)*(\\w+)?)');
    patterns{k} = struct('op', strtrim(parts{1}), 'pattern', pattern);
end

ast = {};
astIndex = 0;
variables = struct;
ruleIndex = 1;

while true
    
    ast
    fprintf(1, 's:%s, ruleIndex:%d\n', s, ruleIndex);
    while ruleIndex <= length(patterns)
        rule = patterns{ruleIndex};
        op = rule.op;
        rule.pattern
        [S, ~, ~, ~, ~, NM, SP] = regexp(s, rule.pattern, 'once');
        if ~isempty(S)
            break
        end
        ruleIndex = ruleIndex + 1;
    end
    
    if isempty(S)
        
        if astIndex == 0
            % Fail
            error('Fail')
            break;
        end

        do
            operation = ast{astIndex};
            'Backtracking'
            operation
            ast{astIndex} = [];
            astIndex = astIndex - 1;

            s = operation.s;
            ruleIndex = 1 + operation.ruleIndex;
            if ruleIndex <= length(patterns)
                break;
            end
        until astIndex == 0
        
        
        continue;
    end
    
    % Reduce
    operation = struct;
    operation.op = op;
    operation.s = s;
    
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

    astIndex = 1 + astIndex;

    ref = createRef(astIndex);
    %dbstop(138);
    operation.s = s;
    operation.ruleIndex = ruleIndex;
    ast{astIndex} = operation;

    if isempty(SP{1}) && isempty(SP{2})
        % Accept
        break;
    end

    s = [SP{1}, ' ', ref, ' ', SP{2}];
    ruleIndex = 1;
        
end

'Done'
s
ast

% Replace all string references by cell references, i.e. _123 by { 123 }.
for j=1:length(ast)
    op = ast{j};
    if ~isstruct(op); continue; end;

    op = rmfield(op, 's');
    op = rmfield(op, 'ruleIndex');

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
    
    
    ast{j} = op;
end

end

