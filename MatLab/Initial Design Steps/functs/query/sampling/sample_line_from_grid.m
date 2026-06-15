function result = sample_line_from_grid(grid, scalarData, q, queryIndex)
%SAMPLE_LINE_FROM_GRID Interpolate scalarData(y,x,z) along a line.

p0 = q.start(:).';
p1 = q.end(:).';

t = linspace(0, 1, q.nPoints).';
X = p0(1) + t*(p1(1)-p0(1));
Y = p0(2) + t*(p1(2)-p0(2));
Z = p0(3) + t*(p1(3)-p0(3));

F = griddedInterpolant({grid.y, grid.x, grid.z}, scalarData, 'cubic', 'none');
data = F(Y, X, Z);

inside = find_points_inside_grid_domain(grid, X, Y, Z);
data(~inside) = NaN;

dxyz = [X - X(1), Y - Y(1), Z - Z(1)];
s = sqrt(sum(dxyz.^2, 2));

result = struct();
result.queryIndex = queryIndex;
result.X = X;
result.Y = Y;
result.Z = Z;
result.s = s;
result.data = data;
result.inside = inside;
end
