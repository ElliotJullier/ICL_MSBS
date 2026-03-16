function plot_coils_on_axes(ax, coils)
hold(ax, 'on');
axes(ax);
for k = 1:numel(coils)
    plot(coils(k).shp);
end
end
