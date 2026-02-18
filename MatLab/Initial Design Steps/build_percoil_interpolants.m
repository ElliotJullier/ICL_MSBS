function F = build_percoil_interpolants(field)
% Builds griddedInterpolant objects for each coil's unit field (Bx,By,Bz).

x = field.x; y = field.y; z = field.z;
Ny = numel(y); Nx = numel(x); Nz = numel(z);

nCoils = size(field.mag_field_unit, 3);

F.Bx = cell(1, nCoils);
F.By = cell(1, nCoils);
F.Bz = cell(1, nCoils);

for k = 1:nCoils
    Bk = field.mag_field_unit(:,:,k);  % 3 x Npts

    Bx = reshape(Bk(1,:), [Ny, Nx, Nz]);
    By = reshape(Bk(2,:), [Ny, Nx, Nz]);
    Bz = reshape(Bk(3,:), [Ny, Nx, Nz]);

    F.Bx{k} = griddedInterpolant({y, x, z}, Bx, 'linear', 'none');
    F.By{k} = griddedInterpolant({y, x, z}, By, 'linear', 'none');
    F.Bz{k} = griddedInterpolant({y, x, z}, Bz, 'linear', 'none');
end
end
