function [X_plane, Y_plane, Z_plane, B_plane] = get_fundamental_plane(field, I, dir, planeName, planeValue)
% Extracts one of the stored fundamental planes directly from the saved
% field grid without interpolation.
%
% planeName: "xy", "xz", or "yz"
% planeValue: coordinate of that plane (e.g. z=0 for xy plane)

mag_field = combine_coil_fields(field.mag_field_unit, I);

switch string(dir)
    case "x"
        comp = 1;
    case "y"
        comp = 2;
    case "z"
        comp = 3;
    otherwise
        error('dir must be "x", "y", or "z".');
end

Ny = numel(field.y);
Nx = numel(field.x);
Nz = numel(field.z);

B_full = reshape(mag_field(comp,:), [Ny, Nx, Nz]);

switch lower(string(planeName))
    case "xy"
        [~, iz] = min(abs(field.z - planeValue));

        X_plane = squeeze(field.X(:,:,iz));
        Y_plane = squeeze(field.Y(:,:,iz));
        Z_plane = squeeze(field.Z(:,:,iz));
        B_plane = squeeze(B_full(:,:,iz));

    case "xz"
        [~, iy] = min(abs(field.y - planeValue));

        X_plane = squeeze(field.X(iy,:,:));
        Y_plane = squeeze(field.Y(iy,:,:));
        Z_plane = squeeze(field.Z(iy,:,:));
        B_plane = squeeze(B_full(iy,:,:));

        % Match dimensions for surf
        X_plane = X_plane.';
        Y_plane = Y_plane.';
        Z_plane = Z_plane.';
        B_plane = B_plane.';

    case "yz"
        [~, ix] = min(abs(field.x - planeValue));

        X_plane = squeeze(field.X(:,ix,:));
        Y_plane = squeeze(field.Y(:,ix,:));
        Z_plane = squeeze(field.Z(:,ix,:));
        B_plane = squeeze(B_full(:,ix,:));

        % Match dimensions for surf
        X_plane = X_plane.';
        Y_plane = Y_plane.';
        Z_plane = Z_plane.';
        B_plane = B_plane.';

    otherwise
        error('planeName must be "xy", "xz", or "yz".');
end
end
