%% plot_planar_offset_difference_views_temp_v2.m
% Temporary plotting script for the comparison-oriented planar Bz Q output.
%
% Expected Q ordering from query_temp_difference_comparisons.m:
%   Q{1} : COMSOL circular (base case, x-z)
%   Q{2} : COMSOL circular minus MATLAB circular (x-z)
%   Q{3} : COMSOL circular minus COMSOL square x-z (x-z)
%   Q{4} : COMSOL square (base case, x-z)
%   Q{5} : COMSOL square x-z minus COMSOL square diagonal (x-z grid)
%
% This plotting script intentionally skips the base cases Q{1} and Q{4},
% and also skips Q{2}. It plots only:
%   Q{3} : COMSOL circular minus COMSOL square
%   Q{5} : COMSOL square x-z minus COMSOL square diagonal
%
% Layout / style:
%   - one MATLAB figure containing tabs
%   - no written plot titles
%   - tab names identify the case and offset
%   - axis equal to preserve equal units on x and z
%   - outline-only coil overlays (no shading)
%   - project colourbar style via set_clrbar.m
%   - export path prepared as: COMSOL/Graphs/Offset Comparison/Difference Views
%   - auto-export is OFF by default

clear; close all;

%% ---------------------------- User settings --------------------------- %%
addpath(genpath("functs"));

qFile = fullfile(pwd, "Q outputs", "Q_Planar_Bz_Offset_Comparisons2.mat");

% Colour-limit options:
%   "globalMax"   : symmetric limits from absolute max across plotted planes
%   "percentile"  : symmetric limits from percentile of abs(data)
%   "manual"      : use manualCLim exactly
colourLimitMode = "manual";
colourPercentile = 99;
manualCLim = [-0.011353, 0.011353];

saveFigures = true;
exportDir   = msbs_graphs_dir("Offset Comparison 2", "Difference Views", "Field");
exportExt   = ".svg";
exportRes   = 400; %#ok<NASGU>

% Representative coil geometry [m]
Ro = 95/2000;
Ri = 36/2000;
h  = 60/1000;
zCoils = [+90/1000, -90/1000];

% Coil colours and styles
greenEdge = 0.9 * [0.56, 0.68, 0.54];
blueEdge  = [0.23, 0.40, 0.67];

circularStyle.lineStyle = '-';
circularStyle.lineWidth = 2.4;
circularStyle.edgeColor = greenEdge;

squareXZStyle.lineStyle = '--';
squareXZStyle.lineWidth = 2.4;
squareXZStyle.edgeColor = blueEdge;

% Chosen style for square diagonal: same colour, different line style.
% This keeps colour mapped to coil type, while line style indicates plane direction.
squareDiagStyle.lineStyle = ':';
squareDiagStyle.lineWidth = 2.4;
squareDiagStyle.edgeColor = blueEdge;

%% ------------------------------ Load Q ------------------------------- %%
S = load(qFile, "Q");
Q = S.Q;
if ~iscell(Q)
    Q = {Q};
end

%% ---------------------- Build list of plots -------------------------- %%
% Plot only the two requested comparison families.
plotCaseIndices = [3, 5];
plotList = struct("caseIndex", {}, "resultIndex", {}, "caseLabel", {}, "comparisonType", {});

for idx = 1:numel(plotCaseIndices)
    iCase = plotCaseIndices(idx);

    if iCase > numel(Q)
        warning("Requested Q{%d} does not exist and will be skipped.", iCase);
        continue
    end

    results = Q{iCase}.results;
    if ~iscell(results)
        results = num2cell(results);
    end

    for iRes = 1:numel(results)
        plotList(end+1).caseIndex = iCase; %#ok<SAGROW>
        plotList(end).resultIndex = iRes;
        [plotList(end).caseLabel, plotList(end).comparisonType] = localCaseLabelAndType(iCase);
    end
end

%% -------------------- Global colourbar limits ------------------------ %%
allAbs = [];

for k = 1:numel(plotList)
    iCase = plotList(k).caseIndex;
    iRes  = plotList(k).resultIndex;

    data = Q{iCase}.results{iRes}.data;
    data = data(isfinite(data));
    allAbs = [allAbs; abs(data(:))]; %#ok<AGROW>
end

switch lower(string(colourLimitMode))
    case "globalmax"
        maxAbs = max(allAbs);
        cLims = [-maxAbs, maxAbs];

    case "percentile"
        maxAbs = prctile(allAbs, colourPercentile);
        cLims = [-maxAbs, maxAbs];

    case "manual"
        cLims = manualCLim;

    otherwise
        error("Unknown colourLimitMode: %s", colourLimitMode);
