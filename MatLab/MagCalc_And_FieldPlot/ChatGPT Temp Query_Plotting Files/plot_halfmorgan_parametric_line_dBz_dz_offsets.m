%% plot_halfmorgan_parametric_line_dBz_dz_offsets.m
% Plot dBz/dz vertical-line comparisons from a HalfMorgan parametric Q file.
%
% Expected Q file from:
%   query_halfmorgan_parametric_line_dBz_dz_offsets.m
%
% Plot grouping:
%   one graph per offset
%   each graph compares all parameter values/cases
%
% Output:
%   COMSOL/Graphs/Half Morgan Parametrics/<parameter>/Line_Plots/dBz_dz_offset_group/

clear; close all; clc;

%% ---------------------------- User settings --------------------------- %%
addpath(genpath("functs"));

studyName = "innerR";

qFile = fullfile(pwd, "Q outputs", ...
    "Q_HalfMorgan_Parametric_" + studyName + "_Line_dBzDz_Offsets.mat");
if ~isfile(qFile)
    qFile = "/mnt/data/Q_HalfMorgan_Parametric_" + studyName + "_Line_dBzDz_Offsets.mat";
end

saveFigures = true;
exportDir = msbs_graphs_dir("Half Morgan Parametrics", studyName, ...
    "Line_Plots", "dBz_dz_offset_group");
exportExt = ".png";

% Axis-limit options:
%   "globalMax"   : symmetric y-limits from global abs max
%   "percentile"  : symmetric y-limits from percentile(abs(data))
%   "manual"      : use manualYLims
yAxisLimitMode = "globalMax";
yPercentile = 99.5;
manualYLims = [-5, 5];    % [T/m]
yPaddingFactor = 1.05;

% Plot-time smoothing.
% smoothWindow = 1 means no smoothing.
% This uses sgolayfilt if available, otherwise smoothdata/conv fallback.
smoothWindow = 11;
sgolayPolyOrder = 3;

% Font sizes
axisTickFontSize = 16;
axisLabelFontSize = 18;
legendFontSize = 15;

% Reference coil axial marker. For height studies this is only a reference
% marker, not one marker per height.
showCoilMarker = true;
zCoilCentre_mm = 90;
coilHeightMarker_mm = 60;

% Colour palette, kept close to the previous project palette.
baseSage = [0.56, 0.68, 0.54];
paramPalette = [ ...
    0.08, 0.27, 0.44; ...
    0.10, 0.39, 0.56; ...
    0.14, 0.50, 0.64; ...
    0.18, 0.60, 0.67; ...
    0.28, 0.68, 0.60; ...
    0.49, 0.72, 0.46; ...
    0.86, 0.55, 0.14; ...
    0.55, 0.35, 0.64; ...
    0.64, 0.32, 0.26; ...
    0.36, 0.36, 0.36];

lineWidth = 1.5;
baseLineWidth = 2.2;

%% ------------------------------ Load Q ------------------------------- %%
if ~isfile(qFile)
    error("Could not find Q file: %s", qFile);
end

S = load(qFile, "Q");
Q = S.Q;
if ~iscell(Q)
    Q = {Q};
end

nCases = numel(Q);

% Extract study metadata.
studyInfo = localGetStudyInfo(Q);
offsetList_mm = studyInfo.offsetList_mm;
paramValues = studyInfo.paramValues;
paramUnits = studyInfo.paramUnits;
baseValue = studyInfo.baseValue;

nOffsets = numel(offsetList_mm);

%% -------------------------- Extract records -------------------------- %%
D = repmat(struct( ...
    "z_mm", [], ...
    "grad", [], ...
    "offset_mm", NaN, ...
    "paramValue", NaN, ...
    "label", ""), nCases, nOffsets);

allGrad = [];
allZ = [];

for iCase = 1:nCases

    results = Q{iCase}.results;
    if ~iscell(results)
        results = num2cell(results);
    end

    if numel(results) < nOffsets
        error("Q{%d} contains %d results, but %d offsets were expected.", ...
            iCase, numel(results), nOffsets);
    end

    paramValue = localGetParamValue(Q{iCase}, iCase);

    for iOffset = 1:nOffsets

        r = results{iOffset};

        z_mm = 1e3 * double(r.Z(:));
        gVal = double(r.data(:));

        [z_mm, sortIdx] = sort(z_mm);
        gVal = gVal(sortIdx);

        gVal = localSmoothGradientForPlotting(gVal, smoothWindow, sgolayPolyOrder);

        D(iCase, iOffset).z_mm = z_mm;
        D(iCase, iOffset).grad = gVal;
        D(iCase, iOffset).offset_mm = offsetList_mm(iOffset);
        D(iCase, iOffset).paramValue = paramValue;
        D(iCase, iOffset).label = localParamLabel(studyName, paramValue, paramUnits);

        finiteMask = isfinite(z_mm) & isfinite(gVal);
        allZ = [allZ; z_mm(finiteMask)]; %#ok<AGROW>
        allGrad = [allGrad; gVal(finiteMask)]; %#ok<AGROW>
    end
