function symbols = grammar()
    symbols = {};

    function sym = operator_bin_token(expr, type, lbp)
        sym = struct('type', type);
        sym.lbp = lbp;
        sym.led = @(left) struct('type', type, 'head', left, 'tail', expr(lbp))
        sym.nud = @() error('Parse:syntax', 'Illegal syntax %s');
    end

    symbols{end+1} = @(expr) operator_bin_token(expr, '+', 10);
    symbols{end+1} = @(expr) operator_bin_token(expr, '-', 10);
    symbols{end+1} = @(expr) operator_bin_token(expr, '*', 20);
    symbols{end+1} = @(expr) operator_bin_token(expr, '/', 20);
end