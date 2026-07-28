%% plot_line_dBz_dz_offset_comparisons_v2.m
% Plotting script for vertical offset-line dBz/dz comparisons.
%
% Expected Q file from:
%   query_temp_line_dBz_dz_offsets.m
%
% Expected Q ordering:
%   Q{1} : COMSOL circular dBz/dz, x-z offset lines
%   Q{2} : COMSOL square dBz/dz, x-z offset lines
%   Q{3} : COMSOL square dBz/dz, diagonal offset lines
%
% Plot groups:
%   1) offset_group:
%      one plot per offset, comparing circular vs square x-z vs square diag
%
%   2) coil_group:
%      one plot per coil/line family, comparing all offsets
%
% Export folder structure:
%   Fig Exports/Offset_Comp/Line_Plots/offset_group/
%   Fig Exports/Offset_Comp/Line_Plots/coil_group/
%
% Filename convention:
%   grad_offset_group_0mm.svg
%   grad_coil_group_COMSOL_Circular.svg
%
% Style convention:
%   - colour = offset
%   - line style = coil/line family
%   - circular        : solid
%   - square x-z      : dashed
%   - square diagonal : dotted

clear; close all; clc;

%% ---------------------------- User settings --------------------------- %%
addpath(genpath("functs"));

qFile = fullfile(pwd, "Q outputs", "Q_Line_dBzDz_Offset_Comparisons2.mat");
if ~isfile(qFile)
    qFile = "/mnt/data/Q_Line_dBzDz_Offset_Comparisons.mat";
end

saveFigures = true;

exportBaseDir   = fullfile(pwd, "Fig Exports", "Morgan Setup", "Offset_Comp2", "Line_Plots");
offsetExportDir = fullfile(exportBaseDir, "offset_group");
coilExportDir   = fullfile(exportBaseDir, "coil_group");
exportExt       = ".png";

% Text sizing and weight.
axisTickFontSize = 16;
axisLabelFontSize = 19;
legendFontSize = 14;
textFontWeight = "bold";

% Axis-limit options:
%   "globalMax"   : symmetric y-limits from global absolute maximum
%   "percentile"  : symmetric y-limits from percentile(abs(data))
%   "manual"      : use manualYLims
yAxisLimitMode = "globalMax";
yPercentile = 99.7;
manualYLims = [-5, 5];    % [T/m], only used when yAxisLimitMode = "manual"
yPaddingFactor = 1.05;

% Smoothing settings.
% sgolayWindow = 1 is intentionally a no-op, but keeps the behaviour explicit.
sgolayWindow = 15;         % must be odd; 1 = no smoothing
sgolayPolyOrder = 3;

% Offset list and project offset colours from the overview script.
offsetList_mm = [0, 5, 10, 25, 50, 75];

offsetColors = [ ...
    0.08, 0.27, 0.44; ...
    0.10, 0.39, 0.56; ...
    0.14, 0.50, 0.64; ...
    0.18, 0.60, 0.67; ...
    0.28, 0.68, 0.60; ...
    0.49, 0.72, 0.46];

% Coil axial marker geometry [mm].
zCoilCentres_mm = [-90, 90];
coilHeight_mm = 60;

% Line family definitions.
caseShortNames = ["COMSOL_Circular", "COMSOL_Square_xz", "COMSOL_Square_diag"];
caseDisplayNames = ["COMSOL circular", "COMSOL square, x-z", "COMSOL square, diagonal"];
caseLineStyles = ["-", "--", ":"];

lineWidth = 1.8;

%% ------------------------------ Load Q ------------------------------- %%
if ~isfile(qFile)
    error("Could not find Q file: %s", qFile);
end

S = load(qFile, "Q");
Q = S.Q;
if ~iscell(Q)
    Q = {Q};
end

if numel(Q) < 3
    error("Expected at least three Q cases: circular, square x-z, square diagonal.");
end

%% -------------------------- Extract records -------------------------- %%
nCases = 3;
nOffsets = numel(offsetList_mm);

D = repmat(struct( ...
    "z_mm", [], ...
    "grad", [], ...
    "offset_mm", NaN, ...
    "caseShortName", "", ...
    "caseDisplayName", ""), nCases, nOffsets);

