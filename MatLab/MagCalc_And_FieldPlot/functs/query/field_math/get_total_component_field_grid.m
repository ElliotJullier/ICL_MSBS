function scalarData = get_total_component_field_grid(dataset, op, component)
%GET_TOTAL_COMPONENT_FIELD_GRID Return one total B component on the grid.
%
% For superposed datasets, this combines field sets using op.currents.
% For precomputed datasets, this returns dataset.B(:,:,:,component,1).

if ~isfield(dataset, "B")
    error("Dataset does not contain grid field data in dataset.B.");
end

[direction, ~] = normalise_direction(component);
scalarData = zeros(numel(dataset.grid.y), numel(dataset.grid.x), numel(dataset.grid.z));
layer = 1;
if isfield(op, "layerIndex"), layer = op.layerIndex; end
if ~dataset.supportsSuperposition && size(dataset.B,5)>1 && ~isfield(op,"layerIndex")
    error("MSBS:LayerSelection", "Select opRequest.layerIndex explicitly for parametric data.");
end
for component_idx = find(abs(direction)>1e-12)
    if dataset.supportsSuperposition
        values = combine_superposed_component_grid(dataset, op.currents, component_idx);
    else
        values = dataset.B(:,:,:,component_idx,layer);
    end
    scalarData = scalarData + direction(component_idx)*values;
end
end
