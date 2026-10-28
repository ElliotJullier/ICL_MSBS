function op = validate_and_solve_operating_point(dataset, opRequest, model)
%VALIDATE_OPERATING_POINT Validate or solve the requested operating point.
%
% mode = "fixed":
%   uses opRequest.currents after checking that the number of currents
%   matches the number of field sets for superposed datasets.
%
% mode = "solve":
%   calls solve_current_operating_point for datasets/models that support
%   current solving.
%
% mode = "precomputed":
%   accepts the dataset as already representing the desired operating point.

if nargin < 3 || strlength(string(model)) == 0
    model = dataset.source;
end

if ~isfield(opRequest, "mode")
    error("opRequest.mode is required.");
end

mode = lower(string(opRequest.mode));

op = struct();
op.mode = mode;
op.currents = [];
op.magnet = [];
op.target = [];
op.rowsToControl = [];
op.residualNorm = [];

switch mode
    case "fixed"
        if ~isfield(opRequest, "currents") || isempty(opRequest.currents)
            error("opRequest.currents is required when mode='fixed'.");
        end

        op.currents = opRequest.currents(:).';
        validate_current_count(dataset, op.currents, model);

    case "solve"
        if ~dataset.supportsCurrentSolve
            error("Current solving is only implemented for supported full-grid superposition datasets.");
        end
        if ~isfield(opRequest, "magnet") || ~isfield(opRequest, "target")
            error("opRequest.magnet and opRequest.target are required when mode='solve'.");
        end

        op = solve_current_operating_point(dataset, opRequest.magnet, opRequest.target);

    case "precomputed"
        if dataset.supportsSuperposition
            error("mode='precomputed' is for total-field datasets. Use mode='fixed' for superposition datasets.");
        end
        op.mode = "precomputed";
        if isfield(dataset,"B")
            nLayers = size(dataset.B,5);
            if nLayers>1 && (~isfield(opRequest,"layerIndex") || isempty(opRequest.layerIndex))
                error("MSBS:LayerSelection","Dataset has %d layers. Specify opRequest.layerIndex.",nLayers);
            end
            if isfield(opRequest,"layerIndex") && ~isempty(opRequest.layerIndex)
                validateattributes(opRequest.layerIndex,{'numeric'},{'scalar','integer','>=',1,'<=',nLayers});
                op.layerIndex = opRequest.layerIndex;
            else
                op.layerIndex = 1;
            end
        end

    otherwise
        error("Unknown opRequest.mode: %s", mode);
end
end

function validate_current_count(dataset, currents, model)
model = string(model);

if model == "simple_biotsavart"
    nRequired = numel(dataset.geometry.coil);
elseif dataset.supportsSuperposition
    nRequired = size(dataset.B, 5);
else
    nRequired = 0;
end

if nRequired > 0 && numel(currents) ~= nRequired
    error("Current vector length (%d) must match number of field sets/coils (%d).", numel(currents), nRequired);
end
end
