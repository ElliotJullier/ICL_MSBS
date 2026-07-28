%% plot_parametric_innerR_xz_Bz_differences_temp_v3.m
% Temporary plotting script for the HalfMorgan parametric innerR study.
%
% Expected Q file from:
%   query_halfmorgan_parametric_innerR_xz_Bz_differences.m
%
% Expected Q ordering:
%   Q{1} : base field, innerR = 18 mm
%   Q{2} : innerR = 8  mm minus 18 mm
%   Q{3} : innerR = 13 mm minus 18 mm
%   Q{4} : innerR = 23 mm minus 18 mm
%   Q{5} : innerR = 28 mm minus 18 mm
%   Q{6} : innerR = 33 mm minus 18 mm
%   Q{7} : innerR = 38 mm minus 18 mm
%   Q{8} : innerR = 43 mm minus 18 mm
%
% Plot style:
%   - one tabbed MATLAB figure
%   - base field plotted as Bz
%   - all other tabs plotted as Delta Bz = Bz(innerR) - Bz(base)
%   - one coil only, because this HalfMorgan export does not contain the
%     bottom coil
%   - base coil outline/fill: sage green
%   - changed-innerR coil overlay: same sage green, dotted edge, filled
%     with 40% opacity
%   - axis equal to preserve geometry
%   - SAME colourbar limits for base and difference cases
%
% Export structure:
%   Fig Exports/Half Morgan Parametrics/innerR/

clear; close all; clc;

%% ---------------------------- User settings --------------------------- %%
addpath(genpath("functs"));

qFile = fullfile(pwd, "Q outputs", "Q_HalfMorgan_Parametric_innerR_25mm_xz_Bz_Differences.mat");
if ~isfile(qFile)
    qFile = "/mnt/data/Q_HalfMorgan_Parametric_innerR_xz_Bz_Differences.mat";
end

saveFigures = true;
exportDir   = fullfile(pwd, "Fig Exports", "Half Morgan Parametrics", "innerR", "25 mm Offset");
exportExt   = ".svg";

% ONE shared colour-limit setting for both base and difference plots:
%   "globalMax"   : symmetric limits from absolute max across all plots
%   "percentile"  : symmetric limits from percentile(abs(data)) across all plots
%   "manual"      : use manualSharedCLim exactly
sharedColourLimitMode = "percentile";
sharedColourPercentile = 99.0;
manualSharedCLim = [-0.05, 0.05];   % [T]

% Coil geometry [m].
Ro = 95/2000;         % fixed outer radius
h  = 60/1000;         % fixed coil height
zCoil = +90/1000;     % single HalfMorgan coil axial centre
baseInnerR_mm = 18;

% Optional fixed axis limits.
useManualAxisLimits = false;
manualXLim_mm = [-60, 60];
manualZLim_mm = [-120, 120];

% Colours / styles.
baseFace = [0.56, 0.68, 0.54];      % project sage green
baseEdge = 0.55 * baseFace;

baseFillAlpha = 0.20;
changedFillAlpha = 0.40;
baseLineWidth = 1.7;
changedLineWidth = 2.3;

%% ------------------------------ Load Q ------------------------------- %%
S = load(qFile, "Q");
Q = S.Q;
if ~iscell(Q)
    Q = {Q};
end

%% -------------------------- Parse plot info -------------------------- %%
plotInfo = repmat(struct( ...
    "innerR_mm", NaN, ...
    "baseInnerR_mm", baseInnerR_mm, ...
    "isDifference", false, ...
    "tabName", "", ...
    "fileName", "", ...
    "data", [], ...
    "X_mm", [], ...
    "Z_mm", [], ...
    "dataName", "Bz"), 1, numel(Q));

allAbs = [];

for k = 1:numel(Q)

    r = localFirstResult(Q{k});

    plotInfo(k).X_mm = 1e3 * double(r.X);
    plotInfo(k).Z_mm = 1e3 * double(r.Z);
    plotInfo(k).data = double(r.data);

    if isfield(r, "dataName")
        plotInfo(k).dataName = string(r.dataName);
    end

    [innerR_this_mm, innerR_base_mm, isDiff] = localGetParametricInfo(Q{k}, k, baseInnerR_mm);

    plotInfo(k).innerR_mm = innerR_this_mm;
    plotInfo(k).baseInnerR_mm = innerR_base_mm;
    plotInfo(k).isDifference = isDiff;

    if isDiff
        plotInfo(k).tabName = sprintf("innerR = %g mm - %g mm", innerR_this_mm, innerR_base_mm);
        plotInfo(k).fileName = sprintf("innerR_diff_%gmm_minus_%gmm", innerR_this_mm, innerR_base_mm);
    else
        plotInfo(k).tabName = sprintf("Base field | innerR = %g mm", innerR_base_mm);
        plotInfo(k).fileName = sprintf("innerR_base_%gmm", innerR_base_mm);
    end

    vals = plotInfo(k).data(isfinite(plotInfo(k).data));
    allAbs = [allAbs; abs(vals(:))]; %#ok<AGROW>
