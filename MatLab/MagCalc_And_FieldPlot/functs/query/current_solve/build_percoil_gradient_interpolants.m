function G = build_percoil_gradient_interpolants(dataset)
%BUILD_PERCOIL_GRADIENT_INTERPOLANTS Build per-coil gradient interpolants.
%
% Used only for current solving. For query-time gradient plots, the code
% computes gradients of the already-combined scalar field instead.
%
% MATLAB gradient convention for arrays B(y,x,z):
%   first output  -> derivative along columns, dimension 2 -> x
%   second output -> derivative along rows,    dimension 1 -> y
%   third output  -> derivative along pages,   dimension 3 -> z

if ~isfield(dataset, "B") || ~dataset.supportsSuperposition
    error("build_percoil_gradient_interpolants requires a superposable dataset.B.");
end

grid = dataset.grid;
dx = mean(diff(grid.x));
dy = mean(diff(grid.y));
dz = mean(diff(grid.z));

nCoils = size(dataset.B, 5);

for k = 1:nCoils
    Bx = dataset.B(:,:,:,1,k);
    By = dataset.B(:,:,:,2,k);
    Bz = dataset.B(:,:,:,3,k);

    [dBx_dx, dBx_dy, dBx_dz] = gradient(Bx, dx, dy, dz);
    [dBy_dx, dBy_dy, dBy_dz] = gradient(By, dx, dy, dz);
    [dBz_dx, dBz_dy, dBz_dz] = gradient(Bz, dx, dy, dz);

    G.dBx_dx{k} = griddedInterpolant({grid.y,grid.x,grid.z}, dBx_dx, 'cubic', 'none');
    G.dBx_dy{k} = griddedInterpolant({grid.y,grid.x,grid.z}, dBx_dy, 'cubic', 'none');
    G.dBx_dz{k} = griddedInterpolant({grid.y,grid.x,grid.z}, dBx_dz, 'cubic', 'none');

    G.dBy_dx{k} = griddedInterpolant({grid.y,grid.x,grid.z}, dBy_dx, 'cubic', 'none');
    G.dBy_dy{k} = griddedInterpolant({grid.y,grid.x,grid.z}, dBy_dy, 'cubic', 'none');
    G.dBy_dz{k} = griddedInterpolant({grid.y,grid.x,grid.z}, dBy_dz, 'cubic', 'none');

    G.dBz_dx{k} = griddedInterpolant({grid.y,grid.x,grid.z}, dBz_dx, 'cubic', 'none');
    G.dBz_dy{k} = griddedInterpolant({grid.y,grid.x,grid.z}, dBz_dy, 'cubic', 'none');
    G.dBz_dz{k} = griddedInterpolant({grid.y,grid.x,grid.z}, dBz_dz, 'cubic', 'none');
end
end
