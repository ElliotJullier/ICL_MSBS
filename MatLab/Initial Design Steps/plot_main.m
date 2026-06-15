close all;

addpath(genpath("functs"));

% ------------------------- Query output file to plot -------------------------
% query_main saves one variable named Q. Q is normally a cell array where
% each Q{k} is one case/model included in that query output file.
Q_file = "Q_Comparison_batch8_QueryBatch.mat";

% ------------------------- Load Q -------------------------
Q = load_Q_case(Q_file);

% ------------------------- Plot settings -------------------------
plotStyle.Q_file = Q_file;
plotStyle.showOrientationReadout = true;
% plotStyle.clim = [-0.5 0.5]*1e-3;

plot_field(Q, plotStyle);
