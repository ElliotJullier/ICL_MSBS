function Bcomp = combine_superposed_component_grid(dataset, currents, component_idx)
%COMBINE_SUPERPOSED_COMPONENT_GRID Sum one component over field sets.
%
% dataset.B must be [Ny,Nx,Nz,3,nFieldSets]. currents must contain one
% value per field set.

if ~isfield(dataset, "B")
    error("combine_superposed_component_grid requires dataset.B.");
end
if ~dataset.supportsSuperposition
    error("combine_superposed_component_grid requires dataset.supportsSuperposition=true.");
end

currents = reshape(currents, 1, 1, 1, 1, []);

if size(dataset.B, 5) ~= numel(currents)
    error("Number of currents must match number of field sets in dataset.B.");
end

Bcomp = sum(dataset.B(:,:,:,component_idx,:) .* currents, 5);
end
