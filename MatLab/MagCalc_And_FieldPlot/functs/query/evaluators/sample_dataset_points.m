function values = sample_dataset_points(dataset,op,points,fieldDirection,gradientDirection)
%SAMPLE_DATASET_POINTS Evaluate projection/derivative at 3xN world points.
a=normalise_direction(fieldDirection); gradientRequested=~isempty(gradientDirection);
if gradientRequested, d=normalise_direction(gradientDirection); else, d=[]; end
if isfield(dataset,"virtualTerms")
    values=zeros(1,size(points,2));
    for term=dataset.virtualTerms
        local=term.rotation.'*(points-term.translation);
        localD=[]; if gradientRequested, localD=term.rotation.'*d(:); end
        sample=sample_dataset_points(term.dataset,term.op,local,term.rotation.'*a(:),localD);
        values=values+term.weight*sample;
    end
else
    scalar=get_total_component_field_grid(dataset,op,a);
    if gradientRequested
        scalar=compute_directional_gradient_grid(dataset.grid,scalar,"Ba",d);
    end
    F=build_scalar_grid_interpolant(dataset.grid,scalar);
    values=F(points(2,:),points(1,:),points(3,:));
end
end
