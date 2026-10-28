function h = setup_coil_geometry_figure(geometry)
%SETUP_COIL_GEOMETRY_FIGURE Assembly overview, retained name for old callers.
h.fig=figure; h.ax=axes("Parent",h.fig); hold(h.ax,"on");
axis(h.ax,"equal"); axis(h.ax,"vis3d"); box(h.ax,"on"); grid(h.ax,"on"); view(h.ax,3);
h.coils=plot_component_geometry(h.ax,geometry); h.axisArrows=gobjects(0);
xlabel(h.ax,"$x$ [m]","Interpreter","latex"); ylabel(h.ax,"$y$ [m]","Interpreter","latex");
zlabel(h.ax,"$z$ [m]","Interpreter","latex");
camlight(h.ax,"headlight"); lighting(h.ax,"gouraud");
end
