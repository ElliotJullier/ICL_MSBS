%% query_main_morgan_centreline_methods.m
% One-off query script for a centreline Bz method comparison.
%
% Cases included:
%   1) MATLAB circular (full Biot-Savart)
%   2) COMSOL circular
%   3) COMSOL square
%   4) Simple Biot-Savart
%   5) Analytical data
%
% Output:
%   Q outputs/Q_Morgan_Centreline_Methods.mat

clear; close all; clc;
addpath(genpath("functs"));

%% ----------------------------- Paths ---------------------------------- %%
datasetDir = fullfile(pwd, "Datasets");
qOutDir    = fullfile(pwd, "Q outputs");

if ~exist(datasetDir, "dir")
    error('Could not find the input folder: "%s"', datasetDir);
end
if ~exist(qOutDir, "dir")
    mkdir(qOutDir);
end

queryOutputFile = fullfile(qOutDir, "Q_Morgan_Centreline_Methods.mat");

%% ------------------------- Shared query ------------------------------- %%
zStart_m = -120e-3;
zEnd_m   =  120e-3;
nPoints  = 300;

centrelineQuery = create_line_field_query( ...
    [0 0 zStart_m], [0 0 zEnd_m], "z", ...
    "NPoints", nPoints, ...
    "Group", 1, ...
    "Overview", false, ...
    "ShowCoils", false, ...
    "Name", "Centreline Bz");

%% ------------------------- Case definitions --------------------------- %%
caseDefs = struct([]);

% 1) MATLAB circular (full Biot-Savart)
caseDefs(1).caseName = "MATLAB Circular";
caseDefs(1).model = "matlab_full_biotsavart";
caseDefs(1).datasetBase = "MorganSetup_FullBS";
caseDefs(1).datasetFile = localResolveDatasetFile(datasetDir, caseDefs(1).datasetBase, [".mat"]);
caseDefs(1).queries = {centrelineQuery};
caseDefs(1).opRequest.mode = "fixed";
% Keep the same current convention used in the previous Morgan comparison script.
caseDefs(1).opRequest.currents = [2.57, -2.76];

% 2) COMSOL circular
caseDefs(2).caseName = "COMSOL Circular";
caseDefs(2).model = "comsol_precomputed";
caseDefs(2).datasetBase = "Morgan_Circular_Export2";
caseDefs(2).datasetFile = localResolveDatasetFile(datasetDir, caseDefs(2).datasetBase, [".mat", ".txt", ".csv", ".dat"]);
caseDefs(2).queries = {centrelineQuery};
caseDefs(2).opRequest.mode = "precomputed";

% 3) COMSOL square
caseDefs(3).caseName = "COMSOL Square";
caseDefs(3).model = "comsol_precomputed";
caseDefs(3).datasetBase = "Morgan_Square_Export2";
caseDefs(3).datasetFile = localResolveDatasetFile(datasetDir, caseDefs(3).datasetBase, [".mat", ".txt", ".csv", ".dat"]);
caseDefs(3).queries = {centrelineQuery};
caseDefs(3).opRequest.mode = "precomputed";

% 4) Simple Biot-Savart
caseDefs(4).caseName = "Simple Biot-Savart";
caseDefs(4).model = "simple_biotsavart";
caseDefs(4).datasetBase = "Morgan_SimpleBS_2";
caseDefs(4).datasetFile = localResolveDatasetFile(datasetDir, caseDefs(4).datasetBase, [".mat"]);
caseDefs(4).queries = {centrelineQuery};
caseDefs(4).opRequest.mode = "fixed";
caseDefs(4).opRequest.currents = [2.57, -2.76];

% 5) Analytical line data (packed after the ordinary queried cases)
includeAnalyticalLine = true;
analyticalLineFile = localResolveDatasetFile(datasetDir, "Morgan_Bz_analytical_2", [".mat"]);
analyticalCaseName = "Analytical";
analyticalQueryName = "Analytical centreline Bz";
analyticalLineGroup = 1;

