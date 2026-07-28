function dataset = load_field_dataset(datasetFile)
%LOAD_FIELD_DATASET Load and validate a saved magnetic field dataset.
%
% The loader standardises grid-based field datasets so downstream query code
% always sees:
%
%   dataset.B(y,x,z,component,fieldSet)
%
% If a future importer saves B as [Ny,Nx,Nz,3], this function reshapes it to
% [Ny,Nx,Nz,3,1] immediately after validation. This is the best place to do
% the 4D-to-5D conversion because every later function can assume one shape.

datasetFile = string(datasetFile);
if ~endsWith(datasetFile, ".mat")
    datasetFile = datasetFile + ".mat";
end

S = load(datasetFile);

if ~isfield(S, "dataset")
    error("Dataset file must contain a variable called dataset.");
end

dataset = S.dataset;

requiredTop = ["source", "createdOn", "supportsSuperposition", "supportsCurrentSolve", "geometry", "grid"];
for k = 1:numel(requiredTop)
    if ~isfield(dataset, requiredTop(k))
        error("dataset.%s is required.", requiredTop(k));
    end
end

validate_grid_struct(dataset.grid);

if isfield(dataset, "B")
    validate_B_grid(dataset.B, dataset.grid);

    if ndims(dataset.B) == 4
        dataset.B = reshape(dataset.B, ...
            size(dataset.B,1), size(dataset.B,2), size(dataset.B,3), size(dataset.B,4), 1);
    end
elseif string(dataset.source) == "simple_biotsavart"
    % A purely analytical simple source may need only geometry.
else
    error("dataset.B is required for grid-based field datasets.");
end

dataset.datasetFile = datasetFile;

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
    error("dataset.B must have size [Ny, Nx, Nz, 3, nFieldSets].");
end
end
