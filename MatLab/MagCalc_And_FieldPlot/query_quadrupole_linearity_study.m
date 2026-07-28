%% query_quadrupole_linearity_study.m
% Query script for quadrupole-linearity comparison using:
%   1) Quadrupole_Base_Export      : coils only
%   2) Quadrupole_PMz_Export       : coils + permanent magnet
%   3) Quadrupole_PMzOnly_Export   : permanent magnet only
%
% The script samples:
%   - Bz on the x-z plane at y = 0, spanning x = [-1, 1] m and z = [-0.6, 0.6] m
%   - dBz/dz on the centreline x = 0, y = 0, spanning z = [-0.6, 0.6] m
%
% It then creates six Q cases:
%   Q{1} : coils + PM
%   Q{2} : coils only
%   Q{3} : PM only
%   Q{4} : coils only + PM only                      (synthetic sum)
%   Q{5} : (coils + PM) - (PM only)                 (reconstructed coils)
%   Q{6} : [(coils + PM) - (PM only)] - (coils only) = residual nonlinearity
%
% Each Q case contains:
%   results{1} : planar Bz
%   results{2} : line dBz/dz

clear; close all; clc;

%% ----------------------------- Paths ---------------------------------- %%
datasetDir = fullfile(pwd, "Datasets");
qOutDir    = fullfile(pwd, "Q outputs");

if ~exist(qOutDir, "dir")
    mkdir(qOutDir);
end

datasetBaseNames = [ ...
    "Quadrupole_Base_Export", ...
    "Quadrupole_PMz_Export", ...
    "Quadrupole_PMzOnly_Export"];

qFile = fullfile(qOutDir, "Q_Quadrupole_Linearity_Study.mat");

%% ------------------------- Query settings ----------------------------- %%
xPlaneLim_m = [-1.0, 1.0];
zPlaneLim_m = [-0.6, 0.6];
yPlane_m = 0.0;

zLineLim_m = [-0.6, 0.6];
xLine_m = 0.0;
yLine_m = 0.0;

planeResolution = [401, 241];   % [Nx, Nz]
nLinePoints = 1201;

%% -------------------------- Load datasets ----------------------------- %%
baseData = cell(1, 3);

for k = 1:3
    baseData{k} = localLoadSingleCaseExport(datasetDir, datasetBaseNames(k));
end

%% --------------------------- Sample queries --------------------------- %%
% Shared query coordinate grids.
xq = linspace(xPlaneLim_m(1), xPlaneLim_m(2), planeResolution(1));
zq = linspace(zPlaneLim_m(1), zPlaneLim_m(2), planeResolution(2));
[Xq, Zq] = meshgrid(xq, zq);
Yq = yPlane_m * ones(size(Xq));

zLine = linspace(zLineLim_m(1), zLineLim_m(2), nLinePoints).';
xLine = xLine_m * ones(size(zLine));
yLine = yLine_m * ones(size(zLine));

% Sample the three physical datasets.
planeBase = localSamplePlaneBz(baseData{1}, Xq, Yq, Zq);
planePMz  = localSamplePlaneBz(baseData{2}, Xq, Yq, Zq);
planePMOnly = localSamplePlaneBz(baseData{3}, Xq, Yq, Zq);

lineBase_Bz = localSampleLineBz(baseData{1}, xLine, yLine, zLine);
linePMz_Bz  = localSampleLineBz(baseData{2}, xLine, yLine, zLine);
linePMOnly_Bz = localSampleLineBz(baseData{3}, xLine, yLine, zLine);

lineBase_grad = localGradient1D(zLine, lineBase_Bz);
linePMz_grad  = localGradient1D(zLine, linePMz_Bz);
linePMOnly_grad = localGradient1D(zLine, linePMOnly_Bz);

% Synthetic combinations.
planeSum = planeBase + planePMOnly;
planeReconstructedCoils = planePMz - planePMOnly;
planeResidual = planeReconstructedCoils - planeBase;

lineSum_Bz = lineBase_Bz + linePMOnly_Bz;
lineReconstructedCoils_Bz = linePMz_Bz - linePMOnly_Bz;
lineResidual_Bz = lineReconstructedCoils_Bz - lineBase_Bz;

lineSum_grad = localGradient1D(zLine, lineSum_Bz);
lineReconstructedCoils_grad = localGradient1D(zLine, lineReconstructedCoils_Bz);
lineResidual_grad = localGradient1D(zLine, lineResidual_Bz);

%% ----------------------------- Pack Q -------------------------------- %%
Q = cell(1, 6);

Q{1} = localMakeQCase( ...
    "Quadrupole + PM", "coils_plus_pm", ...
    Xq, Zq, planePMz, zLine, linePMz_grad);

Q{2} = localMakeQCase( ...
    "Quadrupole only", "coils_only", ...
    Xq, Zq, planeBase, zLine, lineBase_grad);

Q{3} = localMakeQCase( ...
    "PM only", "pm_only", ...
    Xq, Zq, planePMOnly, zLine, linePMOnly_grad);

Q{4} = localMakeQCase( ...
    "Quadrupole only + PM only", "sum_coils_plus_pm", ...
    Xq, Zq, planeSum, zLine, lineSum_grad);

Q{5} = localMakeQCase( ...
    "(Quadrupole + PM) - (PM only)", "reconstructed_coils", ...
    Xq, Zq, planeReconstructedCoils, zLine, lineReconstructedCoils_grad);

