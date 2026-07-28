%% prepare_morgan_spatial_overview_Q_from_dataset.m
% Rebuild a minimal Q file containing the Morgan coil geometry required by
% the circular-versus-square spatial overview plot.
%
% Input:
%   Datasets/MorganSetup_FullBS.mat
%
% Output:
%   Q outputs/Q_Morgan_Spatial_Overview.mat
%
% No field sampling is required. The overview plot uses only dataset.geometry.

clear; close all; clc;
addpath(genpath("functs"));

%% ----------------------------- Paths ---------------------------------- %%
datasetFile = fullfile(pwd, "Datasets", "MorganSetup_FullBS.mat");
qOutDir = fullfile(pwd, "Q outputs");
qFile = fullfile(qOutDir, "Q_Morgan_Spatial_Overview.mat");

if ~isfile(datasetFile)
    altPath = "/mnt/data/MorganSetup_FullBS.mat";
    if isfile(altPath)
        datasetFile = altPath;
    else
        error("Could not find MorganSetup_FullBS.mat.");
    end
end

if ~exist(qOutDir, "dir")
    mkdir(qOutDir);
end

%% ---------------------------- Load data ------------------------------- %%
dataset = load_field_dataset(datasetFile);

if ~isfield(dataset, "geometry") || ~isfield(dataset.geometry, "coil")
    error("MorganSetup_FullBS.mat does not contain dataset.geometry.coil.");
end

coilArray = dataset.geometry.coil;
if ~iscell(coilArray)
    coilArray = num2cell(coilArray);
end

if numel(coilArray) < 2
    error("Expected at least two coils in dataset.geometry.coil.");
end

%% --------------------------- Minimal Q case --------------------------- %%
Q = cell(1, 1);

Q{1} = struct();
Q{1}.meta = struct();
Q{1}.meta.caseName = "Morgan spatial overview geometry";
Q{1}.meta.model = "matlab_full_biotsavart";
Q{1}.meta.source = string(dataset.source);
Q{1}.meta.datasetFile = string(datasetFile);
Q{1}.meta.queryFile = string(mfilename("fullpath"));
Q{1}.meta.createdOn = string(datetime("now", "Format", "yyyy-MM-dd HH:mm:ss"));

Q{1}.geometry = dataset.geometry;
Q{1}.queries = {};
Q{1}.results = {};

save(qFile, "Q", "-v7.3");

fprintf("Saved overview Q file to:\n  %s\n", qFile);
