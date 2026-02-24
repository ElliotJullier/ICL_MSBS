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

    [dBx_dy, dBx_dx, dBx_dz] = gradient(Bx, dy, dx, dz);
    [dBy_dy, dBy_dx, dBy_dz] = gradient(By, dy, dx, dz);
    [dBz_dy, dBz_dx, dBz_dz] = gradient(Bz, dy, dx, dz);

    % Build interpolants
    G.dBx_dx{k} = griddedInterpolant({y,x,z}, dBx_dx, 'linear', 'none');
    G.dBx_dy{k} = griddedInterpolant({y,x,z}, dBx_dy, 'linear', 'none');
    G.dBx_dz{k} = griddedInterpolant({y,x,z}, dBx_dz, 'linear', 'none');

    G.dBy_dx{k} = griddedInterpolant({y,x,z}, dBy_dx, 'linear', 'none');
    G.dBy_dy{k} = griddedInterpolant({y,x,z}, dBy_dy, 'linear', 'none');
    G.dBy_dz{k} = griddedInterpolant({y,x,z}, dBy_dz, 'linear', 'none');

    G.dBz_dx{k} = griddedInterpolant({y,x,z}, dBz_dx, 'linear', 'none');
    G.dBz_dy{k} = griddedInterpolant({y,x,z}, dBz_dy, 'linear', 'none');
    G.dBz_dz{k} = griddedInterpolant({y,x,z}, dBz_dz, 'linear', 'none');

end

end
