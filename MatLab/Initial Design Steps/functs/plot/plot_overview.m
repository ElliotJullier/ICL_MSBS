function plot_overview(plot_requests, Q_list, plotStyle)
overview_requests = {};
for k = 1:numel(plot_requests)
    if isfield(plot_requests{k}, 'inOverview') && logical(plot_requests{k}.inOverview)
        overview_requests{end+1} = plot_requests{k}; %#ok<AGROW>
    end
end
if isempty(overview_requests)
    return
end

[coils, ~, ~] = load_coilfield_mat(Q_list{1}.input.load_filename);
ax = create_plot_axes(coils, plotStyle);

refComponent = "";
for k = 1:numel(overview_requests)
    r = overview_requests{k};
    if contains(lower(char(string(r.type))), 'plane')
        if refComponent == ""
            refComponent = string(r.component);
        elseif string(r.component) ~= refComponent
            error("Grouped overview planes must share the same field component.");
        end
        surf(ax, r.X, r.Y, r.Z, r.B, 'EdgeColor','none');
    elseif contains(lower(char(string(r.type))), 'line')
        plot3(ax, r.X, r.Y, r.Z, 'r-', 'LineWidth', 2);
    end
end

if refComponent ~= ""
    set_clrbar(ax, plotStyle.clim, refComponent);
end
if plotStyle.showOrientationReadout
    attach_view_report_callback(ax);
end
end
