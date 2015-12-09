classdef Qty
%
%Usage:
%   q = Qty(3, 'kg');
%   q.to('g').toString() -> '3000[g]'
%   q.to('meter') -> error: Cannot convert kg to meter


    properties (Constant)
    end

    properties (SetAccess = public)
        scalar
        numerator = {};
        denominator = {};
    end

    methods

        function qty = Qty(scalar, unit)
            qty.scalar = scalar;
            if ischar(unit)
                [numerator, denominator] = Qty.parse(unit);
                qty.numerator = numerator;
                qty.denominator = denominator;
            end

            % Assert valid unit
            %[~] = Qty.getUnitByName(unit);
        end

        function unit = getUnit(this)
        this.numerator
            if ~isempty(this.numerator) && ~isempty(this.denominator)
                unit = sprintf('[%s/%s]', strjoin(this.numerator, '*'), strjoin(this.denominator, '*'));
            elseif isempty(this.denominator)
                unit = sprintf('[%s]', strjoin(this.numerator, '*'));
            elseif isempty(this.numerator)
                unit = sprintf('[1/%s]', strjoin(this.denominator, '*'));
            else
                unit = '[1]';
            end
        end

        function s = toString(this)
            s = sprintf('%f%s', this.scalar, this.getUnit());
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
            qty.numerator = num;
            qty.denominator = den;
        end

        function other = to(this, targetUnit)
            p = this.resolve();
            other = Qty(1, targetUnit);
            q = other.resolve();
            if ~isequal(q.numerator, p.numerator) || ~isequal(q.denominator, p.denominator)
                error('Cannot convert %s to %s', this.getUnit(), targetUnit);
            end
            other.scalar = p.scalar*other.scalar/q.scalar;

            %num = {};
            %den = {};
            %scalar = this.scalar;
            %for k=1:length(p.numerator)
            %    a = Qty.getUnitByName(p.numerator{k})
            %    b = Qty.getUnitByName(q.numerator{k})
            %    num{end+1} = a{3};
            %    if ~isequal(a{3}, b{3})
            %        error('Cannot convert %s to %s', this.getUnit(), targetUnit);
            %    end
            %    scalar = scalar*a{2}/b{2};
            %end

            %for k=1:length(p.denominator)
            %    a = Qty.getUnitByName(p.denominator{k});
            %    b = Qty.getUnitByName(q.denominator{k});
            %    den{end+1} = a{3};
            %    if ~isequal(a{3}, b{3})
            %        error('Cannot convert %s to %s', this.getUnit(), targetUnit);
            %    end
            %    scalar = scalar*b{2}/a{2};
            %end

            %other = Qty(p.scalar/q.scalar, []);
            %other.numerator = p.numerator;
            %other.denominator = p.denominator;
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
                units.km = {{'km' 'kilometer'} 1000 {'meter'}};
                units.cm = {{'cm' 'centimeter'} 0.001 {'meter'}};
                units.l = {{'l' 'liter'} 1e-3 {'meter' 'meter' 'meter'}};
                units.ml = {{'ml' 'mililiter'} 1e-6 {'meter' 'meter' 'meter'}};

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
