function h = add_coil_presence_to_line_plot(ax, lineReq, geometry, colorVal)
%ADD_COIL_PRESENCE_TO_LINE_PLOT Shade coil regions along a line plot.
%
% This implementation samples the line and shades regions whose points lie
% inside each coil's outer envelope/material. It is approximate; a future
% exact version should analytically compute line/annular-cylinder interval
% intersections for each coil.

h = gobjects(0);

if isempty(geometry) || ~isfield(lineReq, 'X') || ~isfield(lineReq, 's')
    return
end

if nargin < 4 || isempty(colorVal)
    colourOrder = get(ax, "ColorOrder");
    colorVal = colourOrder(1, :);
end
colorVal = reshape(double(colorVal), 1, 3);

pts = [lineReq.X(:).'; lineReq.Y(:).'; lineReq.Z(:).'];
s   = lineReq.s(:);

if numel(s) < 2
    return
end

mask = coil_material_mask(pts, geometry);
yl = ylim(ax);

ds = median(abs(diff(s)), 'omitnan');
if ~isfinite(ds) || ds <= 0
    ds = 0;
end

outerColor = 0.80*colorVal + 0.20*[1 1 1];
bodyColor  = colorVal;
boundaryColor = max(0, 0.65*colorVal);

hOuter = draw_mask_spans(ax, s, mask.outer, yl, ds, outerColor, 0.25);
hMaterial = draw_mask_spans(ax, s, mask.material, yl, ds, bodyColor, 0.55);
hBounds = draw_mask_boundaries(ax, s, mask.outer, ds, boundaryColor);

% Return material handles first so the legend swatch uses the main coil-set
% colour rather than the lighter outer-envelope colour.
h = [hMaterial(:); hOuter(:); hBounds(:)];

% Do not use uistack here. In line plots with yyaxis, reordering axes
% children can fail because the children list contains yyaxis-dependent
% graphics objects, patches, and constant-line objects.
end

function h = draw_mask_spans(ax, s, mask, yl, ds, colorVal, alphaVal)
h = gobjects(0);
edges = diff([false, mask(:).', false]);
idxStart = find(edges == 1);
idxEnd   = find(edges == -1) - 1;

for j = 1:numel(idxStart)
    s0 = s(idxStart(j));
    s1 = s(idxEnd(j));

    if ds > 0
        s0 = max(min(s), s0 - 0.5*ds);
        s1 = min(max(s), s1 + 0.5*ds);
    end

    h(end+1,1) = patch(ax, ...
        [s0 s1 s1 s0], ...
        [yl(1) yl(1) yl(2) yl(2)], ...
        colorVal, ...
        'FaceAlpha', alphaVal, ...
        'EdgeColor', 'none', ...
        'DisplayName', 'Coils', ...
        'HandleVisibility', 'off', ...
        'HitTest', 'off'); %#ok<AGROW>
end
end

function h = draw_mask_boundaries(ax, s, mask, ds, colorVal)
h = gobjects(0);
edges = diff([false, mask(:).', false]);
idxStart = find(edges == 1);
idxEnd   = find(edges == -1) - 1;

for j = 1:numel(idxStart)
    s0 = s(idxStart(j));
    s1 = s(idxEnd(j));

    if ds > 0
        s0 = max(min(s), s0 - 0.5*ds);
        s1 = min(max(s), s1 + 0.5*ds);
    end

    h(end+1,1) = xline(ax, s0, '--', ...
        'Color', colorVal, ...
        'LineWidth', 1.0, ...
        'DisplayName', 'Coils', ...
        'HandleVisibility', 'off'); %#ok<AGROW>

    h(end+1,1) = xline(ax, s1, '--', ...
        'Color', colorVal, ...
        'LineWidth', 1.0, ...
        'DisplayName', 'Coils', ...
        'HandleVisibility', 'off'); %#ok<AGROW>
end
end
