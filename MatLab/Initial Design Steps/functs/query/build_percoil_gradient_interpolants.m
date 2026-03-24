function G = build_percoil_gradient_interpolants(field)
% Builds per-coil interpolants for all spatial derivatives of B.
%
% Returns struct G with:
% G.dBx_dx{k}, G.dBx_dy{k}, G.dBx_dz{k}
% G.dBy_dx{k}, G.dBy_dy{k}, G.dBy_dz{k}
% G.dBz_dx{k}, G.dBz_dy{k}, G.dBz_dz{k}

x = field.x; 
y = field.y; 
z = field.z;

dx = mean(diff(x));
dy = mean(diff(y));
dz = mean(diff(z));

Ny = numel(y); 
Nx = numel(x); 
Nz = numel(z);

nCoils = size(field.mag_field_unit, 3);

for k = 1:nCoils

    Bk = field.mag_field_unit(:,:,k);

    Bx = reshape(Bk(1,:), [Ny, Nx, Nz]);
    By = reshape(Bk(2,:), [Ny, Nx, Nz]);
    Bz = reshape(Bk(3,:), [Ny, Nx, Nz]);

    % MATLAB gradient returns derivatives in dimension order:
    % (dim1, dim2, dim3) → (y, x, z)

    [dBx_dx, dBx_dy, dBx_dz] = gradient(Bx, dx, dy, dz);
    [dBy_dx, dBy_dy, dBy_dz] = gradient(By, dx, dy, dz);
    [dBz_dx, dBz_dy, dBz_dz] = gradient(Bz, dx, dy, dz);

    % Build interpolants
    G.dBx_dx{k} = griddedInterpolant({y,x,z}, dBx_dx, 'cubic', 'none');
    G.dBx_dy{k} = griddedInterpolant({y,x,z}, dBx_dy, 'cubic', 'none');
    G.dBx_dz{k} = griddedInterpolant({y,x,z}, dBx_dz, 'cubic', 'none');

    G.dBy_dx{k} = griddedInterpolant({y,x,z}, dBy_dx, 'cubic', 'none');
    G.dBy_dy{k} = griddedInterpolant({y,x,z}, dBy_dy, 'cubic', 'none');
    G.dBy_dz{k} = griddedInterpolant({y,x,z}, dBy_dz, 'cubic', 'none');

    G.dBz_dx{k} = griddedInterpolant({y,x,z}, dBz_dx, 'cubic', 'none');
    G.dBz_dy{k} = griddedInterpolant({y,x,z}, dBz_dy, 'cubic', 'none');
    G.dBz_dz{k} = griddedInterpolant({y,x,z}, dBz_dz, 'cubic', 'none');

end

end
