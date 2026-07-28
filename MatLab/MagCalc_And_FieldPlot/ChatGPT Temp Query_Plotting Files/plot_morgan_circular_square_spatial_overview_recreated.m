%% plot_morgan_circular_square_spatial_overview_recreated.m
% Recreate the circular-versus-square Morgan spatial sampling overview.
%
% Preferred input:
%   Q outputs/Q_Morgan_Spatial_Overview.mat
%
% Fallback input:
%   Datasets/MorganSetup_FullBS.mat
%
% The dataset contains two circular coils. This script:
%   - uses the actual upper circular coil mesh
%   - replaces the lower circular coil visually with a representative square
%     annular coil having the same outer width, inner width, height, and pose
%   - draws the centreline, x-z offset lines, diagonal offset lines, and
%     reference half-planes
%
% Export:
%   Fig Exports/Morgan Setup/Circular_v_Square_Spatial_Overview.svg

clear; close all; clc;
addpath(genpath("functs"));

%% --------------------------- User settings ---------------------------- %%
qFile = fullfile(pwd, "Q outputs", "Q_Morgan_Spatial_Overview.mat");
datasetFile = fullfile(pwd, "Datasets", "MorganSetup_FullBS.mat");

zLine_mm = [-120, 120];
offsetList_mm = [0, 5, 10, 25, 50, 75];

figName = "Circular_v_Square_Spatial_Overview";

saveFig = true;
exportDir = fullfile(pwd, "Fig Exports", "Morgan Setup");
exportName = "Circular_v_Square_Spatial_Overview.png";

%% ------------------------------ Styling ------------------------------ %%
samplingLineWidth = 3;

% Text sizing and weight.
axisTickFontSize = 16;
axisLabelFontSize = 19;
legendFontSize = 14;
textFontWeight = "bold";

% Project-style circular coil green.
circularCoilFaceColor = [0.56, 0.68, 0.54];
circularCoilEdgeColor = 0.55 * circularCoilFaceColor;
circularCoilFaceAlpha = 0.55;

% Representative square coil blue.
squareCoilFaceColor = [0.23, 0.40, 0.67];
squareCoilEdgeColor = [0.11, 0.24, 0.46];
squareCoilFaceAlpha = 0.55;

% Reference planes.
planeXZColor   = [0.65, 0.79, 0.92];
planeDiagColor = [0.79, 0.85, 0.93];
planeEdgeColor = [0.45, 0.52, 0.60];
planeAlpha = 0.8;

centrelineColor = [0.08, 0.08, 0.08];

offsetColors = [ ...
    0.08, 0.27, 0.44; ...
    0.10, 0.39, 0.56; ...
    0.14, 0.50, 0.64; ...
    0.18, 0.60, 0.67; ...
    0.28, 0.68, 0.60; ...
    0.49, 0.72, 0.46];

%% --------------------------- Load geometry --------------------------- %%
if isfile(qFile)
    S = load(qFile, "Q");
    Q = S.Q;

    if iscell(Q)
        thisCase = Q{1};
    else
        thisCase = Q(1);
    end

    g = thisCase.geometry;
    fprintf("Loaded geometry from:\n  %s\n", qFile);

else
    if ~isfile(datasetFile)
        altPath = "/mnt/data/MorganSetup_FullBS.mat";
        if isfile(altPath)
            datasetFile = altPath;
        else
            error([ ...
                "Could not find either:\n  %s\nor:\n  %s"], ...
                qFile, datasetFile);
        end
    end

    dataset = load_field_dataset(datasetFile);
    g = dataset.geometry;
    fprintf("Loaded geometry directly from:\n  %s\n", datasetFile);
end

coilArray = g.coil;
if ~iscell(coilArray)
    coilArray = num2cell(coilArray);
end

if numel(coilArray) < 2
    error("The geometry must contain at least two coils.");
end

coilTop = coilArray{1};
coilBottomSource = coilArray{2};

Vtop_m = double(coilTop.shape.Vertices);
Ftop = double(coilTop.shape.Faces);

