%% query_temp_difference_comparisons.m
% Build a comparison-oriented Q output for planar Bz offset studies.
%
% Input datasets (same as before):
%   1) Morgan_Circular_Export    : COMSOL circular coil
%   2) Morgan_Square_Export      : COMSOL square coil
%   3) MorganSetup_FullBS.mat    : MATLAB circular coil, Full Biot-Savart
%
% Output ordering:
%   Q{1} : COMSOL circular (base case, x-z offset planes)
%   Q{2} : COMSOL circular minus MATLAB circular (synthetic difference, x-z)
%   Q{3} : COMSOL circular minus COMSOL square (synthetic difference, x-z)
%   Q{4} : COMSOL square (base case, x-z offset planes)
%   Q{5} : COMSOL square x-z minus COMSOL square diagonal
%
% Notes:
%   - The first two differences are created as synthetic datasets using the
%     project helper create_synthetic_difference_dataset(...).
%   - The square x-z minus square diagonal comparison is created after
%     querying, because it compares two different plane families rather than
%     two volumetric datasets.
%   - A different Q filename is used so this does not overwrite the earlier
%     planar-view output.

clear; close all;

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

queryOutputFile = fullfile(qOutDir, "Q_Planar_Bz_Offset_Comparisons2.mat");

%% ------------------------- Operating point ---------------------------- %%
opRequest = struct();
opRequest.mode = "fixed";
opRequest.currents = [2.57, -2.76];

opRequestPrecomputed = struct();
opRequestPrecomputed.mode = "precomputed";

%% ---------------------------- Queries --------------------------------- %%
planeRes = 240;
component = "z";

offset_list_mm = [0, 5, 10, 25, 50, 75];

q_xz   = {};
q_diag = {};

for i = 1:numel(offset_list_mm)

    r_mm = offset_list_mm(i);
    r_m  = 1e-3 * r_mm;

    % x-z planes: y = r
    q_xz{1, i} = create_custom_plane_field_query( ...
        [0 r_m 0], ...
        [0 1 0], ...
        component, ...
        "Resolution", planeRes, ...
        "Group", "Bz_xz_parallel_planes", ...
        "Overview", false, ...
        "Name", sprintf("Bz on x-z plane, y = %d mm", r_mm), ...
        "ShowCoils", false);

    % diagonal-z planes: x + y = sqrt(2) r
    x0_m =  r_m / sqrt(2);
    y0_m =  r_m / sqrt(2);

    q_diag{1, i} = create_custom_plane_field_query( ...
        [x0_m y0_m 0], ...
        [1 1 0], ...
        component, ...
        "Resolution", planeRes, ...
        "Group", "Bz_diag_parallel_planes", ...
        "Overview", false, ...
        "Name", sprintf("Bz on diagonal-z plane, perpendicular offset = %d mm", r_mm), ...
        "ShowCoils", false);
end

%% ------------------------- Physical case definitions ------------------ %%
circDef = struct();
circDef.caseName     = "COMSOL circular coil";
circDef.model        = "comsol_precomputed";
circDef.datasetBase  = "Morgan_Circular_Export2";
circDef.datasetFile  = localResolveDatasetFile(datasetDir, circDef.datasetBase, ...
    [".mat", ".txt", ".csv", ".dat"]);
circDef.geometryFile = "";

squareDef = struct();
squareDef.caseName     = "COMSOL square coil";
squareDef.model        = "comsol_precomputed";
squareDef.datasetBase  = "Morgan_Square_Export2";
squareDef.datasetFile  = localResolveDatasetFile(datasetDir, squareDef.datasetBase, ...
    [".mat", ".txt", ".csv", ".dat"]);
squareDef.geometryFile = "";

matCircDef = struct();
matCircDef.caseName     = "MATLAB circular coil, Full Biot-Savart";
matCircDef.model        = "matlab_full_biotsavart";
matCircDef.datasetBase  = "MorganSetup_FullBS";
matCircDef.datasetFile  = localResolveDatasetFile(datasetDir, matCircDef.datasetBase, ...
    [".mat"]);
matCircDef.geometryFile = "";

%% ---------------------------- Load datasets --------------------------- %%
circDataset    = localLoadDatasetForCase(circDef);
squareDataset  = localLoadDatasetForCase(squareDef);
matCircDataset = localLoadDatasetForCase(matCircDef);

circOp    = validate_and_solve_operating_point(circDataset,    opRequest, circDef.model);
squareOp  = validate_and_solve_operating_point(squareDataset,  opRequest, squareDef.model);
matCircOp = validate_and_solve_operating_point(matCircDataset, opRequest, matCircDef.model);

