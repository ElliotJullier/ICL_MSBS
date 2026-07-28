function q = create_line_gradient_query(startPoint, endPoint, component, varargin)
%CREATE_LINE_GRADIENT_QUERY Define a directional-gradient query along a line.
%
% For grid-based models, the optional "GradientDirection" selects dBcomponent/dn.
% If omitted, the line direction is used. For the simple Biot-Savart model,
% only the derivative along the queried line is supported.

p = inputParser;
addParameter(p, "NPoints", 200, @(x)isnumeric(x) && isscalar(x) && x >= 2);
addParameter(p, "GradientDirection", [], @(x)isnumeric(x) && (isempty(x) || numel(x)==3));
addParameter(p, "Group", [], @(x)true);
addParameter(p, "Overview", false, @(x)islogical(x) || isnumeric(x));
addParameter(p, "Name", "", @(x)isstring(x) || ischar(x));
addParameter(p, "ShowCoils", false, @(x)islogical(x) || isnumeric(x));
parse(p, varargin{:});
opts = p.Results;

q = struct();
q.type = "line";
q.quantity = "gradient";
q.component = component;
q.start = startPoint(:).';
q.end = endPoint(:).';
q.nPoints = round(opts.NPoints);
q.gradientDirection = opts.GradientDirection;
q.name = string(opts.Name);
q.plot = struct( ...
    "group", opts.Group, ...
    "inOverview", logical(opts.Overview), ...
    "showCoils", logical(opts.ShowCoils));
end
