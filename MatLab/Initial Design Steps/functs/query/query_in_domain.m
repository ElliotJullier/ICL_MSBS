function inside = query_in_domain(field, X, Y, Z)
xmin = min(field.x); xmax = max(field.x);
ymin = min(field.y); ymax = max(field.y);
zmin = min(field.z); zmax = max(field.z);

inside = (X >= xmin) & (X <= xmax) & ...
         (Y >= ymin) & (Y <= ymax) & ...
         (Z >= zmin) & (Z <= zmax);
end
