function s = plotStyle()
%PLOTSTYLE Return a template plotStyle struct used by plot_field.
%
% Optional fields:
%   s.clim
%       1x2 numeric vector [cmin cmax]. If omitted or empty, plot_field
%       computes symmetric limits from plane data.
%
%   s.Q_file
%       string filename of the loaded Q file. Used only for figure names and
%       titles so generated figures can be traced back to the query output.
%
% Coil display is controlled per query using the "ShowCoils" name-value
% option in the query builder functions. Overview plots always show coils.
%
%   s.showOrientationReadout
%       true  -> prints azimuth/elevation when mouse interaction ends.
%       false -> no orientation callback.
%
% Typical usage:
%   ps = plotStyle();
%   ps.clim = [-0.5 0.5]*1e-3;
%   plot_field(Q, ps)

s = struct();
s.clim = [];
s.Q_file = "";
s.showOrientationReadout = true;
end
