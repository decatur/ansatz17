classdef Qty
%
%Usage:
%   q = Qty(3, 'kg')
%   q.to('g').toString() -> '3000[g]'
%   q.to('meter') -> error: Cannot convert kg to meter
%   
%   q = Qty(3, 'bar')
%   p = Qty(1, 'kg/s/cm/s')
%   q.add(p).toString() -> '103[kilogram/meter/second/second]'

    properties (SetAccess = public)
        scalar
        numerator = {};
        denominator = {};
    end

    methods

        function qty = Qty(scalar, unit)
            qty.scalar = scalar;
            if ischar(unit)
                [qty.numerator, qty.denominator] = Qty.parse(unit);
            % Bug: In Octave you cannot pass class instance to constructor???
            % elseif isa(unit, 'Qty')
            %    qty.numerator = unit.numerator;
            %    qty.denominator = unit.denominator;
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

        function s = toString(this)
            s = sprintf('%g[%s]', this.scalar, this.getUnit());
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
            qty = Qty(scalar, []);
            qty.numerator = sort(num);
            qty.denominator = sort(den);
        end

        function other = to(this, targetUnit)
            p = this.resolve();
            other = Qty(1, targetUnit);
            q = other.resolve();
            if ~isequal(q.numerator, p.numerator) || ~isequal(q.denominator, p.denominator)
                error('Cannot convert %s to %s', this.getUnit(), targetUnit);
            end
            other.scalar = p.scalar*other.scalar/q.scalar;
        end

        function b = sameUnit(this, other)
            % this and other MUST be resolved
            b = isequal(this.numerator, other.numerator) && isequal(this.denominator, other.denominator);
        end

        function sum = add(this, other)
            sum = this.resolve();
            q = other.resolve();
            if ~sameUnit(sum, q)
                error('Not compatible %s %s', this.toString(), other.toString());
            end
            sum.scalar = sum.scalar + q.scalar;
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
                units.g = {{'g' 'gram'} 1000 {'kilogram'}};
                units.m = {{'m' 'meter'} 1 {'meter'}};
                units.s = {{'s' 'second'} 1 {'second'}};
                units.km = {{'km' 'kilometer'} 1000 {'meter'}};
                units.cm = {{'cm' 'centimeter'} 1e-2 {'meter'}};
                units.mm = {{'mm' 'milimeter'} 1e-3 {'meter'}};
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
