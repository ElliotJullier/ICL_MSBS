function add_coil_presence_to_line_plot(ax, lineReq, load_filename)
% Shade projected coil presence on a 2D line plot.
%
% Visual meaning:
%   - light grey  = inside outer coil envelope (including bore)
%   - darker grey = inside actual winding material
%   - dashed lines = outer projected coil boundaries
%
% Geometry test is done pointwise along the sampled line in coil-local coords:
%   outer:    rho <= Ro   and |z| <= h/2
%   bore:     rho <  Ri   and |z| <= h/2
%   material: outer & ~bore

if nargin < 3 || strlength(string(load_filename)) == 0
    return
end

[coils, geom, ~] = load_coilfield_mat(load_filename);

if isempty(coils) || ~isfield(lineReq, 'X') || ~isfield(lineReq, 's')
    return
end

pts = [lineReq.X(:).'; lineReq.Y(:).'; lineReq.Z(:).'];
s   = lineReq.s(:);

if numel(s) < 2
    return
end

yl = ylim(ax);

% Sample spacing used to slightly widen spans to cell widths
ds = median(abs(diff(s)), 'omitnan');
if ~isfinite(ds) || ds <= 0
    ds = 0;
end

hOuter    = gobjects(0);
hMaterial = gobjects(0);
hBounds   = gobjects(0);

legendHandleMade = false;

for k = 1:numel(coils)
    pts_local = coord_global2local(pts, coils(k).rel_pos);

    rho = hypot(pts_local(1,:), pts_local(2,:));
    zc  = pts_local(3,:);

    inside_outer = ...
        (rho <= geom.coil_outer_radius) & ...
        (abs(zc) <= geom.coil_height/2);

    inside_bore = ...
        (rho < geom.coil_inner_radius) & ...
        (abs(zc) <= geom.coil_height/2);

    inside_material = inside_outer & ~inside_bore;

    % Draw outer envelope first (light grey)
    hOuter_k = draw_mask_spans(ax, s, inside_outer, yl, ds, [0.5 0.5 0.5], 0.10);

    % Draw winding material on top (darker grey)
    hMaterial_k = draw_mask_spans(ax, s, inside_material, yl, ds, [0.3 0.3 0.3], 0.16);

    % Draw dashed boundary lines at outer projected edges
    [hBounds_k, ~] = draw_mask_boundaries(ax, s, inside_outer, ds, [0.35 0.35 0.35]);

    hOuter    = [hOuter; hOuter_k]; %#ok<AGROW>
    hMaterial = [hMaterial; hMaterial_k]; %#ok<AGROW>
    hBounds   = [hBounds; hBounds_k]; %#ok<AGROW>

    % Give only one legend entry total
    if ~legendHandleMade
        if ~isempty(hBounds_k)
            set(hBounds_k(1), 'DisplayName', 'Coil', 'HandleVisibility', 'on');
            if numel(hBounds_k) > 1
                set(hBounds_k(2:end), 'HandleVisibility', 'off');
            end
            legendHandleMade = true;
        elseif ~isempty(hOuter_k)
            set(hOuter_k(1), 'DisplayName', 'Coil', 'HandleVisibility', 'on');
            if numel(hOuter_k) > 1
                set(hOuter_k(2:end), 'HandleVisibility', 'off');
            end
            legendHandleMade = true;
        end
    else
        if ~isempty(hOuter_k)
            set(hOuter_k, 'HandleVisibility', 'off');
        end
        if ~isempty(hMaterial_k)
            set(hMaterial_k, 'HandleVisibility', 'off');
        end
        if ~isempty(hBounds_k)
            set(hBounds_k, 'HandleVisibility', 'off');
        end
    end
end

% Keep patches behind plotted data
if ~isempty(hOuter)
    uistack(hOuter, 'bottom');
end
if ~isempty(hMaterial)
    uistack(hMaterial, 'bottom');
end
if ~isempty(hBounds)
    uistack(hBounds, 'bottom');
end

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
        'HandleVisibility', 'off', ...
        'HitTest', 'off'); %#ok<AGROW>
end

end


function [h, edgeVals] = draw_mask_boundaries(ax, s, mask, ds, colorVal)

h = gobjects(0);
edgeVals = [];

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

    edgeVals = [edgeVals; s0; s1]; %#ok<AGROW>

    h(end+1,1) = xline(ax, s0, '--', ...
        'Color', colorVal, ...
        'LineWidth', 1.0, ...
        'HandleVisibility', 'off'); %#ok<AGROW>

    h(end+1,1) = xline(ax, s1, '--', ...
        'Color', colorVal, ...
        'LineWidth', 1.0, ...
        'HandleVisibility', 'off'); %#ok<AGROW>
end

end