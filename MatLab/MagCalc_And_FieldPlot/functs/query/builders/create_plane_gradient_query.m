function q = create_plane_gradient_query(plane, planeOffset, component, gradientDirection, varargin)
%CREATE_PLANE_GRADIENT_QUERY Define a directional-gradient query on a grid plane.
%
% gradientDirection is a 1x3 or 3x1 vector defining the derivative direction
% in global coordinates, for example [0 0 1] for dBcomponent/dz.

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
q.quantity = "gradient";
q.plane = plane;
q.planeOffset = planeOffset;
q.component = component;
q.gradientDirection = normalise_direction(gradientDirection);
q.name = string(opts.Name);
q.plot = struct( ...
    "group", opts.Group, ...
    "inOverview", logical(opts.Overview), ...
    "showCoils", logical(opts.ShowCoils));
end
