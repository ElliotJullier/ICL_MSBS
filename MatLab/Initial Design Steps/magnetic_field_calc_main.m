clear
close all;

addpath("functs"); % Code clarity so helper functions sotred here.
addpath("functs/magnetic_calc/");

save_filename = "coilfield_run0b.mat";

% coil_outer_radius = 0.456/2 ;
% coil_inner_radius = 0.2/2;
% N = 150;
wire_outer_radius = 5/1000;
wire_inner_radius = 0;

coil_outer_radius = 1.4*0.456/2*sqrt(2) ;
coil_inner_radius = 0.456/2*sqrt(2);
N = 300;

coil_h = (pi*wire_outer_radius^2*N)/((coil_outer_radius-coil_inner_radius)*0.7); % Calculated height assuming 70% packing efficiency

coil_vert_pos = 0.456/2;
coil_streamwise_pos = 0.3;

% rel_pos expects [x, y, z, yaw, pitch, roll]
% coil0_rel_pos = [0, 0, 0, 0, pi/2, 0];
coil0_rel_pos = [0.5, 0, 0, 0, -pi/2, 0];
% coil1_rel_pos = [ coil_streamwise_pos, 0, coil_vert_pos, 0, 0, 0];
% coil2_rel_pos = [ coil_streamwise_pos, coil_vert_pos, 0, 0, 0, -pi/2];
% coil3_rel_pos = [ coil_streamwise_pos, 0, -coil_vert_pos, 0,  pi, 0];
% coil4_rel_pos = [ coil_streamwise_pos, -coil_vert_pos, 0, 0, 0, pi/2];
% coil5_rel_pos = [-coil_streamwise_pos, 0,  coil_vert_pos, 0,   0, 0];
% coil6_rel_pos = [ -coil_streamwise_pos, coil_vert_pos, 0, 0, 0, -pi/2];
% coil7_rel_pos = [-coil_streamwise_pos, 0, -coil_vert_pos, 0,  pi, 0];
% coil8_rel_pos = [ -coil_streamwise_pos, -coil_vert_pos, 0, 0, 0, pi/2];
% coil9_rel_pos = [-0.5, 0, 0, 0, pi/2, 0];

coil_defs = { ...
    "coil0", coil0_rel_pos; ...
    % "coil1", coil1_rel_pos; ...
    % "coil2", coil2_rel_pos; ...
    % "coil3", coil3_rel_pos; ...
    % "coil4", coil4_rel_pos; ...
    % "coil5", coil5_rel_pos; ...
    % "coil6", coil6_rel_pos; ...
    % "coil7", coil7_rel_pos; ...
    % "coil8", coil8_rel_pos; ...
    % "coil9", coil9_rel_pos; ...
};

x = linspace(-0.75, 0.75, 200);
z = linspace(-coil_vert_pos, coil_vert_pos, 100);
y = z; % not technically coil_vert_pos but it fills the wind tunnel as required

[X, Y, Z] = meshgrid(x, y, z);
output_coord_list = [reshape(X, 1, []); reshape(Y, 1, []); reshape(Z, 1, [])];

geom = struct();
geom.coil_outer_radius = coil_outer_radius;
geom.coil_inner_radius = coil_inner_radius;
geom.N = N;
geom.wire_outer_radius = wire_outer_radius;
geom.wire_inner_radius = wire_inner_radius;
geom.coil_height = coil_h;

nCoils = size(coil_defs, 1);
coils = repmat(struct('name', "", 'rel_pos', zeros(1,6), 'shp', []), nCoils, 1);

for k = 1:nCoils
    coils(k).name    = coil_defs{k,1};
    coils(k).rel_pos = coil_defs{k,2};
end

mag_field_unit = zeros(3, size(output_coord_list, 2), nCoils);

for k = 1:nCoils
    local_output_field = coord_global2local(output_coord_list, coils(k).rel_pos);

    local_mag_field = Coil_Field( ...
        geom.coil_outer_radius, geom.coil_inner_radius, geom.coil_height, geom.N, ...
        geom.wire_outer_radius, geom.wire_inner_radius, local_output_field, ...
        "progress", true, "progressStepPercent", 5, "blockSize", 50000);

    % Rotate field vectors from coil-local components back to global components
    mag_field_unit(:, :, k) = coord_local2global(local_mag_field, [0, 0, 0, coils(k).rel_pos(4:6)]);

    fprintf("[%s] Coil %d/%d finished\n", datestr(now,"HH:MM:SS"), k, nCoils);

end

for k = 1:nCoils
    coils(k).shp = extract_coilShape( ...
        geom.coil_outer_radius, ...
        geom.coil_inner_radius, ...
        geom.N, ...
        geom.wire_outer_radius, ...
        coils(k).rel_pos);
end

field = struct();
field.x = x;
field.y = y;
field.z = z;
field.mag_field_unit = mag_field_unit;

save_coilfield_mat(save_filename, coils, geom, field);
