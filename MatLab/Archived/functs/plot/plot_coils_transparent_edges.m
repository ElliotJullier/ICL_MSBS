function h = plot_coils_transparent_edges(ax, geometry, varargin)
%PLOT_COILS_TRANSPARENT_EDGES Plot filled coil bodies on field plots.
%
% Coils are drawn as semi-transparent bodies. The function name is retained
% for compatibility with existing plotting code.
%
% Optional name-value inputs:
%   "Color"       RGB colour for the coil set. Default uses the axes colour order.
%   "Alpha"       face opacity. Default 0.55.
%   "DisplayName" legend display name. Default "Coils".

p = inputParser;
addParameter(p, "Color", [], @(x)isnumeric(x) && (isempty(x) || numel(x) == 3));
addParameter(p, "Alpha", 0.55, @(x)isnumeric(x) && isscalar(x));
addParameter(p, "DisplayName", "Coils", @(x)isstring(x) || ischar(x));
parse(p, varargin{:});
opts = p.Results;

if nargin < 2 || isempty(geometry) || ~isstruct(geometry) || ...
   ~isfield(geometry, "coil") || isempty(geometry.coil)
    h = gobjects(0);
    return
end

colour = opts.Color;
if isempty(colour)
    colourOrder = get(ax, "ColorOrder");
    colour = colourOrder(1, :);
end
colour = reshape(double(colour), 1, 3);
edgeColour = max(0, 0.65*colour);

coils = geometry.coil;
nCoils = numel(coils);
h = gobjects(nCoils, 1);

for k = 1:nCoils
    if ~isfield(coils(k), "shape") || isempty(coils(k).shape)
        continue
    end

    shp = coils(k).shape;

    if isstruct(shp) && isfield(shp, 'Faces') && isfield(shp, 'Vertices')
        h(k) = patch(ax, ...
            'Faces', shp.Faces, ...
            'Vertices', shp.Vertices, ...
            'FaceColor', colour, ...
            'FaceAlpha', opts.Alpha, ...
            'EdgeColor', edgeColour, ...
            'LineWidth', 1.0, ...
            'DisplayName', char(string(opts.DisplayName)), ...
            'HandleVisibility', 'off', ...
            'HitTest', 'off');
    else
        hp = plot(ax, shp);
        set(hp, ...
            'FaceColor', colour, ...
            'FaceAlpha', opts.Alpha, ...
            'EdgeColor', edgeColour, ...
            'LineWidth', 1.0, ...
            'DisplayName', char(string(opts.DisplayName)), ...
            'HandleVisibility', 'off', ...
            'HitTest', 'off');
        h(k) = hp;
    end
end
end
