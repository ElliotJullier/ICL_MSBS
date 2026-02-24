% Plotcube add-on required

clear
close all;

addpath("functs"); % Code clarity so helper functions sotred here.

% ------------------------- Load saved file -------------------------
load_filename = "coilfield_run2.mat";
[coils, geom, field] = load_coilfield_mat(load_filename);

nCoils = numel(coils);

% ------------------------- Build per-coil interpolants (unit-current) -------------------------
% Field interpolants (Bx, By, Bz) per coil
F = build_percoil_interpolants(field);

% Gradient interpolants (9 components) per coil
G = build_percoil_gradient_interpolants(field);

% ------------------------- Magnet definition -------------------------
% Magnet pose uses same format as coils:
% [x, y, z, yaw, pitch, roll]
magnet_pos = [0, 0, 0, 0, 0, 0]; % The position is only used to calculate currents, not used to generate the plots, whereas magnet rotation will influence the forces

% Magnet dipole moment 
mu_0 = 1.2256*10^-6; % CONST Magnetic permeability of free space in N/A^2

magnet_remanence = 1.5; % Tesla
magnet_volume = 6/1000*pi*(1.5/1000)^2; % m^3
magnet_magnetisation_direction = [1; 0; 0]; % LOCAL magnetisation direction (likely to be always x)

m_local = magnet_remanence./mu_0.*magnet_volume.*magnet_magnetisation_direction;

% Convert dipole moment to global frame using existing transform function
% (translation set to zero so this acts as a pure rotation)
m_global = coord_local2global(m_local, [0, 0, 0, magnet_pos(4), magnet_pos(5), magnet_pos(6)]);

% ------------------------- Desired force and torque -------------------------
F_des = [0; 0; 0.1];  % [Fx; Fy; Fz] in N
T_des = [0; 0; 0];  % [Tx; Ty; Tz] in Nm

% Frame selection for inputs:
% "global" or "local"
forceFrame  = "global";
torqueFrame = "global";

% If local requested, rotate into global frame before allocation
if forceFrame == "local"
    F_des = coord_local2global(F_des, [0, 0, 0, magnet_pos(4), magnet_pos(5), magnet_pos(6)]);
end
if torqueFrame == "local"
    T_des = coord_local2global(T_des, [0, 0, 0, magnet_pos(4), magnet_pos(5), magnet_pos(6)]);
end

b = [F_des; T_des];

% ------------------------- Build mapping matrix A at magnet position -------------------------
p = magnet_pos(1:3);
A = build_wrench_matrix_at_point(F, G, p, m_global, nCoils);

% ------------------------- Select which DOFs to control (optional) -------------------------
% If you want to solve a reduced problem (e.g. for 4-coil case controlling Fz and Ty):
% rows_to_control = [3, 5];  % Fz (3) and Ty (5)
% Otherwise, solve full 6-DOF wrench:
rows_to_control = [3];

if ~isempty(rows_to_control)
    A = A(rows_to_control, :);
    b = b(rows_to_control);
end

% ------------------------- Solve currents (minimum-norm least squares) -------------------------
I = lsqminnorm(A, b);

disp("Solved currents (A):");
disp(I.');

% ------------------------- Plot planes of the field using solved currents -------------------------
% Plot coil geometries / wind tunnel box
figStruct = CoilGeom_setupFig(coils);

% Choose component to plot: "x", "y" or "z"
dir = "z";

% Planes centred at origin
planePoint = [0, 0, 0];

% XY plane: normal z
[X_xy, Y_xy, Z_xy, B_xy] = plane_sample_field_percoil(field, F, planePoint, [0, 0, 1], dir, I);
add_plane(figStruct.ax, X_xy, Y_xy, Z_xy, B_xy, dir);

% XZ plane: normal y
[X_xz, Y_xz, Z_xz, B_xz] = plane_sample_field_percoil(field, F, planePoint, [0, 1, 0], dir, I);
add_plane(figStruct.ax, X_xz, Y_xz, Z_xz, B_xz, dir);

% YZ plane: normal x
[X_yz, Y_yz, Z_yz, B_yz] = plane_sample_field_percoil(field, F, planePoint, [1, 0, 0], dir, I);
add_plane(figStruct.ax, X_yz, Y_yz, Z_yz, B_yz, dir);

% ------------------------- Local helper -------------------------
function add_plane(ax, X, Y, Z, B, dir)
    hold(ax, 'on');
    surf(ax, X, Y, Z, B, 'EdgeColor','none');

    clrb = colorbar(ax);
    clrb.Label.String = append("$B_", string(dir), "$ [T]");
    clrb.Label.Interpreter = 'latex';

    Bmax = max(abs(B), [], "all", "omitnan");
    if isempty(Bmax) || ~isfinite(Bmax) || Bmax <= 0
        clim(ax, [-1, 1]);
    else
        clim(ax, [-Bmax, Bmax]);
    end
end