end

fprintf("Colour limits used: [%g, %g] T\n", cLims(1), cLims(2));

%% --------------------------- Tabbed figure --------------------------- %%
if saveFigures && ~exist(exportDir, "dir")
    mkdir(exportDir);
end

mainFig = figure("Name", "Planar offset comparison difference views", ...
    "NumberTitle", "off", ...
    "Color", "w", ...
    "Units", "pixels", ...
    "Position", [80, 80, 1050, 820]);

tabGroup = uitabgroup(mainFig);

%% --------------------------- Plot all views -------------------------- %%
for k = 1:numel(plotList)

    iCase = plotList(k).caseIndex;
    iRes  = plotList(k).resultIndex;

    qcase = Q{iCase};

    if ~iscell(qcase.queries)
        qcase.queries = num2cell(qcase.queries);
    end
    if ~iscell(qcase.results)
        qcase.results = num2cell(qcase.results);
    end

    q = qcase.queries{iRes};
    r = qcase.results{iRes};

    point = double(q.point(:).');
    offset_m = localInferOffsetFromQueryPoint(point);
    offset_mm = 1e3 * offset_m;
    offset_mm_round = round(offset_mm, 6);

    caseLabel = plotList(k).caseLabel;
    comparisonType = plotList(k).comparisonType;

    xPlot_mm = 1e3 * r.X;
    zPlot_mm = 1e3 * r.Z;
    xLabelStr = '$x~[\mathrm{mm}]$';

    figName = sprintf('%s__offset_%gmm', caseLabel, offset_mm_round);
    figName = regexprep(figName, '\s+', '_');

    tabName = sprintf('%s | %g mm', strrep(caseLabel, '_', ' '), offset_mm_round);

    tab = uitab(tabGroup, "Title", tabName);
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

    surf(ax, xPlot_mm, zPlot_mm, zeros(size(r.data)), smoothdata2(r.data, "sgolay"), ...
        "EdgeColor", "none", ...
        "FaceColor", "interp");

    view(ax, 2);
    axis(ax, "tight");
    axis(ax, "xy");
    axis(ax, "equal");

    cb = set_clrbar(ax, cLims, r.dataName);
    cb.TickLabelInterpreter = "latex";

    % Outline-only coil overlays for the requested comparison family.
    localDrawComparisonOverlays(ax, comparisonType, offset_m, ...
        Ro, Ri, h, zCoils, circularStyle, squareXZStyle, squareDiagStyle);

    xlabel(ax, xLabelStr);
    ylabel(ax, '$z~[\mathrm{mm}]$');

    set(ax, "Tag", figName);

    if saveFigures
        exportName = localSanitiseExportName(tabName);
        exportFile = fullfile(exportDir, exportName + exportExt);
        exportgraphics(ax, exportFile, "ContentType", "vector");
    end
end

%% -------------------------- Local functions -------------------------- %%
function offset_m = localInferOffsetFromQueryPoint(point)
% Infer the intended perpendicular offset from the saved query point.

    if numel(point) < 3
        error("Query point must contain at least three coordinates.");
    end

    offset_m = abs(point(2));
end

function [caseLabel, comparisonType] = localCaseLabelAndType(iCase)
% Return the display label and comparison family.

    switch iCase
        case 3
            caseLabel = 'COMSOL_Circular_minus_COMSOL_Square';
            comparisonType = "circular_vs_square";
        case 5
            caseLabel = 'COMSOL_Square_xz_minus_COMSOL_Square_diag';
            comparisonType = "square_xz_vs_square_diag";
        otherwise
            caseLabel = sprintf('Case_%d', iCase);
            comparisonType = "circular_vs_square";
    end
end

function localDrawComparisonOverlays(ax, comparisonType, offset_m, ...
    Ro, Ri, h, zCoils, circularStyle, squareXZStyle, squareDiagStyle)
% Draw only outline overlays, no shading.
% Comparison family controls which outlines are shown.

    comparisonType = string(comparisonType);

    switch comparisonType
        case "circular_vs_square"
            circularIntervals = localCircularAnnulusIntervals(abs(offset_m), Ro, Ri);
            squareIntervals   = localSquareAnnulusXZIntervals(offset_m, Ro, Ri);

            for kCoil = 1:numel(zCoils)
                localDrawIntervalsAtZ(ax, circularIntervals, zCoils(kCoil), h, circularStyle);
                localDrawIntervalsAtZ(ax, squareIntervals,   zCoils(kCoil), h, squareXZStyle);
            end

        case "square_xz_vs_square_diag"
            squareXZIntervals   = localSquareAnnulusXZIntervals(offset_m, Ro, Ri);
            squareDiagIntervals = localSquareAnnulusDiagonalIntervals(offset_m, Ro, Ri);

            for kCoil = 1:numel(zCoils)
                localDrawIntervalsAtZ(ax, squareXZIntervals,   zCoils(kCoil), h, squareXZStyle);
                localDrawIntervalsAtZ(ax, squareDiagIntervals, zCoils(kCoil), h, squareDiagStyle);
            end

        otherwise
            error("Unknown comparisonType: %s", comparisonType);
    end
end

function intervals = localCircularAnnulusIntervals(d, Ro, Ri)
% Cross-section of circular annulus by a vertical plane at distance d.

    if d > Ro
        intervals = zeros(0, 2);
        return
    end

    xo = sqrt(max(Ro^2 - d^2, 0));

    if d < Ri
        xi = sqrt(max(Ri^2 - d^2, 0));
        intervals = [-xo, -xi; xi, xo];
    else
        intervals = [-xo, xo];
    end
end

function intervals = localSquareAnnulusXZIntervals(y0, Ro, Ri)
% Cross-section of square annulus by y = y0.

    if abs(y0) > Ro
        intervals = zeros(0, 2);
        return
    end

    outer = [-Ro, Ro];

    if abs(y0) < Ri
        inner = [-Ri, Ri];
        intervals = localSubtractInterval(outer, inner);
    else
        intervals = outer;
    end
end

function intervals = localSquareAnnulusDiagonalIntervals(d, Ro, Ri)
% Cross-section of square annulus by x + y = sqrt(2) d.
% Horizontal coordinate is still treated as the local in-plane coordinate
% for the outline comparison plot.

    outer = localSquareDiagonalIntervalForHalfWidth(d, Ro);

    if isempty(outer)
        intervals = zeros(0, 2);
        return
    end

    inner = localSquareDiagonalIntervalForHalfWidth(d, Ri);

    if isempty(inner)
        intervals = outer;
    else
        intervals = localSubtractInterval(outer, inner);
    end
end

function interval = localSquareDiagonalIntervalForHalfWidth(d, a)
% Return [uMin uMax] for the intersection of x+y=sqrt(2)d
% with the square |x|<=a, |y|<=a.

    s = sqrt(2) * a;

    lower1 = d - s;
    upper1 = d + s;

    lower2 = -d - s;
    upper2 = -d + s;

    uMin = max(lower1, lower2);
    uMax = min(upper1, upper2);

    if uMin >= uMax
        interval = [];
    else
        interval = [uMin, uMax];
    end
end

function intervals = localSubtractInterval(outer, inner)
% Subtract one interval from one outer interval.

    if isempty(inner)
        intervals = outer;
        return
    end

    intervals = zeros(0, 2);

    if inner(1) > outer(1)
        intervals(end+1, :) = [outer(1), min(inner(1), outer(2))]; %#ok<AGROW>
    end

    if inner(2) < outer(2)
        intervals(end+1, :) = [max(inner(2), outer(1)), outer(2)]; %#ok<AGROW>
    end

    keep = intervals(:,2) > intervals(:,1);
    intervals = intervals(keep, :);
end

function localDrawIntervalsAtZ(ax, intervals_m, zCentre_m, height_m, style)
% Draw interval outlines as rectangles in the current 2D axes.

    if isempty(intervals_m)
        return
    end

    z0_mm = 1e3 * (zCentre_m - 0.5 * height_m);
    z1_mm = 1e3 * (zCentre_m + 0.5 * height_m);

    for i = 1:size(intervals_m, 1)
        x0_mm = 1e3 * intervals_m(i, 1);
        x1_mm = 1e3 * intervals_m(i, 2);

        X = [x0_mm, x1_mm, x1_mm, x0_mm];
        Z = [z0_mm, z0_mm, z1_mm, z1_mm];

        patch(ax, X, Z, 'w', ...
            "FaceColor", "none", ...
            "EdgeColor", style.edgeColor, ...
            "LineWidth", style.lineWidth, ...
            "LineStyle", style.lineStyle);
    end
end

function exportName = localSanitiseExportName(tabName)
% Convert tab names into clean export filenames.

    exportName = string(tabName);
    exportName = replace(exportName, "|", " ");
    exportName = regexprep(exportName, '\\s+mm', 'mm');
    exportName = regexprep(exportName, '[^A-Za-z0-9]+', '_');
    exportName = regexprep(exportName, '_+', '_');
    exportName = regexprep(exportName, '^_|_$', '');
end
