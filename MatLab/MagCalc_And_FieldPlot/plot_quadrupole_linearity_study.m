%% plot_quadrupole_linearity_study.m
% Plot script for Q_Quadrupole_Linearity_Study.mat
%
% Figures produced:
%   1) Planar Bz, quadrupole + PM
%   2) Planar Bz residual nonlinearity
%   3) Line dBz/dz comparison:
%        - quadrupole + PM
%        - quadrupole only
%        - PM only
%        - quadrupole only + PM only
%
% Export folder:
%   Fig Exports/Quadrupole Linearity/

clear; close all; clc;

%% ---------------------------- User settings --------------------------- %%
addpath(genpath("functs"));

qFile = fullfile(pwd, "Q outputs", "Q_Quadrupole_Linearity_Study.mat");
if ~isfile(qFile)
    qFile = "/mnt/data/Q_Quadrupole_Linearity_Study.mat";
end

saveFigures = false;
exportDir = fullfile(pwd, "Fig Exports", "Quadrupole Linearity");

% Text settings.
axisTickFontSize = 16;
axisLabelFontSize = 19;
legendFontSize = 14;
colorbarTickFontSize = 15;
colorbarLabelFontSize = 18;
textFontWeight = "bold";

% Plane colour limits.
planeAbsLimitMode = "percentile";
planeAbsPercentile = 99.0;
planeAbsManual = [-0.05, 0.05];  % [T]

planeResidualLimitMode = "percentile";
planeResidualPercentile = 99.0;
planeResidualManual = [-1e-3, 1e-3]; % [T]

% Line colour limits / style.
lineAxisLimitMode = "percentile";
linePercentile = 99.5;
lineManual = [-5, 5];  % [T/m]
linePaddingFactor = 1.05;

% Plot-time smoothing for line plots.
smoothWindow = 1;
sgolayPolyOrder = 2;

% Geometry for overlays.
magnetRadius_m = 0.05;
magnetHeight_m = 0.2;
magnetCenter_x_m = 0.0;
magnetCenter_z_m = 0.0;

coilOuterLength_m = 0.6;
coilInnerLength_m = 0.45;
coilHeight_m = 0.2;

xCoilCentres_m = [-0.5, 0.5];
zCoilCentres_m = [-0.7, 0.7];

coilColors = [ ...
    0.08, 0.27, 0.44; ... % bottom-left
    0.49, 0.72, 0.46; ... % bottom-right
    0.86, 0.55, 0.14; ... % top-left
    0.55, 0.35, 0.64];    % top-right

magnetColor = [0, 0, 0];
coilFaceAlpha = 0.28;
coilLineWidth = 1.6;
magnetFaceAlpha = 1.0;

% Line-case styling.
lineCaseOrder = [1, 2, 3, 4];
lineCaseColors = [ ...
    0.08, 0.27, 0.44; ... % quadrupole + PM
    0.56, 0.68, 0.54; ... % quadrupole only
    0.0,  0.0,  0.0; ...  % PM only
    0.55, 0.35, 0.64];    % sum
lineCaseStyles = ["-", "--", "-.", ":"];
lineCaseNames = [ ...
    "Quadrupole + PM", ...
    "Quadrupole only", ...
    "PM only", ...
    "Quadrupole only + PM only"];

%% ------------------------------ Load Q ------------------------------- %%
if ~isfile(qFile)
    error("Could not find Q file: %s", qFile);
end

S = load(qFile, "Q");
Q = S.Q;
if ~iscell(Q)
    Q = {Q};
end

if numel(Q) < 6
    error("Expected at least six Q cases.");
end

%% ------------------------- Extract results --------------------------- %%
% Case map:
%   1 : quadrupole + PM
%   2 : quadrupole only
%   3 : PM only
%   4 : sum
%   5 : reconstructed coils
%   6 : residual

planePMz = Q{1}.results{1};
planeResidual = Q{6}.results{1};

