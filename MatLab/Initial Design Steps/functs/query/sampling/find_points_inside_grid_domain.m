function inside = find_points_inside_grid_domain(grid, X, Y, Z)
%FIND_POINTS_INSIDE_GRID_DOMAIN Return true for points inside grid bounds.

xmin = min(grid.x); xmax = max(grid.x);
ymin = min(grid.y); ymax = max(grid.y);
zmin = min(grid.z); zmax = max(grid.z);

inside = (X >= xmin) & (X <= xmax) & ...
         (Y >= ymin) & (Y <= ymax) & ...
         (Z >= zmin) & (Z <= zmax);
end
