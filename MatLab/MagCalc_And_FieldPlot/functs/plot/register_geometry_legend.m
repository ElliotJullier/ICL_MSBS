function h = register_geometry_legend(ax,component,alpha)
%REGISTER_GEOMETRY_LEGEND One filled swatch per role, independent of contours.
role=lower(string(component.role)); tag="MSBSGeometryLegend_"+role;
h=findobj(ax,"Type","patch","Tag",tag);
if ~isempty(h), h=h(1); return; end
[color,label]=component_plot_style(component);
h=patch(ax,NaN,NaN,color,"FaceAlpha",alpha,"EdgeColor","none", ...
    "DisplayName",label,"Tag",tag,"HitTest","off");
end
