%% query_quadrupole_linearity_study_v4.m
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

% Treatment of NaN Bz values in otherwise regular exports:
%   "ignore"   : interpolate using only finite Bz samples
%   "preserve" : use the regular grid directly; NaNs can propagate
%   "error"    : stop if any Bz sample is NaN
nanHandlingMode = "ignore";

%% -------------------------- Load datasets ----------------------------- %%
baseData = cell(1, 3);

for k = 1:3
    baseData{k} = localLoadSingleCaseExport(datasetDir, datasetBaseNames(k), nanHandlingMode);

    fprintf("Loaded %s: mode=%s, samples=%d, Nx=%d, Ny=%d, Nz=%d\n", ...
        datasetBaseNames(k), ...
        baseData{k}.mode, ...
        baseData{k}.nSamples, ...
        numel(baseData{k}.x), ...
        numel(baseData{k}.y), ...
        numel(baseData{k}.z));
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
function dataset = localLoadSingleCaseExport(datasetDir, baseName, nanHandlingMode)
% Load a COMSOL export as either a rectilinear or scattered dataset.
%
% Supported forms:
%   - full Cartesian 3D grid
%   - Cartesian x-z plane with one y value
%   - unstructured/scattered x-z cut-plane export
%   - unstructured/scattered 3D export
%
% Duplicate coordinate rows are averaged before interpolation.

    fileName = localResolveDatasetFile( ...
        datasetDir, baseName, [".txt", ".csv", ".dat", ".mat"]);
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
            error("MAT file '%s' must contain numeric M, data, or exportData.", ...
                fileName);
        end
    else
        M = readmatrix(fileName, ...
            "FileType", "text", ...
            "Delimiter", ",");
    end

    M = double(M);

    if size(M, 2) < 6
        error("Dataset '%s' must contain x,y,z,Bx,By,Bz columns.", ...
            fileName);
    end

    % Keep the expected six columns.
    M = M(:,1:6);

    % Only invalid coordinates are removed. Rows with NaN field values are
    % retained so the regular coordinate grid is not mistaken for an
    % incomplete grid.
    finiteCoordinates = all(isfinite(M(:,1:3)), 2);
    M = M(finiteCoordinates, :);

    if isempty(M)
        error("Dataset '%s' contains no finite coordinate rows.", fileName);
    end

    nanHandlingMode = lower(string(nanHandlingMode));
    validModes = ["ignore", "preserve", "error"];

    if ~any(nanHandlingMode == validModes)
        error("Unknown nanHandlingMode: %s", nanHandlingMode);
    end

    % COMSOL can write nominally identical coordinates with tiny
    % floating-point differences. Snap only at a negligible spatial scale.
    coordinateTolerance_m = 1e-10;
    M(:,1:3) = round(M(:,1:3) / coordinateTolerance_m) ...
        * coordinateTolerance_m;

    % Average duplicate x-y-z samples while ignoring NaN field values.
    [xyzUnique, ~, duplicateGroup] = unique(M(:,1:3), "rows");
    BxUnique = accumarray(duplicateGroup, M(:,4), [], @localMeanFinite);
    ByUnique = accumarray(duplicateGroup, M(:,5), [], @localMeanFinite);
    BzUnique = accumarray(duplicateGroup, M(:,6), [], @localMeanFinite);

    M = [xyzUnique, BxUnique, ByUnique, BzUnique];

    x = unique(M(:,1), "sorted");
    y = unique(M(:,2), "sorted");
    z = unique(M(:,3), "sorted");

    Nx = numel(x);
    Ny = numel(y);
    Nz = numel(z);

    dataset = struct();
    dataset.fileName = string(fileName);
    dataset.x = x(:).';
    dataset.y = y(:).';
    dataset.z = z(:).';
    dataset.nSamples = size(M,1);
    dataset.coordinateTolerance_m = coordinateTolerance_m;

    expectedRows = Nx * Ny * Nz;

    if size(M,1) == expectedRows
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

        dataset.Bx = Bx;
        dataset.By = By;
        dataset.Bz = Bz;

        dataset.nNaNBz = nnz(~isfinite(Bz));

        if dataset.nNaNBz > 0
            fprintf("  %s contains %d NaN Bz grid values.\n", ...
                baseName, dataset.nNaNBz);

            switch nanHandlingMode
                case "error"
                    error([ ...
                        "Dataset '%s' contains %d NaN Bz values. " + ...
                        "Set nanHandlingMode to 'ignore' or 'preserve'."], ...
                        fileName, dataset.nNaNBz);

                case "ignore"
                    [Xgrid, Ygrid, Zgrid] = ndgrid(x, y, z);
                    finiteBz = isfinite(Bz);

                    dataset.sampleX = Xgrid(finiteBz);
                    dataset.sampleY = Ygrid(finiteBz);
                    dataset.sampleZ = Zgrid(finiteBz);
                    dataset.sampleBz = Bz(finiteBz);

                    if Ny == 1
                        dataset.mode = "rectilinear2d_ignore_nan";
                        dataset.yPlane = y(1);
                    else
                        dataset.mode = "rectilinear3d_ignore_nan";
                    end

                    return

                case "preserve"
                    % Continue below using griddedInterpolant directly.
            end
        end

        if Ny == 1
            dataset.mode = "rectilinear2d";
            dataset.yPlane = y(1);
        else
            dataset.mode = "rectilinear3d";
        end

        return
    end

    % Incomplete Cartesian products are often normal for COMSOL cut-plane
    % exports because the values are written on an unstructured mesh.
    ySpan = max(M(:,2)) - min(M(:,2));

    if ySpan <= 10 * coordinateTolerance_m
        dataset.mode = "scattered2d";
        dataset.yPlane = mean(M(:,2));

        % Collapse any duplicate x-z points independently of y.
        [xzUnique, ~, xzGroup] = unique(M(:,[1,3]), "rows");
        dataset.sampleX = xzUnique(:,1);
        dataset.sampleZ = xzUnique(:,2);
        dataset.sampleBz = accumarray(xzGroup, M(:,6), [], @localMeanFinite);

        finiteBz = isfinite(dataset.sampleBz);
        dataset.sampleX = dataset.sampleX(finiteBz);
        dataset.sampleZ = dataset.sampleZ(finiteBz);
        dataset.sampleBz = dataset.sampleBz(finiteBz);
        dataset.nSamples = numel(dataset.sampleBz);

        warning([ ...
            "Dataset '%s' is not a complete rectilinear grid. " + ...
            "Using 2D scattered interpolation on its x-z cut-plane."], ...
            fileName);
    else
        dataset.mode = "scattered3d";
        finiteBz = isfinite(M(:,6));
        dataset.sampleX = M(finiteBz,1);
        dataset.sampleY = M(finiteBz,2);
        dataset.sampleZ = M(finiteBz,3);
        dataset.sampleBz = M(finiteBz,6);

        warning([ ...
            "Dataset '%s' is not a complete rectilinear grid. " + ...
            "Using 3D scattered interpolation."], ...
            fileName);
    end
