function result = sample_fundamental_plane_from_grid(grid, scalarData, q, queryIndex)
%SAMPLE_FUNDAMENTAL_PLANE_FROM_GRID Slice scalarData on an xy/xz/yz plane.

[Xg, Yg, Zg] = meshgrid(grid.x, grid.y, grid.z);

switch lower(string(q.plane))
    case "xy"
        [~, idx] = min(abs(grid.z - q.planeOffset));
        X = Xg(:,:,idx);
        Y = Yg(:,:,idx);
        Z = Zg(:,:,idx);
        data = scalarData(:,:,idx);
        actualOffset = grid.z(idx);

    case "xz"
        [~, idx] = min(abs(grid.y - q.planeOffset));
        X = squeeze(Xg(idx,:,:)).';
        Y = squeeze(Yg(idx,:,:)).';
        Z = squeeze(Zg(idx,:,:)).';
        data = squeeze(scalarData(idx,:,:)).';
        actualOffset = grid.y(idx);

    case "yz"
        [~, idx] = min(abs(grid.x - q.planeOffset));
        X = squeeze(Xg(:,idx,:)).';
        Y = squeeze(Yg(:,idx,:)).';
        Z = squeeze(Zg(:,idx,:)).';
        data = squeeze(scalarData(:,idx,:)).';
        actualOffset = grid.x(idx);

    otherwise
        error('q.plane must be "xy", "xz", or "yz".');
end

result = struct();
result.queryIndex = queryIndex;
result.X = X;
result.Y = Y;
result.Z = Z;
result.data = data;
result.inside = true(size(data));
result.requestedPlaneOffset = q.planeOffset;
result.planeOffset = actualOffset;
end
