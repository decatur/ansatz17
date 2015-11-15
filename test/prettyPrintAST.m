function buffer = prettyPrintAST(ast)
    buffer = '';

    function append(chunk)
        buffer = sprintf('%s%s', buffer, num2str(chunk));
    endfunction

    function s = unref(ref)
        if iscell(ref)
            s = sprintf('->%d', ref{1});
        else
            s = num2str(ref);
        end
    endfunction
    
    for j=1:length(ast)
        append(sprintf('[ '));
        op = ast{j};
        if isstruct(op)
            append(op.op);
            fields = fieldnames(op);
            for k=1:length(fields)
                name = fields{k};
                if strcmp(name, 'op')
                    % skip
                elseif strcmp(name, 'list')
                    append(' | args: ');
                    list = op.list;
                    sep = '';
                    for l=1:length(list)
                        append(sprintf('%s%s', sep, unref(list{l})));
                        sep = ', ';
                    end
                    op.list = list;
                else
                    %sprintf(' | %s: %s', name, unref(op.(name)))
                %dbstop(34);
                    append(sprintf(' | %s: %s', name, unref(op.(name))));
                end
            end
        else
            append(ast{j});
        end
        append(sprintf(' ]\n'));
    end
endfunction