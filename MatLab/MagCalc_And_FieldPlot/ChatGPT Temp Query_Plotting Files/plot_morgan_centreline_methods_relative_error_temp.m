%% plot_morgan_centreline_methods_relative_error_temp.m
% Temporary plotter for centreline Bz relative error against COMSOL square.
%
% Uses the existing Q output from:
%   query_main_morgan_centreline_methods_v2.m
%
% Expected Q ordering:
%   Q{1} : MATLAB Circular
%   Q{2} : COMSOL Circular
%   Q{3} : COMSOL Square          <-- base case
%   Q{4} : Simple Biot-Savart
%   Q{5} : Analytical
%
% Relative error definition:
%   epsilon = (case - COMSOL square) / COMSOL square
%
% Near-zero denominator handling:
%   Since Bz crosses or approaches zero near the centreline origin, relative
%   error is not meaningful where |Bz_base| is very small. Those points are
%   masked to NaN before plotting.
%
% Output:
%   COMSOL/Graphs/Morgan Setup/Offset_Comp2/Centreline_Methods_Relative_Error.svg

clear; close all; clc;
addpath(genpath("functs"));

%% ---------------------------- User settings --------------------------- %%
qFile = fullfile(pwd, "Q outputs", "Q_Morgan_Centreline_Methods.mat");
if ~isfile(qFile)
    qFile = "/mnt/data/Q_Morgan_Centreline_Methods.mat";
end

saveFigure = true;
exportDir = msbs_graphs_dir("Morgan Setup", "Offset_Comp2");
exportName = "Centreline_Methods_Relative_Error.svg";

baseCaseIndex = 3;     % COMSOL square

% Denominator mask:
% points where |Bz_base| < baseFloorFraction*max(abs(Bz_base)) are masked.
baseFloorFraction = 1e-3;

% Axis-limit options for relative error.
%   "globalMax"   : symmetric limits from global abs max
%   "percentile"  : symmetric limits from percentile(abs(relative error))
%   "manual"      : use manualYLims
axisLimitMode = "percentile";
percentileVal = 99.0;
manualYLims = [-1, 1];       % dimensionless
yPaddingFactor = 1.05;

% Coil axial marker geometry [mm], matching the recent line-plot style.
zCoilCentres_mm = [-90, 90];
coilHeight_mm = 60;

% Line colours and styles.
% Kept consistent with Centreline_Methods.
styleDefs = struct([]);
styleDefs(1).caseName = "MATLAB Circular";
styleDefs(1).displayName = "MATLAB circular";
styleDefs(1).color = [0.36, 0.52, 0.34];      % darker sage green
styleDefs(1).lineStyle = "--";
styleDefs(1).lineWidth = 1.8;

styleDefs(2).caseName = "COMSOL Circular";
styleDefs(2).displayName = "COMSOL circular";
styleDefs(2).color = [0.36, 0.52, 0.34];      % same green, solid = COMSOL
styleDefs(2).lineStyle = "-";
styleDefs(2).lineWidth = 1.8;

styleDefs(3).caseName = "COMSOL Square";
styleDefs(3).displayName = "COMSOL square (base)";
styleDefs(3).color = [0.23, 0.40, 0.67];      % project medium-dark blue
styleDefs(3).lineStyle = "-";
styleDefs(3).lineWidth = 1.8;

styleDefs(4).caseName = "Simple Biot-Savart";
styleDefs(4).displayName = "Simple BS";
styleDefs(4).color = [0.86, 0.55, 0.14];      % muted orange
styleDefs(4).lineStyle = "--";
styleDefs(4).lineWidth = 1.8;

styleDefs(5).caseName = "Analytical";
styleDefs(5).displayName = "Analytical";
styleDefs(5).color = [0.55, 0.35, 0.64];      % muted purple
styleDefs(5).lineStyle = "-.";
styleDefs(5).lineWidth = 1.8;

%% ------------------------------ Load Q ------------------------------- %%
if ~isfile(qFile)
    error("Could not find Q file: %s", qFile);
end

S = load(qFile, "Q");
Q = S.Q;
if ~iscell(Q)
    Q = {Q};
end

nCases = min(numel(Q), numel(styleDefs));

if baseCaseIndex > nCases
    error("baseCaseIndex=%d exceeds number of available cases (%d).", ...
        baseCaseIndex, nCases);
end

series = repmat(struct("z_mm", [], "Bz_T", [], "displayName", "", "style", struct()), 1, nCases);

for iCase = 1:nCases
    results = Q{iCase}.results;
    if ~iscell(results)
        results = num2cell(results);
    end
    if isempty(results)
        error("Q{%d} contains no results.", iCase);
    end

    r = results{1};

    z_mm = 1e3 * double(r.Z(:));
    Bz_T = double(r.data(:));

    [z_mm, sortIdx] = sort(z_mm);
    Bz_T = Bz_T(sortIdx);

    finiteMask = isfinite(z_mm) & isfinite(Bz_T);
    z_mm = z_mm(finiteMask);
    Bz_T = Bz_T(finiteMask);

    % Remove duplicate z positions if present.
    [z_mm, uniqueIdx] = unique(z_mm, "stable");
    Bz_T = Bz_T(uniqueIdx);

    series(iCase).z_mm = z_mm;
    series(iCase).Bz_T = Bz_T;
    series(iCase).displayName = styleDefs(iCase).displayName;
    series(iCase).style = styleDefs(iCase);
end

