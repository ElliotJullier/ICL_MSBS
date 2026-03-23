function [coils, geom, field] = load_coilfield_mat(load_filename)

if strlength(string(load_filename)) == 0
    error("load_filename must be non-empty.");
end

load_filename = string(load_filename);
if ~endsWith(load_filename, ".mat")
    load_filename = load_filename + ".mat";
end

tmp = load(load_filename, "coils", "geom", "field");
% coils is a nx1 struct, n the number of coils which contains the
% alphashape and relative positions of the coils (as an Tx, Ty, Tz, roll,
% pitch, yaw) - see coords_global2local for details
coils = tmp.coils;

% geom is a 1x1 struct which contains some of the geometrical values used
% for the coils, so far coil_outer_radius, coil_inner_radius, N (number of
% turns), wire_outer_radius and wire_inner_radius (which can be 0 for
% non-hollow wires)
geom  = tmp.geom;

% field is a 1x1 struct containing the rectangular-prism grid vectors
% x, y, z and the sampled magnetic field data mag_field_unit. Derived grid
% layout fields (output_dims, X, Y, Z, output_coord_list) are rebuilt on
% load so the saved .mat can stay light.
field = tmp.field;
field = rebuild_field_layout(field);

end
