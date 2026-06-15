function result = sample_custom_plane_from_grid(grid, scalarData, q, queryIndex)
%SAMPLE_CUSTOM_PLANE_FROM_GRID Interpolate scalarData on an arbitrary plane.

resolution = q.resolution;
if isscalar(resolution)
    Nu = resolution;
    Nv = resolution;
else
    Nu = resolution(1);
    Nv = resolution(2);
end

p0 = q.point(:).';
n  = q.normal(:).';

if norm(n) < eps
    error("q.normal must be non-zero.");
end
n = n ./ norm(n);

ref = [0 0 1];
if abs(dot(n, ref)) > 0.95
    ref = [0 1 0];
end

e1 = cross(ref, n);
e1 = e1 ./ norm(e1);
e2 = cross(n, e1);
e2 = e2 ./ norm(e2);

corners = [ ...
    min(grid.x) min(grid.y) min(grid.z);
    min(grid.x) min(grid.y) max(grid.z);
    min(grid.x) max(grid.y) min(grid.z);
    min(grid.x) max(grid.y) max(grid.z);
    max(grid.x) min(grid.y) min(grid.z);
    max(grid.x) min(grid.y) max(grid.z);
    max(grid.x) max(grid.y) min(grid.z);
    max(grid.x) max(grid.y) max(grid.z)];

dC = corners - p0;
uC = dC * e1(:);
vC = dC * e2(:);

u = linspace(min(uC), max(uC), Nu);
v = linspace(min(vC), max(vC), Nv);
[U, V] = meshgrid(u, v);

X = p0(1) + U*e1(1) + V*e2(1);
Y = p0(2) + U*e1(2) + V*e2(2);
Z = p0(3) + U*e1(3) + V*e2(3);

F = build_scalar_grid_interpolant(grid, scalarData);
data = F(Y, X, Z);

inside = find_points_inside_grid_domain(grid, X, Y, Z);
X(~inside) = NaN;
Y(~inside) = NaN;
Z(~inside) = NaN;
data(~inside) = NaN;

result = struct();
result.queryIndex = queryIndex;
result.X = X;
result.Y = Y;
result.Z = Z;
result.data = data;
result.inside = inside;
result.resolution = [Nu Nv];
end
