%% query_temp_line_dBz_dz_offsets.m
% Query vertical offset-line gradients dBz/dz for COMSOL cases only.
%
% Cases:
%   Q{1} : COMSOL circular, vertical lines at x = 0, y = r
%   Q{2} : COMSOL square x-z, vertical lines at x = 0, y = r
%   Q{3} : COMSOL square diagonal, vertical lines at x = r/sqrt(2), y = r/sqrt(2)
%
% Offsets:
%   r = [0, 5, 10, 25, 50, 75] mm
%
% Quantity:
%   dBz/dz only
%
% Output:
%   Q outputs/Q_Line_dBzDz_Offset_Comparisons.mat
%
% Notes:
%   - The diagonal square line is the central vertical line of the corrected
%     diagonal offset plane x + y = sqrt(2) r.
%   - GradientDirection is explicitly [0 0 1], so the query returns dBz/dz.
%   - No MATLAB circular / Full Biot-Savart case is included.

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

queryOutputFile = fullfile(qOutDir, "Q_Line_dBzDz_Offset_Comparisons2.mat");

%% ------------------------- Operating point ---------------------------- %%
% COMSOL precomputed fields are already total fields. This mode states that
% explicitly and avoids irrelevant current superposition.
opRequest = struct();
opRequest.mode = "precomputed";

%% ---------------------------- Line queries ---------------------------- %%
component = "z";                  % Bz component
gradientDirection = [0 0 1];       % d/dz only

offset_list_mm = [0, 5, 10, 25, 50, 75];
zLine_mm = [-120, 120];            % line extent in z [mm]
nLinePoints = 500;

z0_m = 1e-3 * zLine_mm(1);
z1_m = 1e-3 * zLine_mm(2);

q_circ_xz    = cell(1, numel(offset_list_mm));
q_square_xz  = cell(1, numel(offset_list_mm));
q_square_diag = cell(1, numel(offset_list_mm));

for i = 1:numel(offset_list_mm)

    r_mm = offset_list_mm(i);
    r_m  = 1e-3 * r_mm;

    %% Circular case: use x-z style offset line, x = 0, y = r
    start_circ = [0, r_m, z0_m];
    end_circ   = [0, r_m, z1_m];

    q_circ_xz{i} = create_line_gradient_query( ...
        start_circ, ...
        end_circ, ...
        component, ...
        "GradientDirection", gradientDirection, ...
        "NPoints", nLinePoints, ...
        "Group", [], ...
        "Overview", false, ...
        "Name", sprintf("dBz/dz on circular x-z offset line, y = %d mm", r_mm), ...
        "ShowCoils", false);

    %% Square x-z case: x = 0, y = r
    start_square_xz = [0, r_m, z0_m];
    end_square_xz   = [0, r_m, z1_m];

    q_square_xz{i} = create_line_gradient_query( ...
        start_square_xz, ...
        end_square_xz, ...
        component, ...
        "GradientDirection", gradientDirection, ...
        "NPoints", nLinePoints, ...
        "Group", [], ...
        "Overview", false, ...
        "Name", sprintf("dBz/dz on square x-z offset line, y = %d mm", r_mm), ...
        "ShowCoils", false);

    %% Square diagonal case: x + y = sqrt(2) r, central line u = 0
    % Corrected diagonal offset position:
    %   x = r/sqrt(2), y = r/sqrt(2)
    x_diag = r_m / sqrt(2);
    y_diag = r_m / sqrt(2);

    start_square_diag = [x_diag, y_diag, z0_m];
    end_square_diag   = [x_diag, y_diag, z1_m];

    q_square_diag{i} = create_line_gradient_query( ...
        start_square_diag, ...
        end_square_diag, ...
        component, ...
        "GradientDirection", gradientDirection, ...
        "NPoints", nLinePoints, ...
        "Group", [], ...
        "Overview", false, ...
        "Name", sprintf("dBz/dz on square diagonal offset line, r = %d mm", r_mm), ...
        "ShowCoils", false);
end

%% ------------------------- Case definitions --------------------------- %%
clear CaseDef

CaseDef(1).caseName     = "COMSOL circular dBz/dz, x-z offset lines";
CaseDef(1).model        = "comsol_precomputed";
CaseDef(1).datasetBase  = "Morgan_Circular_Export2";
CaseDef(1).datasetFile  = localResolveDatasetFile(datasetDir, CaseDef(1).datasetBase, ...
    [".mat", ".txt", ".csv", ".dat"]);
CaseDef(1).geometryFile = "";
CaseDef(1).queries      = q_circ_xz;

CaseDef(2).caseName     = "COMSOL square dBz/dz, x-z offset lines";
CaseDef(2).model        = "comsol_precomputed";
CaseDef(2).datasetBase  = "Morgan_Square_Export2";
CaseDef(2).datasetFile  = localResolveDatasetFile(datasetDir, CaseDef(2).datasetBase, ...
    [".mat", ".txt", ".csv", ".dat"]);
CaseDef(2).geometryFile = "";
CaseDef(2).queries      = q_square_xz;

CaseDef(3).caseName     = "COMSOL square dBz/dz, diagonal offset lines";
CaseDef(3).model        = "comsol_precomputed";
CaseDef(3).datasetBase  = "Morgan_Square_Export2";
CaseDef(3).datasetFile  = localResolveDatasetFile(datasetDir, CaseDef(3).datasetBase, ...
    [".mat", ".txt", ".csv", ".dat"]);
CaseDef(3).geometryFile = "";
CaseDef(3).queries      = q_square_diag;

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

fprintf("\nSaved line-gradient Q output to:\n  %s\n", queryOutputFile);

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
% Load a COMSOL precomputed dataset using the correct project loader.

    datasetFile = string(caseDef.datasetFile);
    model = lower(string(caseDef.model));

    [~, ~, ext] = fileparts(datasetFile);
    ext = lower(string(ext));

    switch model
        case "comsol_precomputed"
            if ext == ".mat"
                dataset = load_field_dataset(datasetFile);
            else
                dataset = load_comsol_precomputed_dataset(datasetFile);
            end

        otherwise
            error("Unsupported model for this temporary script: %s", model);
    end
end