%% ---------------------------- Base query cases ------------------------ %%
Qcirc = localRunPreparedDatasetQueries( ...
    circDataset, circOp, q_xz, ...
    "COMSOL circular", "comsol_precomputed", circDef.datasetFile, mfilename("fullpath"));

QsquareXZ = localRunPreparedDatasetQueries( ...
    squareDataset, squareOp, q_xz, ...
    "COMSOL square xz", "comsol_precomputed", squareDef.datasetFile, mfilename("fullpath"));

QsquareDiag = localRunPreparedDatasetQueries( ...
    squareDataset, squareOp, q_diag, ...
    "COMSOL square diag", "comsol_precomputed", squareDef.datasetFile, mfilename("fullpath"));

%% ------------------------- Synthetic dataset queries ------------------ %%
[diffCircMinusMatDataset, ~] = create_synthetic_difference_dataset( ...
    circDataset, circOp, matCircDataset, matCircOp, ...
    "CaseNameA", circDef.caseName, ...
    "CaseNameB", matCircDef.caseName, ...
    "DatasetFileA", circDef.datasetFile, ...
    "DatasetFileB", matCircDef.datasetFile, ...
    "Verbose", true);

QcircMinusMat = localRunPreparedDatasetQueries( ...
    diffCircMinusMatDataset, ...
    validate_and_solve_operating_point(diffCircMinusMatDataset, opRequestPrecomputed, "synthetic_difference"), ...
    q_xz, ...
    "COMSOL circular minus MATLAB circular", "synthetic_difference", ...
    "synthetic_difference", mfilename("fullpath"));

[diffCircMinusSquareDataset, ~] = create_synthetic_difference_dataset( ...
    circDataset, circOp, squareDataset, squareOp, ...
    "CaseNameA", circDef.caseName, ...
    "CaseNameB", squareDef.caseName, ...
    "DatasetFileA", circDef.datasetFile, ...
    "DatasetFileB", squareDef.datasetFile, ...
    "Verbose", true);

QcircMinusSquare = localRunPreparedDatasetQueries( ...
    diffCircMinusSquareDataset, ...
    validate_and_solve_operating_point(diffCircMinusSquareDataset, opRequestPrecomputed, "synthetic_difference"), ...
    q_xz, ...
    "COMSOL circular minus COMSOL square xz", "synthetic_difference", ...
    "synthetic_difference", mfilename("fullpath"));

%% ------------------- Square x-z minus square diagonal ----------------- %%
QsquareXZMinusDiag = localMakeSquareDirectionDifferenceCase( ...
    QsquareXZ, QsquareDiag, ...
    "COMSOL square xz minus COMSOL square diag", ...
    mfilename("fullpath"));

%% ------------------------------ Final Q ------------------------------- %%
Q = { ...
    Qcirc, ...
    QcircMinusMat, ...
    QcircMinusSquare, ...
    QsquareXZ, ...
    QsquareXZMinusDiag};

save(queryOutputFile, "Q", "-v7.3");

fprintf("\nSaved comparison Q output to:\n  %s\n", queryOutputFile);

%% =========================== Local functions ========================== %%
function Qcase = localRunPreparedDatasetQueries(dataset, op, queries, caseName, model, datasetFile, queryFile)

    caseDef = struct();
    caseDef.caseName = string(caseName);
    caseDef.model = string(model);
    caseDef.datasetFile = string(datasetFile);
    caseDef.geometryFile = "";
    caseDef.queries = queries;

    [results, queriesOut] = run_field_queries(dataset, op, queries, model);

    Qcase = pack_query_case(dataset, op, queriesOut, results, caseDef, queryFile);
end

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

function dataset = localLoadDatasetForCase(caseDef)

    datasetFile = string(caseDef.datasetFile);
    model = lower(string(caseDef.model));

    [~, ~, ext] = fileparts(datasetFile);
    ext = lower(string(ext));

    switch model
        case "matlab_full_biotsavart"
            dataset = load_field_dataset(datasetFile);

        case "comsol_precomputed"
            if ext == ".mat"
                dataset = load_field_dataset(datasetFile);
            else
                dataset = load_comsol_precomputed_dataset(datasetFile);
            end

        otherwise
            error("Unsupported model: %s", model);
    end
end

