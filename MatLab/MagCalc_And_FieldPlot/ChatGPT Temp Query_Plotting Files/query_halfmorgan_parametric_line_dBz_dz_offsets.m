%% query_halfmorgan_parametric_line_dBz_dz_offsets.m
% Query vertical line gradients dBz/dz for a HalfMorgan COMSOL parametric export.
%
% Export format:
%   columns 1:3   = x, y, z
%   columns 4:6   = Bx, By, Bz for parametric case 1
%   columns 7:9   = Bx, By, Bz for parametric case 2
%   ...
%
% Workflow:
%   1) Set studyName to "height", "innerR", or "R".
%   2) Set paramValues_mm in the same order as the COMSOL parametric export.
%      If left empty, the script uses case numbers instead.
%   3) Run this script to create one Q file containing dBz/dz lines for all
%      parameter values and all requested offsets.
%
% Q structure:
%   Q{k} = one parameter value/case
%   Q{k}.results{iOffset} = one vertical line at the requested offset
%
% Output:
%   Q outputs/Q_HalfMorgan_Parametric_<studyName>_Line_dBzDz_Offsets.mat

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

%% ------------------------- Study settings ----------------------------- %%
% Choose one:
%   "height"
%   "innerR"
%   "R"
studyName = "R";

% Dataset name is built as:
%   HalfMorgan_Parametric_<studyName>_Export
datasetBase = "HalfMorgan_Parametric_" + studyName + "_Export";
datasetFile = localResolveDatasetFile(datasetDir, datasetBase, [".txt", ".csv", ".dat", ".mat"]);

% Parameter values in the same order as the COMSOL export.
% Leave [] to use case numbers in legends/filenames.
%
% Examples:
%   innerR: paramValues_mm = 8:5:43;
%   R:      paramValues_mm = 35:5:70;       % update to your actual sweep
%   height: paramValues_mm = [40 45 50 55]; % update to your actual sweep
paramValues_mm = [0.0375:0.01:0.0675];

% Optional base/reference value. Used only for styling in the plotter.
% Leave NaN if there is no explicit base case.
baseParamValue_mm = 0.0475;

% Vertical line offsets. These are x-z style offsets:
%   x = 0, y = offset
offsetList_mm = [0, 5, 10, 25, 50, 75];

% z extent of every vertical line.
zLine_mm = [-120, 120];
nLinePoints = 500;

queryOutputFile = fullfile(qOutDir, ...
    "Q_HalfMorgan_Parametric_" + studyName + "_Line_dBzDz_Offsets.mat");

%% ------------------------- Load parametric data ----------------------- %%
paramData = localLoadParametricComsolExport(datasetFile);

if isempty(paramValues_mm)
    paramValues_mm = 1:paramData.nCases;
    parameterUnits = "case";
else
    parameterUnits = "mm";
end

paramValues_mm = double(paramValues_mm(:).');

if paramData.nCases ~= numel(paramValues_mm)
    error([ ...
        "The file contains %d field cases, but paramValues_mm contains %d values.\n" + ...
        "Detected columns: %d. Expected columns for this parameter list: %d.\n" + ...
        "Update paramValues_mm to match the COMSOL export ordering."], ...
        paramData.nCases, numel(paramValues_mm), paramData.nColumns, 3 + 3*numel(paramValues_mm));
end

fprintf("Loaded %d parametric cases from:\n  %s\n", paramData.nCases, datasetFile);
fprintf("Study parameter: %s\n", studyName);

%% ----------------------------- Queries -------------------------------- %%
lineQueries = cell(1, numel(offsetList_mm));

for iOffset = 1:numel(offsetList_mm)
    off_mm = offsetList_mm(iOffset);
    off_m  = off_mm * 1e-3;

    lineQueries{iOffset} = create_line_gradient_query( ...
        [0, off_m, zLine_mm(1)*1e-3], ...
        [0, off_m, zLine_mm(2)*1e-3], ...
        "z", ...
        "GradientDirection", [0 0 1], ...
        "NPoints", nLinePoints, ...
        "Group", iOffset, ...
        "Overview", false, ...
        "ShowCoils", false, ...
        "Name", sprintf("dBz/dz, y offset = %g mm", off_mm));
end

%% ----------------------- Create datasets and query -------------------- %%
op = struct();
op.mode = "precomputed";
op.currents = [];
op.magnet = [];
op.target = [];
op.rowsToControl = [];
op.residualNorm = [];

Q = cell(1, paramData.nCases);

for iCase = 1:paramData.nCases

    thisParam = paramValues_mm(iCase);
    dataset = localMakeSingleCaseDataset(paramData, iCase, ...
        sprintf("%s_%g", studyName, thisParam), datasetFile);

    caseDef = struct();
    caseDef.caseName = sprintf("%s = %g %s", studyName, thisParam, parameterUnits);
    caseDef.model = "comsol_precomputed";
    caseDef.datasetFile = datasetFile;
    caseDef.parameterName = studyName;
    caseDef.parameterValue = thisParam;
    caseDef.parameterUnits = parameterUnits;
    caseDef.baseParameterValue = baseParamValue_mm;
    caseDef.queries = lineQueries;

    [results, queriesUsed] = run_field_queries(dataset, op, caseDef.queries, caseDef.model);

    Q{iCase} = pack_query_case(dataset, op, queriesUsed, results, caseDef, mfilename("fullpath"));

    Q{iCase}.parametricStudy = struct();
    Q{iCase}.parametricStudy.parameterName = studyName;
    Q{iCase}.parametricStudy.parameterValues = paramValues_mm;
    Q{iCase}.parametricStudy.parameterUnits = parameterUnits;
    Q{iCase}.parametricStudy.baseValue = baseParamValue_mm;
    Q{iCase}.parametricStudy.datasetFile = string(datasetFile);

    Q{iCase}.parametric = struct();
    Q{iCase}.parametric.parameterName = studyName;
    Q{iCase}.parametric.parameterValue = thisParam;
    Q{iCase}.parametric.parameterUnits = parameterUnits;
    Q{iCase}.parametric.baseValue = baseParamValue_mm;
    Q{iCase}.parametric.caseIndex = iCase;
    Q{iCase}.parametric.offsetList_mm = offsetList_mm;
end

save(queryOutputFile, "Q", "-v7.3");
fprintf("\nSaved parametric line-gradient Q output to:\n  %s\n", queryOutputFile);

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

function paramData = localLoadParametricComsolExport(fileName)

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

Bcase = paramData.B(:,:,:,:,iCase);
dataset.B = reshape(Bcase, size(paramData.B,1), size(paramData.B,2), size(paramData.B,3), 3, 1);
end
