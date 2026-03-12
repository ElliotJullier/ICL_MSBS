function mag_field = combine_coil_fields(mag_field_unit, currents)
% This helper combines per-coil unit-current magnetic fields into a single
% total magnetic field using a current vector.

% Allow single-coil case stored as 3xN
if ismatrix(mag_field_unit) && size(mag_field_unit,1) == 3
    mag_field_unit = reshape(mag_field_unit, size(mag_field_unit,1), size(mag_field_unit,2), 1);
end

% Validate first two dimensions only
if size(mag_field_unit,1) ~= 3
    error("mag_field_unit must have size 3xNxnCoils.");
end

currents = reshape(currents, 1, 1, []);

if size(mag_field_unit,3) ~= numel(currents)
    error("Mismatch between coils and current vector.");
end

mag_field = sum(mag_field_unit .* currents, 3);

end