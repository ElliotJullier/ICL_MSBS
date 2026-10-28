function components = geometry_components(geometry)
%GEOMETRY_COMPONENTS New components, or legacy mesh coils for old Q files.
components=struct("name",{},"role",{},"shape",{},"color",{},"alpha",{},"closed",{});
if ~isstruct(geometry), return; end
if isfield(geometry,"components") && ~isempty(geometry.components)
    components=geometry.components;
    for j=1:numel(components)
        [shape,report]=clean_component_mesh(components(j).shape);
        components(j).shape=shape; components(j).closed=report.closed;
    end
    return
end
if ~isfield(geometry,"coil"), return; end
for k=1:numel(geometry.coil)
    coil=geometry.coil(k);
    if ~isfield(coil,"shape") || ~isstruct(coil.shape) || ~isfield(coil.shape,"Faces"), continue; end
    shape=coil.shape; closed=false;
    if size(shape.Faces,2)==3
        F=shape.Faces; edges=sort([F(:,[1 2]);F(:,[2 3]);F(:,[3 1])],2);
        [~,~,idx]=unique(edges,"rows"); closed=all(accumarray(idx,1)==2);
    end
    name="Coil "+k;
    if isfield(coil,"coilName"), name=string(coil.coilName); end
    components(end+1)=struct("name",name,"role","coil","shape",shape, ...
        "color",[0.20 0.65 0.30],"alpha",0.5,"closed",closed); %#ok<AGROW>
end
end
