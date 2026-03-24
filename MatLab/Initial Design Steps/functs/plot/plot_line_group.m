function plot_line_group(groupStruct, plotStyle)
reqs = groupStruct.requests;
if isempty(reqs)
    return
end

fig = figure;
ax = axes('Parent', fig);
hold(ax, 'on');

components = strings(1, numel(reqs));

for k = 1:numel(reqs)
    r = reqs{k};

    if isfield(r, 'legendName') && ~isempty(r.legendName)
        plot(ax, r.s, r.B, ...
            'LineWidth', 1.5, ...
            'DisplayName', char(string(r.legendName)));
    else
        plot(ax, r.s, r.B, 'LineWidth', 1.5);
    end

    components(k) = string(r.component);
end

% Shade coil presence using the first line in the group
if isfield(reqs{1}, 'source_load_filename') && strlength(string(reqs{1}.source_load_filename)) > 0
    add_coil_presence_to_line_plot(ax, reqs{1}, reqs{1}.source_load_filename);
end

hasLegend = any(cellfun(@(rr) isfield(rr,'legendName') && ~isempty(rr.legendName), reqs));

legendObjs = findobj(ax, '-property', 'DisplayName');
hasCoilLegend = any(arrayfun(@(h) strcmp(get(h, 'DisplayName'), 'Coil'), legendObjs));

if hasLegend || hasCoilLegend
    legend(ax, 'show', 'Location', 'best', 'Interpreter', 'latex');
end

grid(ax, 'on');
xlabel(ax, 'Distance along line [m]', 'Interpreter','latex');

ucomp = unique(components);
if numel(ucomp) == 1
    ylabel(ax, append("$B_", ucomp(1), "$ [T]"), 'Interpreter', 'latex');
else
    ylabel(ax, "$B$ [T]", 'Interpreter', 'latex');
end
end
