function set_plane_view(ax, r)
% Sets the camera to look normal to a queried plane.

if isfield(r, 'plane')
    switch lower(string(r.plane))
        case "xy"
            view(ax, 0, 90);   % top-down
        case "xz"
            view(ax, 0, 0);    % look along -y / side-on
        case "yz"
            view(ax, 90, 0);   % look along -x / front-on
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

    % Camera should look towards the plane along the opposite normal
    view(ax, -n.');

else
    view(ax, 3);
end

axis(ax, 'tight');
camproj(ax, 'orthographic');

end