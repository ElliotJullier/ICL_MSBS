clear
close all;


% Coil geometry parameters
coil_outer_radius = 0.456/2 ;% m
coil_inner_radius = 0.2/2; % m
N = 150; % number of turns
wire_outer_radius = 5/1000; % m
wire_inner_radius = 0; % m, assuming hollow wire
% height is determined automatically
% Coil positions is determined from WT working section centreline, using
% the Tohoku/JAXA style layout, we use +- measurements from centreline, not
% distance between opposing coils
coil_vert_pos = 0.456/2; % m
coil_streamwise_pos = 0.3; % m
% need horizontal cross-stream position for coils 2,4,6,8
% need axial coils params as well

% Define Output field
% Here is the x-z plane (operator POV from the side)
x = linspace(-0.75, 0.75, 30);
y = [0];
z = linspace(-coil_vert_pos, coil_vert_pos, 20);
output_dims = [length(y), length(x), length(z)]; % y and x inverted because of the way meshgrid works
[X, Y, Z] = meshgrid(x, y, z);
X_line = reshape(X, 1, []);
Y_line = reshape(Y, 1, []);
Z_line = reshape(Z, 1, []);
output_field = [X_line;Y_line;Z_line];
mag_field = zeros(size(output_field));

I_front = 50;
I_rear = 30;
% Sum up multiple coils effects
% % Coil 1
coil1_rel_pos = [coil_streamwise_pos, 0, coil_vert_pos, 0, 0, 0];
local_output_field = coord_global2local(output_field, coil1_rel_pos);
mag_field = mag_field - I_front*Coil_Field(coil_outer_radius, coil_inner_radius, N, wire_outer_radius, wire_inner_radius, local_output_field);

% Coil 3
coil3_rel_pos = [coil_streamwise_pos, 0, -coil_vert_pos, 0, pi, 0];
local_output_field = coord_global2local(output_field, coil3_rel_pos);
mag_field = mag_field + I_front*Coil_Field(coil_outer_radius, coil_inner_radius, N, wire_outer_radius, wire_inner_radius, local_output_field);

% Coil 5
coil5_rel_pos = [-coil_streamwise_pos, 0, coil_vert_pos, 0, 0, 0];
local_output_field = coord_global2local(output_field, coil5_rel_pos);
mag_field = mag_field - I_rear*Coil_Field(coil_outer_radius, coil_inner_radius, N, wire_outer_radius, wire_inner_radius, local_output_field);

% Coil 7
coil7_rel_pos = [-coil_streamwise_pos, 0, -coil_vert_pos, 0, pi, 0];
local_output_field = coord_global2local(output_field, coil7_rel_pos);
mag_field = mag_field + I_rear*Coil_Field(coil_outer_radius, coil_inner_radius, N, wire_outer_radius, wire_inner_radius, local_output_field);
% End of coils


% Plot results
% Generate coil shapes in right positions
coil1_shp = extract_coilShape(coil_outer_radius, coil_inner_radius, N, wire_outer_radius, coil1_rel_pos);
coil3_shp = extract_coilShape(coil_outer_radius, coil_inner_radius, N, wire_outer_radius, coil3_rel_pos);
coil5_shp = extract_coilShape(coil_outer_radius, coil_inner_radius, N, wire_outer_radius, coil5_rel_pos);
coil7_shp = extract_coilShape(coil_outer_radius, coil_inner_radius, N, wire_outer_radius, coil7_rel_pos);

% Generate wind tunnel bounding box

plot(coil1_shp);
hold on;
axis equal;
box on;
xlabel("$x$ [m]", 'Interpreter','latex');
ylabel("$y$ [m]", 'Interpreter','latex');
zlabel("$z$ [m]", 'Interpreter','latex');
plot(coil3_shp);
plot(coil5_shp);
plot(coil7_shp);
plotcube([1.52 0.46 0.46], [-1.52/2, -0.46/2, -0.46/2], 0, [0 0 0]);

% Masking magnetic field for certain values
magField_indices = abs(output_field(2, :)-0)<=1e-10; % Absolute change of variable - desired level must be below 1e-10
deshaped_magField_indices = reshape(magField_indices, output_dims);
X_masked=X;
X_masked(~deshaped_magField_indices) = NaN;
X_masked = squeeze(X_masked);
Y_masked = Y;
Y_masked(~deshaped_magField_indices) = NaN;
Y_masked = squeeze(Y_masked);
Z_masked = Z;
Z_masked(~deshaped_magField_indices) = NaN;
Z_masked = squeeze(Z_masked);
% We extract the x, y, and z components of magnetic field and reshape them
% into meshgrid format for plotting
Bx_field = reshape(mag_field(1, :), output_dims);
Bx_field(~deshaped_magField_indices) = NaN;
Bx_field = squeeze(Bx_field);
By_field = reshape(mag_field(2, :), output_dims);
By_field(~deshaped_magField_indices) = NaN;
By_field = squeeze(By_field);
Bz_field = reshape(mag_field(3, :), output_dims);
Bz_field(~deshaped_magField_indices) = NaN;
Bz_field = squeeze(Bz_field);
surf(X_masked, Y_masked, Z_masked, Bz_field);
clrb = colorbar;
% Define colourmap
%clrm = [repmat([0 0], [10, 1]), linspace(1, 0, 10)'; repmat()];
clrb.Label.String = "$B_Z$ [T]";
clrb.Label.Interpreter = 'latex';
clim([-max(abs(Bz_field), [], "all"), max(abs(Bz_field), [], "all")]);
%I = 100; % Amps
%test_mag_field = test_mag_field*I;
%quiver3(output_field(1, :), output_field(2, :), output_field(3, :), test_mag_field(1, :), test_mag_field(2, :), test_mag_field(3, :));