end

if isempty(allGrad)
    error("No finite gradient data found in the Q output.");
end

xLims = [min(allZ), max(allZ)];

switch lower(string(yAxisLimitMode))
    case "globalmax"
        yMaxAbs = max(abs(allGrad));
        yLims = yPaddingFactor * [-yMaxAbs, yMaxAbs];

    case "percentile"
        yMaxAbs = prctile(abs(allGrad), yPercentile);
        yLims = yPaddingFactor * [-yMaxAbs, yMaxAbs];

    case "manual"
        yLims = manualYLims;

    otherwise
        error("Unknown yAxisLimitMode: %s", yAxisLimitMode);
end

if ~all(isfinite(yLims)) || diff(yLims) <= 0
    error("Invalid y-axis limits: [%g, %g]", yLims(1), yLims(2));
end

fprintf("x limits: [%g, %g] mm\n", xLims(1), xLims(2));
fprintf("y limits: [%g, %g] T/m\n", yLims(1), yLims(2));

%% --------------------------- Line styles ----------------------------- %%
lineColors = localMakeParamColors(nCases, paramPalette, paramValues, baseValue, baseSage);
lineStyles = strings(1, nCases);
lineWidths = lineWidth * ones(1, nCases);

for iCase = 1:nCases
    if isfinite(baseValue) && abs(paramValues(iCase) - baseValue) < 1e-9
        lineStyles(iCase) = ":";
        lineWidths(iCase) = baseLineWidth;
    else
        lineStyles(iCase) = "-";
    end
end

%% --------------------------- Tabbed figure --------------------------- %%
if saveFigures && ~exist(exportDir, "dir")
    mkdir(exportDir);
end

mainFig = figure("Name", "HalfMorgan parametric dBz/dz line offsets", ...
    "NumberTitle", "off", ...
    "Color", "w", ...
    "Units", "pixels", ...
    "Position", [80, 80, 1050, 820]);

tabGroup = uitabgroup(mainFig);

for iOffset = 1:nOffsets

    offset_mm = offsetList_mm(iOffset);

    tabName = sprintf("%s | dBz/dz | offset %g mm", studyName, offset_mm);
    fileName = sprintf("%s_grad_offset_group_%gmm", studyName, offset_mm);

    tab = uitab(tabGroup, "Title", tabName);
    ax = axes("Parent", tab);

    localPrepareAxes(ax, xLims, yLims, axisTickFontSize, axisLabelFontSize);

    if showCoilMarker
        localAddCoilAxialMarker(ax, zCoilCentre_mm, coilHeightMarker_mm, yLims);
    end

    for iCase = 1:nCases
        plot(ax, D(iCase, iOffset).z_mm, D(iCase, iOffset).grad, ...
            "Color", lineColors(iCase,:), ...
            "LineStyle", lineStyles(iCase), ...
            "LineWidth", lineWidths(iCase), ...
            "DisplayName", D(iCase, iOffset).label);
    end

    xlabel(ax, '$z~[\mathrm{mm}]$');
    ylabel(ax, '$\partial B_z/\partial z~[\mathrm{T\,m^{-1}}]$');

    leg = legend(ax, "Location", "best");
    leg.Interpreter = "latex";
    leg.FontSize = legendFontSize;
    leg.Box = "off";

    if saveFigures
        exportFile = fullfile(exportDir, fileName + exportExt);
        exportgraphics(ax, exportFile, "ContentType", "vector");
    end
end