% Infer dimensions from the actual upper circular coil mesh.
radialTop_m = hypot(Vtop_m(:,1), Vtop_m(:,2));
outerRadius_m = max(radialTop_m);
positiveRadial = radialTop_m(radialTop_m > 1e-9);
innerRadius_m = min(positiveRadial);
coilHeight_m = max(Vtop_m(:,3)) - min(Vtop_m(:,3));

outerWidth_m = 2 * outerRadius_m;
innerWidth_m = 2 * innerRadius_m;

poseBottom = localGetPose(coilBottomSource);
[FbottomSquare, VbottomSquare_m] = localMakeSquareCoil( ...
    outerWidth_m, innerWidth_m, coilHeight_m, poseBottom);

fprintf("Extracted Morgan geometry:\n");
fprintf("  outer radius = %.3f mm\n", 1e3*outerRadius_m);
fprintf("  inner radius = %.3f mm\n", 1e3*innerRadius_m);
fprintf("  coil height  = %.3f mm\n", 1e3*coilHeight_m);
poseTop = localGetPose(coilTop);
fprintf("  top centre z = %.3f mm\n", 1e3*poseTop(3));
fprintf("  bottom centre z = %.3f mm\n", 1e3*poseBottom(3));

% Convert geometry to mm for plotting.
Vtop = 1e3 * Vtop_m;
VbottomSquare = 1e3 * VbottomSquare_m;
outerRadius_mm = 1e3 * outerRadius_m;

%% ----------------------- Derived plotting ranges ---------------------- %%
maxOffset_mm = max(offsetList_mm);
planeHalfSpan_mm = maxOffset_mm + 20;

xLim_mm = 1.15 * [-planeHalfSpan_mm, planeHalfSpan_mm];
yLim_mm = xLim_mm;
zLim_mm = 1.05 * zLine_mm;

zPlot = linspace(zLine_mm(1), zLine_mm(2), 200).';

%% ------------------------------- Figure ------------------------------ %%
fig = figure( ...
    "Name", figName, ...
    "NumberTitle", "off", ...
    "Color", "w", ...
    "Units", "pixels", ...
    "Position", [120, 80, 1180, 860]);

ax = axes(fig);
hold(ax, "on");
axis(ax, "equal");
box(ax, "on");
grid(ax, "on");

ax.GridAlpha = 0.10;
ax.MinorGridAlpha = 0.06;
ax.LineWidth = 1.2;
ax.FontSize = axisTickFontSize;
ax.FontWeight = textFontWeight;
ax.TickLabelInterpreter = "latex";

ax.XAxis.Label.Interpreter = "latex";
ax.YAxis.Label.Interpreter = "latex";
ax.ZAxis.Label.Interpreter = "latex";

ax.XAxis.Label.FontSize = axisLabelFontSize;
ax.YAxis.Label.FontSize = axisLabelFontSize;
ax.ZAxis.Label.FontSize = axisLabelFontSize;

ax.XAxis.Label.FontWeight = textFontWeight;
ax.YAxis.Label.FontWeight = textFontWeight;
ax.ZAxis.Label.FontWeight = textFontWeight;

% Upper actual circular coil.
hTop = patch(ax, ...
    "Faces", Ftop, ...
    "Vertices", Vtop, ...
    "FaceColor", circularCoilFaceColor, ...
    "EdgeColor", circularCoilEdgeColor, ...
    "FaceAlpha", circularCoilFaceAlpha, ...
    "LineWidth", 0.8, ...
    "DisplayName", "Top circular coil");

% Lower representative square coil.
hBottom = patch(ax, ...
    "Faces", FbottomSquare, ...
    "Vertices", VbottomSquare, ...
    "FaceColor", squareCoilFaceColor, ...
    "EdgeColor", squareCoilEdgeColor, ...
    "FaceAlpha", squareCoilFaceAlpha, ...
    "LineWidth", 0.8, ...
    "DisplayName", "Bottom representative square coil");

