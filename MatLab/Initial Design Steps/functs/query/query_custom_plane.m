function result = query_custom_plane(field, F, I, q)
% Queries a field component on a custom plane defined by a point and normal.
%
% Required fields in q:
%   q.point       [1x3]
%   q.normal      [1x3]
%   q.component   "x", "y", or "z"
%
% Optional:
%   q.resolution  scalar or [Nu Nv]

% ------------------------- Defaults -------------------------
if ~isfield(q, 'resolution')
    q.resolution = [150 150];
end

if isscalar(q.resolution)
    Nu = q.resolution;
    Nv = q.resolution;
else
    Nu = q.resolution(1);
    Nv = q.resolution(2);
end

p0 = q.point(:).';
n  = q.normal(:).';

if norm(n) < eps
    error("q.normal must be non-zero.");
end

n = n ./ norm(n);

% ------------------------- Build plane basis -------------------------
% Choose a reference vector not parallel to n
ref = [0 0 1];
if abs(dot(n, ref)) > 0.95
    ref = [0 1 0];
end

e1 = cross(ref, n);
e1 = e1 ./ norm(e1);

e2 = cross(n, e1);
e2 = e2 ./ norm(e2);

% ------------------------- Domain bounding box -------------------------
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

% ------------------------- Project corners into plane coordinates -------------------------
dC = corners - p0; % global coord dist from each corner to start of plane

uC = dC * e1(:);
vC = dC * e2(:);

uMin = min(uC); uMax = max(uC);
vMin = min(vC); vMax = max(vC);

u = linspace(uMin, uMax, Nu);
v = linspace(vMin, vMax, Nv);
[U, V] = meshgrid(u, v);

% ------------------------- Build plane points in global coordinates -------------------------
X = p0(1) + U*e1(1) + V*e2(1);
Y = p0(2) + U*e1(2) + V*e2(2);
Z = p0(3) + U*e1(3) + V*e2(3);

% ------------------------- Evaluate field component -------------------------
B = zeros(size(X));

for k = 1:numel(I)
    switch string(q.component)
        case "x"
            Bk = F.Bx{k}(Y, X, Z);
        case "y"
            Bk = F.By{k}(Y, X, Z);
        case "z"
            Bk = F.Bz{k}(Y, X, Z);
        otherwise
            error('component must be "x", "y", or "z".');
    end

    B = B + I(k)*Bk;
end

% ------------------------- Mask outside field domain -------------------------
inside = query_in_domain(field, X, Y, Z);

X(~inside) = NaN;
Y(~inside) = NaN;
Z(~inside) = NaN;
B(~inside) = NaN;

% ------------------------- Package result -------------------------
result = struct();
result.type = "custom_plane";
result.component = q.component;
result.point = q.point;
result.normal = q.normal;
result.resolution = [Nu Nv];
result.X = X;
result.Y = Y;
result.Z = Z;
result.B = B;
end