%% ----------------------- Build relative errors ------------------------ %%
zBase_mm = series(baseCaseIndex).z_mm;
Bbase_T  = series(baseCaseIndex).Bz_T;

baseAbsMax = max(abs(Bbase_T));
baseFloor = baseFloorFraction * baseAbsMax;
validBase = isfinite(Bbase_T) & abs(Bbase_T) >= baseFloor;

relSeries = series;
allErr = [];

for iCase = 1:nCases

    if iCase == baseCaseIndex
        BcaseOnBase = Bbase_T;
    else
        BcaseOnBase = interp1( ...
            series(iCase).z_mm, series(iCase).Bz_T, ...
            zBase_mm, "linear", NaN);
    end

    relErr = NaN(size(Bbase_T));
    valid = validBase & isfinite(BcaseOnBase);

    relErr(valid) = (BcaseOnBase(valid) - Bbase_T(valid)) ./ Bbase_T(valid);

    relSeries(iCase).z_mm = zBase_mm;
    relSeries(iCase).Bz_T = relErr;   % stored in Bz_T field for reuse of plotting loop

    allErr = [allErr; relErr(isfinite(relErr))]; %#ok<AGROW>
end

if isempty(allErr)
    error("No finite relative-error values were produced. Check base denominator mask.");
end

xLims = [min(zBase_mm), max(zBase_mm)];

switch lower(string(axisLimitMode))
    case "globalmax"
        yMaxAbs = max(abs(allErr));
        yLims = 100*yPaddingFactor * [-yMaxAbs, yMaxAbs];

    case "percentile"
        yMaxAbs = prctile(abs(allErr), percentileVal);
        yLims = 100*yPaddingFactor * [-yMaxAbs, yMaxAbs];

    case "manual"
        yLims = manualYLims;

    otherwise
        error("Unknown axisLimitMode: %s", axisLimitMode);
end

if ~all(isfinite(yLims)) || diff(yLims) <= 0
    error("Invalid y-axis limits: [%g, %g]", yLims(1), yLims(2));
end

fprintf("Base case: %s\n", series(baseCaseIndex).displayName);
fprintf("Base denominator floor: %.4g T\n", baseFloor);
fprintf("Masked %d/%d base-grid points due to near-zero denominator.\n", ...
    nnz(~validBase), numel(validBase));
fprintf("Relative-error y limits: [%g, %g]\n", yLims(1), yLims(2));

%% ------------------------------- Plot -------------------------------- %%
if saveFigure && ~exist(exportDir, "dir")
    mkdir(exportDir);
end

fig = figure("Name", "Centreline Methods Relative Error", ...
    "NumberTitle", "off", ...
    "Color", "w", ...
    "Units", "pixels", ...
    "Position", [120, 120, 900, 650]);

ax = axes(fig);
hold(ax, "on");
box(ax, "on");
grid(ax, "on");
ax.GridAlpha = 0.16;
ax.MinorGridAlpha = 0.08;
ax.XMinorGrid = "on";
ax.YMinorGrid = "on";
ax.LineWidth = 1.0;
ax.FontSize = 11;
ax.TickLabelInterpreter = "latex";
ax.XAxis.Label.Interpreter = "latex";
ax.YAxis.Label.Interpreter = "latex";

localAddCoilAxialMarkers(ax, zCoilCentres_mm, coilHeight_mm, yLims);

% Zero-error reference.
line(ax, xLims, [0 0], ...
    "Color", [0.15, 0.15, 0.15], ...
    "LineStyle", ":", ...
    "LineWidth", 1.0, ...
    "HandleVisibility", "off");

for iCase = 1:nCases
    plot(ax, relSeries(iCase).z_mm, smoothdata(relSeries(iCase).Bz_T, "sgolay", 10)*100, ...
        "Color", relSeries(iCase).style.color, ...
        "LineStyle", relSeries(iCase).style.lineStyle, ...
        "LineWidth", relSeries(iCase).style.lineWidth, ...
        "DisplayName", relSeries(iCase).displayName);
end

xlim(ax, xLims);
ylim(ax, yLims);

xlabel(ax, '$z~[\mathrm{mm}]$', 'Interpreter','latex');
ylabel(ax, "$\epsilon_{COMSOL \,Square}$ [$\%$]", 'Interpreter', 'latex');

leg = legend(ax, "Location", "best");
leg.Interpreter = "latex";
leg.Box = "off";

if saveFigure
    exportgraphics(ax, fullfile(exportDir, exportName), "ContentType", "vector");
end

%% --------------------------- Local functions ------------------------- %%
function localAddCoilAxialMarkers(ax, zCoilCentres_mm, coilHeight_mm, yLims)
% Add subtle vertical bands showing the axial extent of the coils.

    y0 = yLims(1);
    y1 = yLims(2);

    bandColor = [0.82, 0.82, 0.82];
    centreLineColor = [0.42, 0.42, 0.42];

    for k = 1:numel(zCoilCentres_mm)
        zc = zCoilCentres_mm(k);
        zA = zc - 0.5 * coilHeight_mm;
        zB = zc + 0.5 * coilHeight_mm;

        patch(ax, [zA zB zB zA], [y0 y0 y1 y1], bandColor, ...
            "FaceAlpha", 0.14, ...
            "EdgeColor", "none", ...
            "HandleVisibility", "off");

        line(ax, [zc zc], [y0 y1], ...
            "Color", centreLineColor, ...
            "LineStyle", ":", ...
            "LineWidth", 0.9, ...
            "HandleVisibility", "off");
    end
end