%% --------------------------- Sampling planes -------------------------- %%
% x-z half-plane: y = 0 and x >= 0.
xPlane = [0, planeHalfSpan_mm; 0, planeHalfSpan_mm];
yPlane = [0, 0; 0, 0];
zPlane = [zLine_mm(1), zLine_mm(1); zLine_mm(2), zLine_mm(2)];

hPlaneXZ = surf(ax, xPlane, yPlane, zPlane, ...
    "FaceColor", planeXZColor, ...
    "EdgeColor", planeEdgeColor, ...
    "FaceAlpha", planeAlpha, ...
    "LineStyle", "-", ...
    "DisplayName", "$x$--$z$ half-plane ($y=0$, $x\geq0$)");

% Diagonal-z half-plane: x = -y and x <= 0.
uPlane = [-planeHalfSpan_mm, 0; -planeHalfSpan_mm, 0];
xDiagPlane = uPlane / sqrt(2);
yDiagPlane = -uPlane / sqrt(2);
zDiagPlane = [zLine_mm(1), zLine_mm(1); zLine_mm(2), zLine_mm(2)];

hPlaneDiag = surf(ax, xDiagPlane, yDiagPlane, zDiagPlane, ...
    "FaceColor", planeDiagColor, ...
    "EdgeColor", planeEdgeColor, ...
    "FaceAlpha", planeAlpha, ...
    "LineStyle", "-", ...
    "DisplayName", "Diagonal-$z$ half-plane ($x=-y$, $x\leq0$)");

%% ---------------------------- Sampling lines -------------------------- %%
hCentre = plot3(ax, ...
    zeros(size(zPlot)), zeros(size(zPlot)), zPlot, "-", ...
    "Color", centrelineColor, ...
    "LineWidth", samplingLineWidth, ...
    "DisplayName", localOffsetLabel(0, outerRadius_mm, true));

legendHandles = [hTop, hBottom, hPlaneXZ, hPlaneDiag, hCentre];

% x-z off-axis lines: x = r, y = 0.
for k = 2:numel(offsetList_mm)
    r_mm = offsetList_mm(k);
    thisColor = offsetColors(k,:);

    hLineXZ = plot3(ax, ...
        r_mm*ones(size(zPlot)), zeros(size(zPlot)), zPlot, "--", ...
        "Color", thisColor, ...
        "LineWidth", samplingLineWidth, ...
        "DisplayName", localOffsetLabel(r_mm, outerRadius_mm, false));

    legendHandles(end+1) = hLineXZ; %#ok<SAGROW>
end

% Diagonal-z lines: x = -r/sqrt(2), y = +r/sqrt(2).
for k = 2:numel(offsetList_mm)
    r_mm = offsetList_mm(k);
    thisColor = offsetColors(k,:);

    xDiag = (-r_mm/sqrt(2))*ones(size(zPlot));
    yDiag = ( r_mm/sqrt(2))*ones(size(zPlot));

    plot3(ax, xDiag, yDiag, zPlot, ":", ...
        "Color", thisColor, ...
        "LineWidth", samplingLineWidth, ...
        "HandleVisibility", "off");
end

hDiagKey = plot3(ax, NaN, NaN, NaN, ":", ...
    "Color", 0.25*[1 1 1], ...
    "LineWidth", samplingLineWidth, ...
    "DisplayName", "Diagonal off-axis lines: same offsets, dotted");

legendHandles(end+1) = hDiagKey;

%% --------------------------- Axes and legend -------------------------- %%
xlabel(ax, "$\mathbf{x}~[\mathbf{mm}]$");
ylabel(ax, "$\mathbf{y}~[\mathbf{mm}]$");
zlabel(ax, "$\mathbf{z}~[\mathbf{mm}]$");

xlim(ax, xLim_mm);
ylim(ax, yLim_mm);
zlim(ax, zLim_mm);

view(ax, -15, 21);

lgd = legend(ax, legendHandles, ...
    "Location", "eastoutside", ...
    "Interpreter", "latex");

lgd.FontSize = legendFontSize;
lgd.FontWeight = textFontWeight;
lgd.ItemTokenSize = [28, 18];

