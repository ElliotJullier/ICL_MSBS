function r = query_coordinates(grid,q,index)
%QUERY_COORDINATES Construct query coordinates without allocating a field grid.
r=struct("queryIndex",index);
switch string(q.type)
    case "line"
        t=linspace(0,1,q.nPoints).'; p0=q.start(:).'; delta=q.end(:).'-p0;
        P=p0+t*delta; X=P(:,1); Y=P(:,2); Z=P(:,3); r.s=t*norm(delta);
    case "fundamental_plane"
        switch q.plane
            case "xy", [X,Y]=meshgrid(grid.x,grid.y); Z=repmat(q.planeOffset,size(X));
            case "xz", [X,Z]=meshgrid(grid.x,grid.z); Y=repmat(q.planeOffset,size(X));
            case "yz", [Y,Z]=meshgrid(grid.y,grid.z); X=repmat(q.planeOffset,size(Y));
        end
        r.requestedPlaneOffset=q.planeOffset; r.planeOffset=q.planeOffset;
    case "custom_plane"
        p0=q.point(:).'; n=normalise_direction(q.normal);
        ref=[0 0 1]; if abs(dot(n,ref))>0.95, ref=[0 1 0]; end
        if isfield(q,"upVector") && ~isempty(q.upVector)
            ref=normalise_direction(q.upVector);
            if abs(dot(ref,n))>1-1e-12, error("MSBS:PlaneUp","UpVector must not be parallel to normal."); end
        end
        u=normalise_direction(cross(ref,n)); v=cross(n,u);
        [cx,cy,cz]=ndgrid([min(grid.x),max(grid.x)],[min(grid.y),max(grid.y)],[min(grid.z),max(grid.z)]);
        corners=[cx(:),cy(:),cz(:)]-p0; cu=corners*u.'; cv=corners*v.';
        ub=[min(cu),max(cu)]; vb=[min(cv),max(cv)];
        if isfield(q,"uLimits") && ~isempty(q.uLimits), ub=q.uLimits; end
        if isfield(q,"vLimits") && ~isempty(q.vLimits), vb=q.vLimits; end
        res=q.resolution; if isscalar(res), res=[res res]; end
        [U,V]=meshgrid(linspace(ub(1),ub(2),res(1)),linspace(vb(1),vb(2),res(2)));
        X=p0(1)+U*u(1)+V*v(1); Y=p0(2)+U*u(2)+V*v(2); Z=p0(3)+U*u(3)+V*v(3);
        r.U=U; r.V=V; r.basisU=u; r.basisV=v; r.resolution=res;
    otherwise
        error("MSBS:QueryType","Unknown query type %s.",q.type);
end
r.X=X; r.Y=Y; r.Z=Z;
r.inside=find_points_inside_grid_domain(grid,X,Y,Z);
end
