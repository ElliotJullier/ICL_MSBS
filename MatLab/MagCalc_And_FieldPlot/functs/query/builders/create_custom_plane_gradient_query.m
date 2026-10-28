function q = create_custom_plane_gradient_query(point, normal, component, gradientDirection, varargin)
%CREATE_CUSTOM_PLANE_GRADIENT_QUERY Define a gradient query on an arbitrary plane.

p = inputParser;
addParameter(p, "Resolution", [150 150], @(x)isnumeric(x) && (isscalar(x) || numel(x)==2));
addParameter(p, "Group", [], @(x)true);
addParameter(p, "Overview", false, @(x)islogical(x) || isnumeric(x));
addParameter(p, "Name", "", @(x)isstring(x) || ischar(x));
addParameter(p, "ShowCoils", false, @(x)islogical(x) || isnumeric(x));
addParameter(p, "ShowGeometry", [], @(x) isempty(x) || islogical(x) || isnumeric(x));
addParameter(p, "UpVector", []);
addParameter(p, "ULimits", []);
addParameter(p, "VLimits", []);
parse(p, varargin{:});
opts = p.Results;
if ~isempty(opts.ShowGeometry), opts.ShowCoils = opts.ShowGeometry; end

q = struct();
q.type = "custom_plane";
q.quantity = "gradient";
q.point = point(:).';
q.normal = normalise_direction(normal);
q.upVector = opts.UpVector;
q.uLimits = opts.ULimits;
q.vLimits = opts.VLimits;
q.component = component;
q.gradientDirection = normalise_direction(gradientDirection);
q.resolution = opts.Resolution;
q.name = string(opts.Name);
q.plot = struct( ...
    "group", opts.Group, ...
    "inOverview", logical(opts.Overview), ...
    "showCoils", logical(opts.ShowCoils));
end
