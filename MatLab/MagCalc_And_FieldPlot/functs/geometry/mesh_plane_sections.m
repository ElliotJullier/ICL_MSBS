function loops = mesh_plane_sections(shape,point,normal)
%MESH_PLANE_SECTIONS Triangle-plane cuts as joined 3D polylines.
% Includes coplanar boundary edges (internal coplanar triangle edges cancel).
% Closed loops preserve separate bore contours. Tangent points are omitted.
normal=normalise_direction(normal); point=double(point(:).');
V=double(shape.Vertices); F=shape.Faces;
tol=1e-9*max(1,max(max(V)-min(V)));
segments=zeros(0,6); coplanar=zeros(0,6);
for i=1:size(F,1)
    tri=V(F(i,:),:); d=(tri-point)*normal.';
    if all(abs(d)<=tol)
        for edge=[1 2;2 3;3 1].'
            coplanar(end+1,:)=[tri(edge(1),:),tri(edge(2),:)]; %#ok<AGROW>
        end
        continue
    end
    if all(d>tol) || all(d<-tol), continue; end
    pts=tri(abs(d)<=tol,:);
    for edge=[1 2;2 3;3 1].'
        a=edge(1); b=edge(2);
        if (d(a)>tol && d(b)<-tol) || (d(a)<-tol && d(b)>tol)
            pts(end+1,:)=tri(a,:)+d(a)/(d(a)-d(b))*(tri(b,:)-tri(a,:)); %#ok<AGROW>
        end
    end
    if size(pts,1)<2, continue; end
    [~,keep]=unique(round(pts/tol),"rows"); pts=pts(keep,:);
    if size(pts,1)>=2 && norm(pts(1,:)-pts(2,:))>tol
        segments(end+1,:)=[pts(1,:),pts(2,:)]; %#ok<AGROW>
    end
end
if ~isempty(coplanar)
    keys=canonical(coplanar,tol); [~,~,idx]=unique(keys,"rows");
    counts=accumarray(idx,1); coplanar=coplanar(counts(idx)==1,:);
    segments=[segments;coplanar];
end
loops={}; if isempty(segments), return; end
[~,keep]=unique(canonical(segments,tol),"rows"); segments=segments(keep,:);
points=[segments(:,1:3);segments(:,4:6)];
[~,first,idx]=unique(round(points/tol),"rows"); nodes=points(first,:);
n=size(segments,1); edges=[idx(1:n),idx(n+1:end)]; used=false(n,1);
while any(~used)
    start=find(~used,1); chain=edges(start,:); used(start)=true;
    while true
        next=find(~used & (edges(:,1)==chain(end) | edges(:,2)==chain(end)),1);
        if isempty(next), break; end
        pair=edges(next,:); used(next)=true;
        chain(end+1)=pair(find(pair~=chain(end),1)); %#ok<AGROW>
        if chain(end)==chain(1), break; end
    end
    % Extend the other end for open sections.
    if chain(end)~=chain(1)
        chain=fliplr(chain);
        while true
            next=find(~used & (edges(:,1)==chain(end) | edges(:,2)==chain(end)),1);
            if isempty(next), break; end
            pair=edges(next,:); used(next)=true;
            chain(end+1)=pair(find(pair~=chain(end),1)); %#ok<AGROW>
        end
    end
    loops{end+1}=nodes(chain,:); %#ok<AGROW>
end
end
function keys=canonical(s,tol)
a=round(s(:,1:3)/tol); b=round(s(:,4:6)/tol);
swap=a(:,1)>b(:,1) | (a(:,1)==b(:,1) & a(:,2)>b(:,2)) | ...
    (a(:,1)==b(:,1) & a(:,2)==b(:,2) & a(:,3)>b(:,3));
temp=a(swap,:); a(swap,:)=b(swap,:); b(swap,:)=temp;
keys=[a,b];
end
