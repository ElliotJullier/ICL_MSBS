function save_coilfield_mat(save_filename, coils, geom, field)

if strlength(string(save_filename)) == 0
    error("save_filename must be non-empty.");
end

save_filename = string(save_filename);
if ~endsWith(save_filename, ".mat")
    save_filename = save_filename + ".mat";
end

save(save_filename, "coils", "geom", "field", "-v7.3");

end