allGrad = [];
allZ = [];

for iCase = 1:nCases

    qcase = Q{iCase};

    results = qcase.results;
    queries = qcase.queries;

    if ~iscell(results)
        results = num2cell(results);
    end
    if ~iscell(queries)
        queries = num2cell(queries);
    end

    if numel(results) < nOffsets
        error("Q{%d} contains %d results, but %d offsets were expected.", ...
            iCase, numel(results), nOffsets);
    end

    for iOffset = 1:nOffsets

        r = results{iOffset};

        z_mm = 1e3 * double(r.Z(:));
        gVal = double(r.data(:));

        [z_mm, sortIdx] = sort(z_mm);
        gVal = gVal(sortIdx);

        gVal = localSmoothSgolay(gVal, sgolayWindow, sgolayPolyOrder);

        D(iCase, iOffset).z_mm = z_mm;
        D(iCase, iOffset).grad = gVal;
        D(iCase, iOffset).offset_mm = offsetList_mm(iOffset);
        D(iCase, iOffset).caseShortName = caseShortNames(iCase);
        D(iCase, iOffset).caseDisplayName = caseDisplayNames(iCase);

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

%% --------------------------- Tabbed figure --------------------------- %%
if saveFigures
    if ~exist(offsetExportDir, "dir")
        mkdir(offsetExportDir);
    end
    if ~exist(coilExportDir, "dir")
        mkdir(coilExportDir);
    end
end

mainFig = figure("Name", "Line dBz/dz offset comparisons", ...
    "NumberTitle", "off", ...
    "Color", "w", ...
    "Units", "pixels", ...
    "Position", [80, 80, 1050, 820]);

tabGroup = uitabgroup(mainFig);

%% ----------------------- Group 1: by offset -------------------------- %%
for iOffset = 1:nOffsets

    offset_mm = offsetList_mm(iOffset);
    thisColor = offsetColors(iOffset, :);

    tabName = sprintf("Offset group | grad | %g mm", offset_mm);
    fileName = sprintf("grad_offset_group_%gmm", offset_mm);

    tab = uitab(tabGroup, "Title", tabName);
    ax = axes("Parent", tab);

    localPrepareAxes(ax, xLims, yLims, axisTickFontSize, axisLabelFontSize, textFontWeight);
    localAddCoilAxialMarkers(ax, zCoilCentres_mm, coilHeight_mm, yLims);

    for iCase = 1:nCases
        plot(ax, D(iCase, iOffset).z_mm, D(iCase, iOffset).grad, ...
            "Color", thisColor, ...
            "LineStyle", caseLineStyles(iCase), ...
            "LineWidth", lineWidth, ...
            "DisplayName", caseDisplayNames(iCase));
    end

    xlabel(ax, '$\mathbf{z}~[\mathbf{mm}]$');
    ylabel(ax, '$\mathbf{\partial B_z/\partial z}~[\mathbf{T\,m^{-1}}]$');

    leg = legend(ax, "Location", "best");
    leg.Interpreter = "latex";
    leg.FontSize = legendFontSize;
    leg.FontWeight = textFontWeight;
    leg.ItemTokenSize = [28, 18];
    leg.Box = "off";

    if saveFigures
        exportFile = fullfile(offsetExportDir, fileName + exportExt);
        exportgraphics(ax, exportFile, "ContentType", "vector");
    end
end

