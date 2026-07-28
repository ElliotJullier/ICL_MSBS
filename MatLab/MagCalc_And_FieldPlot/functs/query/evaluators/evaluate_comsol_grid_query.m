function result = evaluate_comsol_grid_query(dataset, op, q, queryIndex) %#ok<INUSD>
%EVALUATE_COMSOL_GRID_QUERY Placeholder for future COMSOL grid support.
%
% This is intentionally not wired to the full-grid evaluator yet because the
% COMSOL export/import format has not been finalised.
%
% Proposed future standard format:
%   dataset.source = "comsol_grid"
%   dataset.grid.x/y/z
%   dataset.B(y,x,z,component,fieldSet)
%   dataset.supportsSuperposition
%   dataset.supportsCurrentSolve
%
% TODO before enabling:
%   Decide whether COMSOL data is exported as a rectilinear grid, scattered
%   table, one file per component, or one file per current case.

error("COMSOL grid query evaluation is not implemented because the COMSOL export/import format has not been finalised.");
end
