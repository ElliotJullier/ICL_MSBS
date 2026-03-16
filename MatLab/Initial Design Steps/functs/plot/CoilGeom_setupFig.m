function h = CoilGeom_setupFig(coils)
% This function sets up the static plot objects: coil geometries and wind
% tunnel bounding box. It returns figure/axes handles and the static object
% handles so they can be reused for multiple field plots.
%
% ----- INPUTS -----
% coils: struct array loaded from coilfield_run*.mat containing at least:
%   - shp: alphaShape object
%   - rel_pos: 6x1 pose [x;y;z;yaw;pitch;roll]
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

nCoils = numel(coils);

% Plot handles
h.coils      = gobjects(nCoils, 1);
h.axisArrows = gobjects(nCoils, 1);

scale = 0.25; % arrow length scaling (adjust if desired)

for k = 1:nCoils

    % Plot alphaShape
    h.coils(k) = plot(coils(k).shp);

    % Plot coil +Z direction arrow using rel_pos
    rel_pos = coils(k).rel_pos(:).';   % ensure 1x6
    centre  = rel_pos(1:3);

    ez_local  = [0;0;1];

    % Pure rotation only (zero translation)
    ez_global = coord_local2global(ez_local, [0 0 0 rel_pos(4:6)]);

    % h.axisArrows(k) = quiver3(centre(1), centre(2), centre(3), ...
    %     scale*ez_global(1), scale*ez_global(2), scale*ez_global(3), ...
    %     'LineWidth', 2, 'Color', 'r', 'MaxHeadSize', 2);

end

% Axis labels
xlabel(h.ax, "$x$ [m]", 'Interpreter','latex');
ylabel(h.ax, "$y$ [m]", 'Interpreter','latex');
zlabel(h.ax, "$z$ [m]", 'Interpreter','latex');

% Generate wind tunnel bounding box
plotcube([1.52 0.46 0.46], [-1.52/2, -0.46/2, -0.46/2], 0, [0 0 0]);

end