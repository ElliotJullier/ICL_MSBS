%% plot_planar_offset_gradients_dBzDz_temp_v4_large_text.m
% Plot absolute planar dBz/dz maps from:
%   Q_Planar_dBz_dz_Offset_Comparisons2.mat
%
% The uploaded Q file contains:
%   Q{1} : COMSOL circular absolute gradient
%   Q{2} : COMSOL circular - MATLAB circular gradient difference
%   Q{3} : COMSOL circular - COMSOL square gradient difference
%   Q{4} : COMSOL square x-z absolute gradient
%   Q{5} : COMSOL square x-z - COMSOL square diagonal gradient difference
%
% Therefore the missing absolute cases are reconstructed as:
%   MATLAB circular      = Q{1} - Q{2}
%   COMSOL square diag   = Q{4} - Q{5}
%
% Output views for every offset:
%   1) MATLAB circular, x-z
%   2) COMSOL circular, x-z
%   3) COMSOL square, x-z
%   4) COMSOL square, diagonal
%
% Gradient filenames include "dBzDz" to avoid SVG conversion/cache clashes
% with the corresponding Bz field figures.

clear; close all; clc;

%% ---------------------------- User settings --------------------------- %%
addpath(genpath("functs"));

qFile = fullfile(pwd, "Q outputs", ...
    "Q_Planar_dBz_dz_Offset_Comparisons2.mat");

if ~isfile(qFile)
    qFile = "/mnt/data/Q_Planar_dBz_dz_Offset_Comparisons2.mat";
end

% Colour-limit options:
%   "globalMax"   : symmetric limits from absolute maximum
%   "percentile"  : symmetric limits from percentile(abs(dBz/dz))
%   "manual"      : use manualCLim exactly
colourLimitMode = "percentile";
colourPercentile = 99.0;
manualCLim = [-5, 5];       % [T/m]

% Optional plotting-only smoothing.
applySmoothing = true;
smoothingWindow = 10;

saveFigures = true;
exportDir = fullfile(pwd, ...
    "Fig Exports", "Offset_Comp2", "Planar Views", "Gradients");
exportExt = ".png";

% Larger text settings.
axisTickFontSize = 16;
axisLabelFontSize = 19;
colorbarTickFontSize = 15;
colorbarLabelFontSize = 18;
textFontWeight = "bold";

% Representative coil geometry [m].
Ro = 95/2000;
Ri = 36/2000;
h  = 60/1000;
zCoils = [+90/1000, -90/1000];

% Coil colours.
greenFace = [0.56, 0.68, 0.54];
greenEdge = 0.55 * greenFace;

blueFace = [0.23, 0.40, 0.67];
blueEdge = [0.11, 0.24, 0.46];

coilAlpha = 0.35;
coilLineWidth = 1.0;
zeroOutlineLineWidth = 2.2;

%% ------------------------------ Load Q ------------------------------- %%
if ~isfile(qFile)
    error("Could not find gradient Q file: %s", qFile);
end

S = load(qFile, "Q");
Q = S.Q;

if ~iscell(Q)
    Q = {Q};
end

if numel(Q) < 5
    error([ ...
        "Expected at least five Q cases in the gradient comparison file.\n" + ...
        "Found %d cases."], numel(Q));
end

nOffsets = numel(Q{1}.results);

for iCase = [1, 2, 4, 5]
    if numel(Q{iCase}.results) ~= nOffsets
        error("Q{%d} does not contain the expected %d offsets.", ...
            iCase, nOffsets);
    end
end

%% ---------------------- Build absolute records ----------------------- %%
% Four records are created per offset in the desired display order.

records = struct( ...
    "caseLabel", {}, ...
    "coilType", {}, ...
    "planeLabel", {}, ...
    "offset_m", {}, ...
    "X", {}, ...
    "Z", {}, ...
    "data", {}, ...
    "tabName", {}, ...
    "exportName", {});

