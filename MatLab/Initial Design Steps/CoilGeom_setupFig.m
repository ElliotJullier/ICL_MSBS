function h = CoilGeom_setupFig(coil_shps)
% This function sets up the static plot objects: coil geometries and wind
% tunnel bounding box. It returns figure/axes handles and the static object
% handles so they can be reused for multiple field plots.
%
% ----- INPUTS -----
% coil_shps: cell array of coil shapes, e.g. {coil1_shp, coil3_shp, ...}
%
% ----- OUTPUTS -----
% h: struct containing figure/axes + handles to plotted geometry objects

% Create figure + axes
h.fig = figure;
h.ax  = axes('Parent', h.fig);

% Configure axes for 3D plotting
hold(h.ax, 'on');
axis(h.ax, 'equal');
axis(h.ax, 'vis3d');
box(h.ax, 'on');
grid(h.ax, 'on');
view(h.ax, 3);

% Ensure this axes is current before plotting alphaShapes
axes(h.ax);

% Plot all coil shapes (alphaShape objects)
h.coils = gobjects(numel(coil_shps), 1);
for k = 1:numel(coil_shps)
    % alphaShape plot does not reliably support plot(ax, shp) in many versions
    % so we set the axes current and call plot(shp)
    h.coils(k) = plot(coil_shps{k});
end

% Axis labels
xlabel(h.ax, "$x$ [m]", 'Interpreter','latex');
ylabel(h.ax, "$y$ [m]", 'Interpreter','latex');
zlabel(h.ax, "$z$ [m]", 'Interpreter','latex');

% Generate wind tunnel bounding box
plotcube([1.52 0.46 0.46], [-1.52/2, -0.46/2, -0.46/2], 0, [0 0 0]);

end