lineCases = struct([]);
for k = 1:numel(lineCaseOrder)
    idx = lineCaseOrder(k);
    r = Q{idx}.results{2};

    z_mm = 1e3 * double(r.Z(:));
    gVal = double(r.data(:));

    [z_mm, sortIdx] = sort(z_mm);
    gVal = gVal(sortIdx);
    gVal = localSmoothGradientForPlotting(gVal, smoothWindow, sgolayPolyOrder);

    lineCases(k).z_mm = z_mm;
    lineCases(k).grad = gVal;
    lineCases(k).name = lineCaseNames(k);
    lineCases(k).color = lineCaseColors(k,:);
    lineCases(k).style = lineCaseStyles(k);
end

%% ---------------------- Determine plot limits ------------------------ %%
absPlaneVals = planePMz.data(isfinite(planePMz.data));
resPlaneVals = planeResidual.data(isfinite(planeResidual.data));

cLimAbs = localResolveSymmetricLimits(abs(absPlaneVals), ...
    planeAbsLimitMode, planeAbsPercentile, planeAbsManual);

cLimResidual = localResolveSymmetricLimits(abs(resPlaneVals), ...
    planeResidualLimitMode, planeResidualPercentile, planeResidualManual);

allGrad = [];
for k = 1:numel(lineCases)
    allGrad = [allGrad; lineCases(k).grad(isfinite(lineCases(k).grad))]; %#ok<AGROW>
end

yLims = localResolveSymmetricLimits(abs(allGrad), ...
    lineAxisLimitMode, linePercentile, lineManual);
yLims = linePaddingFactor * yLims;

%% ---------------------------- Export dir ----------------------------- %%
if saveFigures && ~exist(exportDir, "dir")
    mkdir(exportDir);
end

%% -------------------------- Figure 1: PMz ---------------------------- %%
fig1 = figure( ...
    "Name", "Quadrupole + PM | Planar Bz", ...
    "NumberTitle", "off", ...
    "Color", "w", ...
    "Units", "pixels", ...
    "Position", [80, 80, 980, 760]);

ax1 = axes(fig1);
localPreparePlaneAxes(ax1, axisTickFontSize, axisLabelFontSize, textFontWeight);

x_mm = 1e3 * planePMz.X;
z_mm = 1e3 * planePMz.Z;

surf(ax1, x_mm, z_mm, zeros(size(planePMz.data)), double(planePMz.data), ...
    "EdgeColor", "none", "FaceColor", "interp");
view(ax1, 2);
axis(ax1, "xy");
axis(ax1, "equal");
xlim(ax1, 1e3 * [min(planePMz.X(:)), max(planePMz.X(:))]);
ylim(ax1, 1e3 * [min(planePMz.Z(:)), max(planePMz.Z(:))]);

localApplyProjectColorbar(ax1, cLimAbs, '$\mathbf{B}_z~[\mathbf{T}]$', ...
    colorbarTickFontSize, colorbarLabelFontSize, textFontWeight);

localDrawQuadrupoleOverlays(ax1, xCoilCentres_m, zCoilCentres_m, ...
    coilOuterLength_m, coilInnerLength_m, coilHeight_m, ...
    coilColors, coilFaceAlpha, coilLineWidth, ...
    magnetCenter_x_m, magnetCenter_z_m, magnetRadius_m, magnetHeight_m, ...
    magnetColor, magnetFaceAlpha);

xlabel(ax1, '$\mathbf{x}~[\mathbf{mm}]$');
ylabel(ax1, '$\mathbf{z}~[\mathbf{mm}]$');

if saveFigures
    exportgraphics(fig1, fullfile(exportDir, "Quadrupole_PMz_Bz_Plane.svg"), "ContentType", "vector");
end

%% ------------------------ Figure 2: residual ------------------------- %%
fig2 = figure( ...
    "Name", "Residual nonlinearity | Planar Bz", ...
    "NumberTitle", "off", ...
    "Color", "w", ...
    "Units", "pixels", ...
    "Position", [120, 120, 980, 760]);

