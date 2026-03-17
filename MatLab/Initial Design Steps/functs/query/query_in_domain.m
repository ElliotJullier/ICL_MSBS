function inside = query_in_domain(field, X, Y, Z)
% Returns a logical mask indicating whether query points lie inside the
% stored field bounding box.

xmin = min(field.x); xmax = max(field.x);
ymin = min(field.y); ymax = max(field.y);
zmin = min(field.z); zmax = max(field.z);

inside = (X >= xmin) & (X <= xmax) & ...
         (Y >= ymin) & (Y <= ymax) & ...
         (Z >= zmin) & (Z <= zmax);
end