end

sharedCLim = localResolveCLim(allAbs, sharedColourLimitMode, sharedColourPercentile, manualSharedCLim);
fprintf("Shared colour limits for base and differences: [%g, %g] T\n", sharedCLim(1), sharedCLim(2));

%% --------------------------- Tabbed figure --------------------------- %%
if saveFigures && ~exist(exportDir, "dir")
    mkdir(exportDir);
end

mainFig = figure("Name", "Parametric innerR x-z Bz differences", ...
    "NumberTitle", "off", ...
    "Color", "w", ...
    "Units", "pixels", ...
    "Position", [80, 80, 1050, 820]);

tabGroup = uitabgroup(mainFig);

%% ------------------------------ Plot -------------------------------- %%
for k = 1:numel(Q)

    info = plotInfo(k);

    tab = uitab(tabGroup, "Title", info.tabName);
    ax = axes("Parent", tab);

    hold(ax, "on");
    box(ax, "on");
    grid(ax, "on");

    ax.Layer = "top";
    ax.GridAlpha = 0.22;
    ax.MinorGridAlpha = 0.12;
    ax.XMinorGrid = "on";
    ax.YMinorGrid = "on";
    ax.LineWidth = 1.0;
    ax.FontSize = 11;
    ax.TickLabelInterpreter = "latex";
    ax.XAxis.Label.Interpreter = "latex";
    ax.YAxis.Label.Interpreter = "latex";

    surf(ax, info.X_mm, info.Z_mm, zeros(size(info.data)), info.data, ...
        "EdgeColor", "none", ...
        "FaceColor", "interp");

    view(ax, 2);
    axis(ax, "xy");
    axis(ax, "equal");

    if useManualAxisLimits
        xlim(ax, manualXLim_mm);
        ylim(ax, manualZLim_mm);
    else
        xlim(ax, [min(info.X_mm(:), [], "omitnan"), max(info.X_mm(:), [], "omitnan")]);
        ylim(ax, [min(info.Z_mm(:), [], "omitnan"), max(info.Z_mm(:), [], "omitnan")]);
    end

    if info.isDifference
        cbLabel = '$\Delta B_z$ [T]';
    else
        cbLabel = '$B_z$ [T]';
    end
    cb = localApplyProjectColorbar(ax, sharedCLim, cbLabel);

    xlabel(ax, '$x~[\mathrm{mm}]$');
    ylabel(ax, '$z~[\mathrm{mm}]$');

    % One-coil overlay only.
    if info.isDifference
        % Changed geometry: same green, dotted edge, filled with 40% opacity.
        localDrawSingleCoilRectangles(ax, Ro, info.innerR_mm/1000, h, zCoil, ...
            "fill", baseFace, baseEdge, changedFillAlpha, changedLineWidth, ":");
        % Base geometry: solid sage-green outline.
        localDrawSingleCoilRectangles(ax, Ro, info.baseInnerR_mm/1000, h, zCoil, ...
            "outline", baseFace, baseEdge, 0, baseLineWidth, "-");
    else
        % Base field case: lightly filled base geometry plus solid edge.
        localDrawSingleCoilRectangles(ax, Ro, info.baseInnerR_mm/1000, h, zCoil, ...
            "fill", baseFace, baseEdge, baseFillAlpha, baseLineWidth, "-");
    end

    set(ax, "Tag", info.fileName);

    if saveFigures
        exportgraphics(ax, fullfile(exportDir, info.fileName + exportExt), ...
            "ContentType", "vector");
    end
end

%% -------------------------- Local functions -------------------------- %%
function r = localFirstResult(qcase)
    results = qcase.results;
    if ~iscell(results)
        results = num2cell(results);
    end
    if isempty(results)
        error("Q case contains no results.");
    end
    r = results{1};
end

