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
        error("Grouped planes must share the same field component.");
    end
end

singlePlane = numel(reqs) == 1;

if singlePlane && ~plotStyle.showCoilsInPlaneFigures
    fig = figure;
    ax = axes('Parent', fig);
    hold(ax, 'on');
    surf(ax, reqs{1}.X, reqs{1}.Y, reqs{1}.Z, reqs{1}.B, 'EdgeColor','none');
    axis(ax, 'equal');
    box(ax, 'on');
    grid(ax, 'on');
    set_clrbar(ax, plotStyle.clim, refComponent);
    set_plane_view(ax, reqs{1});
    return
end

if plotStyle.showCoilsInPlaneFigures
    [coils, ~, ~] = load_coilfield_mat(Q_list{1}.input.load_filename);
    ax = create_plot_axes(coils, plotStyle);
else
    fig = figure;
    ax = axes('Parent', fig);
    hold(ax, 'on');
    axis(ax, 'equal');
    box(ax, 'on');
    grid(ax, 'on');
    view(ax, 3);
end

for k = 1:numel(reqs)
    surf(ax, reqs{k}.X, reqs{k}.Y, reqs{k}.Z, reqs{k}.B, 'EdgeColor','none');
end

set_clrbar(ax, plotStyle.clim, refComponent);

if singlePlane
    set_plane_view(ax, reqs{1});
else
    view(ax, 3);
end

if plotStyle.showOrientationReadout
    attach_view_report_callback(ax);
end
end
