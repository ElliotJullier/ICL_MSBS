function scalarData = get_total_component_field_grid(dataset, op, component)
%GET_TOTAL_COMPONENT_FIELD_GRID Return one total B component on the grid.
%
% For superposed datasets, this combines field sets using op.currents.
% For precomputed datasets, this returns dataset.B(:,:,:,component,1).

if ~isfield(dataset, "B")
    error("Dataset does not contain grid field data in dataset.B.");
end

component_idx = get_component_index(component);

if dataset.supportsSuperposition
    scalarData = combine_superposed_component_grid(dataset, op.currents, component_idx);
else
    scalarData = dataset.B(:,:,:,component_idx,1);
end
end
