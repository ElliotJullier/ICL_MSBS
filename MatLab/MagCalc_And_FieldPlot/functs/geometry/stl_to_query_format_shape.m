function shape = stl_to_query_format_shape(stlFile, pose, varargin)
%STL_TO_QUERY_FORMAT_SHAPE Convert one STL mesh into shape.Faces/Vertices.
%
% Output:
%   shape.Faces
%   shape.Vertices
%
% The output shape matches the plotting format used by geometry.coil(k).shape.
%
% pose = [x y z yaw pitch roll] is applied after optional scaling and
% optional re-centring/origin correction.

if nargin < 2 || isempty(pose)
    pose = zeros(1,6);
end

p = inputParser;
addParameter(p, "InputScale", 1, @(x)isnumeric(x) && isscalar(x));
addParameter(p, "LocalOrigin", [], @(x)isnumeric(x) && (isempty(x) || isequal(size(x), [1 3])));
addParameter(p, "CentreMode", "none", @(x)any(strcmpi(string(x), ["none","boundingBox","centroid"])));
parse(p, varargin{:});
opts = p.Results;

shape = read_stl_patch_shape(stlFile);
V = double(shape.Vertices) .* opts.InputScale;

if ~isempty(opts.LocalOrigin)
    V = V - opts.LocalOrigin .* opts.InputScale;
end

switch lower(string(opts.CentreMode))
    case "none"
        % Use STL coordinates as supplied.
    case "boundingbox"
        bbCentre = 0.5*(min(V, [], 1) + max(V, [], 1));
        V = V - bbCentre;
    case "centroid"
        V = V - mean(V, 1, "omitnan");
end

pose = double(pose);
if numel(pose) ~= 6
    error("pose must be a 1x6 vector [x y z yaw pitch roll].");
end

if exist("coord_local2global", "file") == 2
    V = coord_local2global(V.', pose).';
else
    V = local_coord_local2global(V, pose);
end

shape.Vertices = V;
end

function Vg = local_coord_local2global(V, relative_position)
% Fallback matching the project coord_local2global convention.

x_trans = relative_position(1);
y_trans = relative_position(2);
z_trans = relative_position(3);
yaw     = relative_position(4);
pitch   = relative_position(5);
roll    = relative_position(6);

translation_matrix = [x_trans; y_trans; z_trans];

rotation_matrix = [ ...
    cos(pitch)*cos(yaw), -cos(roll)*sin(yaw)+sin(roll)*sin(pitch)*cos(yaw),  sin(roll)*sin(yaw)+cos(roll)*sin(pitch)*cos(yaw); ...
    cos(pitch)*sin(yaw),  cos(roll)*cos(yaw)+sin(roll)*sin(pitch)*sin(yaw), -sin(roll)*cos(yaw)+cos(roll)*sin(pitch)*sin(yaw); ...
    -sin(pitch),          sin(roll)*cos(pitch),                              cos(roll)*cos(pitch)];

Vg = zeros(size(V));
for i = 1:size(V, 1)
    Vg(i,:) = (rotation_matrix \ V(i,:).').' + translation_matrix.';
end
end
