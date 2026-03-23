close all;

addpath("functs");
addpath("functs/plot");

% ------------------------- Which queried cases to plot -------------------------
Q_sources = { ...
    "Q_case1_BiotSavartFull.mat", ...
    % "Q_case1_BiotSavartSimple.mat" ...
    % "Q_run12.mat", ...
    % "Q_run13.mat" ...
    % "Q_comsol_case1.mat"
};

% ------------------------- Load Qs from workspace or .mat files -------------------------
Q_list = cell(size(Q_sources));
for k = 1:numel(Q_sources)
    Q_list{k} = load_Q_case(Q_sources{k});
end

% ------------------------- Plot settings -------------------------
% plotStyle.clim = [-0.5 0.5]*10^-3;
plotStyle.showCoils = true;
plotStyle.showOrientationReadout = true;

plot_field(Q_list, plotStyle);
