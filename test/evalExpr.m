function result = evalExpr(ast)
%evaluate
%
% Usage:
%   result = evalExpr(ast)
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

    if strcmp(type, '*')
        ast{k}.value = ast{node.head}.value * ast{node.tail}.value;
    elseif strcmp(type, '/')
        ast{k}.value = ast{node.head}.value / ast{node.tail}.value;
    elseif strcmp(type, '+')
        ast{k}.value = ast{node.head}.value + ast{node.tail}.value;
    elseif strcmp(type, '-')
        ast{k}.value = ast{node.head}.value - ast{node.tail}.value;
    elseif strcmp(type, 'identifier')
        if ~isfield(node, 'value')
            error('Eval:undefined', '%s undefined', node.name);
        end
    else
        % A literal node
    end
end

result = ast{end}.value;

end