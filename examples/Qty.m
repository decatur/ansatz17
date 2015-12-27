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
%
% COPYRIGHT Wolfgang Kuehn 2015 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz17.

    properties (SetAccess = public)
        scalar
        numerator = {};
        denominator = {};
    end

    methods

        function qty = Qty(scalar, unit)
            if nargin == 1 && ischar(scalar)
                % Create a quantity from a string, for example '1 year'.
                namedToken = regexp(scalar, '^(?<scalar>(\+|\-)?\d+(\.\d*)?(e(\+|\-)?\d+)?)\s*(?<unit>.*)$', 'once', 'ignorecase', 'names');
                qty.scalar = str2double(namedToken.scalar);
                [qty.numerator, qty.denominator] = Qty.parse(namedToken.unit);
            else
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
        end

        function unit = getUnit(this)
            % Returns a string representation of the unit. The unit 1 is returned as empty string.
            if ~isempty(this.numerator) && ~isempty(this.denominator)
                unit = sprintf('%s/%s', strjoin(this.numerator, '*'), strjoin(this.denominator, '/'));
            elseif isempty(this.denominator)
                % Note we also get here if unit is 1.
                unit = sprintf('%s', strjoin(this.numerator, '*'));
            elseif isempty(this.numerator)
                unit = sprintf('1/%s', strjoin(this.denominator, '/'));
            end
        end

        function display(this)
            this.toString()
        end

        function s = toString(this)
            % Need to trim in case unit is 1, which has empty representation.
            s = strtrim(sprintf('%g %s', this.scalar, this.getUnit()));
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
            [S, E, TE, M, T, NM, SP] = regexp(unit, '[a-z]+|1', 'ignorecase');
            for k=1:length(M)
                if M{k} == '1'
                    continue;
                end
                op = strtrim(SP{k});
                if op == '/'
                    denominator{end+1} = M{k};
                elseif isempty(op) || op == '*'
                    numerator{end+1} = M{k};
                else
                    error('Invalid unit %s ', op);
                end
            end
        end

        function unit = getUnitByName(s)
            unit = Qty.lookupUnit(s);
            if isempty(unit); error('Unknown unit %s ', s); end;
        end

        function unit = lookupUnit(s)
            % Workaround: There are no static properties in MATLAB.
            % Alternatively, define 
            %       properties(Constant) units=createUnits() end
            % with createUnits() containing the initialization code below.
            persistent units prefixes

            if isempty(units)
                prefixes = struct();
                prefixes.M = 1e6; %prefixes.Mega = 1e6;
                prefixes.k = 1e3; %prefixes.kilo = 1e3;
                prefixes.c = 1e-2; %prefixes.centi = 1e-2;
                prefixes.m = 1e-3; %prefixes.milli = 1e-3;
                prefixes.u = 1e-6; %prefixes.micro = 1e-6;

                units = struct();

                %%%% Begin Code generated by unitTranspiler.html
                units.acre={{'acre','acres'},4046.85642,{'meter','meter'}};
                units.Ah={{'Ah'},3600,{'ampere','second'}};
                units.ampere={{'A','Ampere','ampere','amp','amps'},1,{'ampere'}};
                units.AMU={{'u','AMU','amu'},1.660538921e-27,{'kilogram'}};
                units.angstrom={{'ang','angstrom','angstroms'},1e-10,{'meter'}};
                units.atm={{'atm','ATM','atmosphere','atmospheres'},101325,{'kilogram'},{'meter','second','second'}};
                units.AU={{'AU','astronomical_unit'},149597900000,{'meter'}};
                units.bar={{'bar','bars'},100000,{'kilogram'},{'meter','second','second'}};
                units.base_pair={{'base_pair','bp'},1,{'each'}};
                units.bequerel={{'Bq','bequerel','bequerels'},1,{},{'second'}};
                units.bit={{'b','bit','bits'},0.125,{'byte'}};
                units.bpm={{'bpm'},0.016666666666666666,{'count'},{'second'}};
                units.bps={{'bps'},0.125,{'byte'},{'second'}};
                units.Bps={{'Bps'},1,{'byte'},{'second'}};
                units.btu={{'BTU','btu','BTUs'},1055.056,{'meter','meter','kilogram'},{'second','second'}};
                units.bushel={{'bu','bsh','bushel','bushels'},0.035239072,{'meter','meter','meter'}};
                units.byte={{'B','byte','bytes'},1,{'byte'}};
                units.calorie={{'cal','calorie','calories'},4.184,{'meter','meter','kilogram'},{'second','second'}};
                units.Calorie={{'Cal','Calorie','Calories'},4184,{'meter','meter','kilogram'},{'second','second'}};
                units.candela={{'cd','candela'},1,{'candela'}};
                units.carat={{'ct','carat','carats'},0.0002,{'kilogram'}};
                units.cell={{'cells','cell'},1,{'each'}};
                units.celsius={{'degC','celsius','celsius','centigrade'},1,{'kelvin'}};
                units.cents={{'cents'},0.01,{'dollar'}};
                units.century={{'century','centuries'},3155692600,{'second'}};
                units.cmh2o={{'cmh2o','cmH2O'},98.0638,{'kilogram'},{'meter','second','second'}};
                units.coulomb={{'C','coulomb','Coulomb'},1,{'ampere','second'}};
                units.count={{'count'},1,{'each'}};
                units.cpm={{'cpm'},0.016666666666666666,{'count'},{'second'}};
                units.cup={{'cu','cup','cups'},0.000236588238,{'meter','meter','meter'}};
                units.curie={{'Ci','curie','curies'},37000000000,{},{'second'}};
                units.dalton={{'Da','Dalton','Daltons','dalton','daltons'},1.660538921e-27,{'kilogram'}};
                units.day={{'d','day','days'},86400,{'second'}};
                units.decade={{'decade','decades'},315569260,{'second'}};
                units.decibel={{'dB','decibel','decibels'},1,{'decibel'}};
                units.degree={{'deg','degree','degrees'},0.0174532925199433,{'radian'}};
                units.dollar={{'USD','dollar'},1,{'dollar'}};
                units.dot={{'dot','dots'},1,{'each'}};
                units.dozen={{'doz','dz','dozen'},12,{'each'}};
                units.dpi={{'dpi'},1,{'dot'},{'inch'}};
                units.dpm={{'dpm'},0.016666666666666666,{'count'},{'second'}};
                units.dram={{'dram','drams','dr'},0.0017718452,{'kilogram'}};
                units.dyne={{'dyn','dyne'},0.00001,{'kilogram','meter'},{'second','second'}};
                units.each={{'each'},1,{'each'}};
                units.erg={{'erg','ergs'},1e-7,{'meter','meter','kilogram'},{'second','second'}};
                units.fahrenheit={{'degF','fahrenheit'},0.5555555555555556,{'kelvin'}};
                units.farad={{'F','farad','Farad'},1,{'farad'}};
                units.fathom={{'fathom','fathoms'},1.829,{'meter'}};
                units.fluid_ounce={{'floz','fluid_ounce','fluid_ounces'},0.0000295735297,{'meter','meter','meter'}};
                units.foot={{'ft','foot','feet'},0.3048,{'meter'}};
                units.fortnight={{'fortnight','fortnights'},1209600,{'second'}};
                units.fps={{'fps'},0.3048,{'meter'},{'second'}};
                units.furlong={{'furlong','furlongs'},201.2,{'meter'}};
                units.gallon={{'gal','gallon','gallons'},0.0037854118,{'meter','meter','meter'}};
                units.gauss={{'G','gauss'},0.0001,{'kilogram'},{'second','second','ampere'}};
                units.gee={{'gee'},9.80665,{'meter'},{'second','second'}};
                units.gradian={{'gon','grad','gradian','grads'},0.01570796326794897,{'radian'}};
                units.grain={{'grain','grains','gr'},0.00006479891,{'kilogram'}};
                units.gram={{'g','gram','grams','gramme','grammes'},0.001,{'kilogram'}};
                units.gray={{'Gy','gray','grays'},1,{'meter','meter'},{'second','second'}};
                units.gross={{'gr','gross'},144,{'dozen','dozen'}};
                units.hectare={{'hectare'},10000,{'meter','meter'}};
                units.henry={{'H','Henry','henry'},1,{'meter','meter','kilogram'},{'second','second','ampere','ampere'}};
                units.hertz={{'Hz','hertz','Hertz'},1,{},{'second'}};
                units.horsepower={{'hp','horsepower'},745.699872,{'kilogram','meter','meter'},{'second','second','second'}};
                units.hour={{'h','hr','hrs','hour','hours'},3600,{'second'}};
                units.inch={{'in','inch','inches'},0.0254,{'meter'}};
                units.inh2o={{'inh2o','inH2O'},249.082052,{'kilogram'},{'meter','second','second'}};
                units.inHg={{'inHg'},3386.3881472,{'kilogram'},{'meter','second','second'}};
                units.joule={{'J','joule','Joule','joules'},1,{'meter','meter','kilogram'},{'second','second'}};
                units.katal={{'kat','katal','Katal'},1,{'mole'},{'second'}};
                units.kelvin={{'degK','kelvin'},1,{'kelvin'}};
                units.kilogram={{'kg','kilogram','kilograms'},1,{'kilogram'}};
                units.knot={{'kt','kn','kts','knot','knots'},0.514444444,{'meter'},{'second'}};
                units.kph={{'kph'},0.277777778,{'meter'},{'second'}};
                units.league={{'league','leagues'},4828,{'meter'}};
                units.light_minute={{'lmin','light_minute'},17987550000,{'meter'}};
                units.light_second={{'ls','light_second'},299792500,{'meter'}};
                units.light_year={{'ly','light_year'},9460528000000000,{'meter'}};
                units.liter={{'l','L','liter','liters','litre','litres'},0.001,{'meter','meter','meter'}};
                units.lumen={{'lm','lumen'},1,{'candela','steradian'}};
                units.lux={{'lux'},1,{'candela','steradian'},{'meter','meter'}};
                units.maxwell={{'Mx','maxwell','maxwells'},1e-8,{'meter','meter','kilogram'},{'second','second','ampere'}};
                units.meter={{'m','meter','meters','metre','metres'},1,{'meter'}};
                units.metric_ton={{'metric_ton','tonne'},1000,{'kilogram'}};
                units.mil={{'mil','mils'},0.0000254,{'meter'}};
                units.mile={{'mi','mile','miles'},1609.344,{'meter'}};
                units.minute={{'min','mins','minute','minutes'},60,{'second'}};
                units.mmHg={{'mmHg'},133.322368,{'kilogram'},{'meter','second','second'}};
                units.molar={{'M','molar'},1000,{'mole'},{'meter','meter','meter'}};
                units.mole={{'mol','mole'},1,{'mole'}};
                units.molecule={{'molecule','molecules'},1,{}};
                units.mph={{'mph'},0.44704,{'meter'},{'second'}};
                units.naut_mile={{'naut_mile','nmi'},1852,{'meter'}};
                units.newton={{'N','Newton','newton'},1,{'kilogram','meter'},{'second','second'}};
                units.nucleotide={{'nucleotide','nt'},1,{'each'}};
                units.oersted={{'Oe','oersted','oersteds'},79.57747154594767,{'ampere'},{'meter'}};
                units.ohm={{'Ohm','ohm'},1,{'meter','meter','kilogram'},{'second','second','second','ampere','ampere'}};
                units.ounce={{'oz','ounce','ounces'},0.0283495231,{'kilogram'}};
                units.parsec={{'pc','parsec','parsecs'},30856780000000000,{'meter'}};
                units.pascal={{'Pa','pascal','Pascal'},1,{'kilogram'},{'meter','second','second'}};
                units.percent={{'percent'},0.01,{}};
                units.pica={{'pica','picas'},0.00423333333,{'meter'}};
                units.pint={{'pt','pint','pints'},0.000473176475,{'meter','meter','meter'}};
                units.pixel={{'pixel','px'},1,{'each'}};
                units.point={{'pt','point','points'},0.000473176475,{'meter','meter','meter'}};
                units.poise={{'P','poise'},0.1,{'kilogram'},{'meter','second'}};
                units.pound={{'lbs','lb','pound','pounds'},0.45359237,{'kilogram'}};
                units.pound_force={{'lbf','pound_force'},4.448222,{'kilogram','meter'},{'second','second'}};
                units.ppi={{'ppi'},1,{'pixel'},{'inch'}};
                units.ppm={{'ppm'},0.000001,{}};
                units.ppt={{'ppt'},1e-9,{}};
                units.psi={{'psi'},6894.76,{'kilogram'},{'meter','second','second'}};
                units.quart={{'qt','quart','quarts'},0.00094635295,{'meter','meter','meter'}};
                units.radian={{'rad','radian','radians'},1,{'radian'}};
                units.rankine={{'degR','rankine'},0.5555555555555556,{'kelvin'}};
                units.rod={{'rd','rod','rods'},5.029,{'meter'}};
                units.roentgen={{'R','roentgen'},0.00933,{'meter','meter'},{'second','second'}};
                units.rotation={{'rotation'},6.283185307179586,{'radian'}};
                units.rpm={{'rpm'},0.10471975511965977,{'radian'},{'second'}};
                units.second={{'s','sec','secs','second','seconds'},1,{'second'}};
                units.short_ton={{'short_ton','tn','ton'},907.18474,{'kilogram'}};
                units.siemens={{'S','Siemens','siemens'},1,{'second','second','second','ampere','ampere'},{'kilogram','meter','meter'}};
                units.sievert={{'Sv','sievert','sieverts'},1,{'meter','meter'},{'second','second'}};
                units.slug={{'slug','slugs'},14.5939029,{'kilogram'}};
                units.sqft={{'sqft'},1,{'feet','feet'}};
                units.steradian={{'sr','steradian','steradians'},1,{'steradian'}};
                units.stokes={{'St','stokes'},0.0001,{'meter','meter'},{'second'}};
                units.stone={{'stone','stones','st'},6.35029318,{'kilogram'}};
                units.tablespoon={{'tb','tbs','tablespoon','tablespoons'},0.0000147867648,{'meter','meter','meter'}};
                units.teaspoon={{'tsp','teaspoon','teaspoons'},0.00000492892161,{'meter','meter','meter'}};
                units.tesla={{'T','tesla','teslas'},1,{'kilogram'},{'second','second','ampere'}};
                units.torr={{'torr'},133.322368,{'kilogram'},{'meter','second','second'}};
                units.volt={{'V','Volt','volt','volts'},1,{'meter','meter','kilogram'},{'second','second','second','ampere'}};
                units.watt={{'W','watt','watts'},1,{'kilogram','meter','meter'},{'second','second','second'}};
                units.weber={{'Wb','weber','webers'},1,{'meter','meter','kilogram'},{'second','second','ampere'}};
                units.week={{'wk','week','weeks'},604800,{'second'}};
                units.Wh={{'Wh'},3600,{'meter','meter','kilogram'},{'second','second'}};
                units.wtpercent={{'wtpercent'},10,{'kilogram'},{'meter','meter','meter'}};
                units.yard={{'yd','yard','yards'},0.9144,{'meter'}};
                units.year={{'y','yr','year','years','annum'},31556926,{'second'}};
                %%%% End Code generated by unitTranspiler.html


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
            end % Initialization

            if s == '1'
                unit = {{},1,{},{}};
                return;
            end
            
            if isfield(units, s)
                unit = units.(s);
                return;
            end

            % Could not match string directly. Now try to match with prefix, for example 'kg' is matched by 'k'+'g'.

            names = fieldnames(prefixes);
            for k=1:length(names)
                prefix = names{k};
                if isequal(strfind(s, prefix), 1)
                    s = s(length(prefix)+1:end);
                    if isfield(units, s)
                       unit = units.(s);
                       unit{2} = unit{2} * prefixes.(prefix);
                       return;
                    end
                    break;
                end
            end

            unit = [];

        end

    end
end

