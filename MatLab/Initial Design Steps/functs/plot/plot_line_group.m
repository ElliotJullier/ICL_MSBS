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

hasLegend = any(cellfun(@(rr) isfield(rr,'legendName') && ~isempty(rr.legendName), reqs));
if hasLegend
    lgd = legend(ax, 'show', 'Location', 'best');
    lgd.Interpreter = 'latex';
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
