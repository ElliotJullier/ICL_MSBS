function plot_field_subplots(Q_list, plotStyle)

allItems = {};

for i = 1:numel(Q_list)
    results = Q_list{i}.plotting;
    caseName = plotStyle.caseNames(i);

    for k = 1:numel(results)
        item = struct();
        item.caseName = caseName;
        item.result = results{k};
        allItems{end+1} = item; %#ok<AGROW>
    end
end

% ------------------------- Split into planes and lines -------------------------
planeItems = {};
lineItems  = {};

for k = 1:numel(allItems)
    r = allItems{k}.result;

    if isfield(r, 's')
        lineItems{end+1} = allItems{k}; %#ok<AGROW>
    else
        planeItems{end+1} = allItems{k}; %#ok<AGROW>
    end
end

hasLine = ~isempty(lineItems);

% ------------------------- Layout -------------------------
if hasLine
    % 1 overview + one subplot per line
    nTotal = 1 + numel(lineItems);
else
    % one subplot per plane
    nTotal = numel(planeItems);
end

nRows = ceil(sqrt(nTotal));
nCols = ceil(nTotal / nRows);

fig = figure;
idx = 1;

% ------------------------- Case B: lines exist -> first subplot is overview -------------------------
if hasLine
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

    refComponent = "";
    % Add all planes to overview
    for k = 1:numel(planeItems)
        r = planeItems{k}.result;
        if refComponent == ""
            refComponent = r.component;
        elseif results{k}.component ~= refComponent
            error("Different B field directions should not be used with plotMode = 'subplots' where a line is queried.");
        end
        surf(ax, r.X, r.Y, r.Z, r.B, 'EdgeColor', 'none');
    end
    set_clrbar(ax, plotStyle.clim, refComponent);

    % Add all lines to overview
    for k = 1:numel(lineItems)
        r = lineItems{k}.result;
        plot3(ax, r.X, r.Y, r.Z, 'k:', 'LineWidth', 2);
    end

    title(ax, "3D overview");
    idx = idx + 1;

    if plotStyle.showOrientationReadout
        attach_view_report_callback(ax);
    end

    % Remaining subplots: line plots only
    for k = 1:numel(lineItems)
        ax = subplot(nRows, nCols, idx, 'Parent', fig);
        item = lineItems{k};
        r = item.result;

        plot(ax, r.s, r.B, 'LineWidth', 1.5);
        grid(ax, 'on');
        xlabel(ax, 'Distance along line [m]');
        ylabel(ax, append("B_", string(r.component), " [T]"));
        title(ax, item.caseName + " : line : " + r.component);

        idx = idx + 1;
    end

% ------------------------- Case A: no lines -> one subplot per plane -------------------------
else
    for k = 1:numel(planeItems)
        ax = subplot(nRows, nCols, idx, 'Parent', fig);
        item = planeItems{k};
        r = item.result;

        surf(ax, r.X, r.Y, r.Z, r.B, 'EdgeColor','none');
        axis(ax, 'equal');
        box(ax, 'on');
        grid(ax, 'on');
        clim(ax, plotStyle.clim);
        colorbar(ax);

        set_plane_view(ax, r);

        title(ax, item.caseName + " : " + r.type + " : " + r.component);

        idx = idx + 1;
    end
end

end