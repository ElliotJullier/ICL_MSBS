function plot_field_separate(Q_list, plotStyle)

allItems = {};

for i = 1:numel(Q_list)
    results = Q_list{i}.plotting.results;
    caseName = plotStyle.caseNames(i);

    for k = 1:numel(results)
        item = struct();
        item.caseName = caseName;
        item.result = results{k};
        allItems{end+1} = item; %#ok<AGROW>
    end
end

% 3D overview only if lines exist
hasLine = false;
for k = 1:numel(allItems)
    if isfield(allItems{k}.result, 's')
        hasLine = true;
        break
    end
end

if hasLine
    [coils, ~, ~] = load_coilfield_mat(Q_list{1}.input.load_filename);
    ax = create_plot_axes(coils, plotStyle);

    for k = 1:numel(allItems)
        r = allItems{k}.result;
        if isfield(r, 's')
            plot3(ax, r.X, r.Y, r.Z, 'r-', 'LineWidth', 2);
        else
            add_plane(ax, r.X, r.Y, r.Z, r.B, r.component, max(abs(plotStyle.clim)));
        end
    end

    clim(ax, plotStyle.clim);
    title(ax, "3D overview");

    if plotStyle.showOrientationReadout
        attach_view_report_callback(ax);
    end
end

for k = 1:numel(allItems)
    item = allItems{k};
    r = item.result;

    fig = figure;
    ax = axes('Parent', fig);

    if isfield(r, 's')
        plot(ax, r.s, r.B, 'LineWidth', 1.5);
        grid(ax, 'on');
        xlabel(ax, 'Distance along line [m]');
        ylabel(ax, append("B_", string(r.component), " [T]"));
        title(ax, item.caseName + " : line");
    else
        surf(ax, r.X, r.Y, r.Z, r.B, 'EdgeColor','none');
        axis(ax, 'equal');
        box(ax, 'on');
        grid(ax, 'on');
        view(ax, 3);
        clim(ax, plotStyle.clim);
        colorbar(ax);
        title(ax, item.caseName + " : " + r.type + " : " + r.component);
    end
end

end