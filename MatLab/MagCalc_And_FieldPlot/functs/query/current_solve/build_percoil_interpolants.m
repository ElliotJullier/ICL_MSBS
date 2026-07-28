function F = build_percoil_interpolants(dataset)
%BUILD_PERCOIL_INTERPOLANTS Build B-field interpolants for each field set.
%
% Requires dataset.B(y,x,z,component,coil) and
% dataset.supportsSuperposition=true. Used by current solving only.

if ~isfield(dataset, "B") || ~dataset.supportsSuperposition
    error("build_percoil_interpolants requires a superposable dataset.B.");
end

grid = dataset.grid;
nCoils = size(dataset.B, 5);

F.Bx = cell(1, nCoils);
F.By = cell(1, nCoils);
F.Bz = cell(1, nCoils);

for k = 1:nCoils
    F.Bx{k} = griddedInterpolant({grid.y, grid.x, grid.z}, dataset.B(:,:,:,1,k), 'cubic', 'none');
    F.By{k} = griddedInterpolant({grid.y, grid.x, grid.z}, dataset.B(:,:,:,2,k), 'cubic', 'none');
    F.Bz{k} = griddedInterpolant({grid.y, grid.x, grid.z}, dataset.B(:,:,:,3,k), 'cubic', 'none');
end
end
