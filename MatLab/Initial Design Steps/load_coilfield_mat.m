function [coils, geom, field] = load_coilfield_mat(load_filename)

if strlength(string(load_filename)) == 0
    error("load_filename must be non-empty.");
end

load_filename = string(load_filename);
if ~endsWith(load_filename, ".mat")
    load_filename = load_filename + ".mat";
end

tmp = load(load_filename, "coils", "geom", "field");
coils = tmp.coils;
geom  = tmp.geom;
field = tmp.field;

end
