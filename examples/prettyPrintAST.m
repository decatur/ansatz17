function buffer = prettyPrintAST(ast)
%prettyPrintAST
%
% Usage:
%   buffer = prettyPrintAST(ast)
%
% COPYRIGHT Wolfgang Kuehn 2015 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz17.

    buffer = '';

    function append(chunk)
        buffer = sprintf('%s%s', buffer, num2str(chunk));
    end

    
    for j=1:length(ast)
        node = ast{j};
        append(sprintf('| %2s | %10s', ['$' num2str(j)], node.type));
        fields = fieldnames(node);
        for k=1:length(fields)
            key = fields{k};
            if strcmp(key, 'type')
                % skip
            elseif strcmp(key, 'head') || strcmp(key, 'tail')
                if isnumeric(node.(key))
                    append(sprintf(' | %s: $%d', key, node.(key)));
                else
                    args = strjoin(cellfun(@(el)['$' num2str(el)], node.(key), 'UniformOutput', false), ', ');
                    append(sprintf(' | %s: %s', key, args));
                end
            else
                append(sprintf(' | %s: %s', key, num2str(node.(key))));
            end
        end
        append(sprintf(' |\n'));
    end
end