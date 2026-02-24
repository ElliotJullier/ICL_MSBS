function [X, Y, Z, B] = plane_sample_field_percoil(field, F, planePoint, planeNormal, dir, I)
% Generates a plane clipped to the grid bounds, then evaluates:
% B = sum_k I(k)*B_k on that plane using per-coil interpolants.

% ---- create plane mesh (same method as before) ----
[X, Y, Z] = plane_mesh_clipped_to_grid(field, planePoint, planeNormal);

% ---- evaluate per coil + combine ----
nCoils = numel(I);
B = zeros(size(X));

for k = 1:nCoils
    switch string(dir)
        case "x"
            Bk = F.Bx{k}(Y, X, Z);
        case "y"
            Bk = F.By{k}(Y, X, Z);
        case "z"
            Bk = F.Bz{k}(Y, X, Z);
        otherwise
            error('dir must be "x", "y", or "z".');
    end

    B = B + I(k)*Bk;
end

end
