function plot_field_single_axes(Q_list, plotStyle)

% Use coils from first Q only for the 3D background
[coils, ~, ~] = load_coilfield_mat(Q_list{1}.input.load_filename);
ax = create_plot_axes(coils, plotStyle);

refComponent = "";

for i = 1:numel(Q_list)
    results = Q_list{i}.plotting;

    for k = 1:numel(results)
        if isfield(results{k}, 's')
            error("Lines cannot be used with plotMode = 'single_axes'.");
        end

        if refComponent == ""
            refComponent = results{k}.component;
        elseif results{k}.component ~= refComponent
            error("Different B field directions should not be used with plotMode = 'single_axes'.");
        end

        surf(ax, results{k}.X, results{k}.Y, results{k}.Z, results{k}.B, 'EdgeColor','none');
    end
end

set_clrbar(ax, plotStyle.clim, refComponent)

if plotStyle.showOrientationReadout
    attach_view_report_callback(ax);
end


end