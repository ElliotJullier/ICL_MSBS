function dataset = attach_geometry_file_to_dataset(dataset, geometryFile)
%ATTACH_GEOMETRY_FILE_TO_DATASET Attach plotting geometry to a dataset.
%
% This is intended for precomputed datasets such as COMSOL exports, where
% the field file contains only x,y,z,Bx,By,Bz and no coil metadata.
%
% Usage:
%   dataset = attach_geometry_file_to_dataset(dataset, caseDef.geometryFile);

if nargin < 2 || strlength(string(geometryFile)) == 0
    return
end

dataset.geometry = load_geometry_file(geometryFile);
dataset.geometryFile = string(geometryFile);

if ~isfield(dataset, "metadata") || ~isstruct(dataset.metadata)
    dataset.metadata = struct();
end
dataset.metadata.geometryFile = string(geometryFile);
end
