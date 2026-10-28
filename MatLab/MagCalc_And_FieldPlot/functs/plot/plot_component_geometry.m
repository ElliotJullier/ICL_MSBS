function h = plot_component_geometry(ax,geometry,alpha)
%PLOT_COMPONENT_GEOMETRY Full surfaces with one filled legend swatch per role.
if nargin<3, alpha=[]; end
h=gobjects(0);
for c=geometry_components(geometry)
    opacity=c.alpha; if ~isempty(alpha), opacity=alpha; end
    [color,~]=component_plot_style(c);
    h(end+1)=patch(ax,"Faces",c.shape.Faces,"Vertices",c.shape.Vertices, ...
        "FaceColor",color,"FaceAlpha",opacity,"EdgeColor","none", ...
        "HandleVisibility","off","Tag","MSBSGeometryFill","HitTest","off"); %#ok<AGROW>
    register_geometry_legend(ax,c,opacity);
end
end
