function result = evaluate_full_biotsavart_query(dataset, op, q, queryIndex)
%EVALUATE_FULL_GRID_QUERY Evaluate one query against gridded B-field data.
%
% This evaluator is used for grid datasets with dataset.B in the standard
% shape [Ny,Nx,Nz,3,nFieldSets]. It supports field and directional-gradient
% queries on fundamental planes, custom planes, and lines.

scalarData = get_total_component_field_grid(dataset, op, q.component); % Same shape as B field except 1 layer in 5th dimension (coils)
[~, label] = normalise_direction(q.component);
dataName = "B" + label;

if q.quantity == "gradient"
    gradDir = q.gradientDirection;
    if isempty(gradDir) && q.type == "line"
        gradDir = q.end(:).' - q.start(:).';
    end
    [scalarData, dataName] = compute_directional_gradient_grid(dataset.grid, scalarData, dataName, gradDir);
end

switch q.type
    case "fundamental_plane"
        result = sample_fundamental_plane_from_grid(dataset.grid, scalarData, q, queryIndex);
    case "line"
        result = sample_line_from_grid(dataset.grid, scalarData, q, queryIndex);
    case "custom_plane"
        result = sample_custom_plane_from_grid(dataset.grid, scalarData, q, queryIndex);
    otherwise
        error("Unknown query type: %s", string(q.type));
end

result.dataName = dataName;
result.plot = q.plot;
end