end

function value = localMeanFinite(values)
% Mean of finite entries; return NaN when a duplicate group contains no
% finite values.

    values = values(isfinite(values));

    if isempty(values)
        value = NaN;
    else
        value = mean(values);
    end
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
% Sample Bz on the requested plane using the appropriate interpolation mode.

    switch string(dataset.mode)

        case "rectilinear3d"
            F = griddedInterpolant( ...
                {dataset.x, dataset.y, dataset.z}, ...
                dataset.Bz, ...
                "linear", "none");

            planeBz = F(Xq, Yq, Zq);

        case "rectilinear2d"
            localCheckRequestedY(dataset.yPlane, Yq, dataset.fileName);

            Bxz = squeeze(dataset.Bz(:,1,:));

            F = griddedInterpolant( ...
                {dataset.x, dataset.z}, ...
                Bxz, ...
                "linear", "none");

            planeBz = F(Xq, Zq);

        case "rectilinear2d_ignore_nan"
            localCheckRequestedY(dataset.yPlane, Yq, dataset.fileName);

            F = scatteredInterpolant( ...
                dataset.sampleX, ...
                dataset.sampleZ, ...
                dataset.sampleBz, ...
                "linear", "none");

            planeBz = F(Xq, Zq);

        case "rectilinear3d_ignore_nan"
            F = scatteredInterpolant( ...
                dataset.sampleX, ...
                dataset.sampleY, ...
                dataset.sampleZ, ...
                dataset.sampleBz, ...
                "linear", "none");

            planeBz = F(Xq, Yq, Zq);

        case "scattered2d"
            localCheckRequestedY(dataset.yPlane, Yq, dataset.fileName);

            F = scatteredInterpolant( ...
                dataset.sampleX, ...
                dataset.sampleZ, ...
                dataset.sampleBz, ...
                "linear", "none");

            planeBz = F(Xq, Zq);

        case "scattered3d"
            F = scatteredInterpolant( ...
                dataset.sampleX, ...
                dataset.sampleY, ...
                dataset.sampleZ, ...
                dataset.sampleBz, ...
                "linear", "none");

            planeBz = F(Xq, Yq, Zq);

        otherwise
            error("Unknown dataset interpolation mode: %s", dataset.mode);
    end

    localWarnAboutNaNs(planeBz, dataset.fileName, "plane");
