function plot_field_subplots(Q_list, plotStyle)

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

nItems = numel(allItems);

% Need overview if any line exists
hasLine = false;
for k = 1:nItems
    if isfield(allItems{k}.result, 's')
        hasLine = true;
        break
    end
end

hasOverview = hasLine;
nTotal = nItems + hasOverview;

nRows = ceil(sqrt(nTotal));
nCols = ceil(nTotal / nRows);

fig = figure;
idx = 1;

if hasOverview
    % Use first Q's coils as geometric backdrop
    [coils, ~, ~] = load_coilfield_mat(Q_list{1}.input.load_filename);

    ax = subplot(nRows, nCols, idx, 'Parent', fig);
    hold(ax, 'on');
    axis(ax, 'equal');
    box(ax, 'on');
    grid(ax, 'on');
    view(ax, 3);

    if plotStyle.showCoils
        plot_coils_on_axes(ax, coils);
    end

    for k = 1:nItems
        r = allItems{k}.result;
        if isfield(r, 's')
            plot3(ax, r.X, r.Y, r.Z, 'r-', 'LineWidth', 2);
        else
            add_plane(ax, r.X, r.Y, r.Z, r.B, r.component, max(abs(plotStyle.clim)));
        end
    end

    clim(ax, plotStyle.clim);
    title(ax, "3D overview");
    idx = idx + 1;

    if plotStyle.showOrientationReadout
        attach_view_report_callback(ax);
    end
end

for k = 1:nItems
    ax = subplot(nRows, nCols, idx, 'Parent', fig);
    item = allItems{k};
    r = item.result;

    if isfield(r, 's')
        plot(ax, r.s, r.B, 'LineWidth', 1.5);
        grid(ax, 'on');
        xlabel(ax, 'Distance along line [m]');
        ylabel(ax, append("B_", string(r.component), " [T]"));
        title(ax, item.caseName + " : line");
    else
        surf(ax, r.X, r.Y, r.Z, r.B, 'EdgeColor','none');
        view(ax, 3);
        axis(ax, 'equal');
        box(ax, 'on');
        grid(ax, 'on');
        clim(ax, plotStyle.clim);
        colorbar(ax);
        title(ax, item.caseName + " : " + r.type + " : " + r.component);
    end

    idx = idx + 1;
end

end