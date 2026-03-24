function add_coil_presence_to_plane_plot(ax, req, load_filename)
% Overlay coil/plane intersection on a single plane plot.
%
% Draws:
%   - semi-transparent grey surface where the plane intersects coil material
%   - dashed black curves for outer boundary and bore boundary
%
% Works directly from the sampled plane grid in req.X, req.Y, req.Z.

if nargin < 3 || strlength(string(load_filename)) == 0
    return
end

[coils, geom, ~] = load_coilfield_mat(load_filename);

if isempty(coils) || ~isfield(req, 'X') || ~isfield(req, 'Y') || ~isfield(req, 'Z')
    return
end

for k = 1:numel(coils)
    pts = [req.X(:).'; req.Y(:).'; req.Z(:).'];
    pts_local = coord_global2local(pts, coils(k).rel_pos);

    xL = reshape(pts_local(1,:), size(req.X));
    yL = reshape(pts_local(2,:), size(req.Y));
    zL = reshape(pts_local(3,:), size(req.Z));

    rho = hypot(xL, yL);

    inside_outer = ...
        (rho <= geom.coil_outer_radius) & ...
        (abs(zL) <= geom.coil_height/2);

    inside_bore = ...
        (rho < geom.coil_inner_radius) & ...
        (abs(zL) <= geom.coil_height/2);

    inside_material = inside_outer & ~inside_bore;

    % Semi-transparent grey annulus on the plane
    hSurf = surf(ax, req.X, req.Y, req.Z, ...
        'FaceColor', [0.55 0.55 0.55], ...
        'EdgeColor', 'none', ...
        'FaceAlpha', 'flat', ...
        'AlphaData', 0.14 * double(inside_material), ...
        'AlphaDataMapping', 'none', ...
        'HandleVisibility', 'off', ...
        'HitTest', 'off');

    % Outer boundary
    hOuter = draw_plane_mask_boundary(ax, req, inside_outer, 'k-', 1.4);

    % Bore boundary
    hBore = draw_plane_mask_boundary(ax, req, inside_bore, 'k--', 1.1);

    % Keep overlays behind the field surface color where possible
    uistack(hSurf, 'bottom');
    if ~isempty(hOuter)
        uistack(hOuter, 'top');
    end
    if ~isempty(hBore)
        uistack(hBore, 'top');
    end
end

end


function hLines = draw_plane_mask_boundary(ax, req, mask, lineSpec, lineWidth)
% Find the boundary of a logical mask in parameter space, then map it back
% onto the 3D plane surface.

hLines = gobjects(0);

if ~any(mask(:))
    return
end

[nr, nc] = size(mask);
u = 1:nc;
v = 1:nr;

C = contourc(u, v, double(mask), [0.5 0.5]);

if isempty(C)
    return
end

idx = 1;
while idx < size(C, 2)
    nPts = C(2, idx);
    seg = C(:, idx+1:idx+nPts);

    uq = seg(1, :);
    vq = seg(2, :);

    [U, V] = meshgrid(u, v);

    Xq = interp2(U, V, req.X, uq, vq, 'linear');
    Yq = interp2(U, V, req.Y, uq, vq, 'linear');
    Zq = interp2(U, V, req.Z, uq, vq, 'linear');

    hLines(end+1,1) = plot3(ax, Xq, Yq, Zq, lineSpec, ...
        'LineWidth', lineWidth, ...
        'HandleVisibility', 'off', ...
        'HitTest', 'off'); %#ok<AGROW>

    idx = idx + nPts + 1;
end

end