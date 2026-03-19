function plot_field_separate(Q_list, plotStyle)

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

% ------------------------- If lines exist, make one 3D overview figure -------------------------
if hasLine
    [coils, ~, ~] = load_coilfield_mat(Q_list{1}.input.load_filename);

    figStruct = CoilGeom_setupFig(coils);
    ax = figStruct.ax;

    if ~plotStyle.showCoils
        cla(ax);
        hold(ax, 'on');
        axis(ax, 'equal');
        box(ax, 'on');
        grid(ax, 'on');
        view(ax, 3);
    end

    refComponent = "";

    % Add all planes
    for k = 1:numel(planeItems)
        r = planeItems{k}.result;

        if refComponent == ""
            refComponent = r.component;
        elseif r.component ~= refComponent
            error("Different B field directions should not be used with plotMode = 'separate_figures' where a line is queried.");
        end

        surf(ax, r.X, r.Y, r.Z, r.B, 'EdgeColor','none');
    end

    % Add all lines
    for k = 1:numel(lineItems)
        r = lineItems{k}.result;
        plot3(ax, r.X, r.Y, r.Z, 'r-', 'LineWidth', 2);
    end

    % Only apply colourbar if there are planes in the overview
    if ~isempty(planeItems)
        set_clrbar(ax, plotStyle.clim, refComponent);
    end

    if plotStyle.showOrientationReadout
        attach_view_report_callback(ax);
    end
end

% ------------------------- One figure per plane -------------------------
for k = 1:numel(planeItems)
    item = planeItems{k};
    r = item.result;

    fig = figure;
    ax = axes('Parent', fig);

    surf(ax, r.X, r.Y, r.Z, r.B, 'EdgeColor','none');
    axis(ax, 'equal');
    box(ax, 'on');
    grid(ax, 'on');

    set_clrbar(ax, plotStyle.clim, r.component);
    set_plane_view(ax, r);

    % No title
end

% ------------------------- One figure per line -------------------------
for k = 1:numel(lineItems)
    item = lineItems{k};
    r = item.result;

    fig = figure;
    ax = axes('Parent', fig);

    plot(ax, r.s, r.B, 'LineWidth', 1.5);
    grid(ax, 'on');
    xlabel(ax, 'Distance along line [m]');
    ylabel(ax, append("B_", string(r.component), " [T]"));

    % No title
end

end