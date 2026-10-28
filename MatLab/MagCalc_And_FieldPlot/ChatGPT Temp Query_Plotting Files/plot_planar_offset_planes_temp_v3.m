%% plot_planar_offset_planes_temp_v3.m
% Temporary plotting script for the planar offset-plane Q output.
%
% Main behaviour:
%   - Q{1}: COMSOL circular  -> plot x-z offset planes only
%   - Q{2}: COMSOL square    -> plot x-z and diagonal offset planes
%   - Q{3}: MATLAB circular  -> plot x-z offset planes only
%
% Each plot is placed in a tab inside one MATLAB figure.
% Each tab name identifies case, plane and offset.
% No written title is added to the axes.
%
% Coil overlay:
%   - solid translucent patch = actual intersection of the coil body with
%     the plotted offset plane
%   - thick dotted outline = original zero-offset coil-section outline
%
% The coil-section overlay is computed analytically from:
%   Ro = 95/2000 m
%   Ri = 36/2000 m
%   h  = 60/1000 m
%   zc = +/-90/1000 m

clear; close all;

%% ---------------------------- User settings --------------------------- %%
addpath(genpath("functs"));

qFile = fullfile(pwd, "Q outputs", "Q_CentrelineOffAxis_Planes_Bz2.mat");
if ~isfile(qFile)
    qFile = "/mnt/data/Q_CentrelineOffAxis_Planes_dBz_dz.mat";
end

% Colour-limit options:
%   "globalMax"   : symmetric limits from absolute max across plotted planes
%   "percentile"  : symmetric limits from percentile of abs(Bz), usually clearer
%   "manual"      : use manualCLim exactly
colourLimitMode = "percentile";
colourPercentile = 99;
manualCLim = [-0.300193, 0.300193];     % [T], only used when colourLimitMode = "manual"

saveFigures = false;
exportDir   = msbs_graphs_dir("Offset_Comp2", "Planar Views", "Field");
exportExt   = ".svg";
exportRes   = 400;   % ignored for SVG, but kept for easy PNG switching later

% Representative coil geometry [m]
Ro = 95/2000;
Ri = 36/2000;
h  = 60/1000;
zCoils = [+90/1000, -90/1000];

% Coil colours
greenFace = [0.56, 0.68, 0.54];
greenEdge = 0.55 * greenFace;

blueFace = [0.23, 0.40, 0.67];
blueEdge = [0.11, 0.24, 0.46];

coilAlpha = 0.35;
coilLineWidth = 1.0;
zeroOutlineLineWidth = 2.2;

%% ------------------------------ Load Q ------------------------------- %%
S = load(qFile, "Q");
Q = S.Q;
if ~iscell(Q)
    Q = {Q};
end

%% ----------------------- Determine plotted records -------------------- %%
% This keeps the plotting logic explicit and avoids using query groups.
%
% With your query order:
%   results 1:nOffsets             = x-z offset planes
%   results nOffsets+1:2*nOffsets  = diagonal offset planes

plotList = struct("caseIndex", {}, "resultIndex", {}, "planeLabel", {});

for iCase = 1:numel(Q)
    results = Q{iCase}.results;
    if ~iscell(results)
        results = num2cell(results);
    end

    nOffsets = numel(results) / 2;

    for iRes = 1:numel(results)
        if iRes <= nOffsets
            planeLabel = "xz";
        else
            planeLabel = "diag";
        end

        % Circular coils are axisymmetric, so diagonal cases duplicate x-z.
        % Skip them for Q{1} COMSOL circular and Q{3} MATLAB circular.
        if (iCase == 1 || iCase == 3) && planeLabel == "diag"
            continue
        end

        plotList(end+1).caseIndex = iCase; %#ok<SAGROW>
        plotList(end).resultIndex = iRes;
        plotList(end).planeLabel = planeLabel;
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

mainFig = figure("Name", "Planar offset-plane Bz maps", ...
    "NumberTitle", "off", ...
    "Color", "w", ...
    "Units", "pixels", ...
    "Position", [80, 80, 1050, 820]);

tabGroup = uitabgroup(mainFig);

