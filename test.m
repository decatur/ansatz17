% COPYRIGHT Wolfgang Kühn 2015 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz17.

function test()

% A simple grammar for arithmetical +-*/() expressions.
grammar = { ...
    'func -> func(list)', ...
    'group -> (right)', ...
    'binaryTimes -> left * right', ...
    'binaryDiv -> left / right', ...
    'binaryPlus -> left + right', ...
    'binaryMinus -> left - right', ...
    'unaryMinus -> -right', ...
    'unaryPlus -> +right'
};

function r = assertTest(s, expected)
    [stack, parseError] = parseLR(s, grammar);
    assert(parseError, []);
    observed = evaluate(stack);    
    assert(observed == expected, '%s: OBSERVED %f EXPECTED %f', s, observed, expected);
    printf('OK %s == %f\n', s, expected);
endfunction


assert(length(parseLR('1+2', grammar)), 1);

assertTest('1', 1);
assertTest('1+2', 3);
assertTest('+1', 1);
assertTest('-1', -1);
assertTest('1+2*3', 1+2*3);
assertTest('1 + 2*3 + 4', 1+2*3+4);
assertTest('1 +-2', 1+-2);
assertTest('-1 + 1', 0);
assertTest('1 + +2', 1 + +2);
assertTest('1 ++2', 3); % Note: ++ is not a valid MATLAB token
assertTest('1/1', 1);
assertTest('1/0', Inf);
assertTest('1+i', 1+i);

assertTest('2*(1+3)', 2*(1+3));
assertTest('abs(1)', 1);
assertTest('abs(-1)', 1);
assertTest('sin(1+2)', sin(1+2));
assertTest('power(-2,2)', 4);

endfunction