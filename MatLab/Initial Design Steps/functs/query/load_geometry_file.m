function geometry = load_geometry_file(geometryFile)
%LOAD_GEOMETRY_FILE Load a plotting geometry struct from a .mat file.
%
% Supported .mat layouts:
%   geometryFile contains variable "geometry"
%   geometryFile contains variable "dataset" with field dataset.geometry
%   geometryFile contains variable "Q" where Q{1}.geometry or Q.geometry exists
%
% The returned geometry is expected to use the project format:
%   geometry.windTunnel
%   geometry.coilSpec
%   geometry.coil(k).coilName
%   geometry.coil(k).coilType
%   geometry.coil(k).pose
%   geometry.coil(k).shape.Faces
%   geometry.coil(k).shape.Vertices

geometryFile = string(geometryFile);

if strlength(geometryFile) == 0
    error("geometryFile was empty.");
end

if ~isfile(geometryFile)
    error("Geometry file does not exist: %s", geometryFile);
end

[~,~,ext] = fileparts(geometryFile);
if lower(string(ext)) ~= ".mat"
    error("Geometry file must be a .mat file. Use stl_to_query_geometry_file to convert STL files first.");
end

S = load(geometryFile);

if isfield(S, "geometry")
    geometry = S.geometry;

elseif isfield(S, "dataset") && isfield(S.dataset, "geometry")
    geometry = S.dataset.geometry;

elseif isfield(S, "Q")
    Q = S.Q;
    if iscell(Q)
        if isempty(Q) || ~isfield(Q{1}, "geometry")
            error("Q variable in geometry file does not contain Q{1}.geometry.");
        end
        geometry = Q{1}.geometry;
    elseif isstruct(Q) && isfield(Q, "geometry")
        geometry = Q.geometry;
    else
        error("Q variable in geometry file does not contain geometry.");
    end

else
    error("Geometry file must contain geometry, dataset.geometry, or Q geometry.");
end

validate_loaded_geometry(geometry, geometryFile);
end

function validate_loaded_geometry(geometry, geometryFile)
if ~isstruct(geometry)
    error("Geometry loaded from %s is not a struct.", geometryFile);
end

if ~isfield(geometry, "coil")
    error("Geometry loaded from %s does not contain geometry.coil.", geometryFile);
end

for k = 1:numel(geometry.coil)
    if ~isfield(geometry.coil(k), "shape") || isempty(geometry.coil(k).shape)
        error("Geometry coil %d in %s does not contain a shape.", k, geometryFile);
    end

    shp = geometry.coil(k).shape;
    if ~isfield(shp, "Faces") || ~isfield(shp, "Vertices")
        error("Geometry coil %d in %s must contain shape.Faces and shape.Vertices.", k, geometryFile);
    end
end

if ~isfield(geometry, "coilSpec")
    geometry.coilSpec = struct();
end

if ~isfield(geometry, "windTunnel")
    geometry.windTunnel = [];
end
end
