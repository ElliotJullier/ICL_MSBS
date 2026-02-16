function mag_field = combine_coil_fields(mag_field_unit, currents)

if ndims(mag_field_unit) ~= 3
    error("mag_field_unit must be 3xNxnCoils.");
end

currents = reshape(currents, 1, 1, []);

if size(mag_field_unit, 3) ~= numel(currents)
    error("Mismatch between coils and current vector.");
end

mag_field = sum(mag_field_unit .* currents, 3);

end
