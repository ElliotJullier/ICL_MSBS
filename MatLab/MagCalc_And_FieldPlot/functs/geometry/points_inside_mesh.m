function inside = points_inside_mesh(shape,points)
%POINTS_INSIDE_MESH Conservative mask for a closed surface, Nx3 world points.
% Exact duplicate triangle hits are merged by mesh_ray_intersections.
V=shape.Vertices; F=shape.Faces; points=double(points);
inside=false(size(points,1),1); lo=min(V); hi=max(V);
tol=1e-9*max(1,max(hi-lo));
candidates=find(all(points>=lo-tol & points<=hi+tol,2));
ray=normalise_direction([1 sqrt(2) sqrt(3)]);
for k=candidates(:).'
    point=points(k,:);
    hits=mesh_ray_intersections(shape,point,ray);
    if any(abs(hits)<tol), inside(k)=true; continue; end
    inside(k)=mod(nnz(hits>tol),2)==1;
    % Treat a point on any facet as material even for a tangent ray.
    if ~inside(k)
        a=V(F(:,1),:); e=V(F(:,2),:)-a; f=V(F(:,3),:)-a; n=cross(e,f,2);
        near=abs(sum((point-a).*n,2))<=tol*vecnorm(n,2,2);
        if any(near)
            e=e(near,:); f=f(near,:); w=point-a(near,:);
            ee=sum(e.*e,2); ef=sum(e.*f,2); ff=sum(f.*f,2);
            den=ee.*ff-ef.^2; we=sum(w.*e,2); wf=sum(w.*f,2);
            u=(ff.*we-ef.*wf)./den; v=(ee.*wf-ef.*we)./den;
            inside(k)=any(u>=-1e-10 & v>=-1e-10 & u+v<=1+1e-10);
        end
    end
end
end
