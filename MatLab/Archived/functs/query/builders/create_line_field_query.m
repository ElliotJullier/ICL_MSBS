function q = create_line_field_query(startPoint, endPoint, component, varargin)
%CREATE_LINE_FIELD_QUERY Define a magnetic-field query along a straight line.
%
% q = create_line_field_query(startPoint, endPoint, component, Name, Value)
%
% Required inputs:
%   startPoint   1x3 or 3x1 start coordinate [x y z] in metres.
%   endPoint     1x3 or 3x1 end coordinate [x y z] in metres.
%   component    "x", "y", or "z" selecting Bx, By, or Bz.
%
% Name-value options:
%   "NPoints"    number of sample points along the line. Default: 200.
%   "Group"      plot group number/string. Empty means ungrouped.
%   "Overview"   true/false, whether to draw this line in that case's 3D overview.
%   "Name"       human-readable query name used in legends.

p = inputParser;
addParameter(p, "NPoints", 200, @(x)isnumeric(x) && isscalar(x) && x >= 2);
addParameter(p, "Group", [], @(x)true);
addParameter(p, "Overview", false, @(x)islogical(x) || isnumeric(x));
addParameter(p, "Name", "", @(x)isstring(x) || ischar(x));
addParameter(p, "ShowCoils", false, @(x)islogical(x) || isnumeric(x));
parse(p, varargin{:});
opts = p.Results;

q = struct();
q.type = "line";
q.quantity = "field";
q.component = component;
q.start = startPoint(:).';
q.end = endPoint(:).';
q.nPoints = round(opts.NPoints);
q.name = string(opts.Name);
q.plot = struct( ...
    "group", opts.Group, ...
    "inOverview", logical(opts.Overview), ...
    "showCoils", logical(opts.ShowCoils));
end
