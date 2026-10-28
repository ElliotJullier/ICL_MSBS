function r = evaluate_virtual_field_query(dataset,op,q,index)
%EVALUATE_VIRTUAL_FIELD_QUERY Sample sources without regridding their volumes.
r=query_coordinates(dataset.grid,q,index);
d=[];
if q.quantity=="gradient"
    d=q.gradientDirection;
    if isempty(d), d=q.end-q.start; end
end
values=sample_dataset_points(dataset,op,[r.X(:).';r.Y(:).';r.Z(:).'],q.component,d);
r.data=reshape(values,size(r.X));
r.inside=isfinite(r.data);
[~,label]=normalise_direction(q.component); r.dataName="B"+label;
if ~isempty(d), [~,label]=normalise_direction(d); r.dataName="d"+r.dataName+"/d"+label; end
r.plot=q.plot;
end