function [innerR_mm, baseInnerR_mm, isDiff] = localGetParametricInfo(qcase, qIndex, defaultBaseInnerR_mm)

    innerR_mm = NaN;
    baseInnerR_mm = defaultBaseInnerR_mm;
    isDiff = qIndex > 1;  % robust fallback for the intended Q ordering

    if isfield(qcase, "parametric")
        p = qcase.parametric;

        if isfield(p, "innerR_mm")
            innerR_mm = double(p.innerR_mm);
        end

        if isfield(p, "baseInnerR_mm")
            baseInnerR_mm = double(p.baseInnerR_mm);
        end

        if isfield(p, "differenceDefinition")
            def = string(p.differenceDefinition);
            isDiff = def ~= "base_field_not_difference";
        end
    end

    if isnan(innerR_mm)
        caseName = "";
        if isfield(qcase, "meta") && isfield(qcase.meta, "caseName")
            caseName = string(qcase.meta.caseName);
        end

        tokens = regexp(char(caseName), 'innerR\s*=\s*([0-9.]+)\s*mm', 'tokens', 'once');
        if ~isempty(tokens)
            innerR_mm = str2double(tokens{1});
        elseif contains(caseName, "Base field")
            innerR_mm = baseInnerR_mm;
            isDiff = false;
        else
            innerR_mm = baseInnerR_mm;
        end
    end

    if ~isfinite(innerR_mm)
        innerR_mm = baseInnerR_mm;
    end
end

function cLims = localResolveCLim(absValues, mode, percentileVal, manualCLim)

    absValues = absValues(isfinite(absValues));

    switch lower(string(mode))
        case "globalmax"
            maxAbs = max(absValues);

        case "percentile"
            maxAbs = prctile(absValues, percentileVal);

        case "manual"
            cLims = manualCLim;
            return

        otherwise
            error("Unknown colour-limit mode: %s", string(mode));
    end

    if isempty(maxAbs) || ~isfinite(maxAbs) || maxAbs <= 0
        maxAbs = 1;
    end

    cLims = [-maxAbs, maxAbs];
end

function cb = localApplyProjectColorbar(ax, climLims, labelStr)
% Apply the same red-grey-blue project colourmap and a reliable latex label.

    clrbMapRange = [0 0 1; 0.8 0.8 0.8; 1 0 0];
    clrmap = create_colormap_from_colour_stops(clrbMapRange);
    colormap(ax, clrmap);
    clim(ax, climLims);

    cb = colorbar(ax);
    cb.TickLabelInterpreter = 'latex';
    cb.Label.String = labelStr;
    cb.Label.Interpreter = 'latex';
end

function localDrawSingleCoilRectangles(ax, Ro, Ri, h, zCoil, mode, faceClr, edgeClr, faceAlpha, lineWidth, lineStyle)
% Draw the x-z cross-section of one rectangular annular coil at y = 0.
% Two rectangles are drawn: left and right conductor blocks.

    Ro_mm = 1e3 * Ro;
    Ri_mm = 1e3 * Ri;
    h_mm  = 1e3 * h;
    zc_mm = 1e3 * zCoil;
    z0 = zc_mm - 0.5*h_mm;

    conductorWidth_mm = Ro_mm - Ri_mm;

    if conductorWidth_mm <= 0
        warning("Skipping coil overlay because Ri >= Ro.");
        return
    end

    % Left conductor block: x = [-Ro, -Ri]
    localDrawRect(ax, [-Ro_mm, z0, conductorWidth_mm, h_mm], ...
        mode, faceClr, edgeClr, faceAlpha, lineWidth, lineStyle);

    % Right conductor block: x = [Ri, Ro]
    localDrawRect(ax, [Ri_mm, z0, conductorWidth_mm, h_mm], ...
        mode, faceClr, edgeClr, faceAlpha, lineWidth, lineStyle);
end

function localDrawRect(ax, pos, mode, faceClr, edgeClr, faceAlpha, lineWidth, lineStyle)

    if string(mode) == "fill"
        rectangle(ax, ...
            "Position", pos, ...
            "FaceColor", [faceClr, faceAlpha], ...
            "EdgeColor", edgeClr, ...
            "LineWidth", lineWidth, ...
            "LineStyle", lineStyle);
    else
        rectangle(ax, ...
            "Position", pos, ...
            "FaceColor", "none", ...
            "EdgeColor", edgeClr, ...
            "LineWidth", lineWidth, ...
            "LineStyle", lineStyle);
    end
end
