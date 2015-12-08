function result = evalExpr(ast, vars)
%evaluate
%
% Usage:
%   result = evalExpr(ast, vars)
%
% COPYRIGHT Wolfgang Kuehn 2015 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz17.

if length(ast) == 0
    result = [];
    return;
end

for k=1:length(ast)
    node = ast{k};    
    type = node.type;

    % TODO: Use a map or attach operation to ast node.
    %ast{k}.value = node.f(ast, vars);
    
    if type == '+'
        ast{k}.value = ast{node.head}.value + ast{node.tail}.value;
    elseif type == '*'
        ast{k}.value = ast{node.head}.value * ast{node.tail}.value;
    elseif type == '/'
        ast{k}.value = ast{node.head}.value / ast{node.tail}.value;
    elseif type == '-'
        ast{k}.value = ast{node.head}.value - ast{node.tail}.value;
    elseif strcmp(type, 'identifier')
        if isfield(vars, node.value)
            ast{k}.value = vars.(node.value);
        end
        if ~isfield(node, 'value')
            % TODO: This may be a function handle, so we cannot check for undefined value.
            %error('Eval:undefined', '%s undefined', node.name);
        end
    elseif strcmp(type, 'funccall')
        % Dereference argument list
        args = cellfun(@(elem) ast{elem}.value, node.tail, 'UniformOutput', false);
        ast{k}.value = feval(ast{node.head}.value, args{:});
    else
        % A literal node
    end
end

result = ast{end}.value;

end