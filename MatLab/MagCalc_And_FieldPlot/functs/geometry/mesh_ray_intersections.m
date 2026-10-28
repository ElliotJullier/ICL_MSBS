function hits = mesh_ray_intersections(shape,point,direction)
%MESH_RAY_INTERSECTIONS Unique signed distances along a unit ray/line.
p=double(point(:).'); d=normalise_direction(direction);
V=double(shape.Vertices); F=shape.Faces;
tol=1e-9*max(1,max(max(V)-min(V)));
v0=V(F(:,1),:); e1=V(F(:,2),:)-v0; e2=V(F(:,3),:)-v0;
h=cross(repmat(d,size(e2,1),1),e2,2); det=sum(e1.*h,2);
good=abs(det)>1e-12.*max(vecnorm(e1,2,2).*vecnorm(e2,2,2),realmin);
u=NaN(size(det)); v=u; t=u; s=p-v0; q=cross(s,e1,2);
u(good)=sum(s(good,:).*h(good,:),2)./det(good);
v(good)=q(good,:)*d.'./det(good);
t(good)=sum(e2(good,:).*q(good,:),2)./det(good);
valid=good & u>=-1e-10 & v>=-1e-10 & u+v<=1+1e-10;
hits=sort(t(valid));
if ~isempty(hits), hits=hits([true;diff(hits)>tol]); end
end
