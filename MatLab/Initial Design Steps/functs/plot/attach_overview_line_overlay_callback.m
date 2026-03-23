function attach_overview_line_overlay_callback(ax, overview_lines, eps_scale)

if nargin < 3 || isempty(eps_scale)
    eps_scale = 3e-3;
end

% Build overlay objects once from original geometry
overlay = struct([]);
for k = 1:numel(overview_lines)
    r = overview_lines{k};

    p0 = [r.X(1),   r.Y(1),   r.Z(1)];
    p1 = [r.X(end), r.Y(end), r.Z(end)];

    % Create graphics objects with temporary positions
    hLine = plot3(ax, [p0(1), p1(1)], [p0(2), p1(2)], [p0(3), p1(3)], ...
        'k:', 'LineWidth', 1.8, 'HitTest', 'off');

    hStart = plot3(ax, p0(1), p0(2), p0(3), 'ko', ...
        'MarkerFaceColor', 'k', 'MarkerSize', 6, 'HitTest', 'off');

    hEnd = plot3(ax, p1(1), p1(2), p1(3), 'kd', ...
        'MarkerFaceColor', 'k', 'MarkerSize', 7, 'HitTest', 'off');

    overlay(k).p0 = p0;
    overlay(k).p1 = p1;
    overlay(k).hLine  = hLine;
    overlay(k).hStart = hStart;
    overlay(k).hEnd   = hEnd;
end

% Store in axes appdata
setappdata(ax, 'overviewLineOverlay', overlay);
setappdata(ax, 'overviewLineOverlayScale', eps_scale);

% Initial refresh
refresh_overview_line_overlay(ax);

% Recompute after view/camera updates
listener = addlistener(ax, 'MarkedClean', @(~,~) refresh_overview_line_overlay(ax));
setappdata(ax, 'overviewLineOverlayListener', listener);

end