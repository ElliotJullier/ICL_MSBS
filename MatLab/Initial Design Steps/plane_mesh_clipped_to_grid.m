function [X, Y, Z] = plane_mesh_clipped_to_grid(field, planePoint, planeNormal)
% Defines a plane p(u,v)=p0+u*e1+v*e2 and clips it to the field bounding box.

p0 = planePoint(:).';
n  = planeNormal(:).';
if norm(n) < eps
    error("planeNormal must be non-zero.");
end
n = n ./ norm(n);

ref = [0 0 1];
if abs(dot(n, ref)) > 0.95
    ref = [0 1 0];
end
e1 = cross(ref, n); e1 = e1 ./ norm(e1);
e2 = cross(n, e1);

xmin = min(field.x); xmax = max(field.x);
ymin = min(field.y); ymax = max(field.y);
zmin = min(field.z); zmax = max(field.z);

corners = [ ...
    xmin ymin zmin;
    xmin ymin zmax;
    xmin ymax zmin;
    xmin ymax zmax;
    xmax ymin zmin;
    xmax ymin zmax;
    xmax ymax zmin;
    xmax ymax zmax ];

dC = corners - p0;
uC = dC*e1(:);
vC = dC*e2(:);

uMin = min(uC); uMax = max(uC);
vMin = min(vC); vMax = max(vC);

dx = mean(diff(field.x));
dy = mean(diff(field.y));
dz = mean(diff(field.z));
ds = min([dx, dy, dz]);

Nu = max(10, ceil((uMax-uMin)/ds));
Nv = max(10, ceil((vMax-vMin)/ds));

u = linspace(uMin, uMax, Nu);
v = linspace(vMin, vMax, Nv);
[U, V] = meshgrid(u, v);

X = p0(1) + U*e1(1) + V*e2(1);
Y = p0(2) + U*e1(2) + V*e2(2);
Z = p0(3) + U*e1(3) + V*e2(3);

inside = (X>=xmin & X<=xmax & Y>=ymin & Y<=ymax & Z>=zmin & Z<=zmax);
X(~inside) = NaN; Y(~inside) = NaN; Z(~inside) = NaN;
end
