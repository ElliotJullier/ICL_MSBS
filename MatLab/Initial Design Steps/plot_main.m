% Get all workspace variables
vars = who;

% Keep variables that start with "Q_"
keep = vars(startsWith(vars, "Q_"));

% Clear everything except those
clearvars('-except', keep{:});
close all;

addpath("functs");
addpath("functs/plot");

% ------------------------- Which queried cases to plot -------------------------
Q_names = { ...
    "Q_3" % Must be a string containing the name of the variable
    % "Q_run12", ...
    % "Q_run13" ...
    % "Q_comsol_case1"
};

% ------------------------- Load Qs from workspace or .mat files -------------------------
Q_list = cell(size(Q_names));

for k = 1:numel(Q_names)
    qname = Q_names{k};

    % 1) Check workspace
    if evalin('base', "exist('" + qname + "','var')")
        Q_list{k} = evalin('base', qname);
        continue
    end

    % 2) Check current folder for matching .mat
    matfile_name = qname + ".mat";
    if exist(matfile_name, 'file')
        S = load(matfile_name);

        if isfield(S, qname)
            Q_list{k} = S.(qname);
        elseif isfield(S, 'Q')
            % fallback if saved as generic Q
            Q_list{k} = S.Q;
        else
            error("File " + matfile_name + " does not contain variable '" + qname + "' or 'Q'.");
        end
        continue
    end

    error("Could not find " + qname + " in workspace or current folder.");
end

% ------------------------- Plot settings -------------------------
% plotStyle.clim = [-0.5 0.5]*10^-3;
plotStyle.showCoils = true;
plotStyle.showOrientationReadout = true;

% Optional display names for legend/titles
plotStyle.caseNames = Q_names;

plotMode = "subplots";   % "single_axes", "subplots", "separate_figures"

plot_field(Q_list, plotMode, plotStyle);