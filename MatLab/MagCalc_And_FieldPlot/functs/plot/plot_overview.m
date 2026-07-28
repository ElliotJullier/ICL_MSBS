function plot_overview(plane_requests, line_requests, Q_case, plotStyle)
%PLOT_OVERVIEW Plot one case-specific 3D overview.
%
% Overview figures show the case geometry when available, except for
% synthetic datasets where the source cases may have different coil layouts.
% Plane requests are drawn as coloured surfaces. Line requests are drawn as
% dashed 3D lines with legend entries using query names or line group labels.

if isempty(plane_requests) && isempty(line_requests)
    return
end

geometry = Q_case.geometry;

caseName = string(Q_case.meta.caseName);
qFile = "";
if isfield(plotStyle, "Q_file")
    qFile = string(plotStyle.Q_file);
end

[~, qFileBase, ~] = fileparts(qFile);
if strlength(qFileBase) == 0
    qFileBase = "Q output";
end

% Put the case name first so exported figures are easier to identify.
figName = "Case Overview: " + caseName + " - " + qFileBase;

% Synthetic datasets are often differences between two cases with different
% coil layouts. Do not show coils in synthetic overviews, even if geometry
% exists from one of the source datasets.
isSyntheticCase = isfield(Q_case, "synthetic") || ...
    (isfield(Q_case, "meta") && isfield(Q_case.meta, "model") && ...
     lower(string(Q_case.meta.model)) == "synthetic_difference");

hasUsableCoilGeometry = isfield(Q_case, "geometry") && ...
    isstruct(geometry) && ...
    isfield(geometry, "coil") && ...
    ~isempty(geometry.coil);

if ~isSyntheticCase && hasUsableCoilGeometry
    figStruct = setup_coil_geometry_figure(geometry);
    set(figStruct.fig, "Name", char(figName));
    ax = figStruct.ax;

    % The overview legend should describe overview query objects only.
    % Coil bodies are background geometry in this plot, so force any objects
    % created by setup_coil_geometry_figure to remain hidden from the legend.
    existingChildren = ax.Children;
    if ~isempty(existingChildren)
        set(existingChildren(isgraphics(existingChildren)), "HandleVisibility", "off");
    end
else
    fig = figure("Name", char(figName));
    ax = axes("Parent", fig);
    hold(ax, "on");
    axis(ax, "equal");
    axis(ax, "vis3d");
    box(ax, "on");
    grid(ax, "on");
    view(ax, 3);

    xlabel(ax, "$x$ [m]", "Interpreter", "latex");
    ylabel(ax, "$y$ [m]", "Interpreter", "latex");
    zlabel(ax, "$z$ [m]", "Interpreter", "latex");
end

hold(ax, 'on');

refLabel = "";
usedLegendLabels = strings(0);

for k = 1:numel(plane_requests)
    r = plane_requests{k};

    if refLabel == ""
        refLabel = string(r.dataName);
    elseif string(r.dataName) ~= refLabel
        error("Overview planes within a case must share the same plotted quantity.");
    end

    if isfield(r, "queryName") && strlength(string(r.queryName)) > 0
        label = string(r.queryName);
    else
        label = "Plane query " + string(r.queryIndex);
    end

    if any(usedLegendLabels == label)
        handleVisibility = "off";
    else
        handleVisibility = "on";
        usedLegendLabels(end+1) = label; %#ok<AGROW>
    end

    surf(ax, r.X, r.Y, r.Z, r.data, ...
        'EdgeColor', 'none', ...
        'DisplayName', char(label), ...
        'HandleVisibility', char(handleVisibility), ...
        "FaceLighting", "none", ...
        "AmbientStrength", 1.0, ...
        "DiffuseStrength", 0.0, ...
        "SpecularStrength", 0.0);
end

if ~isempty(line_requests)
    usedLegendLabels = plot_overview_lines(ax, line_requests, usedLegendLabels);
end

if refLabel ~= ""
    set_clrbar(ax, plotStyle.clim.field, refLabel);
end

% Show a legend only for explicitly labelled overview query objects. Coils
% and start/end markers have HandleVisibility='off', so they are excluded.
if ~isempty(usedLegendLabels)
    legend(ax, 'show', 'Location', 'best', 'Interpreter', 'none');
end

title(ax, figName, 'Interpreter', 'none');

write_plot_metadata_file(figName, [plane_requests(:); line_requests(:)], plotStyle);

if plotStyle.showOrientationReadout
    attach_view_report_callback(ax);
end
end

function usedLegendLabels = plot_overview_lines(ax, line_requests, usedLegendLabels)
colors = lines(numel(line_requests));

for k = 1:numel(line_requests)
    r = line_requests{k};

    if isfield(r.query, "plot") && ...
       isfield(r.query.plot, "group") && ...
       ~isempty(r.query.plot.group)

        label = "Line group " + string(r.query.plot.group);

    elseif isfield(r, "queryName") && strlength(string(r.queryName)) > 0
        label = string(r.queryName);

    else
        label = "Line query " + string(r.queryIndex);
    end

    if any(usedLegendLabels == label)
        handleVisibility = "off";
    else
        handleVisibility = "on";
        usedLegendLabels(end+1) = label; %#ok<AGROW>
    end

    plot3(ax, r.X, r.Y, r.Z, '--', ...
        'Color', colors(k,:), ...
        'LineWidth', 1.7, ...
        'DisplayName', char(label), ...
        'HandleVisibility', char(handleVisibility), ...
        'HitTest', 'off');

    plot3(ax, r.X(1), r.Y(1), r.Z(1), 'o', ...
        'Color', colors(k,:), ...
        'MarkerFaceColor', colors(k,:), ...
        'HandleVisibility', 'off', ...
        'HitTest', 'off');

    plot3(ax, r.X(end), r.Y(end), r.Z(end), 'd', ...
        'Color', colors(k,:), ...
        'MarkerFaceColor', colors(k,:), ...
        'HandleVisibility', 'off', ...
        'HitTest', 'off');
end
end
