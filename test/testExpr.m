function testExpr()
%test Execute all tests.
%
% COPYRIGHT Wolfgang Kühn 2015 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz17.


function assertTest(s, expected)
    [ast, parseError] = parse(s);
    if ~isempty(parseError)
        fprintf(1, '%s %s\n', parseError, s);
        return
    end
    observed = evalExpr(ast);
    if isempty(observed) && isempty(expected)    
        fprintf(1, 'OK empty\n');
    elseif isequaln(observed, expected)    
        fprintf(1, 'OK %s == %f\n', s, expected);
    else
        fprintf(1, '%s: OBSERVED %f EXPECTED %f\n', s, observed, expected);
    end
    
end

assertTest('', []);
assertTest('1', 1);
assertTest('1+2', 3);
assertTest('1-2+3', 2);
assertTest('+1', 1);
assertTest('-1', -1);
assertTest('3-2-1', 0); % - is left associative
assertTest('1+2*3', 1+2*3); % * takes precedence over +
assertTest('1 + 2*3 + 4', 1+2*3+4);
assertTest('1 +-2', 1+-2);
assertTest('-1 + 1', 0);
assertTest('1 + +2', 1 + +2);
assertTest('1 ++2', 3); % Note: ++ is not a valid MATLAB token
assertTest('1/1', 1);
assertTest('4/2*3', 6);
assertTest('1/0', Inf);

assertTest('2*(1+3)', 2*(1+3));
assertTest('abs(1)', 1);
assertTest('abs(-1)', 1);
assertTest('sin(1+2)', sin(1+2));
assertTest('power(-2,2)', 4);

%assertFailure('1+');
%assertFailure('1+-2');
%assertFailure('1+');
%assertFailure('1+foo');


end