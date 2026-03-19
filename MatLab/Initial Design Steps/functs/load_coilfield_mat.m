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

% geom is a 1x1 struct with 9 fields: x, y and z which define the
% rectangular prism domain of magnetic field calculation, output_dims which
% contains the dimension in each direction. X, Y, Z which is the meshgrid
% output of x, y, z. output_coord_list is an unpacked X, Y, Z such that it
% is a list of coordinates (3 rows, k columns) where k is
% len(x)*len(y)*len(z). Lastly mag_field_unit is of the same dimensions of
% output_coord_list but with a 3rd direction where each plane represents
% the effects of each coil
field = tmp.field;

end
