function h = plot_coils_transparent_edges(ax,geometry,varargin)
%PLOT_COILS_TRANSPARENT_EDGES Compatibility wrapper for component surfaces.
% Component role colours replace the former single coil-set colour.
p=inputParser; addParameter(p,"Color",[]); addParameter(p,"Alpha",[]);
addParameter(p,"DisplayName","Geometry"); parse(p,varargin{:});
h=plot_component_geometry(ax,geometry,p.Results.Alpha);
end