%% ---------------------- Group 2: by coil family ---------------------- %%
for iCase = 1:nCases

    tabName = sprintf("Coil group | grad | %s", strrep(caseDisplayNames(iCase), ",", ""));
    fileName = sprintf("grad_coil_group_%s", caseShortNames(iCase));

    tab = uitab(tabGroup, "Title", tabName);
    ax = axes("Parent", tab);

    localPrepareAxes(ax, xLims, yLims, axisTickFontSize, axisLabelFontSize, textFontWeight);
    localAddCoilAxialMarkers(ax, zCoilCentres_mm, coilHeight_mm, yLims);

    for iOffset = 1:nOffsets
        offset_mm = offsetList_mm(iOffset);
        thisColor = offsetColors(iOffset, :);

        plot(ax, D(iCase, iOffset).z_mm, D(iCase, iOffset).grad, ...
            "Color", thisColor, ...
            "LineStyle", caseLineStyles(iCase), ...
            "LineWidth", lineWidth, ...
            "DisplayName", sprintf('%g mm', offset_mm));
    end

    xlabel(ax, '$\mathbf{z}~[\mathbf{mm}]$');
    ylabel(ax, '$\mathbf{\partial B_z/\partial z}~[\mathbf{T\,m^{-1}}]$');

    leg = legend(ax, "Location", "best");
    leg.Interpreter = "latex";
    leg.FontSize = legendFontSize;
    leg.FontWeight = textFontWeight;
    leg.ItemTokenSize = [28, 18];
    leg.Box = "off";

    if saveFigures
        exportFile = fullfile(coilExportDir, fileName + exportExt);
        exportgraphics(ax, exportFile, "ContentType", "vector");
    end
end

%% -------------------------- Local functions -------------------------- %%
function localPrepareAxes(ax, xLims, yLims, ...
    axisTickFontSize, axisLabelFontSize, textFontWeight)

    hold(ax, "on");
    box(ax, "on");
    grid(ax, "on");

    ax.GridAlpha = 0.16;
    ax.MinorGridAlpha = 0.08;
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

    xlim(ax, xLims);
    ylim(ax, yLims);
end

function localAddCoilAxialMarkers(ax, zCoilCentres_mm, coilHeight_mm, yLims)
% Add subtle vertical bands showing the axial extent of the coils.
% This marks where the vertical sampling lines pass through/near the coil
% axial positions without adding filled coil cross-sections to a line plot.

    y0 = yLims(1);
    y1 = yLims(2);

    bandColor = [0.82, 0.82, 0.82];
    centreLineColor = [0.42, 0.42, 0.42];

    for k = 1:numel(zCoilCentres_mm)
        zc = zCoilCentres_mm(k);
        zA = zc - 0.5 * coilHeight_mm;
        zB = zc + 0.5 * coilHeight_mm;

        patch(ax, [zA zB zB zA], [y0 y0 y1 y1], bandColor, ...
            "FaceAlpha", 0.4, ...
            "EdgeColor", "none", ...
            "HandleVisibility", "off");

        line(ax, [zc zc], [y0 y1], ...
            "Color", centreLineColor, ...
            "LineStyle", ":", ...
            "LineWidth", 1.3, ...
            "HandleVisibility", "off");
    end
end

function yOut = localSmoothSgolay(yIn, sgolayWindow, sgolayPolyOrder)
% Smooth only for plotting. sgolayWindow = 1 gives a deliberate no-op.

    yOut = yIn(:);

    if sgolayWindow <= 1
        return
    end

    sgolayWindow = round(sgolayWindow);
    if mod(sgolayWindow, 2) == 0
        sgolayWindow = sgolayWindow + 1;
    end

    finiteMask = isfinite(yOut);
    if nnz(finiteMask) < sgolayWindow
        return
    end

    % Fill gaps temporarily so smoothing can operate.
    idx = (1:numel(yOut)).';
    yFilled = yOut;
    
    if any(~finiteMask)
        yFilled(~finiteMask) = interp1( ...
            idx(finiteMask), yOut(finiteMask), idx(~finiteMask), ...
            "linear", "extrap");
    end
    
    if exist("sgolayfilt", "file") == 2
        % Signal Processing Toolbox available.
        polyOrder = min(sgolayPolyOrder, sgolayWindow - 1);
        ySmoothed = sgolayfilt(yFilled, polyOrder, sgolayWindow);
    
    elseif exist("smoothdata", "file") == 2
        % Base/fallback smoothing.
        % This is not true Savitzky-Golay unless your MATLAB supports
        % smoothdata(...,"sgolay",...), so use moving mean as a robust fallback.
        ySmoothed = smoothdata(yFilled, "movmean", sgolayWindow);
    
    else
        % Last-resort fallback with no toolbox dependency.
        kernel = ones(sgolayWindow, 1) / sgolayWindow;
        ySmoothed = conv(yFilled, kernel, "same");
    end
    
    % Preserve original NaN locations.
    ySmoothed(~finiteMask) = NaN;
    yOut = ySmoothed;
end
