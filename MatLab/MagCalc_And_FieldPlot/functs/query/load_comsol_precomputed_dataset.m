function dataset = load_comsol_precomputed_dataset(fileName)
%LOAD_COMSOL_PRECOMPUTED_DATASET Import a COMSOL total-field text export.
%
% Expected file format:
%   x, y, z, Bx, By, Bz
%
% The COMSOL file is treated as a precomputed total-field dataset:
%   dataset.supportsSuperposition = false
%   dataset.supportsCurrentSolve  = false
%
% The imported field is stored using the project convention:
%   dataset.B(yIndex, xIndex, zIndex, componentIndex, 1)
%
% where:
%   componentIndex = 1 -> Bx
%   componentIndex = 2 -> By
%   componentIndex = 3 -> Bz
%
% The file must contain a complete rectilinear grid. Incomplete grids are
% rejected because query interpolation and field comparisons assume a valid
% grid.

fileName = string(fileName);

if ~isfile(fileName)
    error("COMSOL data file does not exist: %s", fileName);
end

M = readmatrix(fileName, "FileType", "text", "Delimiter", ",");

if size(M, 2) < 6
    error("COMSOL data file must contain at least six columns: x,y,z,Bx,By,Bz.");
end

M = M(:, 1:6);
M = M(all(isfinite(M), 2), :);

if isempty(M)
    error("COMSOL data file contains no valid numeric x,y,z,Bx,By,Bz rows.");
end

x = unique(M(:,1), "sorted");
y = unique(M(:,2), "sorted");
z = unique(M(:,3), "sorted");

Nx = numel(x);
Ny = numel(y);
Nz = numel(z);
expectedRows = Nx * Ny * Nz;

if size(M, 1) ~= expectedRows
    error("COMSOL grid is incomplete or non-rectilinear: expected %d grid rows from unique x/y/z values, found %d numeric rows.", ...
        expectedRows, size(M, 1));
end

[isX, ix] = ismember(M(:,1), x);
[isY, iy] = ismember(M(:,2), y);
[isZ, iz] = ismember(M(:,3), z);

if ~all(isX & isY & isZ)
    error("Failed to map COMSOL coordinates onto unique grid vectors.");
end

linearIdx = sub2ind([Ny, Nx, Nz], iy, ix, iz);

if numel(unique(linearIdx)) ~= expectedRows
    error("COMSOL data contains duplicate grid points or missing grid points.");
end

B = NaN(Ny, Nx, Nz, 3, 1);

for componentIndex = 1:3
    componentGrid = NaN(Ny, Nx, Nz);
    componentGrid(linearIdx) = M(:, 3 + componentIndex);
    B(:,:,:,componentIndex,1) = componentGrid;
end

grid = struct();
grid.x = x(:).';
grid.y = y(:).';
grid.z = z(:).';

geometry = struct();
geometry.windTunnel = [min(x) max(x); min(y) max(y); min(z) max(z)];
geometry.coilSpec = struct();
geometry.coil = struct([]);

dataset = struct();
dataset.source = "comsol_precomputed";
dataset.createdOn = string(datetime("now", "Format", "yyyy-MM-dd HH:mm:ss"));
dataset.inputFile = fileName;
dataset.datasetFile = fileName;
dataset.supportsSuperposition = false;
dataset.supportsCurrentSolve = false;
dataset.geometry = geometry;
dataset.grid = grid;
dataset.B = B;
end
