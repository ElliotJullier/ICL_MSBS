function h = setup_coil_geometry_figure(geometry)
%SETUP_COIL_GEOMETRY_FIGURE Set up figure/axes and plot static coil geometry.

h.fig = figure;
h.ax  = axes('Parent', h.fig);

hold(h.ax, 'on');
axis(h.ax, 'equal');
axis(h.ax, 'vis3d');
box(h.ax, 'on');
grid(h.ax, 'on');
view(h.ax, 3);

coils = geometry.coil;
nCoils = numel(coils);

h.coils      = gobjects(nCoils, 1);
h.axisArrows = gobjects(nCoils, 1);

for k = 1:nCoils
    shp = coils(k).shape;

    if isempty(shp) || ~isfield(shp, 'Faces') || ~isfield(shp, 'Vertices')
        warning("geometry.coil(%d).shape is missing Faces/Vertices and will not be plotted.", k);
        continue
    end

    if isempty(shp.Faces) || isempty(shp.Vertices)
        warning("geometry.coil(%d).shape has empty Faces/Vertices and will not be plotted.", k);
        continue
    end

    sageGreen = [0.56 0.68 0.54];
    
    h.coils(k) = patch('Parent', h.ax, ...
        'Faces', shp.Faces, ...
        'Vertices', shp.Vertices, ...
        'FaceColor', sageGreen, ...
        'EdgeColor', 0.55*sageGreen, ...
        'FaceAlpha', 0.85, ...
        'DisplayName', 'Coils', ...
        'HandleVisibility', 'off');
    
    pose = coils(k).pose(:).';
    centre  = pose(1:3);

    ez_local  = [0; 0; 1];
    ez_global = coord_local2global(ez_local, [0 0 0 pose(4:6)]);

    % Uncomment if desired
    % h.axisArrows(k) = quiver3(h.ax, centre(1), centre(2), centre(3), ...
    %     0.1*ez_global(1), 0.1*ez_global(2), 0.1*ez_global(3), ...
    %     0, 'r', 'LineWidth', 1.5, 'MaxHeadSize', 2);
end

xlabel(h.ax, "$x$ [m]", 'Interpreter', 'latex');
ylabel(h.ax, "$y$ [m]", 'Interpreter', 'latex');
zlabel(h.ax, "$z$ [m]", 'Interpreter', 'latex');

camlight(h.ax, 'headlight');
lighting(h.ax, 'gouraud');
end
