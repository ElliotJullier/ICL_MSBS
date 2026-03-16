function plot_field_single_axes(Q_list, plotStyle)

% Use coils from first Q only for the 3D background
[coils, ~, ~] = load_coilfield_mat(Q_list{1}.input.load_filename);
ax = create_plot_axes(coils, plotStyle);

for i = 1:numel(Q_list)
    results = Q_list{i}.plotting.results;

    for k = 1:numel(results)
        if isfield(results{k}, 's')
            error("Lines cannot be used with plotMode = 'single_axes'.");
        end
        if k > 1 && results{k}.component ~= results{k-1}.component
            error("Different B field directions should not be used with plotMode = 'single_axes'.")
        end

        surf(ax, results{k}.X, results{k}.Y, results{k}.Z, results{k}.B, 'EdgeColor','none');
    end
end

clrb = colorbar(ax);
clrb.Label.String = append("$B_", results{end}.component, "$ [T]");
clrb.Label.Interpreter = 'latex';
clrmap_range = [0 0 1; 0.8 0.8 0.8; 1 0 0];
clrmap = def_clrmap(clrmap_range);
colormap(clrmap);
clim(ax, plotStyle.clim);

if plotStyle.showOrientationReadout
    attach_view_report_callback(ax);
end


end