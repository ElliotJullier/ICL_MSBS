function inside = find_points_inside_grid_domain(grid, X, Y, Z)
%FIND_POINTS_INSIDE_GRID_DOMAIN Return true for points inside grid bounds.

xmin = min(grid.x); xmax = max(grid.x);
ymin = min(grid.y); ymax = max(grid.y);
zmin = min(grid.z); zmax = max(grid.z);

tol = 64*eps(max(1,max(abs([xmin xmax ymin ymax zmin zmax]))));
inside = (X >= xmin-tol) & (X <= xmax+tol) & ...
         (Y >= ymin-tol) & (Y <= ymax+tol) & ...
         (Z >= zmin-tol) & (Z <= zmax+tol);
end
