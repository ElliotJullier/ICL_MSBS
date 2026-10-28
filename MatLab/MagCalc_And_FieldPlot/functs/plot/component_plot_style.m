function [color,label] = component_plot_style(component)
%COMPONENT_PLOT_STYLE Role palette applied at plot time, including older Qs.
switch lower(string(component.role))
    case "coil", color=[0.20 0.65 0.30]; label="Coils";
    case "yoke", color=[0.25 0.25 0.25]; label="Yokes";
    case "core", color=[0.60 0.30 0.78]; label="Cores";
    otherwise, color=component.color; label=string(component.role);
end
end
