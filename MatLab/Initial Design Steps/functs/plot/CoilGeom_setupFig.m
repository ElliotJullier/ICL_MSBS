function h = CoilGeom_setupFig(coils)
% Set up figure/axes and plot static coil geometry + WT box.

h.fig = figure;
h.ax  = axes('Parent', h.fig);

hold(h.ax, 'on');
axis(h.ax, 'equal');
axis(h.ax, 'vis3d');
box(h.ax, 'on');
grid(h.ax, 'on');
view(h.ax, 3);

nCoils = numel(coils);

h.coils      = gobjects(nCoils, 1);
h.axisArrows = gobjects(nCoils, 1);

for k = 1:nCoils
    shp = coils(k).shp;

    if isempty(shp) || ~isfield(shp, 'Faces') || ~isfield(shp, 'Vertices')
        warning("coils(%d).shp is missing Faces/Vertices and will not be plotted.", k);
        continue
    end

    if isempty(shp.Faces) || isempty(shp.Vertices)
        warning("coils(%d).shp has empty Faces/Vertices and will not be plotted.", k);
        continue
    end

    h.coils(k) = patch('Parent', h.ax, ...
        'Faces', shp.Faces, ...
        'Vertices', shp.Vertices, ...
        'FaceColor', [0.65 0.65 0.65], ...
        'EdgeColor', 'k', ...
        'FaceAlpha', 1);

    % Optional: plot coil local +z axis direction
    rel_pos = coils(k).rel_pos(:).';
    centre  = rel_pos(1:3);

    ez_local  = [0; 0; 1];
    ez_global = coord_local2global(ez_local, [0 0 0 rel_pos(4:6)]);

    % Uncomment if desired
    % h.axisArrows(k) = quiver3(h.ax, centre(1), centre(2), centre(3), ...
    %     0.1*ez_global(1), 0.1*ez_global(2), 0.1*ez_global(3), ...
    %     0, 'r', 'LineWidth', 1.5, 'MaxHeadSize', 2);
end

xlabel(h.ax, "$x$ [m]", 'Interpreter', 'latex');
ylabel(h.ax, "$y$ [m]", 'Interpreter', 'latex');
zlabel(h.ax, "$z$ [m]", 'Interpreter', 'latex');

if exist('plotcube', 'file') == 2
    axes(h.ax);
    plotcube([1.52 0.46 0.46], [-1.52/2, -0.46/2, -0.46/2], 0, [0 0 0]);
end

camlight(h.ax, 'headlight');
lighting(h.ax, 'gouraud');

end