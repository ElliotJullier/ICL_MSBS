function bore = coil_bore_geometry(shape)
%COIL_BORE_GEOMETRY Infer holes only for a verified straight-extruded coil.
% Not a bounding-box/convex-hull approximation. Arbitrary coils return [].
persistent inputs outputs
if isempty(inputs), inputs={}; outputs={}; end
for k=1:numel(inputs), if isequaln(inputs{k},shape), bore=outputs{k}; return; end; end
bore=[]; V=shape.Vertices; F=shape.Faces;
normals=cross(V(F(:,2),:)-V(F(:,1),:),V(F(:,3),:)-V(F(:,1),:),2);
normals=normals./vecnorm(normals,2,2);
candidates=unique(round(normals*1e8)/1e8,"rows");
tol=1e-7*max(1,max(max(V)-min(V)));
for candidate=candidates.'
    n=normalise_direction(candidate);
    alignment=abs(normals*n.');
    if any(alignment>1e-7 & alignment<1-1e-7), continue; end
    w=V*n.'; low=min(w); high=max(w);
    if high-low<tol, continue; end
    capIds=find(alignment>1-1e-7);
    capPositions=mean(reshape(w(F(capIds,:)),[],3),2);
    if any(abs(capPositions-low)>tol & abs(capPositions-high)>tol), continue; end
    point=.5*(low+high)*n; loops=mesh_plane_sections(shape,point,n);
    ref=[0 0 1]; if abs(dot(n,ref))>.95, ref=[0 1 0]; end
    u=normalise_direction(cross(ref,n)); v=cross(n,u);
    region=polyshape(); valid=true;
    for k=1:numel(loops)
        pts=loops{k};
        if norm(pts(1,:)-pts(end,:))>tol, valid=false; break; end
        uv=(pts(1:end-1,:)-point)*[u(:),v(:)];
        region=xor(region,polyshape(uv(:,1),uv(:,2),"KeepCollinearPoints",true));
    end
    if ~valid || region.NumHoles==0, continue; end
    holesInProfile=holes(region); BV=[]; BF=[];
    for hole=holesInProfile.'
        tr=triangulation(hole); T=tr.ConnectivityList; P=tr.Points; count=size(P,1);
        boundaryEdges=freeBoundary(tr);
        meshVertices=[P(:,1)*u+P(:,2)*v+low*n;P(:,1)*u+P(:,2)*v+high*n];
        side=[boundaryEdges(:,1),boundaryEdges(:,2),boundaryEdges(:,2)+count; ...
            boundaryEdges(:,1),boundaryEdges(:,2)+count,boundaryEdges(:,1)+count];
        meshFaces=[fliplr(T);T+count;side];
        BF=[BF;meshFaces+size(BV,1)]; BV=[BV;meshVertices]; %#ok<AGROW>
    end
    candidateBore=struct("Faces",BF,"Vertices",BV);
    [candidateBore,report]=clean_component_mesh(candidateBore);
    if report.closed, bore=candidateBore; break; end
end
inputs{end+1}=shape; outputs{end+1}=bore;
if numel(inputs)>32, inputs(1)=[]; outputs(1)=[]; end
end
