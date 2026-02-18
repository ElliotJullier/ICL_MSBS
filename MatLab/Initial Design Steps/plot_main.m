% Plotcube add-on required

clear
close all;

load_filename = "coilfield_run1.mat";
[coils, geom, field] = load_coilfield_mat(load_filename);

figStruct = CoilGeom_setupFig({coils.shp});

% ------------------------- Currents -------------------------
I = ones(1, numel(coils)); 

% ------------------------- Magnet pose and directions -------------------------
magnet_pose   = [0, 0, 0, 1, 0, 0];
planePoint    = magnet_pose(1:3);

mag_grad_dir  = magnet_pose(4:6);   % used later for gradients
plane_normal  = [0, 1, 0];          % x-z plane. Position should be at magnet

% ------------------------- Build per-coil interpolants -------------------------
F = build_percoil_interpolants(field);

% ------------------------- Define plane + sample desired component -------------------------
dir = "z";
[Xp, Yp, Zp, Bp] = plane_sample_field_percoil(field, F, planePoint, plane_normal, dir, I);

% ------------------------- Plot -------------------------
hold(figStruct.ax, 'on');
surf(figStruct.ax, Xp, Yp, Zp, Bp, 'EdgeColor','none');

clrb = colorbar(figStruct.ax);
clrb.Label.String = append("$B_", string(dir), "$ [T]");
clrb.Label.Interpreter = 'latex';

Bmax = max(abs(Bp), [], "all", "omitnan");
if isempty(Bmax) || ~isfinite(Bmax) || Bmax <= 0
    clim(figStruct.ax, [-1, 1]);  % robust fallback
else
    clim(figStruct.ax, [-Bmax, Bmax]);
end