%% --------------------------- Plot all planes ------------------------- %%
for k = 1:numel(plotList)

    iCase = plotList(k).caseIndex;
    iRes  = plotList(k).resultIndex;
    planeLabel = plotList(k).planeLabel;

    qcase = Q{iCase};

    q = qcase.queries{iRes};
    r = qcase.results{iRes};

    point = double(q.point(:).');

    caseLabel = localCaseLabel(iCase, qcase);
    coilType = localCoilTypeForCase(iCase);

    if coilType == "square"
        coilFace = blueFace;
        coilEdge = blueEdge;
    else
        coilFace = greenFace;
        coilEdge = greenEdge;
    end

    if planeLabel == "xz"
        % x-z parallel planes: y = offset.
        offset_m = point(2);
        offset_mm = 1e3 * offset_m;

        xPlot_mm = 1e3 * r.X;
        zPlot_mm = 1e3 * r.Z;

        xLabelStr = '$x~[\mathrm{mm}]$';

    else
        % diagonal parallel planes: x + y = const.
        %
        % For the query definition point = [r/sqrt(2), r/sqrt(2), 0],
        % the perpendicular offset from the origin is norm(point(1:2)).
        offset_m = abs(point(1) + point(2)) / sqrt(2);
        offset_mm = 1e3 * offset_m;

        % In-plane coordinate along the x = -y direction.
        xPlot_mm = 1e3 * (r.Y - r.X) / sqrt(2);
        zPlot_mm = 1e3 * r.Z;

        xLabelStr = '$u=(y-x)/\sqrt{2}~[\mathrm{mm}]$';
    end

    offset_mm_round = round(offset_mm, 6);

    figName = sprintf('%s__%s__offset_%gmm', ...
        caseLabel, planeLabel, offset_mm_round);
    figName = regexprep(figName, '\s+', '_');

    tabName = sprintf('%s | %s | %g mm', ...
        strrep(caseLabel, '_', ' '), upper(planeLabel), offset_mm_round);

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

    surf(ax, xPlot_mm, zPlot_mm, zeros(size(r.data)), smoothdata2(r.data, "sgolay", 10), ...
        "EdgeColor", "none", ...
        "FaceColor", "interp");

    view(ax, 2);
    axis(ax, "tight");
    axis(ax, "xy");
    axis equal;

    % Project colourbar/colormap style.
    cb = set_clrbar(ax, cLims, r.dataName);
    cb.TickLabelInterpreter = "latex";

    % Accurate analytic coil-section overlay.
    localDrawAnalyticCoilOverlay(ax, coilType, planeLabel, offset_m, ...
        Ro, Ri, h, zCoils, ...
        coilFace, coilEdge, coilAlpha, coilLineWidth, zeroOutlineLineWidth);

    xlabel(ax, xLabelStr);
    ylabel(ax, '$z~[\mathrm{mm}]$');

    % Make manual inspection/saving easier.
    set(ax, "Tag", figName);

    if saveFigures
        exportName = localSanitiseExportName(tabName);
        exportFile = fullfile(exportDir, exportName + exportExt);
    
        exportgraphics(ax, exportFile, ...
            "ContentType", "vector");
    end
end

%% -------------------------- Local functions -------------------------- %%
function caseLabel = localCaseLabel(iCase, qcase)
% Simple explicit mapping, with a metadata fallback.

    switch iCase
        case 1
            caseLabel = 'COMSOL_Circular';
        case 2
            caseLabel = 'COMSOL_Square';
        case 3
            caseLabel = 'MATLAB_Circular';
        otherwise
            if isfield(qcase, 'meta') && isfield(qcase.meta, 'caseName')
                caseLabel = char(qcase.meta.caseName);
            else
                caseLabel = sprintf('Case_%d', iCase);
            end
        end
end

function coilType = localCoilTypeForCase(iCase)
% Explicit mapping for the current Q output.

    if iCase == 2
        coilType = "square";
    else
        coilType = "circular";
    end
end

function localDrawAnalyticCoilOverlay(ax, coilType, planeLabel, offset_m, ...
    Ro, Ri, h, zCoils, faceClr, edgeClr, faceAlpha, lineWidth, zeroLineWidth)
% Draw actual offset-plane coil intersection plus zero-offset reference.

    % Draw actual current-offset coil intersection first.
    currentIntervals = localCoilIntervals(coilType, planeLabel, offset_m, Ro, Ri);

    for kCoil = 1:numel(zCoils)
        localDrawIntervalsAtZ(ax, currentIntervals, zCoils(kCoil), h, ...
            faceClr, edgeClr, faceAlpha, lineWidth, "-", "fill");
    end

    % Draw zero-offset reference outline on top.
    zeroIntervals = localCoilIntervals(coilType, planeLabel, 0, Ro, Ri);

    for kCoil = 1:numel(zCoils)
        localDrawIntervalsAtZ(ax, zeroIntervals, zCoils(kCoil), h, ...
            faceClr, edgeClr, 0, zeroLineWidth, ":", "outline");
    end
end

function intervals = localCoilIntervals(coilType, planeLabel, offset_m, Ro, Ri)
% Return in-plane coordinate intervals [uMin uMax] in metres.
%
% For x-z planes:
%   coordinate is x.
%
% For diagonal planes:
%   coordinate is u = (y-x)/sqrt(2).

    coilType = string(coilType);
    planeLabel = string(planeLabel);

    switch coilType

        case "circular"
            % Circular annulus is axisymmetric. Any vertical plane at
            % perpendicular distance |offset_m| has the same form.
            d = abs(offset_m);
            intervals = localCircularAnnulusIntervals(d, Ro, Ri);

        case "square"
            if planeLabel == "xz"
                % Square annulus sliced by y = const.
                d = offset_m;
                intervals = localSquareAnnulusXZIntervals(d, Ro, Ri);

            elseif planeLabel == "diag"
                % Square annulus sliced by x + y = sqrt(2)*d.
                %
                % In coordinates:
                %   v = (x+y)/sqrt(2) = d
                %   u = (y-x)/sqrt(2)
                d = offset_m;
                intervals = localSquareAnnulusDiagonalIntervals(d, Ro, Ri);

            else
                error("Unknown planeLabel: %s", planeLabel);
            end

        otherwise
            error("Unknown coilType: %s", coilType);
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
% Cross-section of square annulus by x + y = sqrt(2)*d.
%
% Uses:
%   v = (x+y)/sqrt(2) = d
%   u = (y-x)/sqrt(2)
%
% For square half-width a, the interval in u is:
%   |(d-u)/sqrt(2)| <= a
%   |(d+u)/sqrt(2)| <= a

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

    % Remove invalid/zero-width pieces.
    keep = intervals(:,2) > intervals(:,1);
    intervals = intervals(keep, :);
end

function localDrawIntervalsAtZ(ax, intervals_m, zCentre_m, height_m, ...
    faceClr, edgeClr, faceAlpha, lineWidth, lineStyle, mode)
% Draw intervals as rectangles in current 2D axes.
%
% x-axis is the in-plane coordinate [mm], y-axis is z [mm].

    if isempty(intervals_m)
        return
    end

    z0_mm = 1e3 * (zCentre_m - 0.5*height_m);
    z1_mm = 1e3 * (zCentre_m + 0.5*height_m);

    for i = 1:size(intervals_m, 1)
        x0_mm = 1e3 * intervals_m(i, 1);
        x1_mm = 1e3 * intervals_m(i, 2);

        X = [x0_mm, x1_mm, x1_mm, x0_mm];
        Z = [z0_mm, z0_mm, z1_mm, z1_mm];

        if mode == "fill"
            patch(ax, X, Z, faceClr, ...
                "FaceAlpha", faceAlpha, ...
                "EdgeColor", edgeClr, ...
                "LineWidth", lineWidth, ...
                "LineStyle", lineStyle);
        else
            patch(ax, X, Z, "w", ...
                "FaceColor", "none", ...
                "EdgeColor", edgeClr, ...
                "LineWidth", lineWidth, ...
                "LineStyle", lineStyle);
        end
    end
end

function exportName = localSanitiseExportName(tabName)
% Convert tab names like:
%   "COMSOL Circular | XZ | 0 mm"
% into:
%   "COMSOL_Circular_xz_0mm"

    exportName = string(tabName);

    % Remove pipe separators while preserving readable tokens.
    exportName = replace(exportName, "|", " ");

    % Remove spaces before unit suffixes.
    exportName = regexprep(exportName, '\s+mm', 'mm');

    % Lowercase plane labels only.
    exportName = regexprep(exportName, '\<XZ\>', 'xz');
    exportName = regexprep(exportName, '\<DIAG\>', 'diag');

    % Replace remaining non-alphanumeric groups with underscores.
    exportName = regexprep(exportName, '[^A-Za-z0-9]+', '_');

    % Clean duplicate/edge underscores.
    exportName = regexprep(exportName, '_+', '_');
    exportName = regexprep(exportName, '^_|_$', '');
end
