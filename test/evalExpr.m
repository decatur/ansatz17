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
            % TODO: This may be a function handle, so we cannot check for undefined value.
            %error('Eval:undefined', '%s undefined', node.name);
        end
    elseif strcmp(type, 'funccall')
        args = {};
        for l=1:length(node.tail)
            args{end+1} = ast{node.tail{l}}.value;
        end
        ast{k}.value = feval(ast{node.head}.name, args{:});
    else
        % A literal node
    end
end

result = ast{end}.value;

end