%% ---------------------------- Load and query ------------------------- %%
Q = cell(1, numel(caseDefs));

for c = 1:numel(caseDefs)
    model = lower(string(caseDefs(c).model));

    switch model
        case "matlab_full_biotsavart"
            dataset = load_field_dataset(caseDefs(c).datasetFile);
        case "simple_biotsavart"
            dataset = load_field_dataset(caseDefs(c).datasetFile);
        case "comsol_precomputed"
            [~, ~, ext] = fileparts(caseDefs(c).datasetFile);
            if strcmpi(ext, '.mat')
                dataset = load_field_dataset(caseDefs(c).datasetFile);
            else
                dataset = load_comsol_precomputed_dataset(caseDefs(c).datasetFile);
            end
        otherwise
            error("Unsupported model: %s", model);
    end

    op = validate_and_solve_operating_point(dataset, caseDefs(c).opRequest, model);
    [results, queriesUsed] = run_field_queries(dataset, op, caseDefs(c).queries, model);
    Q{c} = pack_query_case(dataset, op, queriesUsed, results, caseDefs(c), mfilename("fullpath"));
end

if includeAnalyticalLine
    Q{end+1} = create_analytical_Bz_line_Qcase( ...
        analyticalLineFile, analyticalLineGroup, analyticalCaseName, analyticalQueryName);
end

save(queryOutputFile, "Q", "-v7.3");
fprintf("Saved query output to:\n  %s\n", queryOutputFile);

%% --------------------------- Local functions ------------------------- %%
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

function Qcase = create_analytical_Bz_line_Qcase(dataFile, groupNumber, caseName, queryName)
% Pack analytical/reference Bz line data into the same basic Q structure.
%
% Required variables in the input MAT file:
%   z_mm : centreline coordinate in mm
%   Bz_G : Bz in Gauss

raw = load(dataFile);

if ~isfield(raw, "z_mm") || ~isfield(raw, "Bz_G")
    error("Analytical line file '%s' must contain variables z_mm and Bz_G.", string(dataFile));
end

z_mm = raw.z_mm(:);
Bz_G = raw.Bz_G(:);

if numel(z_mm) ~= numel(Bz_G)
    error("Analytical line data must have the same number of z_mm and Bz_G entries.");
end
if any(~isfinite(z_mm)) || any(~isfinite(Bz_G))
    error("Analytical line data contains NaN or Inf values.");
end

[z_mm, sortIdx] = sort(z_mm);
Bz_G = Bz_G(sortIdx);

z_m  = z_mm * 1e-3;
Bz_T = Bz_G * 1e-4;
s_m  = z_m - z_m(1);

q = struct();
q.type = "line";
q.quantity = "field";
q.component = "z";
q.start = [0 0 z_m(1)];
q.end   = [0 0 z_m(end)];
q.nPoints = numel(z_m);
q.name = string(queryName);
q.plot = struct("group", groupNumber, "inOverview", false, "showCoils", false);

result = struct();
result.queryIndex = 1;
result.X = zeros(size(z_m));
result.Y = zeros(size(z_m));
result.Z = z_m;      % preserve the physical z coordinate for plotting
result.s = s_m;
result.data = Bz_T;
result.inside = true(size(Bz_T));
result.dataName = "Bz";
result.plot = q.plot;

Qcase = struct();
Qcase.meta = struct();
Qcase.meta.caseName = string(caseName);
Qcase.meta.model = "analytical_line";
Qcase.meta.source = "external_analytical_line";
Qcase.meta.datasetFile = string(dataFile);
Qcase.meta.geometryFile = "";
Qcase.meta.queryFile = string(mfilename("fullpath"));
Qcase.meta.createdOn = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));

Qcase.geometry = struct("coil", struct([]), "coilSpec", struct(), "windTunnel", []);
Qcase.current = struct("values", [], "mode", "external", "rowsToControl", [], "residualNorm", []);
Qcase.magnet = [];
Qcase.target = [];
Qcase.queries = {q};
Qcase.results = {result};
end
