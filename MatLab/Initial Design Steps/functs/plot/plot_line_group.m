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
    plot(ax, r.s, r.B, 'LineWidth', 1.5);
    components(k) = string(r.component);
end

grid(ax, 'on');
xlabel(ax, 'Distance along line [m]');

ucomp = unique(components);
if numel(ucomp) == 1
    ylabel(ax, append("$B_", ucomp(1), "$ [T]"), 'Interpreter', 'latex');
else
    ylabel(ax, "$B$ [T]", 'Interpreter', 'latex');
end
end
