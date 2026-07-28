%% query_halfmorgan_parametric_innerR_xz_Bz_differences.m
% Query Bz on the x-z plane at y = 0 for a COMSOL parametric export where:
%
%   columns 1:3      = x, y, z
%   columns 4:6      = Bx, By, Bz for case 1
%   columns 7:9      = Bx, By, Bz for case 2
%   columns 10:12    = Bx, By, Bz for case 3
%   ...
%
% Parameter:
%   innerR_mm = 8:5:43
%   base case = innerR_mm = 18
%
% Output Q ordering:
%   Q{1} : base field, innerR = 18 mm, Bz on x-z plane
%   Q{2} : innerR = 8  mm minus base, Bz difference on x-z plane
%   Q{3} : innerR = 13 mm minus base, Bz difference on x-z plane
%   Q{4} : innerR = 23 mm minus base, Bz difference on x-z plane
%   ...
%
% Output file:
%   Q outputs/Q_HalfMorgan_Parametric_innerR_xz_Bz_Differences.mat

clear; close all; clc;

%% ----------------------------- Paths ---------------------------------- %%
addpath(genpath("functs"));

datasetDir = fullfile(pwd, "Datasets");
qOutDir    = fullfile(pwd, "Q outputs");

if ~exist(datasetDir, "dir")
    error('Could not find the input folder: "%s"', datasetDir);
end

if ~exist(qOutDir, "dir")
    mkdir(qOutDir);
end

datasetBase = "HalfMorgan_Parametric_innerR_Export";
datasetFile = localResolveDatasetFile(datasetDir, datasetBase, [".txt", ".csv", ".dat", ".mat"]);

queryOutputFile = fullfile(qOutDir, "Q_HalfMorgan_Parametric_innerR_25mm_xz_Bz_Differences.mat");

%% ------------------------- Parametric settings ------------------------ %%
innerR_mm = 8:5:43;
baseInnerR_mm = 18;

baseIdx = find(innerR_mm == baseInnerR_mm, 1, "first");
if isempty(baseIdx)
    error("baseInnerR_mm = %g mm is not present in innerR_mm.", baseInnerR_mm);
end

%% ----------------------------- Query ---------------------------------- %%
% x-z plane at 0 mm offset means y = 0.
% x-z plane at exactly y = 0, using interpolated custom-plane sampling.
% Plane definition:
%   point  = [0 0 0]
%   normal = [0 1 0]
% so the plane is y = 0.
planeQueryBase = create_custom_plane_field_query([0 25/1000 0], [0 1 0], "z", ...
    "Resolution", [150 150], ...
    "Group", 1, ...
    "Overview", false, ...
    "ShowCoils", false, ...
    "Name", sprintf("Base Bz, innerR = %g mm, x-z plane y = 0", baseInnerR_mm));

planeQueryDiff = create_custom_plane_field_query([0 25/1000 0], [0 1 0], "z", ...
    "Resolution", [150 150], ...
    "Group", 2, ...
    "Overview", false, ...
    "ShowCoils", false, ...
    "Name", "Bz difference relative to base, x-z plane y = 0");

%% ------------------------ Load parametric data ------------------------ %%
paramData = localLoadParametricComsolExport(datasetFile, innerR_mm);

if paramData.nCases ~= numel(innerR_mm)
    error([ ...
        "The file contains %d field cases, but innerR_mm contains %d values.\n" + ...
        "Detected columns: %d. Expected columns for this innerR list: %d.\n" + ...
        "Update innerR_mm to match the export ordering, or check the export file."], ...
        paramData.nCases, numel(innerR_mm), paramData.nColumns, 3 + 3*numel(innerR_mm));
end

fprintf("Loaded %d parametric cases from:\n  %s\n", paramData.nCases, datasetFile);
fprintf("Base case: innerR = %g mm, case index %d.\n", baseInnerR_mm, baseIdx);

%% ----------------------- Create datasets and query -------------------- %%
op = struct();
op.mode = "precomputed";
op.currents = [];
op.magnet = [];
op.target = [];
op.rowsToControl = [];
op.residualNorm = [];

baseDataset = localMakeSingleCaseDataset(paramData, baseIdx, ...
    sprintf("innerR_%gmm_base", baseInnerR_mm), datasetFile);

Q = {};

% First Q case: base field, not a difference.
baseCaseDef = struct();
baseCaseDef.caseName = sprintf("Base field, innerR = %g mm", baseInnerR_mm);
baseCaseDef.model = "comsol_precomputed";
baseCaseDef.datasetFile = datasetFile;
baseCaseDef.innerR_mm = baseInnerR_mm;
baseCaseDef.baseInnerR_mm = baseInnerR_mm;
baseCaseDef.isDifference = false;
baseCaseDef.queries = {planeQueryBase};

