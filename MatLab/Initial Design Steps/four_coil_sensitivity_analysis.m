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
output_field = coords_to_areaGrid(x, y, z);
mag_field = zeros(size(output_field));

% Sum up multiple coils effects
% Coil 1
coil1_rel_pos = [coil_streamwise_pos, 0, coil_vert_pos, 0, 0, 0];
output_field = coord_global2local(output_field, coil1_rel_pos);
mag_field = mag_field + Coil_Field(coil_outer_radius, coil_inner_radius, N, wire_outer_radius, wire_inner_radius, output_field);

% Coil 3
coil3_rel_pos = [coil_streamwise_pos, 0, -coil_vert_pos, 0, pi, 0];
output_field = coord_global2local(output_field, coil3_rel_pos);
mag_field = mag_field + Coil_Field(coil_outer_radius, coil_inner_radius, N, wire_outer_radius, wire_inner_radius, output_field);

% Coil 5
coil5_rel_pos = [-coil_streamwise_pos, 0, coil_vert_pos, 0, 0, 0];
output_field = coord_global2local(output_field, coil5_rel_pos);
mag_field = mag_field + Coil_Field(coil_outer_radius, coil_inner_radius, N, wire_outer_radius, wire_inner_radius, output_field);

% Coil 7
coil7_rel_pos = [-coil_streamwise_pos, 0, -coil_vert_pos, 0, pi, 0];
output_field = coord_global2local(output_field, coil7_rel_pos);
mag_field = mag_field + Coil_Field(coil_outer_radius, coil_inner_radius, N, wire_outer_radius, wire_inner_radius, output_field);
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
plot(coil3_shp);
plot(coil5_shp);
plot(coil7_shp);
plotcube([1.52 0.46 0.46], [-1.52/2, -0.46/2, -0.46/2], 0, [0 0 0]);
contourf()
%I = 100; % Amps
%test_mag_field = test_mag_field*I;
%quiver3(output_field(1, :), output_field(2, :), output_field(3, :), test_mag_field(1, :), test_mag_field(2, :), test_mag_field(3, :));
