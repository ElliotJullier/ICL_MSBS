function dataset = pack_field_dataset(source, geometry, grid, B, varargin)
%PACK_FIELD_DATASET Build the saved magnetic field dataset structure.
%
% The saved dataset uses one magnetic field variable:
%
%   dataset.B(y,x,z,component,fieldSet)
%
% where component 1/2/3 means x/y/z. If supportsSuperposition is true,
% fieldSet is usually the coil number and B(:,:,:,:,k) is the field from
% coil k per ampere/reference current. If supportsSuperposition is false,
% fieldSet is usually 1 and B(:,:,:,:,1) is the total precomputed field.
%
% Coordinates are saved compactly as dataset.grid.x/y/z. Meshgrid arrays are
% intentionally not saved.

p = inputParser;
addParameter(p, "saveFile", "", @(x)isstring(x) || ischar(x));
addParameter(p, "supportsSuperposition", true, @(x)islogical(x) || isnumeric(x));
addParameter(p, "supportsCurrentSolve", true, @(x)islogical(x) || isnumeric(x));
parse(p, varargin{:});
opts = p.Results;

validate_grid_struct(grid);
validate_B_grid(B, grid);

dataset = struct();
dataset.source = string(source);
dataset.createdOn = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
dataset.saveFile = string(opts.saveFile);
dataset.supportsSuperposition = logical(opts.supportsSuperposition);
dataset.supportsCurrentSolve = logical(opts.supportsCurrentSolve);
dataset.geometry = geometry;
dataset.grid = grid;
dataset.B = B;

end

function validate_grid_struct(grid)
required = {"x", "y", "z"};
for k = 1:numel(required)
    if ~isfield(grid, required{k})
        error("grid.%s is required.", required{k});
    end
end
end

function validate_B_grid(B, grid)
expected = [numel(grid.y), numel(grid.x), numel(grid.z), 3];
sz = size(B);

if numel(sz) == 4
    sz(5) = 1;
end

if numel(sz) < 5 || any(sz(1:4) ~= expected)
    error("B must have size [Ny, Nx, Nz, 3, nFieldSets].");
end
end