%% -------------------------- Local functions -------------------------- %%
function studyInfo = localGetStudyInfo(Q)

    q1 = Q{1};

    studyInfo = struct();
    studyInfo.parameterName = "parameter";
    studyInfo.paramValues = 1:numel(Q);
    studyInfo.paramUnits = "case";
    studyInfo.baseValue = NaN;
    studyInfo.offsetList_mm = [0, 5, 10, 25, 50, 75];

    if isfield(q1, "parametricStudy")
        ps = q1.parametricStudy;

        if isfield(ps, "parameterName")
            studyInfo.parameterName = string(ps.parameterName);
        end
        if isfield(ps, "parameterValues")
            studyInfo.paramValues = double(ps.parameterValues(:).');
        end
        if isfield(ps, "parameterUnits")
            studyInfo.paramUnits = string(ps.parameterUnits);
        end
        if isfield(ps, "baseValue")
            studyInfo.baseValue = double(ps.baseValue);
        end
    end

    if isfield(q1, "parametric") && isfield(q1.parametric, "offsetList_mm")
        studyInfo.offsetList_mm = double(q1.parametric.offsetList_mm(:).');
    elseif isfield(q1, "queries")
        queries = q1.queries;
        if iscell(queries)
            studyInfo.offsetList_mm = NaN(1, numel(queries));
            for k = 1:numel(queries)
                q = queries{k};
                studyInfo.offsetList_mm(k) = 1e3 * q.start(2);
            end
        end
    end
end

function paramValue = localGetParamValue(qcase, fallbackIndex)

    paramValue = fallbackIndex;

    if isfield(qcase, "parametric") && isfield(qcase.parametric, "parameterValue")
        paramValue = double(qcase.parametric.parameterValue);
    end
end

function label = localParamLabel(studyName, value, units)

    if string(units) == "case"
        label = sprintf('%s case %g', studyName, value);
    else
        label = sprintf('%s = %g %s', studyName, value, units);
    end
end

function colors = localMakeParamColors(nCases, palette, paramValues, baseValue, baseColor)

    colors = zeros(nCases, 3);

    if nCases <= size(palette,1)
        colors(:,:) = palette(1:nCases,:);
    else
        xi = linspace(1, size(palette,1), nCases);
        colors(:,:) = interp1(1:size(palette,1), palette, xi, "linear");
    end

    if isfinite(baseValue)
        [minDiff, idx] = min(abs(paramValues - baseValue));
        if minDiff < 1e-9
            colors(idx,:) = baseColor;
        end
    end
end

function localPrepareAxes(ax, xLims, yLims, axisTickFontSize, axisLabelFontSize)

    hold(ax, "on");
    box(ax, "on");
    grid(ax, "on");

    ax.GridAlpha = 0.16;
    ax.MinorGridAlpha = 0.08;
    ax.XMinorGrid = "on";
    ax.YMinorGrid = "on";
    ax.LineWidth = 1.0;

    % Tick-label font size
    ax.FontSize = axisTickFontSize;
    ax.TickLabelInterpreter = "latex";

    % Axis-label font size
    ax.XAxis.Label.Interpreter = "latex";
    ax.YAxis.Label.Interpreter = "latex";
    ax.XAxis.Label.FontSize = axisLabelFontSize;
    ax.YAxis.Label.FontSize = axisLabelFontSize;

    xlim(ax, xLims);
    ylim(ax, yLims);
end

function localAddCoilAxialMarker(ax, zCentre_mm, coilHeight_mm, yLims)

    y0 = yLims(1);
    y1 = yLims(2);

    zA = zCentre_mm - 0.5 * coilHeight_mm;
    zB = zCentre_mm + 0.5 * coilHeight_mm;

    patch(ax, [zA zB zB zA], [y0 y0 y1 y1], [0.82, 0.82, 0.82], ...
        "FaceAlpha", 0.14, ...
        "EdgeColor", "none", ...
        "HandleVisibility", "off");

    line(ax, [zCentre_mm zCentre_mm], [y0 y1], ...
        "Color", [0.42, 0.42, 0.42], ...
        "LineStyle", ":", ...
        "LineWidth", 0.9, ...
        "HandleVisibility", "off");
end

function yOut = localSmoothGradientForPlotting(yIn, smoothWindow, sgolayPolyOrder)
% Smooth only for plotting. smoothWindow = 1 gives a deliberate no-op.

    yOut = yIn(:);

    if smoothWindow <= 1
        return
    end

    smoothWindow = round(smoothWindow);
    if mod(smoothWindow, 2) == 0
        smoothWindow = smoothWindow + 1;
    end

    finiteMask = isfinite(yOut);
    if nnz(finiteMask) < smoothWindow
        return
    end

    idx = (1:numel(yOut)).';
    yFilled = yOut;

    if any(~finiteMask)
        yFilled(~finiteMask) = interp1( ...
            idx(finiteMask), yOut(finiteMask), idx(~finiteMask), ...
            "linear", "extrap");
    end

    if exist("sgolayfilt", "file") == 2
        polyOrder = min(sgolayPolyOrder, smoothWindow - 1);
        ySmoothed = sgolayfilt(yFilled, polyOrder, smoothWindow);

    elseif exist("smoothdata", "file") == 2
        ySmoothed = smoothdata(yFilled, "movmean", smoothWindow);

    else
        kernel = ones(smoothWindow, 1) / smoothWindow;
        ySmoothed = conv(yFilled, kernel, "same");
    end

    ySmoothed(~finiteMask) = NaN;
    yOut = ySmoothed;
end