Q{6} = localMakeQCase( ...
    "Residual nonlinearity", "residual_nonlinearity", ...
    Xq, Zq, planeResidual, zLine, lineResidual_grad);

save(qFile, "Q", "-v7.3");
fprintf("Saved Q file to:\n  %s\n", qFile);

%% -------------------------- Local functions -------------------------- %%
function dataset = localLoadSingleCaseExport(datasetDir, baseName)

    fileName = localResolveDatasetFile(datasetDir, baseName, [".txt", ".csv", ".dat", ".mat"]);
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
            error("MAT file '%s' must contain numeric M, data, or exportData.", fileName);
        end
    else
        M = readmatrix(fileName, "FileType", "text", "Delimiter", ",");
    end

    M = double(M);
    M = M(all(isfinite(M), 2), :);

    if size(M, 2) < 6
        error("Dataset '%s' must contain x,y,z,Bx,By,Bz columns.", fileName);
    end

    x = unique(M(:,1), "sorted");
    y = unique(M(:,2), "sorted");
    z = unique(M(:,3), "sorted");

    Nx = numel(x);
    Ny = numel(y);
    Nz = numel(z);

    expectedRows = Nx * Ny * Nz;
    if size(M, 1) ~= expectedRows
        error("Dataset '%s' is not a complete rectilinear grid.", fileName);
    end

    [~, ix] = ismember(M(:,1), x);
    [~, iy] = ismember(M(:,2), y);
    [~, iz] = ismember(M(:,3), z);

    linearIdx = sub2ind([Nx, Ny, Nz], ix, iy, iz);

    Bx = NaN(Nx, Ny, Nz);
    By = NaN(Nx, Ny, Nz);
    Bz = NaN(Nx, Ny, Nz);

    Bx(linearIdx) = M(:,4);
    By(linearIdx) = M(:,5);
    Bz(linearIdx) = M(:,6);

    dataset = struct();
    dataset.fileName = string(fileName);
    dataset.x = x(:).';
    dataset.y = y(:).';
    dataset.z = z(:).';
    dataset.Bx = Bx;
    dataset.By = By;
    dataset.Bz = Bz;
end

function fileName = localResolveDatasetFile(datasetDir, baseName, extensions)

    directPath = fullfile(datasetDir, baseName);
    if isfile(directPath)
        fileName = directPath;
        return
    end

    for k = 1:numel(extensions)
        candidate = fullfile(datasetDir, baseName + extensions(k));
        if isfile(candidate)
            fileName = candidate;
            return
        end
    end

    alt = fullfile("/mnt/data", baseName);
    if isfile(alt)
        fileName = alt;
        return
    end
    for k = 1:numel(extensions)
        candidate = fullfile("/mnt/data", baseName + extensions(k));
        if isfile(candidate)
            fileName = candidate;
            return
        end
    end

    error("Could not resolve dataset '%s'.", baseName);
end

function planeBz = localSamplePlaneBz(dataset, Xq, Yq, Zq)

    F = griddedInterpolant({dataset.x, dataset.y, dataset.z}, dataset.Bz, "linear", "none");
    planeBz = F(Xq, Yq, Zq);
end

function lineBz = localSampleLineBz(dataset, xLine, yLine, zLine)

    F = griddedInterpolant({dataset.x, dataset.y, dataset.z}, dataset.Bz, "linear", "none");
    lineBz = F(xLine, yLine, zLine);
end

function g = localGradient1D(z, f)

    g = gradient(f, z);
end

function Qcase = localMakeQCase(caseName, sourceName, Xq, Zq, planeBz, zLine, lineGrad)

    planeQuery = struct();
    planeQuery.type = "plane";
    planeQuery.component = "z";
    planeQuery.name = "Bz on x-z plane, y = 0";
    planeQuery.point = [0 0 0];
    planeQuery.normal = [0 1 0];

    lineQuery = struct();
    lineQuery.type = "line_gradient";
    lineQuery.component = "z";
    lineQuery.gradientDirection = [0 0 1];
    lineQuery.name = "dBz/dz on centreline, x = 0, y = 0";
    lineQuery.start = [0 0 zLine(1)];
    lineQuery.end   = [0 0 zLine(end)];

    planeResult = struct();
    planeResult.queryIndex = 1;
    planeResult.X = Xq;
    planeResult.Y = zeros(size(Xq));
    planeResult.Z = Zq;
    planeResult.data = planeBz;
    planeResult.dataName = "Bz";
    planeResult.plot = struct("group", 1, "inOverview", false, "showCoils", false);

    lineResult = struct();
    lineResult.queryIndex = 2;
    lineResult.X = zeros(size(zLine));
    lineResult.Y = zeros(size(zLine));
    lineResult.Z = zLine;
    lineResult.s = zLine - zLine(1);
    lineResult.data = lineGrad;
    lineResult.dataName = "dBz/dz";
    lineResult.plot = struct("group", 2, "inOverview", false, "showCoils", false);

    Qcase = struct();
    Qcase.meta = struct();
    Qcase.meta.caseName = string(caseName);
    Qcase.meta.source = string(sourceName);
    Qcase.meta.createdOn = string(datetime("now", "Format", "yyyy-MM-dd HH:mm:ss"));

    Qcase.geometry = struct();
    Qcase.geometry.note = "Analytic overlay geometry is defined in the plotting script.";

    Qcase.queries = {planeQuery, lineQuery};
    Qcase.results = {planeResult, lineResult};
end
