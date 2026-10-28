function [shape,report] = clean_component_mesh(original)
%CLEAN_COMPONENT_MESH Remove verifiable flat internal partition patches.
% No capping, hull replacement or geometry displacement. Separate closed
% shells/cavities are retained. Repair is accepted only if all edges end up
% incident to exactly two triangles. Actual holes cause an unchanged result.
persistent inputs outputs reports
if isempty(inputs), inputs={}; outputs={}; reports={}; end
for k=1:numel(inputs)
    if isequaln(inputs{k},original), shape=outputs{k}; report=reports{k}; return; end
end
shape=original; F=double(shape.Faces); V=double(shape.Vertices);
[edges,faceIds,index,counts]=edge_data(F);
report=struct("closed",all(counts==2),"removedFaces",0,"boundaryEdges",nnz(counts==1), ...
    "nonmanifoldEdges",nnz(counts>2),"status","unchanged");
if report.closed
    report.status="already_closed";
elseif all(counts>=2) && any(counts>2)
    % Connect facets through ordinary two-triangle edges; a partition ends
    % at the three/four-triangle seams of the non-manifold surface complex.
    pairs=zeros(nnz(counts==2),2); row=0;
    for e=find(counts==2).'
        faces=faceIds(index==e); row=row+1; pairs(row,:)=faces(:).';
    end
    graphMesh=graph(pairs(:,1),pairs(:,2),[],size(F,1));
    groups=conncomp(graphMesh);
    nonmanifoldFaces=unique(faceIds(ismember(index,find(counts>2))));
    remove=false(size(F,1),1);
    [dx,dy,dz]=ndgrid(-1:1,-1:1,-1:1);
    directions=[dx(:),dy(:),dz(:)]; directions=directions(any(directions,2),:);
    epsilon=1e-7*max(1,max(max(V)-min(V)));
    for group=unique(groups)
        ids=find(groups==group);
        if ~any(ismember(ids,nonmanifoldFaces)), continue; end
        normals=cross(V(F(ids,2),:)-V(F(ids,1),:),V(F(ids,3),:)-V(F(ids,1),:),2);
        lengths=vecnorm(normals,2,2); normals=normals./lengths;
        n=normals(1,:);
        if any(abs(normals*n.')<1-1e-8), continue; end % Only flat partitions.
        planeOffset=V(F(ids,1),:)*n.';
        if max(planeOffset)-min(planeOffset)>epsilon, continue; end
        dirs=[directions;n;-n];
        dirs=dirs(abs(dirs*n.')>1e-6,:);
        visible=false;
        for face=ids(:).'
            centre=mean(V(F(face,:),:),1);
            for d=dirs.'
                d=normalise_direction(d);
                hits=mesh_ray_intersections(original,centre+epsilon*d,d);
                if ~any(hits>epsilon/10), visible=true; break; end
            end
            if visible, break; end
        end
        if ~visible, remove(ids)=true; end
    end
    candidate=F(~remove,:);
    [~,~,~,newCounts]=edge_data(candidate);
    if any(remove) && ~isempty(candidate) && all(newCounts==2)
        shape.Faces=candidate; report.closed=true;
        report.removedFaces=nnz(remove); report.status="internal_partitions_removed";
    else
        report.status="nonmanifold_not_repaired";
    end
end
inputs{end+1}=original; outputs{end+1}=shape; reports{end+1}=report;
% Bound the session cache; entries are exact mesh matches, never heuristic keys.
if numel(inputs)>32, inputs(1)=[]; outputs(1)=[]; reports(1)=[]; end
end
function [edges,faces,index,counts]=edge_data(F)
raw=sort([F(:,[1 2]);F(:,[2 3]);F(:,[3 1])],2);
faces=repmat((1:size(F,1)).',3,1);
[edges,~,index]=unique(raw,"rows"); counts=accumarray(index,1);
end