ax2 = axes(fig2);
localPreparePlaneAxes(ax2, axisTickFontSize, axisLabelFontSize, textFontWeight);

surf(ax2, x_mm, z_mm, zeros(size(planeResidual.data)), double(planeResidual.data), ...
    "EdgeColor", "none", "FaceColor", "interp");
view(ax2, 2);
axis(ax2, "xy");
axis(ax2, "equal");
xlim(ax2, 1e3 * [min(planeResidual.X(:)), max(planeResidual.X(:))]);
ylim(ax2, 1e3 * [min(planeResidual.Z(:)), max(planeResidual.Z(:))]);

localApplyProjectColorbar(ax2, cLimResidual, '$\mathbf{B}_z~[\mathbf{T}]$', ...
    colorbarTickFontSize, colorbarLabelFontSize, textFontWeight);

localDrawQuadrupoleOverlays(ax2, xCoilCentres_m, zCoilCentres_m, ...
    coilOuterLength_m, coilInnerLength_m, coilHeight_m, ...
    coilColors, coilFaceAlpha, coilLineWidth, ...
    magnetCenter_x_m, magnetCenter_z_m, magnetRadius_m, magnetHeight_m, ...
    magnetColor, magnetFaceAlpha);

xlabel(ax2, '$\mathbf{x}~[\mathbf{mm}]$');
ylabel(ax2, '$\mathbf{z}~[\mathbf{mm}]$');

if saveFigures
    exportgraphics(fig2, fullfile(exportDir, "Quadrupole_Linearity_Residual_Bz_Plane.svg"), "ContentType", "vector");
end

%% ----------------------- Figure 3: line plot ------------------------- %%
fig3 = figure( ...
    "Name", "Quadrupole linearity | dBz/dz centreline", ...
    "NumberTitle", "off", ...
    "Color", "w", ...
    "Units", "pixels", ...
    "Position", [160, 160, 980, 700]);

ax3 = axes(fig3);
localPrepareLineAxes(ax3, axisTickFontSize, axisLabelFontSize, textFontWeight, ...
    [min(lineCases(1).z_mm), max(lineCases(1).z_mm)], yLims);

localAddCoilHeightBands(ax3, 1e3*zCoilCentres_m, 1e3*coilHeight_m, yLims);

for k = 1:numel(lineCases)
    plot(ax3, lineCases(k).z_mm, lineCases(k).grad, ...
        "Color", lineCases(k).color, ...
        "LineStyle", lineCases(k).style, ...
        "LineWidth", 1.8, ...
        "DisplayName", lineCases(k).name);
end

xlabel(ax3, '$\mathbf{z}~[\mathbf{mm}]$');
ylabel(ax3, '$\mathbf{\partial B_z/\partial z}~[\mathbf{T\,m^{-1}}]$');

leg = legend(ax3, "Location", "best");
leg.Interpreter = "latex";
leg.FontSize = legendFontSize;
leg.FontWeight = textFontWeight;
leg.ItemTokenSize = [28, 18];
leg.Box = "off";

if saveFigures
    exportgraphics(fig3, fullfile(exportDir, "Quadrupole_Linearity_dBzDz_Line.svg"), "ContentType", "vector");
end

%% -------------------------- Local functions -------------------------- %%
function lims = localResolveSymmetricLimits(absValues, mode, percentileVal, manualLims)

    absValues = absValues(isfinite(absValues));

    switch lower(string(mode))
        case "globalmax"
            maxAbs = max(absValues);
            lims = [-maxAbs, maxAbs];

        case "percentile"
            maxAbs = prctile(absValues, percentileVal);
            lims = [-maxAbs, maxAbs];

        case "manual"
            lims = manualLims;

        otherwise
            error("Unknown limit mode: %s", mode);
    end
end

