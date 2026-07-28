function geometry = stl_to_query_geometry_file(outputFile, stlInput, pose, varargin)
%STL_TO_QUERY_GEOMETRY_FILE Convert one or more STL meshes to a geometry .mat file.
%
% This writes a file containing variable "geometry", suitable for:
%
%   caseDefs(k).geometryFile = "my_comsol_coil_geometry.mat";
%
% Simple single-coil use:
%
%   stl_to_query_geometry_file( ...
%       "comsol_geometry.mat", ...
%       "coil.stl", ...
%       [0 0 0 0 -pi/2 0], ...
%       "CoilName", "COMSOL coil 1", ...
%       "InputScale", 1e-3);
%
% Multi-coil use:
%
%   coilDef(1).stlFile = "coil_a.stl";
%   coilDef(1).pose = [0 0 0.09 0 0 0];
%   coilDef(1).coilName = "Coil A";
%
%   coilDef(2).stlFile = "coil_b.stl";
%   coilDef(2).pose = [0 0 -0.09 0 0 0];
%   coilDef(2).coilName = "Coil B";
%
%   stl_to_query_geometry_file("comsol_geometry.mat", coilDef);
%
% Pose convention:
%   pose = [x y z yaw pitch roll], SI units and radians.
%   This uses the same coord_local2global convention as extract_coilShape.
%
% Important:
%   The pose rotates/translates the STL vertices as supplied. If the STL is
%   not centred at the intended local coil origin, rotation occurs about the
%   STL's own coordinate origin. Use LocalOrigin or CentreMode to correct
%   oddly-centred STL files.

if nargin < 3
    pose = [];
end

p = inputParser;
addParameter(p, "CoilName", "STL coil", @(x)isstring(x) || ischar(x));
addParameter(p, "CoilType", "stl", @(x)isstring(x) || ischar(x));
addParameter(p, "InputScale", 1, @(x)isnumeric(x) && isscalar(x));
addParameter(p, "LocalOrigin", [], @(x)isnumeric(x) && (isempty(x) || isequal(size(x), [1 3])));
addParameter(p, "CentreMode", "none", @(x)any(strcmpi(string(x), ["none","boundingBox","centroid"])));
addParameter(p, "WindTunnel", [], @(x)isnumeric(x) && (isempty(x) || isequal(size(x), [3 2])));
addParameter(p, "Overwrite", true, @(x)islogical(x) || isnumeric(x));
parse(p, varargin{:});
opts = p.Results;

outputFile = string(outputFile);
if ~endsWith(outputFile, ".mat", "IgnoreCase", true)
    outputFile = outputFile + ".mat";
end

if isfile(outputFile) && ~logical(opts.Overwrite)
    error("Output geometry file already exists: %s", outputFile);
end

coilDefs = normalise_stl_inputs(stlInput, pose, opts);

geometry = struct();
geometry.source = "stl_geometry_file";
geometry.createdOn = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
geometry.geometryFile = outputFile;
geometry.windTunnel = opts.WindTunnel;
geometry.coilSpec = struct();
geometry.coilSpec.stl = struct( ...
    "source", "stl", ...
    "description", "STL-derived plotting geometry; not used for field computation.");

emptyCoil = struct( ...
    "coilName", "", ...
    "coilType", "stl", ...
    "pose", zeros(1,6), ...
    "shape", [], ...
    "sourceFile", "");

geometry.coil = repmat(emptyCoil, 1, numel(coilDefs));

for k = 1:numel(coilDefs)
    thisDef = coilDefs(k);

    geometry.coil(k).coilName = string(thisDef.coilName);
    geometry.coil(k).coilType = string(thisDef.coilType);
    geometry.coil(k).pose = double(thisDef.pose);
    geometry.coil(k).sourceFile = string(thisDef.stlFile);

    geometry.coil(k).shape = stl_to_query_format_shape( ...
        thisDef.stlFile, ...
        thisDef.pose, ...
        "InputScale", thisDef.inputScale, ...
        "LocalOrigin", thisDef.localOrigin, ...
        "CentreMode", thisDef.centreMode);
end

save(outputFile, "geometry");
fprintf("Saved geometry file: %s\n", outputFile);
end

function coilDefs = normalise_stl_inputs(stlInput, pose, opts)
if isstruct(stlInput)
    coilDefs = stlInput(:).';

    for k = 1:numel(coilDefs)
        if ~isfield(coilDefs(k), "stlFile")
            error("coilDefs(%d).stlFile is required.", k);
        end
        if ~isfield(coilDefs(k), "pose")
            error("coilDefs(%d).pose is required.", k);
        end
        if ~isfield(coilDefs(k), "coilName") || strlength(string(coilDefs(k).coilName)) == 0
            coilDefs(k).coilName = "STL coil " + string(k);
        end
        if ~isfield(coilDefs(k), "coilType") || strlength(string(coilDefs(k).coilType)) == 0
            coilDefs(k).coilType = "stl";
        end
        if ~isfield(coilDefs(k), "inputScale") || isempty(coilDefs(k).inputScale)
            coilDefs(k).inputScale = opts.InputScale;
        end
        if ~isfield(coilDefs(k), "localOrigin")
            coilDefs(k).localOrigin = opts.LocalOrigin;
        end
        if ~isfield(coilDefs(k), "centreMode") || strlength(string(coilDefs(k).centreMode)) == 0
            coilDefs(k).centreMode = opts.CentreMode;
        end
    end

else
    stlFiles = string(stlInput);
    if isempty(pose)
        error("pose is required when stlInput is a filename or string array.");
    end

    if isvector(pose) && numel(pose) == 6
        pose = reshape(pose, 1, 6);
    end

    if size(pose, 1) == 1 && numel(stlFiles) > 1
        pose = repmat(pose, numel(stlFiles), 1);
    end

    if size(pose, 1) ~= numel(stlFiles) || size(pose, 2) ~= 6
        error("pose must be 1x6 or nFiles x 6.");
    end

    template = struct( ...
        "stlFile", "", ...
        "pose", zeros(1,6), ...
        "coilName", "", ...
        "coilType", "", ...
        "inputScale", opts.InputScale, ...
        "localOrigin", opts.LocalOrigin, ...
        "centreMode", opts.CentreMode);

    coilDefs = repmat(template, 1, numel(stlFiles));

    coilNames = string(opts.CoilName);
    if numel(coilNames) == 1 && numel(stlFiles) > 1
        coilNames = coilNames + " " + string(1:numel(stlFiles));
    end

    coilTypes = string(opts.CoilType);
    if numel(coilTypes) == 1 && numel(stlFiles) > 1
        coilTypes = repmat(coilTypes, 1, numel(stlFiles));
    end

    for k = 1:numel(stlFiles)
        coilDefs(k).stlFile = stlFiles(k);
        coilDefs(k).pose = pose(k,:);
        coilDefs(k).coilName = coilNames(min(k, numel(coilNames)));
        coilDefs(k).coilType = coilTypes(min(k, numel(coilTypes)));
    end
end
end
