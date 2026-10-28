function intervals = mesh_line_intervals(shape,startPoint,endPoint)
%MESH_LINE_INTERVALS Solid intervals in metres along a finite line segment.
% Triangle hits are merged before inside tests, so shared triangle edges do
% not create false material spans. Requires a closed mesh, including bores.
p=double(startPoint(:).'); delta=double(endPoint(:).')-p; L=norm(delta);
if L==0, error("MSBS:Line","Line endpoints must differ."); end
d=delta/L; V=double(shape.Vertices); F=shape.Faces;
tol=1e-9*max(1,max(max(V)-min(V)));
hits=ray_hits(p,d,V,F,tol);
cuts=sort([0;hits(hits>tol & hits<L-tol);L]);
cuts=cuts([true;diff(cuts)>tol]);
intervals=zeros(0,2);
% Irrational generic direction avoids systematic alignment with mesh edges.
ray=normalise_direction([1,sqrt(2),sqrt(3)]);
for k=1:numel(cuts)-1
    midpoint=p+mean(cuts(k:k+1))*d;
    forward=ray_hits(midpoint,ray,V,F,tol);
    inside=mod(numel(forward(forward>tol)),2)==1;
    % A line lying on the surface has zero penetration, not a solid interval.
    if inside && ~on_surface(midpoint,V,F,tol)
        intervals(end+1,:)=cuts(k:k+1).'; %#ok<AGROW>
    end
end
end
function hits=ray_hits(p,d,V,F,tol)
v0=V(F(:,1),:); e1=V(F(:,2),:)-v0; e2=V(F(:,3),:)-v0;
h=cross(repmat(d,size(e2,1),1),e2,2); det=sum(e1.*h,2);
good=abs(det)>1e-12.*max(vecnorm(e1,2,2).*vecnorm(e2,2,2),realmin);
u=NaN(size(det)); v=u; t=u;
s=p-v0; q=cross(s,e1,2);
u(good)=sum(s(good,:).*h(good,:),2)./det(good);
v(good)=q(good,:)*d.'./det(good);
t(good)=sum(e2(good,:).*q(good,:),2)./det(good);
valid=good & u>=-1e-10 & v>=-1e-10 & u+v<=1+1e-10;
hits=sort(t(valid));
if ~isempty(hits), hits=hits([true;diff(hits)>tol]); end
end
function tf=on_surface(p,V,F,tol)
a=V(F(:,1),:); b=V(F(:,2),:); c=V(F(:,3),:);
e=b-a; f=c-a; n=cross(e,f,2); lengths=vecnorm(n,2,2);
near=abs(sum((p-a).*n,2))<=tol.*lengths;
a=a(near,:); e=e(near,:); f=f(near,:); w=p-a;
ee=sum(e.*e,2); ef=sum(e.*f,2); ff=sum(f.*f,2); we=sum(w.*e,2); wf=sum(w.*f,2);
den=ee.*ff-ef.^2;
u=(ff.*we-ef.*wf)./den; v=(ee.*wf-ef.*we)./den;
tf=any(u>=-1e-10 & v>=-1e-10 & u+v<=1+1e-10);
end
