function set_plane_view(ax, r)
if isfield(r, 'query') && isfield(r.query, 'plane')
    planeName = r.query.plane;
elseif isfield(r, 'plane')
    planeName = r.plane;
else
    planeName = "";
end

if strlength(string(planeName)) > 0
    switch lower(char(string(planeName)))
        case "xy"
            view(ax, 0, 90);
        case "xz"
            view(ax, 0, 0);
        case "yz"
            view(ax, 90, 0);
        otherwise
            view(ax, 3);
    end
elseif isfield(r, 'query') && isfield(r.query, 'normal')
    n = r.query.normal(:);
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
