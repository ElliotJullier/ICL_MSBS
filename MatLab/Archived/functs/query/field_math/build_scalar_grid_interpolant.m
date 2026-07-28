function F = build_scalar_grid_interpolant(grid, scalarData, method, extrapolationMethod)
%BUILD_SCALAR_GRID_INTERPOLANT Build a griddedInterpolant for scalar grid data.
%
% scalarData must use the project grid convention:
%   scalarData(yIndex, xIndex, zIndex)
%
% The interpolant is therefore constructed with:
%   {grid.y, grid.x, grid.z}
%
% and should be evaluated as:
%   F(Y, X, Z)

if nargin < 3 || strlength(string(method)) == 0
    method = "cubic";
end

if nargin < 4 || strlength(string(extrapolationMethod)) == 0
    extrapolationMethod = "none";
end

expectedSize = [numel(grid.y), numel(grid.x), numel(grid.z)];

if ~isequal(size(scalarData), expectedSize)
    error("scalarData must have size [numel(grid.y), numel(grid.x), numel(grid.z)].");
end

F = griddedInterpolant( ...
    {grid.y(:), grid.x(:), grid.z(:)}, ...
    scalarData, ...
    char(method), ...
    char(extrapolationMethod));
end
