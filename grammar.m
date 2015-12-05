function symbols = grammar(p)


    function node = binOpNode(sym, left, p)
        node = struct('type', sym.type, 'head', left, 'tail', p.expression(sym.lbp));
    end


    sym = struct('type', '+', 'lbp', 10);
    sym.led = @(left) binOpNode(sym, left, p);
    sym.nud = @() error('Parse:syntax', 'Illegal syntax');
    p.createSymbol(sym);

    sym = struct('type', '-', 'lbp', 10);
    sym.led = @(left) binOpNode(sym, left, p);
    sym.nud = @() error('Parse:syntax', 'Illegal syntax');
    p.createSymbol(sym);
    
    sym = struct('type', '*', 'lbp', 20);
    sym.led = @(left) binOpNode(sym, left, p);
    sym.nud = @() error('Parse:syntax', 'Illegal syntax');
    p.createSymbol(sym);
    
    sym = struct('type', '/', 'lbp', 20);
    sym.led = @(left) binOpNode(sym, left, p);
    sym.nud = @() error('Parse:syntax', 'Illegal syntax');
    p.createSymbol(sym);

end