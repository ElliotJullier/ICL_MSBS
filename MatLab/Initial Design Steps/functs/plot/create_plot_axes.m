function ax = create_plot_axes(coils, plotStyle)

figStruct = CoilGeom_setupFig(coils);
ax = figStruct.ax;

if ~plotStyle.showCoils
    cla(ax);
    hold(ax, 'on');
    axis(ax, 'equal');
    box(ax, 'on');
    grid(ax, 'on');
    view(ax, 3);
end

end