function coil_shape = extract_coilShape(Ro, Ri, h, rel_pos)
% Build a triangulated surface for an annular cylindrical coil.
%
% INPUTS
%   Ro      outer radius [m]
%   Ri      inner radius [m]
%   h       coil height [m]
%   rel_pos [x y z yaw pitch roll]
%
% OUTPUT
%   coil_shape struct with:
%       .Faces
%       .Vertices

nTheta = 20;
nRad   = 5;

theta = linspace(0, 2*pi, nTheta+1);

% ---------- Outer cylindrical surface ----------
[Theta_o, Z_o] = meshgrid(theta, [-h/2, h/2]);
Xo = Ro * cos(Theta_o);
Yo = Ro * sin(Theta_o);
Zo = Z_o;

fv_o = surf2patch(Xo, Yo, Zo, 'triangles');

% ---------- Inner cylindrical surface ----------
[Theta_i, Z_i] = meshgrid(theta, [-h/2, h/2]);
Xi = Ri * cos(Theta_i);
Yi = Ri * sin(Theta_i);
Zi = Z_i;

fv_i = surf2patch(Xi, Yi, Zi, 'triangles');
fv_i.faces = fliplr(fv_i.faces); % reverse normals for inner wall

% ---------- Top annular face ----------
[Theta_t, R_t] = meshgrid(theta, linspace(Ri, Ro, nRad));
Xt = R_t .* cos(Theta_t);
Yt = R_t .* sin(Theta_t);
Zt = (h/2) * ones(size(Xt));

fv_t = surf2patch(Xt, Yt, Zt, 'triangles');

% ---------- Bottom annular face ----------
[Theta_b, R_b] = meshgrid(theta, linspace(Ri, Ro, nRad));
Xb = R_b .* cos(Theta_b);
Yb = R_b .* sin(Theta_b);
Zb = (-h/2) * ones(size(Xb));

fv_b = surf2patch(Xb, Yb, Zb, 'triangles');
fv_b.faces = fliplr(fv_b.faces); % reverse normals for bottom face

% ---------- Combine all patch pieces ----------
V = [];
F = [];

[V, F] = append_patch(V, F, fv_o.vertices, fv_o.faces);
[V, F] = append_patch(V, F, fv_i.vertices, fv_i.faces);
[V, F] = append_patch(V, F, fv_t.vertices, fv_t.faces);
[V, F] = append_patch(V, F, fv_b.vertices, fv_b.faces);

% Transform vertices from local to global
V_global = coord_local2global(V.', rel_pos).';

coil_shape = struct();
coil_shape.Faces    = F;
coil_shape.Vertices = V_global;

end

function [Vout, Fout] = append_patch(Vin, Fin, Vadd, Fadd)
offset = size(Vin, 1);
Vout = [Vin; Vadd];
Fout = [Fin; Fadd + offset];
end