for iOffset = 1:nOffsets

    qCirc = Q{1}.queries{iOffset};
    rCirc = Q{1}.results{iOffset};

    rCircMinusMat = Q{2}.results{iOffset};

    qSquareXZ = Q{4}.queries{iOffset};
    rSquareXZ = Q{4}.results{iOffset};

    rSquareXZMinusDiag = Q{5}.results{iOffset};

    % All cases use the same requested perpendicular offset list.
    point = double(qCirc.point(:).');
    offset_m = abs(point(2));
    offset_mm = 1e3 * offset_m;
    offset_mm_round = round(offset_mm, 6);

    % Absolute reconstructions.
    dataCOMSOLCirc = double(rCirc.data);
    dataMATLABCirc = dataCOMSOLCirc - double(rCircMinusMat.data);

    dataSquareXZ = double(rSquareXZ.data);
    dataSquareDiag = dataSquareXZ - double(rSquareXZMinusDiag.data);

    % MATLAB circular x-z.
    records(end+1) = localMakeRecord( ... %#ok<SAGROW>
        "MATLAB_Circular", "circular", "xz", offset_m, ...
        double(rCirc.X), double(rCirc.Z), dataMATLABCirc, ...
        sprintf("MATLAB Circular | XZ | %g mm", offset_mm_round), ...
        sprintf("MATLAB_Circular_xz_dBzDz_%gmm", offset_mm_round));

    % COMSOL circular x-z.
    records(end+1) = localMakeRecord( ... %#ok<SAGROW>
        "COMSOL_Circular", "circular", "xz", offset_m, ...
        double(rCirc.X), double(rCirc.Z), dataCOMSOLCirc, ...
        sprintf("COMSOL Circular | XZ | %g mm", offset_mm_round), ...
        sprintf("COMSOL_Circular_xz_dBzDz_%gmm", offset_mm_round));

    % COMSOL square x-z.
    records(end+1) = localMakeRecord( ... %#ok<SAGROW>
        "COMSOL_Square", "square", "xz", offset_m, ...
        double(rSquareXZ.X), double(rSquareXZ.Z), dataSquareXZ, ...
        sprintf("COMSOL Square | XZ | %g mm", offset_mm_round), ...
        sprintf("COMSOL_Square_xz_dBzDz_%gmm", offset_mm_round));

    % COMSOL square diagonal.
    %
    % Q{5} stores x-z minus diagonal after the diagonal result was mapped
    % onto the x-z comparison grid. The X coordinate therefore acts as the
    % diagonal in-plane coordinate u for this reconstructed view.
    records(end+1) = localMakeRecord( ... %#ok<SAGROW>
        "COMSOL_Square", "square", "diag", offset_m, ...
        double(rSquareXZ.X), double(rSquareXZ.Z), dataSquareDiag, ...
        sprintf("COMSOL Square | DIAG | %g mm", offset_mm_round), ...
        sprintf("COMSOL_Square_diag_dBzDz_%gmm", offset_mm_round));
end

%% -------------------- Global colourbar limits ------------------------ %%
allAbs = [];

for k = 1:numel(records)
    data = records(k).data;
    data = data(isfinite(data));
    allAbs = [allAbs; abs(data(:))]; %#ok<AGROW>
end

switch lower(string(colourLimitMode))
    case "globalmax"
        maxAbs = max(allAbs);

    case "percentile"
        maxAbs = prctile(allAbs, colourPercentile);

    case "manual"
        cLims = manualCLim;

    otherwise
        error("Unknown colourLimitMode: %s", colourLimitMode);
end

if lower(string(colourLimitMode)) ~= "manual"
    if isempty(maxAbs) || ~isfinite(maxAbs) || maxAbs <= 0
        error("Could not determine valid gradient colour limits.");
    end

    cLims = [-maxAbs, maxAbs];
end

fprintf("Gradient colour limits used: [%g, %g] T/m\n", ...
    cLims(1), cLims(2));

%% --------------------------- Tabbed figure --------------------------- %%
if saveFigures && ~exist(exportDir, "dir")
    mkdir(exportDir);
end

mainFig = figure( ...
    "Name", "Planar offset-plane dBz/dz maps", ...
    "NumberTitle", "off", ...
    "Color", "w", ...
    "Units", "pixels", ...
    "Position", [80, 80, 1100, 850]);

tabGroup = uitabgroup(mainFig);

%% --------------------------- Plot all planes ------------------------- %%
for k = 1:numel(records)

    rec = records(k);

    if rec.coilType == "square"
        coilFace = blueFace;
        coilEdge = blueEdge;
    else
        coilFace = greenFace;
        coilEdge = greenEdge;
    end

    if rec.planeLabel == "xz"
        xPlot_mm = 1e3 * rec.X;
        xLabelStr = '$\mathbf{x}~[\mathbf{mm}]$';
    else
        % The reconstructed diagonal result is stored on the common
        % comparison-coordinate grid, interpreted here as u.
        xPlot_mm = 1e3 * rec.X;
        xLabelStr = ...
            '$\mathbf{u}=(\mathbf{y}-\mathbf{x})/\sqrt{2}~[\mathbf{mm}]$';
    end

    zPlot_mm = 1e3 * rec.Z;
    dataToPlot = rec.data;

    if applySmoothing
        dataToPlot = localSmoothMap(dataToPlot, smoothingWindow);
    end

    tab = uitab(tabGroup, "Title", rec.tabName);
    ax = axes("Parent", tab);

    hold(ax, "on");
    box(ax, "on");
    grid(ax, "on");

    ax.Layer = "top";
    ax.GridAlpha = 0.22;
    ax.MinorGridAlpha = 0.12;
    ax.XMinorGrid = "on";
    ax.YMinorGrid = "on";
    ax.LineWidth = 1.2;
    ax.FontSize = axisTickFontSize;
    ax.FontWeight = textFontWeight;
    ax.TickLabelInterpreter = "latex";

    ax.XAxis.Label.Interpreter = "latex";
    ax.YAxis.Label.Interpreter = "latex";
    ax.XAxis.Label.FontSize = axisLabelFontSize;
    ax.YAxis.Label.FontSize = axisLabelFontSize;
    ax.XAxis.Label.FontWeight = textFontWeight;
    ax.YAxis.Label.FontWeight = textFontWeight;

    surf(ax, ...
        xPlot_mm, zPlot_mm, zeros(size(dataToPlot)), dataToPlot, ...
        "EdgeColor", "none", ...
        "FaceColor", "interp");

    view(ax, 2);
    axis(ax, "tight");
    axis(ax, "xy");
    axis(ax, "equal");

    cb = localApplyGradientColorbar( ...
        ax, cLims, colorbarTickFontSize, ...
        colorbarLabelFontSize, textFontWeight);

    localDrawAnalyticCoilOverlay( ...
        ax, rec.coilType, rec.planeLabel, rec.offset_m, ...
        Ro, Ri, h, zCoils, ...
        coilFace, coilEdge, coilAlpha, ...
        coilLineWidth, zeroOutlineLineWidth);

    xlabel(ax, xLabelStr);
    ylabel(ax, '$\mathbf{z}~[\mathbf{mm}]$');

    set(ax, "Tag", rec.exportName);

    if saveFigures
        exportFile = fullfile(exportDir, rec.exportName + exportExt);
        exportgraphics(ax, exportFile, "ContentType", "vector");
    end
end

%% -------------------------- Local functions -------------------------- %%
function rec = localMakeRecord(caseLabel, coilType, planeLabel, offset_m, ...
    X, Z, data, tabName, exportName)

    rec = struct();
    rec.caseLabel = string(caseLabel);
    rec.coilType = string(coilType);
    rec.planeLabel = string(planeLabel);
    rec.offset_m = double(offset_m);
    rec.X = X;
    rec.Z = Z;
    rec.data = data;
    rec.tabName = string(tabName);
    rec.exportName = string(exportName);
end

function dataOut = localSmoothMap(dataIn, windowSize)
% Plotting-only smoothing with a safe fallback.

    dataOut = dataIn;

    if windowSize <= 1
        return
    end

    if exist("smoothdata2", "file") == 2
        dataOut = smoothdata2(dataIn, "sgolay", windowSize);
    elseif exist("smoothdata", "file") == 2
        dataOut = smoothdata(dataIn, 1, "movmean", windowSize);
        dataOut = smoothdata(dataOut, 2, "movmean", windowSize);
    end
end

function cb = localApplyGradientColorbar( ...
    ax, cLims, tickFontSize, labelFontSize, fontWeight)
% Apply project colourmap and an explicit LaTeX gradient label.

    colourStops = [ ...
        0.0, 0.0, 1.0;
        0.8, 0.8, 0.8;
        1.0, 0.0, 0.0];

    clrmap = create_colormap_from_colour_stops(colourStops);
    colormap(ax, clrmap);
    clim(ax, cLims);

    cb = colorbar(ax);
    cb.TickLabelInterpreter = "latex";
    cb.FontSize = tickFontSize;
    cb.FontWeight = fontWeight;

    cb.Label.String = ...
        '$\partial B_z/\partial z~[\mathrm{T\,m^{-1}}]$';
    cb.Label.Interpreter = "latex";
    cb.Label.FontSize = labelFontSize;
    cb.Label.FontWeight = fontWeight;
end

function localDrawAnalyticCoilOverlay(ax, coilType, planeLabel, offset_m, ...
    Ro, Ri, h, zCoils, faceClr, edgeClr, faceAlpha, ...
    lineWidth, zeroLineWidth)
% Draw actual offset-plane coil intersection plus zero-offset reference.

    currentIntervals = localCoilIntervals( ...
        coilType, planeLabel, offset_m, Ro, Ri);

    for kCoil = 1:numel(zCoils)
        localDrawIntervalsAtZ( ...
            ax, currentIntervals, zCoils(kCoil), h, ...
            faceClr, edgeClr, faceAlpha, lineWidth, "-", "fill");
    end

    zeroIntervals = localCoilIntervals( ...
        coilType, planeLabel, 0, Ro, Ri);

    for kCoil = 1:numel(zCoils)
        localDrawIntervalsAtZ( ...
            ax, zeroIntervals, zCoils(kCoil), h, ...
            faceClr, edgeClr, 0, zeroLineWidth, ":", "outline");
    end
end

function intervals = localCoilIntervals( ...
    coilType, planeLabel, offset_m, Ro, Ri)

    coilType = string(coilType);
    planeLabel = string(planeLabel);

    switch coilType
        case "circular"
            intervals = localCircularAnnulusIntervals( ...
                abs(offset_m), Ro, Ri);

        case "square"
            if planeLabel == "xz"
                intervals = localSquareAnnulusXZIntervals( ...
                    offset_m, Ro, Ri);
            elseif planeLabel == "diag"
                intervals = localSquareAnnulusDiagonalIntervals( ...
                    offset_m, Ro, Ri);
            else
                error("Unknown planeLabel: %s", planeLabel);
            end

        otherwise
            error("Unknown coilType: %s", coilType);
    end
end

function intervals = localCircularAnnulusIntervals(d, Ro, Ri)

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

    if isempty(inner)
        intervals = outer;
        return
    end

    intervals = zeros(0, 2);

    if inner(1) > outer(1)
        intervals(end+1,:) = ...
            [outer(1), min(inner(1), outer(2))]; %#ok<AGROW>
    end

    if inner(2) < outer(2)
        intervals(end+1,:) = ...
            [max(inner(2), outer(1)), outer(2)]; %#ok<AGROW>
    end

    intervals = intervals(intervals(:,2) > intervals(:,1), :);
end

function localDrawIntervalsAtZ(ax, intervals_m, zCentre_m, height_m, ...
    faceClr, edgeClr, faceAlpha, lineWidth, lineStyle, mode)

    if isempty(intervals_m)
        return
    end

    z0_mm = 1e3 * (zCentre_m - 0.5*height_m);
    z1_mm = 1e3 * (zCentre_m + 0.5*height_m);

    for i = 1:size(intervals_m, 1)
        x0_mm = 1e3 * intervals_m(i,1);
        x1_mm = 1e3 * intervals_m(i,2);

        X = [x0_mm, x1_mm, x1_mm, x0_mm];
        Z = [z0_mm, z0_mm, z1_mm, z1_mm];

        if string(mode) == "fill"
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
