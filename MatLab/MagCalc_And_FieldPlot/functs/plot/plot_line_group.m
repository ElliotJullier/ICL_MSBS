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

requestedAxis="auto"; if isfield(plotStyle,"lineAxis"), requestedAxis=plotStyle.lineAxis; end
[coordinates,xLabel]=line_plot_coordinates(reqs,requestedAxis);
for k=1:numel(reqs), reqs{k}.plotCoordinates=coordinates{k}; end
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

set(fig, "Name", char(figName), "NumberTitle","off");

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

    lineHandles(k) = plot(ax, r.plotCoordinates, r.data, ...
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

% Avoid unreadable tick labels when a derivative is constant up to roundoff.
if useDualAxis
    yyaxis(ax,'left'); stabilise_constant_axis(ax,reqs(~isGradient));
    yyaxis(ax,'right'); stabilise_constant_axis(ax,reqs(isGradient));
    yyaxis(ax,'left');
else
    stabilise_constant_axis(ax,reqs);
end
plot_coil_groups_on_line_axes(ax, coilGroups, useDualAxis, plotStyle);

if numel(reqs) > 1 || ~isempty(coilGroups)
    legend(ax, 'show', 'Location', 'bestoutside', 'Interpreter', 'none');
end



if exist('write_plot_metadata_file', 'file') == 2
    write_plot_metadata_file(figName, reqs, plotStyle);
end

grid(ax, 'on');
xlabel(ax, xLabel, 'Interpreter','latex');

if useDualAxis
    yyaxis(ax, 'left');

    if ~isempty(fieldAxisColor)
        ax.YAxis(1).Color = fieldAxisColor;
    end

    fieldLabels = unique(labels(~isGradient));
    if numel(fieldLabels) == 1
        ylabel(ax, field_quantity_label(fieldLabels(1)), 'Interpreter', 'latex');
    else
        ylabel(ax, 'Magnetic field [T]', 'Interpreter', 'latex');
    end

    yyaxis(ax, 'right');

    if ~isempty(gradientAxisColor)
        ax.YAxis(2).Color = gradientAxisColor;
    end

    gradientLabels = unique(labels(isGradient));
    if numel(gradientLabels) == 1
        ylabel(ax, field_quantity_label(gradientLabels(1)), 'Interpreter', 'latex');
    else
        ylabel(ax, 'Field gradient [T/m]', 'Interpreter', 'latex');
    end

    yyaxis(ax, 'left');

else
    uLabels = unique(labels);

    if numel(uLabels) == 1
        ylabel(ax, field_quantity_label(uLabels(1)), 'Interpreter', 'latex');
    elseif hasGradient
        ylabel(ax, 'Field gradient [T/m]', 'Interpreter', 'latex');
    else
        ylabel(ax, 'Magnetic field [T]', 'Interpreter', 'latex');
    end
end
apply_scientific_plot_style(ax,plotStyle);
end

function plot_coil_groups_on_line_axes(ax,groups,useDualAxis,style)
if useDualAxis, yyaxis(ax,'left'); end
alpha=[]; if isfield(style,"geometryAlpha"), alpha=style.geometryAlpha; end
showBores=true; if isfield(style,"showCoilBores"), showBores=style.showCoilBores; end
for g=1:numel(groups)
    used={};
    for r=groups(g).records
        record=r{1};
        endpoints=[record.X(1),record.Y(1),record.Z(1),record.X(end),record.Y(end),record.Z(end)];
        if any(cellfun(@(previous) isequaln(previous,endpoints),used)), continue; end
        used{end+1}=endpoints;
        add_coil_presence_to_line_plot(ax,record,groups(g).geometry,[],alpha,showBores);
    end
end
end

function stabilise_constant_axis(ax,records)
values=[];
for r=records
    data=r{1}.data; values=[values;data(isfinite(data))]; %#ok<AGROW>
end
if isempty(values), return; end
lo=min(values); hi=max(values); scale=max(abs([lo hi]));
if hi-lo<=1e-10*max(scale,realmin)
    centre=0.5*(lo+hi); pad=0.05*max(scale,1e-12);
    ylim(ax,centre+[-pad pad]);
end
end
