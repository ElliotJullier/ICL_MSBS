function result = get_fundamental_plane(field, I, q)
mag_field = combine_coil_fields(field.mag_field_unit, I);

switch string(q.component)
    case "x"
        comp = 1;
    case "y"
        comp = 2;
    case "z"
        comp = 3;
    otherwise
        error('q.component must be "x", "y", or "z".');
end

Ny = numel(field.y);
Nx = numel(field.x);
Nz = numel(field.z);

B_full = reshape(mag_field(comp,:), [Ny, Nx, Nz]);

switch lower(string(q.plane))
    case "xy"
        [~, iz] = min(abs(field.z - q.value));
        X_plane = squeeze(field.X(:,:,iz));
        Y_plane = squeeze(field.Y(:,:,iz));
        Z_plane = squeeze(field.Z(:,:,iz));
        B_plane = squeeze(B_full(:,:,iz));
    case "xz"
        [~, iy] = min(abs(field.y - q.value));
        X_plane = squeeze(field.X(iy,:,:)).';
        Y_plane = squeeze(field.Y(iy,:,:)).';
        Z_plane = squeeze(field.Z(iy,:,:)).';
        B_plane = squeeze(B_full(iy,:,:)).';
    case "yz"
        [~, ix] = min(abs(field.x - q.value));
        X_plane = squeeze(field.X(:,ix,:)).';
        Y_plane = squeeze(field.Y(:,ix,:)).';
        Z_plane = squeeze(field.Z(:,ix,:)).';
        B_plane = squeeze(B_full(:,ix,:)).';
    otherwise
        error('q.plane must be "xy", "xz", or "yz".');
end

result = struct();
result.type = "fundamental_plane";
result.component = q.component;
result.plane = q.plane;
result.value = q.value;
result.X = X_plane;
result.Y = Y_plane;
result.Z = Z_plane;
result.B = B_plane;

if isfield(q, 'group')
    result.group = q.group;
end
if isfield(q, 'inOverview')
    result.inOverview = q.inOverview;
else
    result.inOverview = false;
end
if isfield(q, 'legendName')
    result.legendName = q.legendName;
end
end
