function [results, queries] = run_field_queries(dataset, op, queries, model)
%RUN_FIELD_QUERIES Validate and evaluate query cell array for one case.
%
% model selects the evaluator. It may differ from dataset.source; for
% example, a simple_biotsavart case can reuse geometry loaded from a full
% Biot-Savart dataset.

if nargin < 4 || strlength(string(model)) == 0
    model = dataset.source;
end
model = lower(string(model));

if ~iscell(queries)
    queries = {queries};
end

results = cell(size(queries));

for k = 1:numel(queries)
    q = validate_and_complete_query(queries{k}, model);

    switch model
        case {"matlab_full_biotsavart", "comsol_precomputed", "synthetic_difference"}
            % These are all grid-based models using dataset.B.
            % For superposed MATLAB data, get_total_component_field_grid
            % combines field sets using op.currents.
            % For COMSOL/synthetic data, dataset.B(:,:,:,:,1) is already
            % the total precomputed field.
            results{k} = evaluate_full_biotsavart_query(dataset, op, q, k);

        case "simple_biotsavart"
            if q.type ~= "line"
                error("Simple Biot-Savart only supports 'line' type queries.");
            end
            results{k} = evaluate_simple_biotsavart_query(dataset, op, q, k);

        case "comsol_grid"
            % Backwards-compatible alias. Prefer model="comsol_precomputed"
            % in new query_main files.
            results{k} = evaluate_full_biotsavart_query(dataset, op, q, k);

        otherwise
            error("Model entered (%s) for query %d is not supported.", model, round(k));
    end

    queries{k} = q;
end
end
