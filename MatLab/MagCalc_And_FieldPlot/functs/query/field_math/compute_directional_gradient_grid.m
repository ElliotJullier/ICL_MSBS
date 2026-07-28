function [gradData, dataName] = compute_directional_gradient_grid(grid, scalarData, dataName, gradientDirection)
%COMPUTE_DIRECTIONAL_GRADIENT_GRID Directional derivative of scalarData.
%
% scalarData is stored as scalarData(y,x,z). MATLAB's gradient convention
% for a 3D array is:
%   first output  -> derivative along columns, dimension 2 -> x
%   second output -> derivative along rows,    dimension 1 -> y
%   third output  -> derivative along pages,   dimension 3 -> z

n = gradientDirection(:).';
if isempty(n) || norm(n) < eps
    error("gradientDirection must be non-zero for grid gradient queries.");
end
n = n ./ norm(n);

dx = mean(diff(grid.x));
dy = mean(diff(grid.y));
dz = mean(diff(grid.z));

[dB_dx, dB_dy, dB_dz] = gradient(scalarData, dx, dy, dz);
gradData = n(1)*dB_dx + n(2)*dB_dy + n(3)*dB_dz;

tol = 1e-12;
if norm(n - [1 0 0]) < tol
    dataName = "d" + dataName + "/dx";
elseif norm(n - [0 1 0]) < tol
    dataName = "d" + dataName + "/dy";
elseif norm(n - [0 0 1]) < tol
    dataName = "d" + dataName + "/dz";
else
    dataName = "d" + dataName + "/dn";
end
end
