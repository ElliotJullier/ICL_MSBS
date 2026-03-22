function set_plane_view(ax, r)
if isfield(r, 'plane')
    switch lower(char(string(r.plane)))
        case "xy"
            view(ax, 0, 90);
        case "xz"
            view(ax, 0, 0);
        case "yz"
            view(ax, 90, 0);
        otherwise
            view(ax, 3);
    end
elseif isfield(r, 'normal')
    n = r.normal(:);
    if norm(n) < eps
        view(ax, 3);
        return
    end
    n = n ./ norm(n);
    view(ax, -n.');
else
    view(ax, 3);
end

axis(ax, 'tight');
camproj(ax, 'orthographic');
end
