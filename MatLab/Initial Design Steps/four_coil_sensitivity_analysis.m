clear
close all;

% ------------------------- Use saved coil and magnetic field files -------------------------


% ------------------------- Coil geometry parameters -------------------------
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

% ------------------------- Define Coil positions -------------------------
coil1_rel_pos = [coil_streamwise_pos, 0, coil_vert_pos, 0, 0, 0];
coil3_rel_pos = [coil_streamwise_pos, 0, -coil_vert_pos, 0, pi, 0];
coil5_rel_pos = [-coil_streamwise_pos, 0, coil_vert_pos, 0, 0, 0];
coil7_rel_pos = [-coil_streamwise_pos, 0, -coil_vert_pos, 0, pi, 0];
% ------------------------- Define Output field -------------------------
% Here is the x-z plane (operator POV from the side)
x = linspace(-0.75, 0.75, 200);
y = [0];
z = linspace(-coil_vert_pos, coil_vert_pos, 100);

% Shaping input x, y, z variables to be a list of coords (x; y; z) format
output_dims = [length(y), length(x), length(z)]; % y and x inverted because of the way meshgrid works

[X, Y, Z] = meshgrid(x, y, z);
output_coord_list = [reshape(X, 1, []); reshape(Y, 1, []); reshape(Z, 1, [])];

% Initialise mag field of correct shape
mag_field = zeros(size(output_coord_list));

% HOW ARE WE DOING COIL CURRENT TO MATCH THE RIGHT FORCE
I_front = 50;
I_rear = 30;

% ------------------------- Summing up coils on mag field -------------------------
% % Coil 1
local_output_field = coord_global2local(output_coord_list, coil1_rel_pos);
mag_field = mag_field - I_front*Coil_Field(coil_outer_radius, coil_inner_radius, N, wire_outer_radius, wire_inner_radius, local_output_field);

% Coil 3
local_output_field = coord_global2local(output_coord_list, coil3_rel_pos);
mag_field = mag_field + I_front*Coil_Field(coil_outer_radius, coil_inner_radius, N, wire_outer_radius, wire_inner_radius, local_output_field);

% Coil 5

local_output_field = coord_global2local(output_coord_list, coil5_rel_pos);
mag_field = mag_field - I_rear*Coil_Field(coil_outer_radius, coil_inner_radius, N, wire_outer_radius, wire_inner_radius, local_output_field);

% Coil 7

local_output_field = coord_global2local(output_coord_list, coil7_rel_pos);
mag_field = mag_field + I_rear*Coil_Field(coil_outer_radius, coil_inner_radius, N, wire_outer_radius, wire_inner_radius, local_output_field);
% ------------------------- End of coils -------------------------


% ------------------------- Plot results -------------------------
% Generate coil shapes in right positions
coil1_shp = extract_coilShape(coil_outer_radius, coil_inner_radius, N, wire_outer_radius, coil1_rel_pos);
coil3_shp = extract_coilShape(coil_outer_radius, coil_inner_radius, N, wire_outer_radius, coil3_rel_pos);
coil5_shp = extract_coilShape(coil_outer_radius, coil_inner_radius, N, wire_outer_radius, coil5_rel_pos);
coil7_shp = extract_coilShape(coil_outer_radius, coil_inner_radius, N, wire_outer_radius, coil7_rel_pos);


figStruct = CoilGeom_setupFig({coil1_shp, coil3_shp, coil5_shp, coil7_shp});

% ------------------------- Plotting Magnetic Field Surfaces -------------------------

% ------------------------- Input masking -------------------------
dir = "z"; % "x" means plotting Bx, "y" and "z" affect equivalently

magField_indices = abs(output_coord_list(2, :)-0)<=1e-10; % Absolute change of variable - desired level must be below 1e-10
% Here we are masking such that out of the complete set of calculated
% variables, a value of y = 0 is taken (within rounding error)
% Plot as many surfaces as required
fig_surf1 = Coil_surf_plot(figStruct.ax, magField_indices, X, Y, Z, mag_field, output_dims, dir);

magField_indices = abs(output_coord_list(3, :)-0)<=1e-10;
fig_surf2 = Coil_surf_plot(figStruct.ax, magField_indices, X, Y, Z, mag_field, output_dims, dir);

