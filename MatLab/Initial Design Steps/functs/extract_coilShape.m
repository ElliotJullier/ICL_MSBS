function coil_shape = extract_coilShape(R, r, N, wire_R, rel_pos)

h = (pi*wire_R^2*N)/((R-r)*0.7); % area matching including a 70% packing efficiency factor
% Maximum packing density of spheres is 74% and of circles is 91%, 3D
% geometry of coils + space for structural supports mean 70% is
% conservative estimate
[R_grid, theta_grid, z_grid] = meshgrid([r, R], linspace(0, 2*pi, 50), [-h/2, h/2]);
% [R_grid, theta_grid, z_grid] = meshgrid([r, R], linspace(0, 2*pi, 50), [0, h]);
theta_grid = reshape(theta_grid, 1, []);
R_grid = reshape(R_grid, 1, []);
z_grid = reshape(z_grid, 1, []);
coil_pos = [R_grid.*cos(theta_grid); R_grid.*sin(theta_grid); z_grid];
global_coil_pos = coord_local2global(coil_pos, rel_pos);
coil_shape = alphaShape(global_coil_pos', r);