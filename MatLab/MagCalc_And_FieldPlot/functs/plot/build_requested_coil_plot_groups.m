function groups = build_requested_coil_plot_groups(records)
%BUILD_REQUESTED_COIL_PLOT_GROUPS Deduplicate exact component meshes.
% Retains the public legacy name and synthetic source-geometry support.
groups=struct("geometry",{},"records",{},"recordIndices",{},"caseNames",{},"legendLabel",{},"signature",{});
for k=1:numel(records)
    record=records{k};
    if ~isfield(record.query,"plot") || ~record.query.plot.showCoils, continue; end
    sources=struct("geometry",record.geometry,"caseName",record.caseName);
    if isfield(record,"synthetic") && isfield(record.synthetic,"coilGeometrySources")
        sources=record.synthetic.coilGeometrySources;
    end
    for source=sources
        components=geometry_components(source.geometry);
        if isempty(components), continue; end
        match=[];
        for g=1:numel(groups)
            if isequaln(groups(g).signature,components), match=g; break; end
        end
        if isempty(match)
            g=numel(groups)+1;
            groups(g)=struct("geometry",source.geometry,"records",{{record}}, ...
                "recordIndices",k,"caseNames",string(source.caseName),"legendLabel","Geometry","signature",components);
        else
            groups(match).records{end+1}=record;
            groups(match).recordIndices(end+1)=k;
            groups(match).caseNames(end+1)=string(source.caseName);
        end
    end
end
end
