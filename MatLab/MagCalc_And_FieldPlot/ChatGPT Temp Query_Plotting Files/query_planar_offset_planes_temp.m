%% query_main.m
% Query centreline/off-axis planar field data for:
%   1) Morgan_Circular_Export    : COMSOL circular coil
%   2) Morgan_Square_Export      : COMSOL square coil
%   3) MorganSetup_FullBS.mat    : MATLAB circular coil, Full Biot-Savart
%
% Folder assumptions:
%   - input datasets are in:  Datasets/
%   - output Q file goes to:  Q outputs/
%
% Output:
%   Q outputs/Q_CentrelineOffAxis_Planes_Bz.mat
%
% Notes:
%   - This script samples full planes. Any half-plane cropping is a plotting
%     decision and is not applied here.
%   - Plane resolution is one scalar used for all planes.
%   - Query component must be "z", not "Bz". The result dataName becomes "Bz".

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

queryOutputFile = fullfile(qOutDir, "Q_CentrelineOffAxis_Planes_dBz_dz2.mat");

%% ------------------------- Operating point ---------------------------- %%
% This current ordering matches your previous default Case 2 / Full
% Biot-Savart output.
%
% For COMSOL precomputed datasets these currents are ignored because the
% COMSOL field is already the total field. For MATLAB Full Biot-Savart they
% are used to superpose the per-coil field sets.
opRequest = struct();
opRequest.mode = "fixed";
opRequest.currents = [2.57, -2.76];

%% ---------------------------- Queries --------------------------------- %%
planeRes = 240;     % scalar: same resolution for every custom plane
component = "z";    % use "z", not "Bz"

offset_list_mm = [0, 5, 10, 25, 50, 75];

q_xz   = {};
q_diag = {};

for i = 1:numel(offset_list_mm)

    r_mm = offset_list_mm(i);
    r_m  = 1e-3 * r_mm;

    %% x-z planes: y = r
    %
    % Plane normal is [0 1 0].
    % Therefore changing the y-coordinate shifts the plane.
    %
    % r = 0  -> y = 0
    % r = 25 -> y = 25 mm
    q_xz{1, i} = create_custom_plane_gradient_query( ...
        [0 r_m 0], ...          % point on plane [m]
        [0 1 0], ... % normal to y = const
        component, ...
        [0 0 1], ...
        "Resolution", planeRes, ...
        "Group", "Bz_xz_parallel_planes", ...
        "Overview", false, ...
        "Name", sprintf("Bz on x-z plane, y = %d mm", r_mm), ...
        "ShowCoils", false);

    %% diagonal-z planes: x = -y + offset
    %
    % Base diagonal plane:
    %   x + y = 0
    %
    % Normal:
    %   n = [1 1 0]
    %
    % To create a parallel plane at perpendicular/radial offset r from the
    % origin, use point:
    %   p = [-r/sqrt(2), +r/sqrt(2), 0]
    %
    % This keeps the plane parallel to x = -y and moves it onto the same
    % side as your diagonal offset lines.
    x0_m = r_m / sqrt(2);
    y0_m = r_m / sqrt(2);

    q_diag{1, i} = create_custom_plane_gradient_query( ...
        [x0_m y0_m 0], ...      % point on shifted diagonal plane [m]
        [1 1 0], ...            % normal to x + y = const
        component, ...
        [0 0 1], ...
        "Resolution", planeRes, ...
        "Group", "Bz_diag_parallel_planes", ...
        "Overview", false, ...
        "Name", sprintf("Bz on diagonal-z plane, r = %d mm", r_mm), ...
        "ShowCoils", false);
end

% Flat cell array of query structs.
planeQueries = [q_xz, q_diag];

%% ------------------------- Case definitions --------------------------- %%
clear CaseDef

CaseDef(1).caseName     = "COMSOL circular coil";
CaseDef(1).model        = "comsol_precomputed";
CaseDef(1).datasetBase  = "Morgan_Circular_Export2";
CaseDef(1).datasetFile  = localResolveDatasetFile(datasetDir, CaseDef(1).datasetBase, ...
    [".mat", ".txt", ".csv", ".dat"]);
CaseDef(1).geometryFile = "";
CaseDef(1).queries      = planeQueries;

CaseDef(2).caseName     = "COMSOL square coil";
CaseDef(2).model        = "comsol_precomputed";
CaseDef(2).datasetBase  = "Morgan_Square_Export2";
CaseDef(2).datasetFile  = localResolveDatasetFile(datasetDir, CaseDef(2).datasetBase, ...
    [".mat", ".txt", ".csv", ".dat"]);
CaseDef(2).geometryFile = "";
CaseDef(2).queries      = planeQueries;

CaseDef(3).caseName     = "MATLAB circular coil, Full Biot-Savart";
CaseDef(3).model        = "matlab_full_biotsavart";
CaseDef(3).datasetBase  = "MorganSetup_FullBS";
CaseDef(3).datasetFile  = localResolveDatasetFile(datasetDir, CaseDef(3).datasetBase, ...
    [".mat"]);
CaseDef(3).geometryFile = "";
CaseDef(3).queries      = planeQueries;

%% ---------------------------- Run queries ----------------------------- %%
Q = cell(1, numel(CaseDef));

for kCase = 1:numel(CaseDef)

    caseDef = CaseDef(kCase);
    model = lower(string(caseDef.model));

    fprintf("Running case %d/%d: %s\n", ...
        kCase, numel(CaseDef), string(caseDef.caseName));

    dataset = localLoadDatasetForCase(caseDef);

    if isfield(caseDef, "geometryFile") && strlength(string(caseDef.geometryFile)) > 0
        dataset = attach_geometry_file_to_dataset(dataset, caseDef.geometryFile);
    end

    op = validate_and_solve_operating_point(dataset, opRequest, model);

    [results, queries] = run_field_queries(dataset, op, caseDef.queries, model);

    Q{kCase} = pack_query_case(dataset, op, queries, results, caseDef, mfilename("fullpath"));
end

save(queryOutputFile, "Q", "-v7.3");

fprintf("\nSaved Q output to:\n  %s\n", queryOutputFile);

%% =========================== Local functions ========================== %%
function datasetFile = localResolveDatasetFile(datasetDir, baseName, extensions)
% Resolve a dataset from a base filename and a list of possible extensions.

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
% Load a dataset using the correct project loader.

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
