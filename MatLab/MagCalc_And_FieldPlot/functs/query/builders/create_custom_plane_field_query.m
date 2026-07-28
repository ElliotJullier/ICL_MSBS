function q = create_custom_plane_field_query(point, normal, component, varargin)
%CREATE_CUSTOM_PLANE_FIELD_QUERY Define a field query on an arbitrary plane.
%
% point  is any point on the plane in global coordinates.
% normal is the plane normal in global coordinates.

p = inputParser;
addParameter(p, "Resolution", [150 150], @(x)isnumeric(x) && (isscalar(x) || numel(x)==2));
addParameter(p, "Group", [], @(x)true);
addParameter(p, "Overview", false, @(x)islogical(x) || isnumeric(x));
addParameter(p, "Name", "", @(x)isstring(x) || ischar(x));
addParameter(p, "ShowCoils", false, @(x)islogical(x) || isnumeric(x));
parse(p, varargin{:});
opts = p.Results;

q = struct();
q.type = "custom_plane";
q.quantity = "field";
q.point = point(:).';
q.normal = normal(:).';
q.component = component;
q.resolution = opts.Resolution;
q.name = string(opts.Name);
q.plot = struct( ...
    "group", opts.Group, ...
    "inOverview", logical(opts.Overview), ...
    "showCoils", logical(opts.ShowCoils));
end
