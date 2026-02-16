clear
close all;

load_filename = "coilfield_run1.mat";

[coils, geom, field] = load_coilfield_mat(load_filename);

figStruct = CoilGeom_setupFig({coils.shp});

I = ones(1, numel(coils));
mag_field = combine_coil_fields(field.mag_field_unit, I);

dir = "x";
magField_indices = abs(field.output_coord_list(2, :)-0)<=1e-10;

fig_surf1 = Coil_surf_plot(figStruct.ax, magField_indices, ...
    field.X, field.Y, field.Z, mag_field, field.output_dims, dir);
