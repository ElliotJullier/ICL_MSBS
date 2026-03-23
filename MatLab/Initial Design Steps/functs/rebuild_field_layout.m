function field = rebuild_field_layout(field)
% Ensure derived grid layout fields exist and are consistent.
%
% Required inputs in field:
%   field.x, field.y, field.z, field.mag_field_unit
%
% Derived/rebuilt fields:
%   field.output_dims
%   field.X, field.Y, field.Z
%   field.output_coord_list

required = {"x", "y", "z", "mag_field_unit"};
for k = 1:numel(required)
    if ~isfield(field, required{k})
        error("field.%s is required.", required{k});
    end
end

field.output_dims = [numel(field.y), numel(field.x), numel(field.z)];

[X, Y, Z] = meshgrid(field.x, field.y, field.z);
field.X = X;
field.Y = Y;
field.Z = Z;
field.output_coord_list = [reshape(X, 1, []); reshape(Y, 1, []); reshape(Z, 1, [])];

end