%% ----------------------------- Export -------------------------------- %%
if saveFig
    if ~exist(exportDir, "dir")
        mkdir(exportDir);
    end

    exportFile = fullfile(exportDir, exportName);
    exportgraphics(fig, exportFile, "ContentType", "vector");
    fprintf("Saved overview figure to:\n  %s\n", exportFile);
end

%% ---------------------------- Local functions ------------------------- %%
function pose = localGetPose(coil)

    if isfield(coil, "pose")
        pose = double(coil.pose(:).');
    else
        pose = [0 0 0 0 0 0];
    end

    if numel(pose) < 6
        pose = [pose, zeros(1, 6-numel(pose))];
    end
end

function labelText = localOffsetLabel(offset_mm, outerRadius_mm, isCentreline)

    rStar = offset_mm / outerRadius_mm;

    if isCentreline
        labelText = sprintf( ...
            "Centreline / %d mm offset ($r^*=%.2f$)", ...
            round(offset_mm), rStar);
    else
        labelText = sprintf( ...
            "%d mm offset ($r^*=%.2f$)", ...
            round(offset_mm), rStar);
    end
end

function [F, V] = localMakeSquareCoil(outerWidth_m, innerWidth_m, height_m, pose)
% Square annular prism aligned with axes, then rotated and translated.

    hwO = outerWidth_m / 2;
    hwI = innerWidth_m / 2;
    hz  = height_m / 2;

    zb = -hz;
    zt =  hz;

    ob = [-hwO -hwO zb;  hwO -hwO zb;  hwO  hwO zb; -hwO  hwO zb];
    ot = [-hwO -hwO zt;  hwO -hwO zt;  hwO  hwO zt; -hwO  hwO zt];
    ib = [-hwI -hwI zb;  hwI -hwI zb;  hwI  hwI zb; -hwI  hwI zb];
    it = [-hwI -hwI zt;  hwI -hwI zt;  hwI  hwI zt; -hwI  hwI zt];

    V = [ob; ot; ib; it];

    OBi = 1:4;
    OTi = 5:8;
    IBi = 9:12;
    ITi = 13:16;

    Ftop = [ ...
        OTi(1) OTi(2) ITi(2) ITi(1);
        OTi(2) OTi(3) ITi(3) ITi(2);
        OTi(3) OTi(4) ITi(4) ITi(3);
        OTi(4) OTi(1) ITi(1) ITi(4)];

    Fbottom = [ ...
        OBi(1) IBi(1) IBi(2) OBi(2);
        OBi(2) IBi(2) IBi(3) OBi(3);
        OBi(3) IBi(3) IBi(4) OBi(4);
        OBi(4) IBi(4) IBi(1) OBi(1)];

    Fouter = [ ...
        OBi(1) OBi(2) OTi(2) OTi(1);
        OBi(2) OBi(3) OTi(3) OTi(2);
        OBi(3) OBi(4) OTi(4) OTi(3);
        OBi(4) OBi(1) OTi(1) OTi(4)];

    Finner = [ ...
        IBi(2) IBi(1) ITi(1) ITi(2);
        IBi(3) IBi(2) ITi(2) ITi(3);
        IBi(4) IBi(3) ITi(3) ITi(4);
        IBi(1) IBi(4) ITi(4) ITi(1)];

    F = [Ftop; Fbottom; Fouter; Finner];

    R = localRotationMatrixXYZ(pose(4:6));
    V = (R*V.').';
    V = V + pose(1:3);
end

function R = localRotationMatrixXYZ(angles)

    rx = angles(1);
    ry = angles(2);
    rz = angles(3);

    Rx = [1 0 0; 0 cos(rx) -sin(rx); 0 sin(rx) cos(rx)];
    Ry = [cos(ry) 0 sin(ry); 0 1 0; -sin(ry) 0 cos(ry)];
    Rz = [cos(rz) -sin(rz) 0; sin(rz) cos(rz) 0; 0 0 1];

    R = Rz*Ry*Rx;
end
