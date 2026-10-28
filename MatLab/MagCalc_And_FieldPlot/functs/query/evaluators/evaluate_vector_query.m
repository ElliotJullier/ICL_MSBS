function r = evaluate_vector_query(dataset,op,q,index)
%EVALUATE_VECTOR_QUERY Cache candidate B vectors, projection and variation.
if q.type=="vector_plane"
    plane=q; plane.type="custom_plane";
    coords=query_coordinates(dataset.grid,plane,index);
    points=[coords.X(:),coords.Y(:),coords.Z(:)];
    u=unique(coords.U(1,:)); v=unique(coords.V(:,1));
    if numel(u)<2 || numel(v)<2
        error("MSBS:VectorPlaneSupport","This plane has no sampled extent in one direction. Select another plane or export a volume.");
    end
    samplingGrid=struct("x",u(:).',"y",v(:).',"z",0);
    shape=size(coords.X); shape(3)=1;
    basis=[coords.basisU(:),coords.basisV(:),q.normal(:)];
    [ru,rv]=meshgrid([min(u),max(u)],[min(v),max(v)]);
    roiVertices=q.point+ru(:)*coords.basisU+rv(:)*coords.basisV;
    roiEdges=[1 2;2 4;4 3;3 1];
else
    bounds=q.bounds;
    if isempty(bounds)
        bounds=[min(dataset.grid.x) max(dataset.grid.x);min(dataset.grid.y) max(dataset.grid.y);min(dataset.grid.z) max(dataset.grid.z)];
    end
    if any(bounds(:,2)<=bounds(:,1)), error("MSBS:VectorVolume","A true 3D vector volume needs sampled extents in all three dimensions. Use a plane query for planar data."); end
    axes=cell(1,3);
    for j=1:3, axes{j}=linspace(bounds(j,1),bounds(j,2),q.resolution(j)); end
    [X,Y,Z]=meshgrid(axes{:}); shape=size(X);
    local=[X(:),Y(:),Z(:)]; points=coord_local2global(local.',q.pose).';
    samplingGrid=struct("x",axes{1},"y",axes{2},"z",axes{3});
    basis=coord_local2global(eye(3),[0 0 0 q.pose(4:6)]);
    [cx,cy,cz]=ndgrid(bounds(1,:),bounds(2,:),bounds(3,:));
    roiVertices=coord_local2global([cx(:),cy(:),cz(:)].',q.pose).';
    roiEdges=[1 2;3 4;5 6;7 8;1 3;2 4;5 7;6 8;1 5;2 6;3 7;4 8];
    coords=struct("queryIndex",index,"X",reshape(points(:,1),shape), ...
        "Y",reshape(points(:,2),shape),"Z",reshape(points(:,3),shape));
end
B=NaN(size(points)); names=["x","y","z"];
for j=1:3, B(:,j)=sample_dataset_points(dataset,op,points.',names(j),[]).'; end
valid=all(isfinite(B),2);
if q.type=="vector_volume"
    if nnz(valid)<4 || rank(points(valid,:)-mean(points(valid,:),1),1e-9*max(1,max(abs(points),[],"all")))<3
        error("MSBS:VectorVolume","Exported data cannot support a 3D volume at these points; no planar extrusion/extrapolation is performed.");
    end
end
material=false(size(valid));
materialMaskComponents=0;
geometries={dataset.geometry};
if isfield(dataset,"synthetic") && isfield(dataset.synthetic,"coilGeometrySources")
    sources=dataset.synthetic.coilGeometrySources; geometries={sources.geometry};
end
seen={};
for geometry=geometries
    components=geometry_components(geometry{1});
    if any(cellfun(@(c)isequaln(c,components),seen)), continue; end
    seen{end+1}=components; %#ok<AGROW>
    for c=components
        if c.closed
            materialMaskComponents=materialMaskComponents+1;
            material(valid)=material(valid) | points_inside_mesh(c.shape,points(valid,:));
        else
            warning("MSBS:VectorMaterialMask","Cannot exclude open component '%s' from vector seeds.",c.name);
        end
    end
end
fullMagnitude=vecnorm(B,2,2); projected=B;
normalComponent=NaN(size(valid)); basisComponents=B*basis;
if q.type=="vector_plane"
    normalComponent=B*q.normal(:);
    projected=B-normalComponent*q.normal(:).';
end
% Tangential/volume variation is an importance heuristic, not an FEM gradient.
% Mask material origins before differentiating to avoid using cross-material stencils.
variationSquared=zeros(shape); projectedVariationSquared=zeros(shape); good=reshape(valid & ~material,shape);
for component=1:3
    scalar=reshape(basisComponents(:,component),shape); scalar(~good)=NaN;
    for direction=1:(2+(q.type=="vector_volume"))
        gradient=compute_directional_gradient_grid(samplingGrid,scalar,"B",names(direction));
        variationSquared=variationSquared+gradient.^2;
        if component<=2, projectedVariationSquared=projectedVariationSquared+gradient.^2; end
    end
end
variation=sqrt(variationSquared(:));
r=coords;
r.points=points; r.B=B; r.projectedB=projected; r.basisComponents=basisComponents;
r.normalComponent=normalComponent; r.magnitude=fullMagnitude;
r.projectedMagnitude=vecnorm(projected,2,2); r.variation=variation;
r.projectedVariation=sqrt(projectedVariationSquared(:));
r.valid=valid; r.inMaterial=material; r.sampleShape=shape; r.samplingGrid=samplingGrid;
r.materialMaskComponents=materialMaskComponents;
r.basis=basis; r.data=fullMagnitude; r.dataName="B vector";
r.roiVertices=roiVertices; r.roiEdges=roiEdges;
r.inside=valid; r.plot=q.plot;
if q.type=="vector_plane"
    r.planePoint=q.point; r.planeNormal=q.normal;
    r.U=coords.U(:); r.V=coords.V(:);
end
end