function Qdiff = localMakeSquareDirectionDifferenceCase(Qxz, Qdiag, caseName, queryFile)
% Build a comparison Q case from square x-z query results minus square
% diagonal query results.
%
% The result is stored on the x-z local coordinate grid, so it can be
% plotted like an x-z map later. The diagonal result is interpolated onto
% the x-z local coordinate grid before subtraction.

    Qdiff = Qxz;

    Qdiff.meta.caseName = string(caseName);
    Qdiff.meta.model = "synthetic_difference";
    Qdiff.meta.source = "synthetic_difference";
    Qdiff.meta.datasetFile = "synthetic_difference";
    Qdiff.meta.queryFile = string(queryFile);
    Qdiff.meta.createdOn = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));

    Qdiff.synthetic = struct();
    Qdiff.synthetic.type = "difference";
    Qdiff.synthetic.operation = "square_xz_minus_square_diag";
    Qdiff.synthetic.caseNameA = string(Qxz.meta.caseName);
    Qdiff.synthetic.caseNameB = string(Qdiag.meta.caseName);
    Qdiff.synthetic.datasetFileA = string(Qxz.meta.datasetFile);
    Qdiff.synthetic.datasetFileB = string(Qdiag.meta.datasetFile);

    if ~iscell(Qdiff.results)
        Qdiff.results = num2cell(Qdiff.results);
    end
    if ~iscell(Qxz.results)
        Qxz.results = num2cell(Qxz.results);
    end
    if ~iscell(Qdiag.results)
        Qdiag.results = num2cell(Qdiag.results);
    end

    nResults = numel(Qxz.results);
    if numel(Qdiag.results) ~= nResults
        error("Qxz and Qdiag must contain the same number of queried offsets.");
    end

    for k = 1:nResults
        rA = Qxz.results{k};
        rB = Qdiag.results{k};

        % Query target grid taken directly from the x-z case.
        XA = double(rA.X);
        ZA = double(rA.Z);
        VA = double(rA.data);

        % Prepare diagonal local coordinate u = (y-x)/sqrt(2) with
        % increasing interpolation axes and data flipped consistently.
        [uB, zB, VB] = localPreparePlaneDataForInterp((rB.Y - rB.X) / sqrt(2), rB.Z, rB.data);

        % Interpolate diagonal data onto the x-z local coordinate grid.
        VB_on_A = interp2(uB, zB, VB, XA, ZA, "linear", NaN);

        rOut = rA;
        rOut.data = VA - VB_on_A;

        % Keep x-z coordinates for later plotting.
        % rOut.X, rOut.Y, rOut.Z already come from rA.

        Qdiff.results{k} = rOut;
    end
end

function [xAxis, zAxis, Vout] = localPreparePlaneDataForInterp(Xgrid, Zgrid, V)
% Convert a masked 2D plane result into finite, ascending axes for interp2.
%
% The query sampler sets X/Z/data to NaN outside the dataset domain. Therefore
% the first row/column may not contain valid coordinates. This function
% reconstructs the axes using finite values across the full grid, then trims
% fully invalid rows/columns.

    Xgrid = double(Xgrid);
    Zgrid = double(Zgrid);
    Vout  = double(V);

    % Estimate coordinate axes while ignoring masked NaNs.
    xAxis = median(Xgrid, 1, "omitnan");   % one value per column
    zAxis = median(Zgrid, 2, "omitnan");   % one value per row

    xAxis = xAxis(:).';
    zAxis = zAxis(:);

    % Keep only rows/columns with finite coordinate values.
    keepX = isfinite(xAxis);
    keepZ = isfinite(zAxis);

    if nnz(keepX) < 2 || nnz(keepZ) < 2
        error("Not enough finite coordinate points remain for interpolation.");
    end

    xAxis = xAxis(keepX);
    zAxis = zAxis(keepZ);
    Vout  = Vout(keepZ, keepX);

    % Remove duplicate axis values if they occur due to numerical masking.
    [xAxis, ix] = unique(xAxis, "stable");
    [zAxis, iz] = unique(zAxis, "stable");
    Vout = Vout(iz, ix);

    if numel(xAxis) < 2 || numel(zAxis) < 2
        error("Interpolation axes have fewer than two unique finite points.");
    end

    % Ensure ascending axes for interp2.
    if any(diff(xAxis) < 0)
        xAxis = fliplr(xAxis);
        Vout = fliplr(Vout);
    end

    if any(diff(zAxis) < 0)
        zAxis = flipud(zAxis);
        Vout = flipud(Vout);
    end

    % Final validation before interp2.
    if any(~isfinite(xAxis)) || any(~isfinite(zAxis))
        error("Interpolation axes still contain non-finite values.");
    end

    if any(diff(xAxis) <= 0)
        error("Horizontal interpolation axis is not strictly increasing.");
    end

    if any(diff(zAxis) <= 0)
        error("Vertical interpolation axis is not strictly increasing.");
    end
end