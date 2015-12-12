classdef Qty
%
%Usage:
%   mass = Qty(81, 'kg')        -> 81 kg
%   mass.to('g')                -> 81000 g
%   
%   height = Qty(1.88, 'm')     -> 1.88 m
%   height.to('cm')             -> 188 cm
%   bmi = mass/height^2         -> 22.9176 kilogram/meter/meter
%
%   2/height                    -> 1.06383 1/m
%   mass.to('m')                -> error: Cannot onvert kg to m
%   mass + height               -> Arguments 81 kg and 1.88 m are not compatible by unit

    properties (SetAccess = public)
        scalar
        numerator = {};
        denominator = {};
    end

    methods

        function qty = Qty(scalar, unit)
            qty.scalar = scalar;
            if nargin == 2 && ischar(unit)
                [qty.numerator, qty.denominator] = Qty.parse(unit);
            % Bug: In Octave you cannot pass class instance to constructor???
            % elseif isa(unit, 'Qty')
            %    qty.numerator = unit.numerator;
            %    qty.denominator = unit.denominator;
            else
                qty.numerator = {};
                qty.denominator = {};
            end
        end

        function unit = getUnit(this)
            if ~isempty(this.numerator) && ~isempty(this.denominator)
                unit = sprintf('%s/%s', strjoin(this.numerator, '*'), strjoin(this.denominator, '/'));
            elseif isempty(this.denominator)
                unit = sprintf('%s', strjoin(this.numerator, '*'));
            elseif isempty(this.numerator)
                unit = sprintf('1/%s', strjoin(this.denominator, '/'));
            else
                unit = '1';
            end
        end

        function display(this)
            this.toString()
        end

        function s = toString(this)
            s = sprintf('%g %s', this.scalar, this.getUnit());
        end

        function qty = resolve(this)
            num = {};
            den = {};
            scalar = this.scalar;
            for k=1:length(this.numerator)
                q = Qty.getUnitByName(this.numerator{k});
                scalar = scalar * q{2};
                num = [num q{3}];
                den = [den q{4}];
            end
            for k=1:length(this.denominator)
                q = Qty.getUnitByName(this.denominator{k});
                scalar = scalar / q{2};
                num = [num q{4}];
                den = [den q{3}];
            end
            qty = Qty(scalar);
            qty.numerator = sort(num);
            qty.denominator = sort(den);
        end

        function qty = reduce(this)
            % Reduces the units fraction. Note we cannot use MATLABs set functions.
            qty = this; % clone
            qty.numerator = {};
            for k=1:length(this.numerator)
                s = this.numerator{k};
                indx = strmatch(s, qty.denominator);
                if isempty(indx)
                    qty.numerator{end+1} = s;
                else
                    qty.denominator(indx(1)) = [];
                end
            end
        end

        function other = to(this, targetUnit)
            p = this.resolve();
            other = Qty(1, targetUnit);
            q = other.resolve();
            if ~isequal(q.numerator, p.numerator) || ~isequal(q.denominator, p.denominator)
                error('Cannot convert %s to %s', this.getUnit(), targetUnit);
            end
            other.scalar = p.scalar/q.scalar;
        end

        function b = sameUnit(this, other)
            % this and other MUST be resolved
            b = isequal(this.numerator, other.numerator) && isequal(this.denominator, other.denominator);
        end

        function res = plus(this, other)
            % Overload binary addition
            res = this.resolve();
            q = other.resolve();
            if ~sameUnit(res, q)
                error('Arguments %s and %s are not compatible by unit', this.toString(), other.toString());
            end
            res.scalar = res.scalar + q.scalar;
        end

        function res = minus(this, other)
            % Overload binary subtraction
            res = this.resolve();
            q = other.resolve();
            if ~sameUnit(res, q)
                error('Arguments %s and %s are not unit compatible by unit', this.toString(), other.toString());
            end
            res.scalar = res.scalar - q.scalar;
        end

        function res = mtimes(this, other)
            % Overload multiplication
            if isa(this, 'Qty') && isa(other, 'Qty')
                res = this.resolve();
                q = other.resolve();
                res.numerator = [res.numerator q.numerator];
                res.denominator = [res.denominator q.denominator];
                res = res.reduce();
                res.scalar = res.scalar * q.scalar;
            elseif isa(this, 'Qty')
                res = this;
                res.scalar = res.scalar*other;
            else
                res = other;
                res.scalar = res.scalar*this;
            end
        end

        function res = mrdivide(this, other)
            % Overload right division
            if isa(this, 'Qty') && isa(other, 'Qty')
                res = this.resolve();
                q = other.resolve();
                res.numerator = [res.numerator q.denominator];
                res.denominator = [res.denominator q.numerator];
                res = res.reduce();
                res.scalar = res.scalar / q.scalar;
            elseif isa(this, 'Qty')
                res = this;
                res.scalar = res.scalar/other;
            else
                res = Qty(this/other.scalar);
                res.numerator = other.denominator;
                res.denominator = other.numerator;
            end
        end

        function res = mpower(this, p)
            % Overload power
            if mod(p, 1) ~= 0
                error('Illegal power %g', p);
            end
            res = Qty(this.scalar ^ p);
            res.numerator = {};
            res.denominator = {};

            for k=1:abs(p)
                res.numerator = [res.numerator this.numerator];
                res.denominator = [res.denominator this.denominator];
            end
            
            if p < 0
                t = res.denominator;
                res.denominator = res.numerator;
                res.numerator = t;
            end
            
            %res = res.reduce();

        end

    end

    methods (Static)

        function [numerator, denominator] = parse(unit)
            % Example: unit = 'a*b/c*d';
            numerator = {};
            denominator = {};
            [S, E, TE, M, T, NM, SP] = regexp(unit, '[a-z]+', 'ignorecase');
            for k=1:length(M)
                op = strtrim(SP{k});
                if op == '/'
                    denominator{end+1} = M{k};
                else
                    assert(isempty(op) || op == '*');
                    numerator{end+1} = M{k};
                end
            end
        end

        function unit = getUnitByName(s)
            % Workaround: There are no static properties in MATLAB.
            % Alternatively, define 
            %       properties(Constant) units=createUnits() end
            % with createUnits() containing the initialization code below.
            persistent units

            if isempty(units)
                units = struct();
                units.kilogram = {{'kg' 'kilogram'} 1 {'kilogram'}};
                units.g = {{'g' 'gram'} 1e-3 {'kilogram'}};
                units.m = {{'m' 'meter'} 1 {'meter'}};
                units.s = {{'s' 'second'} 1 {'second'}};
                units.km = {{'km' 'kilometer'} 1000 {'meter'}};
                units.cm = {{'cm' 'centimeter'} 1e-2 {'meter'}};
                units.mm = {{'mm' 'millimeter'} 1e-3 {'meter'}};
                units.l = {{'l' 'liter'} 1e-3 {'meter' 'meter' 'meter'}};
                units.ml = {{'ml' 'mililiter'} 1e-6 {'meter' 'meter' 'meter'}};
                units.bar = {{'bar'} 1 {'kilogram'} {'meter' 'second' 'second'}};


                % Add all aliases to map.
                names = fieldnames(units);
                for k=1:length(names)
                    unit = units.(names{k});
                    aliases = unit{1};
                    for l=1:length(aliases)
                        units.(aliases{l}) = unit;
                        if length(unit) == 3
                            units.(aliases{l}){end+1} = {};
                        end
                    end
                end
            end

            if isfield(units, s)
                unit = units.(s);
            else
                error('Unknown unit %s ', s);
            end

        end

    end
end
