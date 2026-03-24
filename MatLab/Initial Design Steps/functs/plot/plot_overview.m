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
    disp("Loaded coil names for overview:")
    disp({coils.name}.')
    for k = 1:numel(coils)
        fprintf('coil %d: shp empty = %d\n', k, isempty(coils(k).shp));
    end
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

hold(ax, 'on');

refComponent = "";

% Plot only explicitly flagged overview planes
for k = 1:numel(overview_planes)
    r = overview_planes{k};

    if refComponent == ""
        refComponent = string(r.component);
    elseif string(r.component) ~= refComponent
        error("Overview planes must share the same field component.");
    end

    surf(ax, r.X, r.Y, r.Z, r.B, 'EdgeColor', 'none');
end

% Attach camera-aware overview overlay
if ~isempty(overview_lines)
    attach_overview_line_overlay_callback(ax, overview_lines, 3e-3);
end

if refComponent ~= ""
    set_clrbar(ax, plotStyle.clim, refComponent);
end

if plotStyle.showOrientationReadout
    attach_view_report_callback(ax);
end

end