[results, queriesUsed] = run_field_queries(baseDataset, op, baseCaseDef.queries, baseCaseDef.model);
Q{end+1} = pack_query_case(baseDataset, op, queriesUsed, results, baseCaseDef, mfilename("fullpath")); %#ok<SAGROW>

% Remaining Q cases: each parametric case minus the base case.
for iCase = 1:paramData.nCases

    thisInnerR_mm = innerR_mm(iCase);

    if iCase == baseIdx
        continue
    end

    thisDataset = localMakeSingleCaseDataset(paramData, iCase, ...
        sprintf("innerR_%gmm", thisInnerR_mm), datasetFile);

    diffDataset = localMakeDifferenceDataset(thisDataset, baseDataset, ...
        sprintf("innerR_%gmm_minus_%gmm", thisInnerR_mm, baseInnerR_mm), ...
        datasetFile, thisInnerR_mm, baseInnerR_mm);

    thisCaseDef = struct();
    thisCaseDef.caseName = sprintf("innerR = %g mm minus base %g mm", thisInnerR_mm, baseInnerR_mm);
    thisCaseDef.model = "comsol_precomputed";
    thisCaseDef.datasetFile = datasetFile;
    thisCaseDef.innerR_mm = thisInnerR_mm;
    thisCaseDef.baseInnerR_mm = baseInnerR_mm;
    thisCaseDef.isDifference = true;

    thisQuery = planeQueryDiff;
    thisQuery.name = sprintf("Bz difference, innerR = %g mm minus %g mm, x-z plane y = 0", ...
        thisInnerR_mm, baseInnerR_mm);
    thisCaseDef.queries = {thisQuery};

    [results, queriesUsed] = run_field_queries(diffDataset, op, thisCaseDef.queries, thisCaseDef.model);
    Q{end+1} = pack_query_case(diffDataset, op, queriesUsed, results, thisCaseDef, mfilename("fullpath")); %#ok<SAGROW>

    Q{end}.parametric = struct();
    Q{end}.parametric.innerR_mm = thisInnerR_mm;
    Q{end}.parametric.baseInnerR_mm = baseInnerR_mm;
    Q{end}.parametric.differenceDefinition = "case_minus_base";
end

% Attach parametric metadata to all Q cases.
for k = 1:numel(Q)
    Q{k}.parametricStudy = struct();
    Q{k}.parametricStudy.parameterName = "innerR";
    Q{k}.parametricStudy.parameterValues_mm = innerR_mm;
    Q{k}.parametricStudy.baseValue_mm = baseInnerR_mm;
    Q{k}.parametricStudy.datasetFile = string(datasetFile);

    if ~isfield(Q{k}, "parametric")
        Q{k}.parametric = struct();
        Q{k}.parametric.innerR_mm = baseInnerR_mm;
        Q{k}.parametric.baseInnerR_mm = baseInnerR_mm;
        Q{k}.parametric.differenceDefinition = "base_field_not_difference";
    end
end

save(queryOutputFile, "Q", "-v7.3");
fprintf("\nSaved parametric innerR Q output to:\n  %s\n", queryOutputFile);

%% =========================== Local functions ========================== %%
function datasetFile = localResolveDatasetFile(datasetDir, baseName, extensions)

datasetDir = string(datasetDir);
baseName = string(baseName);
extensions = string(extensions);

directPath = fullfile(datasetDir, baseName);
if isfile(directPath)
    datasetFile = directPath;
    return
end

[~, ~, existingExt] = fileparts(baseName);
if strlength(string(existingExt)) > 0
    error('Could not find dataset file: "%s"', directPath);
end

candidates = strings(1, numel(extensions));
for k = 1:numel(extensions)
    candidates(k) = fullfile(datasetDir, baseName + extensions(k));
    if isfile(candidates(k))
        datasetFile = candidates(k);
        return
    end
end

error("Could not resolve dataset '%s' in %s. Tried:\n  %s", ...
    baseName, datasetDir, strjoin(candidates, newline + "  "));
end

function paramData = localLoadParametricComsolExport(fileName, innerR_mm)

fileName = string(fileName);
[~, ~, ext] = fileparts(fileName);

