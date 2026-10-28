function plot_plane_group(groupStruct, plotStyle)
% PLOT_PLANE_GROUP Plot one group of plane records.
%
% Each record in groupStruct.requests contains the sampled plane data and
% the case/query context needed for plotting.
%
% Coil geometry is plotted for records whose query requested ShowCoils=true.
% Records with ShowCoils=false do not cause an error. Requested coil
% geometries are grouped by equivalent coil position/setup so overlapping
% coil sets are plotted only once.
reqs = groupStruct.requests;
if isempty(reqs)
    return
end

refLabel = "";
for k = 1:numel(reqs)
    thisLabel = string(reqs{k}.dataName);
    if refLabel == ""
        refLabel = thisLabel;
    elseif thisLabel ~= refLabel
        error("Grouped planes must share the same plotted quantity. Split them into different groups.");
    end
end

coilGroups = build_requested_coil_plot_groups(reqs);

singlePlane = isscalar(reqs);

fig = figure;
ax = axes('Parent', fig);
hold(ax, 'on');
axis(ax, 'equal');
box(ax, 'on');
grid(ax, 'on');

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
    figName = "Plane: " + string(reqs{1}.caseName) + " - " + qFileBase;
else
    % Grouped plots can contain multiple cases, so the case names belong in
    % the legend rather than the title.
    figName = "Plane group " + groupLabel + " - " + qFileBase;
end

set(fig, "Name", char(figName), "NumberTitle","off");
if isfield(plotStyle,"colourScaleClass")
    setappdata(fig,"MSBSColourScaleClass",plotStyle.colourScaleClass);
    setappdata(fig,"MSBSColourScaleLimits",plotStyle.colourScaleLimits);
end
if isfield(plotStyle,"gradientColorLimitReport")
    setappdata(fig,"MSBSGradientColorLimitReport",plotStyle.gradientColorLimitReport);
end

for k = 1:numel(reqs)
    surf(ax, reqs{k}.X, reqs{k}.Y, reqs{k}.Z, reqs{k}.data, ...
        'EdgeColor', 'none', ...
        'HandleVisibility', visibility_for_surface(singlePlane), ...
        'DisplayName', char(string(reqs{k}.caseName) + ": " + string(reqs{k}.queryName)));
end

plot_coil_groups_on_plane_axes(ax, coilGroups, plotStyle);

quantityClass = get_record_group_quantity_class(reqs);
set_clrbar(ax, plotStyle.clim.(quantityClass), refLabel);

if singlePlane
    set_plane_view(ax, reqs{1});
else
    view(ax, 3);
end

xlabel(ax, '$x$ [m]', 'Interpreter', 'latex');
ylabel(ax, '$y$ [m]', 'Interpreter', 'latex');
zlabel(ax, '$z$ [m]', 'Interpreter', 'latex');

if numel(reqs) > 1 || ~isempty(coilGroups)
    legend(ax, 'show', 'Location', 'southoutside', 'Interpreter', 'none', 'Orientation','horizontal');
end

apply_scientific_plot_style(ax,plotStyle);

if exist('write_plot_metadata_file', 'file') == 2
    write_plot_metadata_file(figName, reqs, plotStyle);
end

if isfield(plotStyle, "showOrientationReadout") && plotStyle.showOrientationReadout
    attach_view_report_callback(ax);
end
end


% -------------------- LOCAL HELPER FUNCTION(S) --------------------------
function value=visibility_for_surface(singlePlane)
if singlePlane, value='off'; else, value='on'; end
end

function plot_coil_groups_on_plane_axes(ax,groups,style)
alpha=[]; if isfield(style,"geometryAlpha"), alpha=style.geometryAlpha; end
for g=1:numel(groups)
    used={};
    for r=groups(g).records
        q=r{1}.query;
        if any(cellfun(@(previous) isequaln(previous,q),used)), continue; end
        used{end+1}=q;
        plot_geometry_sections(ax,groups(g).geometry,q,alpha);
    end
end
end

function quantityClass = get_record_group_quantity_class(reqs)
%GET_RECORD_GROUP_QUANTITY_CLASS Return "field" or "gradient" for a group.

if isempty(reqs)
    quantityClass = "field";
    return
end

classes = strings(1, numel(reqs));

for k = 1:numel(reqs)
    r = reqs{k};

    if isfield(r, "query") && isfield(r.query, "quantity")
        q = lower(string(r.query.quantity));
    else
        q = "";
    end

    if q == "gradient" || startsWith(string(r.dataName), "dB")
        classes(k) = "gradient";
    else
        classes(k) = "field";
    end
end

if numel(unique(classes)) > 1
    error("Grouped plane plots cannot mix field and gradient quantities. Use separate groups.");
end

quantityClass = classes(1);
end
