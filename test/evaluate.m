function result = evaluate(ast)
%evaluate
%
% Usage:
%   result = evaluate(ast)
%
% COPYRIGHT Wolfgang Kuehn 2015 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz17.

function value = unref(ref)
    if iscell(ref)
        value = ast{ref{1}};
    else
        value = ref;
    end
end

% In case ast is empty
result = [];

for k=1:length(ast)
    result = ast{k};

    if ~isstruct(result)
        continue;
    end
    
    op = result.op;
    
    if isfield(result, 'left')
        left = unref(result.left);
    end

    if isfield(result, 'right')
        right = unref(result.right);
    end

    if strcmp(op, 'unaryPlus')
        result = right;
    elseif strcmp(op, 'unaryMinus')
        result = -right;
    elseif strcmp(op, 'binaryTimes')
        result = left * right;
    elseif strcmp(op, 'binaryDiv')
        result = left / right;
    elseif strcmp(op, 'binaryPlus')
        result = left + right;
    elseif strcmp(op, 'binaryMinus')
        result = left - right;
    elseif strcmp(op, 'group')
        result = right;
    elseif strcmp(op, 'func')
        args = result.list;
        for k=1:length(args)
            args{k} = unref(args{k});
        end
        funcRule = unref(result.name);
        result = feval(funcRule.name, args{:});
    end

    ast{k} = result;
end

end