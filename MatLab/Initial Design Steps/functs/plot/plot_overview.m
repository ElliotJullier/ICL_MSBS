function plot_overview(plane_requests, line_requests, Q_list, plotStyle)

overview_planes = {};
for k = 1:numel(plane_requests)
    r = plane_requests{k};
    if isfield(r, 'inOverview') && logical(r.inOverview)
        overview_planes{end+1} = r; %#ok<AGROW>
    end
end

% All lines are shown in overview if overview exists
overview_lines = line_requests;

if isempty(overview_planes) && isempty(overview_lines)
    return
end

% Create figure/axes directly here
if plotStyle.showCoils
    [coils, ~, ~] = load_coilfield_mat(Q_list{1}.input.load_filename);
    figStruct = CoilGeom_setupFig(coils);
    ax = figStruct.ax;
else
    fig = figure;
    ax = axes('Parent', fig);
    hold(ax, 'on');
    axis(ax, 'equal');
    box(ax, 'on');
    grid(ax, 'on');
    view(ax, 3);
end

refComponent = "";

% Plot only explicitly flagged overview planes
for k = 1:numel(overview_planes)
    r = overview_planes{k};

    if refComponent == ""
        refComponent = string(r.component);
    elseif string(r.component) ~= refComponent
        error("Overview planes must share the same field component.");
    end

    surf(ax, r.X, r.Y, r.Z, r.B, 'EdgeColor','none');
end

% Plot all lines
for k = 1:numel(overview_lines)
    r = overview_lines{k};
    % Main sampled path
    plot3(ax, r.X, r.Y, r.Z, 'k:', 'LineWidth', 1.5);
    
    % Start point marker
    plot3(ax, r.X(1), r.Y(1), r.Z(1), 'ko', ...
        'MarkerFaceColor', 'k', ...
        'MarkerSize', 6);
    
    % Arrowhead at end
    if numel(r.X) >= 2
        dx = r.X(end) - r.X(end-1);
        dy = r.Y(end) - r.Y(end-1);
        dz = r.Z(end) - r.Z(end-1);
    
        quiver3(ax, ...
            r.X(end-1), r.Y(end-1), r.Z(end-1), ...
            dx, dy, dz, ...
            0, ... % no autoscaling
            'Color', 'k', ...
            'LineWidth', 1.5, ...
            'MaxHeadSize', 2);
    end
end

if refComponent ~= ""
    set_clrbar(ax, plotStyle.clim, refComponent);
end

if plotStyle.showOrientationReadout
    attach_view_report_callback(ax);
end

end