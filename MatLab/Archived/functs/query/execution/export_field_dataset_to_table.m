function export_field_dataset_to_table(dataset, fileName)
%EXPORT_FIELD_DATASET_TO_TABLE Export a precomputed grid dataset to CSV.
%
% Output columns:
%   x, y, z, Bx, By, Bz, Bnorm
%
% For superposable datasets, export_field_dataset_to_table intentionally
% errors because an operating point is required before a total field exists.

fileName = string(fileName);

if dataset.supportsSuperposition
    error("Cannot export a superposable dataset directly. Export a precomputed or synthetic total-field dataset instead.");
end

if ~isfield(dataset, "B")
    error("dataset.B is required.");
end

[X, Y, Z] = meshgrid(dataset.grid.x, dataset.grid.y, dataset.grid.z);

Bx = dataset.B(:,:,:,1,1);
By = dataset.B(:,:,:,2,1);
Bz = dataset.B(:,:,:,3,1);
Bnorm = sqrt(Bx.^2 + By.^2 + Bz.^2);

T = table( ...
    X(:), Y(:), Z(:), ...
    Bx(:), By(:), Bz(:), Bnorm(:), ...
    'VariableNames', {'x','y','z','Bx','By','Bz','Bnorm'});

writetable(T, fileName);
end
