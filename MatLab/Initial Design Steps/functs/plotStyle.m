function s = plotStyle()
% PLOTSTYLE  Template and documentation for the plotStyle struct used by plot_field.
%
%   s = plotStyle() returns a template plotStyle struct with recommended fields.
%
%   Required fields:
%       None
%
%   Optional fields:
%       s.clim
%           1x2 numeric vector [cmin cmax].
%           Colour limits applied to plane plots.
%           If omitted or empty, plot_field computes limits automatically
%           from all queried plane B values.
%
%       s.showCoils
%           logical scalar.
%           true  -> show coils in overview plot
%           false -> overview is drawn without coil geometry
%
%       s.showOrientationReadout
%           logical scalar.
%           true  -> prints azimuth/elevation when mouse interaction ends
%           false -> no orientation callback
%
%       s.showCoilsInPlaneFigures
%           logical scalar.
%           true  -> single-plane figures show coil/plane intersection
%                    overlays, and multi-plane figures show transparent
%                    3D coil bodies with black edges
%           false -> plane figures contain only the plane field surfaces
%
%   Typical usage:
%       ps = plotStyle();
%       ps.clim = [-0.5 0.5];
%       ps.showCoils = true;
%       ps.showOrientationReadout = true;
%
%   Used by:
%       plot_field(Q_list, plotStyle)

s = struct();
s.clim = [];
s.showCoils = true;
s.showOrientationReadout = true;
s.showCoilsInPlaneFigures = true;
end