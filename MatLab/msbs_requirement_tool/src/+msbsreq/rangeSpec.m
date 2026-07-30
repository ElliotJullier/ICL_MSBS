function spec = rangeSpec(nominal, variation, variationMode)
%RANGESPEC Construct a nominal/lower/upper range specification.
%   variation=[] creates a nominal-only value.
%   variationMode is "absolute" or "percent".

arguments
    nominal (1,1) double {mustBeFinite}
    variation {mustBeNumericOrLogical}
    variationMode (1,1) string {mustBeMember(variationMode,["absolute","percent"])} = "absolute"
end

if isempty(variation)
    spec = struct('nominal', nominal, 'lower', nominal, 'upper', nominal, ...
        'hasVariation', false, 'variation', [], 'variationMode', variationMode);
    return
end

validateattributes(variation, {'numeric'}, {'scalar','real','finite','nonnegative'});
if variationMode == "absolute"
    lower = nominal - variation;
    upper = nominal + variation;
else
    lower = nominal * (1 - variation/100);
    upper = nominal * (1 + variation/100);
end

if lower > upper
    [lower, upper] = deal(upper, lower);
end
spec = struct('nominal', nominal, 'lower', lower, 'upper', upper, ...
    'hasVariation', variation > 0, 'variation', variation, ...
    'variationMode', variationMode);
end

function mustBeNumericOrLogical(value)
if ~(isnumeric(value) || islogical(value))
    error('msbsreq:InvalidRangeVariation', 'Variation must be numeric or empty.');
end
end