end

function lineBz = localSampleLineBz(dataset, xLine, yLine, zLine)
% Sample Bz along the centreline using the appropriate interpolation mode.

    switch string(dataset.mode)

        case "rectilinear3d"
            F = griddedInterpolant( ...
                {dataset.x, dataset.y, dataset.z}, ...
                dataset.Bz, ...
                "linear", "none");

            lineBz = F(xLine, yLine, zLine);

        case "rectilinear2d"
            localCheckRequestedY(dataset.yPlane, yLine, dataset.fileName);

            Bxz = squeeze(dataset.Bz(:,1,:));

            F = griddedInterpolant( ...
                {dataset.x, dataset.z}, ...
                Bxz, ...
                "linear", "none");

            lineBz = F(xLine, zLine);

        case "rectilinear2d_ignore_nan"
            localCheckRequestedY(dataset.yPlane, yLine, dataset.fileName);

            F = scatteredInterpolant( ...
                dataset.sampleX, ...
                dataset.sampleZ, ...
                dataset.sampleBz, ...
                "linear", "none");

            lineBz = F(xLine, zLine);

        case "rectilinear3d_ignore_nan"
            F = scatteredInterpolant( ...
                dataset.sampleX, ...
                dataset.sampleY, ...
                dataset.sampleZ, ...
                dataset.sampleBz, ...
                "linear", "none");

            lineBz = F(xLine, yLine, zLine);

        case "scattered2d"
            localCheckRequestedY(dataset.yPlane, yLine, dataset.fileName);

            F = scatteredInterpolant( ...
                dataset.sampleX, ...
                dataset.sampleZ, ...
                dataset.sampleBz, ...
                "linear", "none");

            lineBz = F(xLine, zLine);

        case "scattered3d"
            F = scatteredInterpolant( ...
                dataset.sampleX, ...
                dataset.sampleY, ...
                dataset.sampleZ, ...
                dataset.sampleBz, ...
                "linear", "none");

            lineBz = F(xLine, yLine, zLine);

        otherwise
            error("Unknown dataset interpolation mode: %s", dataset.mode);
    end

    localWarnAboutNaNs(lineBz, dataset.fileName, "line");
end

function localCheckRequestedY(yExport, yRequested, fileName)

    tolerance = 1e-9;

    if any(abs(yRequested(:) - yExport) > tolerance)
        error([ ...
            "Dataset '%s' contains only one y plane at y = %.9g m, " + ...
            "but the query requests y = %.9g m."], ...
            fileName, yExport, yRequested(1));
    end
end

function localWarnAboutNaNs(values, fileName, queryType)

    nNaN = nnz(~isfinite(values));

    if nNaN > 0
        warning([ ...
            "%d of %d sampled %s values are outside the interpolation " + ...
            "domain for '%s' and were returned as NaN."], ...
            nNaN, numel(values), queryType, fileName);
    end
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
