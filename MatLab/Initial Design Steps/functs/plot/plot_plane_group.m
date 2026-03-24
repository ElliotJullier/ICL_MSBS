function plot_plane_group(groupStruct, Q_list, plotStyle)

reqs = groupStruct.requests;
if isempty(reqs)
    return
end

refComponent = "";
for k = 1:numel(reqs)
    if refComponent == ""
        refComponent = string(reqs{k}.component);
    elseif string(reqs{k}.component) ~= refComponent
        error("Grouped planes must share the same field component. Split them into different groups.");
    end
end

singlePlane = isscalar(reqs);

% Always create a plain figure/axes here
fig = figure;
ax = axes('Parent', fig);
hold(ax, 'on');
axis(ax, 'equal');
box(ax, 'on');
grid(ax, 'on');

% Plot field planes first
for k = 1:numel(reqs)
    surf(ax, reqs{k}.X, reqs{k}.Y, reqs{k}.Z, reqs{k}.B, 'EdgeColor', 'none');
end

% Coil overlays
if plotStyle.showCoilsInPlaneFigures
    if ~isfield(Q_list{1}, 'input') || ~isfield(Q_list{1}.input, 'load_filename')
        error("Plane coil overlay requires Q.input.load_filename to be available.");
    end

    load_filename = Q_list{1}.input.load_filename;

    if singlePlane
        add_coil_presence_to_plane_plot(ax, reqs{1}, load_filename);
    else
        [coils, ~, ~] = load_coilfield_mat(load_filename);
        plot_coils_transparent_edges(ax, coils);
    end
end

set_clrbar(ax, plotStyle.clim, refComponent);

if singlePlane
    set_plane_view(ax, reqs{1});
else
    view(ax, 3);
end

xlabel(ax, '$x$ [m]', 'Interpreter', 'latex');
ylabel(ax, '$y$ [m]', 'Interpreter', 'latex');
zlabel(ax, '$z$ [m]', 'Interpreter', 'latex');


if plotStyle.showOrientationReadout
    attach_view_report_callback(ax);
end

end