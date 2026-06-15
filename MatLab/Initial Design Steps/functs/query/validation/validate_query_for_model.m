function validate_query_for_model(q, model)
%VALIDATE_QUERY_FOR_MODEL Check whether a model can evaluate one query.
%
% This function performs only model-capability checks. It assumes
% validate_and_complete_query has already checked that the query contains
% the fields required by its type.
%
% Supported model behaviour:
%   matlab_full_biotsavart:
%       grid-based field and gradient queries on lines/planes/custom planes.
%
%   comsol_precomputed / comsol_grid:
%       grid-based field and gradient queries on lines/planes/custom planes.
%       The COMSOL dataset is precomputed, so current solving is handled
%       elsewhere by the operating-point validation.
%
%   synthetic_difference:
%       grid-based field and gradient queries on lines/planes/custom planes.
%
%   simple_biotsavart:
%       line queries only. Field lines and line gradients are allowed. The
%       simple model does not support arbitrary planes or custom planes.

model = lower(string(model));
queryType = lower(string(q.type));
quantity = lower(string(q.quantity));

switch model
    case {"matlab_full_biotsavart", "comsol_precomputed", "comsol_grid", "synthetic_difference"}
        % These are all treated as grid-based datasets at query time.
        allowedTypes = ["line", "fundamental_plane", "custom_plane"];
        allowedQuantities = ["field", "gradient"];

        if ~any(queryType == allowedTypes)
            error("Model '%s' does not support query type '%s'.", model, queryType);
        end

        if ~any(quantity == allowedQuantities)
            error("Model '%s' does not support query quantity '%s'.", model, quantity);
        end

    case "simple_biotsavart"
        % The simple Biot-Savart model is an on-axis/line evaluator. It does
        % not have a full 3D field grid, so it cannot return planes.
        if queryType ~= "line"
            error("Simple Biot-Savart only supports line queries. Requested query type was '%s'.", queryType);
        end

        if ~any(quantity == ["field", "gradient"])
            error("Simple Biot-Savart supports only field or line-gradient queries. Requested quantity was '%s'.", quantity);
        end

    otherwise
        error("Unknown query model '%s'.", model);
end
end
