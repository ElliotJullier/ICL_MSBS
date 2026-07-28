function plot_line_group(groupStruct, plotStyle)
%PLOT_LINE_GROUP Plot one group of line results.
%
% Coil-hit shading is plotted for records whose query requested
% ShowCoils=true. Records with ShowCoils=false do not cause an error.
% Requested coil geometries are grouped by equivalent coil position/setup so
% overlapping coil sets are plotted only once.
reqs = groupStruct.requests;
if isempty(reqs)
    return
end

isGradient = false(1, numel(reqs));

for k = 1:numel(reqs)
    r = reqs{k};

    if isfield(r, "query") && isfield(r.query, "quantity")
        isGradient(k) = lower(string(r.query.quantity)) == "gradient";
    else
        isGradient(k) = startsWith(string(r.dataName), "dB");
    end
end

hasField = any(~isGradient);
hasGradient = any(isGradient);
useDualAxis = hasField && hasGradient;

coilGroups = build_requested_coil_plot_groups(reqs);

fig = figure;
ax = axes('Parent', fig);
hold(ax, 'on');

qFile = "";
if isfield(plotStyle, "Q_file")
    qFile = string(plotStyle.Q_file);
end

[~, qFileBase, ~] = fileparts(qFile);
if strlength(qFileBase) == 0
    qFileBase = "Q output";
end

groupLabel = string(groupStruct.key);
isUngrouped = startsWith(groupLabel, "ungrouped");

if isUngrouped
    % Ungrouped plots contain one case/query, so include the case name in
    % the title because there may be no legend entry to identify it.
    figName = "Line: " + string(reqs{1}.caseName) + " - " + qFileBase;
else
    % Grouped plots can contain multiple cases, so the case names belong in
    % the legend rather than the title.
    figName = "Line group " + groupLabel + " - " + qFileBase;
end

set(fig, "Name", char(figName));

labels = strings(1, numel(reqs));
lineHandles = gobjects(1, numel(reqs));

fieldAxisColor = [];
gradientAxisColor = [];

for k = 1:numel(reqs)
    r = reqs{k};

    displayName = string(r.caseName);
    if isfield(r, "queryName") && strlength(string(r.queryName)) > 0
        displayName = displayName + ": " + string(r.queryName);
    end

    if useDualAxis
        if isGradient(k)
            yyaxis(ax, 'right');
        else
            yyaxis(ax, 'left');
        end
    end

    lineHandles(k) = plot(ax, r.s, r.data, ...
        'LineWidth', 1.5, ...
        'DisplayName', char(displayName));

    thisColor = get(lineHandles(k), 'Color');

    if useDualAxis
        if isGradient(k) && isempty(gradientAxisColor)
            gradientAxisColor = thisColor;
        elseif ~isGradient(k) && isempty(fieldAxisColor)
            fieldAxisColor = thisColor;
        end
    end

    if isfield(r, 'dataName')
        labels(k) = string(r.dataName);
    else
        labels(k) = "data";
    end
end

plot_coil_groups_on_line_axes(ax, coilGroups, useDualAxis);

if numel(reqs) > 1 || ~isempty(coilGroups)
    legend(ax, 'show', 'Location', 'best', 'Interpreter', 'none');
end

title(ax, figName, "Interpreter", "none");

if exist('write_plot_metadata_file', 'file') == 2
    write_plot_metadata_file(figName, reqs, plotStyle);
end

grid(ax, 'on');
xlabel(ax, 'Distance along line [m]', 'Interpreter','latex');

if useDualAxis
    yyaxis(ax, 'left');

    if ~isempty(fieldAxisColor)
        ax.YAxis(1).Color = fieldAxisColor;
    end

    fieldLabels = unique(labels(~isGradient));
    if numel(fieldLabels) == 1
        ylabel(ax, latex_data_label(fieldLabels(1)), 'Interpreter', 'latex');
    else
        ylabel(ax, 'Magnetic field [T]', 'Interpreter', 'latex');
    end

    yyaxis(ax, 'right');

    if ~isempty(gradientAxisColor)
        ax.YAxis(2).Color = gradientAxisColor;
    end

    gradientLabels = unique(labels(isGradient));
    if numel(gradientLabels) == 1
        ylabel(ax, latex_data_label(gradientLabels(1)), 'Interpreter', 'latex');
    else
        ylabel(ax, 'Field gradient [T/m]', 'Interpreter', 'latex');
    end

    yyaxis(ax, 'left');

else
    uLabels = unique(labels);

    if numel(uLabels) == 1
        ylabel(ax, latex_data_label(uLabels(1)), 'Interpreter', 'latex');
    elseif hasGradient
        ylabel(ax, 'Field gradient [T/m]', 'Interpreter', 'latex');
    else
        ylabel(ax, 'Magnetic field [T]', 'Interpreter', 'latex');
    end
end
end

function plot_coil_groups_on_line_axes(ax, coilGroups, useDualAxis)
%PLOT_COIL_GROUPS_ON_LINE_AXES Shade one coil-hit overlay per distinct coil set.

if isempty(coilGroups)
    return
end

if useDualAxis
    yyaxis(ax, 'left');
end

colourOrder = get(ax, "ColorOrder");
if isempty(colourOrder)
    colourOrder = lines(max(1, numel(coilGroups)));
end

for g = 1:numel(coilGroups)
    colour = colourOrder(mod(g-1, size(colourOrder, 1)) + 1, :);
    representativeRecord = coilGroups(g).records{1};

    hCoils = add_coil_presence_to_line_plot(ax, ...
        representativeRecord, ...
        coilGroups(g).geometry, ...
        colour);

    validCoils = hCoils(isgraphics(hCoils));
    if ~isempty(validCoils)
        set(validCoils, "HandleVisibility", "off");
        set(validCoils(1), ...
            "DisplayName", char(coilGroups(g).legendLabel), ...
            "HandleVisibility", "on");
    end
end
end

function lbl = latex_data_label(dataName)
dataName = string(dataName);
if startsWith(dataName, "B") && strlength(dataName) == 2
    comp = extractAfter(dataName, 1);
    lbl = "$B_" + comp + "$ [T]";
elseif startsWith(dataName, "dB")
    lbl = "$" + dataName + "$ [T/m]";
else
    lbl = dataName;
end
end
