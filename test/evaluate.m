% COPYRIGHT Wolfgang Kühn 2015 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz17.

function result = evaluate(stack)

function value = unref(ref)
    if iscell(ref)
        value = stack{ref{1}};
    else
        value = ref;
    end
endfunction

for i=1:length(stack)
    operation = stack{i};
    if ~isstruct(operation)
        continue;
    end
    
    op = operation.op;
    
    if isfield(operation, 'left')
        left = unref(operation.left);
    end

    if isfield(operation, 'right')
        right = unref(operation.right);
    end

    if strcmp(op, 'unaryPlus')
        stack{i} = right;
    elseif strcmp(op, 'unaryMinus')
        stack{i} = -right;
    elseif strcmp(op, 'binaryTimes')
        stack{i} = left * right;
    elseif strcmp(op, 'binaryDiv')
        stack{i} = left / right;
    elseif strcmp(op, 'binaryPlus')
        stack{i} = left + right;
    elseif strcmp(op, 'binaryMinus')
        stack{i} = left - right;
    elseif strcmp(op, 'group')
        stack{i} = right;
    elseif strcmp(op, 'func')
        args = operation.list;
        for k=1:length(args)
            args{k} = unref(args{k});
        end
        stack{i} = feval(unref(operation.name).name, args{:});
    end
end

result = stack{end};

endfunction