function refresh_overview_line_overlay(ax)

if ~isgraphics(ax, 'axes')
    return
end

overlay = getappdata(ax, 'overviewLineOverlay');
if isempty(overlay)
    return
end

eps_scale = getappdata(ax, 'overviewLineOverlayScale');
if isempty(eps_scale)
    eps_scale = 3e-3;
end

drawnow limitrate

% Camera direction
cam_dir = camtarget(ax) - campos(ax);
cam_norm = norm(cam_dir);
if cam_norm < eps
    cam_dir = [1, 1, 1];
    cam_norm = norm(cam_dir);
end
cam_dir = cam_dir ./ cam_norm;

% Scene length from current axes limits
xl = xlim(ax);
yl = ylim(ax);
zl = zlim(ax);

sx = xl(2) - xl(1);
sy = yl(2) - yl(1);
sz = zl(2) - zl(1);

sceneL = max([sx, sy, sz]);
if sceneL <= 0 || ~isfinite(sceneL)
    sceneL = 1;
end

% Negative sign because you found this is the correct visual direction
eps_view = -eps_scale * sceneL;

for k = 1:numel(overlay)
    p0s = overlay(k).p0 + eps_view * cam_dir;
    p1s = overlay(k).p1 + eps_view * cam_dir;

    if isgraphics(overlay(k).hLine)
        set(overlay(k).hLine, ...
            'XData', [p0s(1), p1s(1)], ...
            'YData', [p0s(2), p1s(2)], ...
            'ZData', [p0s(3), p1s(3)]);
    end

    if isgraphics(overlay(k).hStart)
        set(overlay(k).hStart, ...
            'XData', p0s(1), ...
            'YData', p0s(2), ...
            'ZData', p0s(3));
    end

    if isgraphics(overlay(k).hEnd)
        set(overlay(k).hEnd, ...
            'XData', p1s(1), ...
            'YData', p1s(2), ...
            'ZData', p1s(3));
    end
end

end