if strcmpi(ext, ".mat")
    raw = load(fileName);
    if isfield(raw, "M")
        M = raw.M;
    elseif isfield(raw, "data")
        M = raw.data;
    elseif isfield(raw, "exportData")
        M = raw.exportData;
    else
        error("MAT file must contain numeric variable M, data, or exportData.");
    end
else
    M = readmatrix(fileName, "FileType", "text", "Delimiter", ",");
end

M = double(M);
M = M(all(isfinite(M), 2), :);

if isempty(M)
    error("No valid numeric rows found in %s.", fileName);
end

nColumns = size(M, 2);

if nColumns < 6
    error("Parametric export must contain at least 6 columns: x,y,z,Bx,By,Bz.");
end

if mod(nColumns - 3, 3) ~= 0
    error("Column count must satisfy 3 + 3*nCases. Found %d columns.", nColumns);
end

nCases = (nColumns - 3) / 3;

x = unique(M(:,1), "sorted");
y = unique(M(:,2), "sorted");
z = unique(M(:,3), "sorted");

Nx = numel(x);
Ny = numel(y);
Nz = numel(z);
expectedRows = Nx * Ny * Nz;

if size(M, 1) ~= expectedRows
    error("Grid is incomplete or non-rectilinear: expected %d rows from unique x/y/z values, found %d rows.", ...
        expectedRows, size(M, 1));
end

[isX, ix] = ismember(M(:,1), x);
[isY, iy] = ismember(M(:,2), y);
[isZ, iz] = ismember(M(:,3), z);

if ~all(isX & isY & isZ)
    error("Failed to map coordinates onto unique grid vectors.");
end

linearIdx = sub2ind([Ny, Nx, Nz], iy, ix, iz);

if numel(unique(linearIdx)) ~= expectedRows
    error("Data contains duplicate or missing grid points.");
end

B = NaN(Ny, Nx, Nz, 3, nCases);

for iCase = 1:nCases
    col0 = 3 + 3*(iCase - 1);
    for componentIndex = 1:3
        componentGrid = NaN(Ny, Nx, Nz);
        componentGrid(linearIdx) = M(:, col0 + componentIndex);
        B(:,:,:,componentIndex,iCase) = componentGrid;
    end
end

paramData = struct();
paramData.fileName = fileName;
paramData.nColumns = nColumns;
paramData.nCases = nCases;
paramData.innerR_mm = innerR_mm(:).';
paramData.grid = struct("x", x(:).', "y", y(:).', "z", z(:).');
paramData.geometry = struct();
paramData.geometry.windTunnel = [min(x) max(x); min(y) max(y); min(z) max(z)];
paramData.geometry.coilSpec = struct();
paramData.geometry.coil = struct([]);
paramData.B = B;
end

function dataset = localMakeSingleCaseDataset(paramData, iCase, label, sourceFile)

dataset = struct();
dataset.source = "comsol_precomputed";
dataset.createdOn = string(datetime("now", "Format", "yyyy-MM-dd HH:mm:ss"));
dataset.inputFile = string(sourceFile);
dataset.datasetFile = string(sourceFile);
dataset.caseLabel = string(label);
dataset.parametricCaseIndex = iCase;
dataset.supportsSuperposition = false;
dataset.supportsCurrentSolve = false;
dataset.geometry = paramData.geometry;
dataset.grid = paramData.grid;
dataset.B = paramData.B(:,:,:,:,iCase);
dataset.B = reshape(dataset.B, ...
    size(paramData.B,1), size(paramData.B,2), size(paramData.B,3), 3, 1);
end

function diffDataset = localMakeDifferenceDataset(caseDataset, baseDataset, label, sourceFile, innerR_mm, baseInnerR_mm)

if ~isequal(caseDataset.grid.x, baseDataset.grid.x) || ...
   ~isequal(caseDataset.grid.y, baseDataset.grid.y) || ...
   ~isequal(caseDataset.grid.z, baseDataset.grid.z)
    error("Case and base grids do not match exactly. This script expects all parametric cases on the same exported grid.");
end

diffDataset = caseDataset;
diffDataset.caseLabel = string(label);
diffDataset.B = caseDataset.B - baseDataset.B;
diffDataset.source = "comsol_precomputed";
diffDataset.synthetic = struct();
diffDataset.synthetic.type = "parametric_difference";
diffDataset.synthetic.definition = "case_minus_base";
diffDataset.synthetic.parameterName = "innerR";
diffDataset.synthetic.innerR_mm = innerR_mm;
diffDataset.synthetic.baseInnerR_mm = baseInnerR_mm;
diffDataset.synthetic.sourceFile = string(sourceFile);
end
