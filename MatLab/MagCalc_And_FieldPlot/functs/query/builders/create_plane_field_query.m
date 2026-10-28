function q = create_plane_field_query(plane, planeOffset, component, varargin)
%CREATE_PLANE_FIELD_QUERY Define a field query on an xy, xz, or yz plane.
%
% planeOffset is the coordinate normal to the plane:
%   "xy" -> z offset
%   "xz" -> y offset
%   "yz" -> x offset

p = inputParser;
addParameter(p, "Group", [], @(x)true);
addParameter(p, "Overview", false, @(x)islogical(x) || isnumeric(x));
addParameter(p, "Name", "", @(x)isstring(x) || ischar(x));
addParameter(p, "ShowCoils", false, @(x)islogical(x) || isnumeric(x));
addParameter(p, "ShowGeometry", [], @(x) isempty(x) || islogical(x) || isnumeric(x));
parse(p, varargin{:});
opts = p.Results;
if ~isempty(opts.ShowGeometry), opts.ShowCoils = opts.ShowGeometry; end

plane = lower(string(plane));
if ~any(plane == ["xy", "xz", "yz"])
    error('plane must be "xy", "xz", or "yz".');
end

q = struct();
q.type = "fundamental_plane";
q.quantity = "field";
q.plane = plane;
q.planeOffset = planeOffset;
q.component = component;
q.name = string(opts.Name);
q.plot = struct( ...
    "group", opts.Group, ...
    "inOverview", logical(opts.Overview), ...
    "showCoils", logical(opts.ShowCoils));
end