function localPreparePlaneAxes(ax, axisTickFontSize, axisLabelFontSize, textFontWeight)

    hold(ax, "on");
    box(ax, "on");
    grid(ax, "on");
    ax.Layer = "top";
    ax.GridAlpha = 0.20;
    ax.MinorGridAlpha = 0.10;
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
end

function cb = localApplyProjectColorbar(ax, cLims, labelStr, tickFontSize, labelFontSize, textFontWeight)

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
    cb.FontWeight = textFontWeight;
    cb.Label.String = labelStr;
    cb.Label.Interpreter = "latex";
    cb.Label.FontSize = labelFontSize;
    cb.Label.FontWeight = textFontWeight;
end

function localDrawQuadrupoleOverlays(ax, xCoilCentres_m, zCoilCentres_m, ...
    outerLength_m, innerLength_m, coilHeight_m, ...
    coilColors, faceAlpha, lineWidth, ...
    magnetCenter_x_m, magnetCenter_z_m, magnetRadius_m, magnetHeight_m, ...
    magnetColor, magnetFaceAlpha)

    outerHalf = outerLength_m / 2;
    innerHalf = innerLength_m / 2;
    zHalf = coilHeight_m / 2;

    idx = 0;
    for iz = 1:numel(zCoilCentres_m)
        for ix = 1:numel(xCoilCentres_m)
            idx = idx + 1;
            xc = xCoilCentres_m(ix);
            zc = zCoilCentres_m(iz);
            clr = coilColors(idx,:);

            % Left conductor block.
            localDrawRect(ax, ...
                [1e3*(xc - outerHalf), 1e3*(zc - zHalf), 1e3*(outerHalf - innerHalf), 1e3*coilHeight_m], ...
                clr, clr, faceAlpha, lineWidth, "-");

            % Right conductor block.
            localDrawRect(ax, ...
                [1e3*(xc + innerHalf), 1e3*(zc - zHalf), 1e3*(outerHalf - innerHalf), 1e3*coilHeight_m], ...
                clr, clr, faceAlpha, lineWidth, "-");
        end
    end

    % Magnet rectangle.
    localDrawRect(ax, ...
        [1e3*(magnetCenter_x_m - magnetRadius_m), 1e3*(magnetCenter_z_m - magnetHeight_m/2), ...
         1e3*(2*magnetRadius_m), 1e3*magnetHeight_m], ...
        magnetColor, magnetColor, magnetFaceAlpha, 1.6, "-");
end

function localDrawRect(ax, pos, faceClr, edgeClr, faceAlpha, lineWidth, lineStyle)

    rectangle(ax, ...
        "Position", pos, ...
        "FaceColor", [faceClr, faceAlpha], ...
        "EdgeColor", edgeClr, ...
        "LineWidth", lineWidth, ...
        "LineStyle", lineStyle);
end

function localPrepareLineAxes(ax, axisTickFontSize, axisLabelFontSize, textFontWeight, xLims, yLims)

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

function localAddCoilHeightBands(ax, zCoilCentres_mm, coilHeight_mm, yLims)

    y0 = yLims(1);
    y1 = yLims(2);

    bandColor = [0.82, 0.82, 0.82];
    centreLineColor = [0.42, 0.42, 0.42];

    for k = 1:numel(zCoilCentres_mm)
        zc = zCoilCentres_mm(k);
        zA = zc - 0.5 * coilHeight_mm;
        zB = zc + 0.5 * coilHeight_mm;

        patch(ax, [zA zB zB zA], [y0 y0 y1 y1], bandColor, ...
            "FaceAlpha", 0.35, ...
            "EdgeColor", "none", ...
            "HandleVisibility", "off");

        line(ax, [zc zc], [y0 y1], ...
            "Color", centreLineColor, ...
            "LineStyle", ":", ...
            "LineWidth", 1.1, ...
            "HandleVisibility", "off");
    end
end

function yOut = localSmoothGradientForPlotting(yIn, smoothWindow, sgolayPolyOrder)

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
