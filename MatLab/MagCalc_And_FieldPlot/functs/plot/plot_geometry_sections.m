function h = plot_geometry_sections(ax,geometry,q,alpha)
%PLOT_GEOMETRY_SECTIONS Fill closed sections and draw true open polylines.
% Never use patch for strokes: patch automatically closes open polygons.
if nargin<4, alpha=[]; end
[point,n]=query_plane(q); n=normalise_direction(n);
ref=[0 0 1]; if abs(dot(n,ref))>0.95, ref=[0 1 0]; end
u=normalise_direction(cross(ref,n)); v=cross(n,u);
h=gobjects(0);
for c=geometry_components(geometry)
    loops=mesh_plane_sections(c.shape,point,n); region=polyshape(); open={};
    tol=1e-8*max(1,max(max(c.shape.Vertices)-min(c.shape.Vertices)));
    for k=1:numel(loops)
        pts=loops{k};
        if size(pts,1)>=4 && norm(pts(1,:)-pts(end,:))<tol
            uv=(pts(1:end-1,:)-point)*[u(:),v(:)];
            piece=polyshape(uv(:,1),uv(:,2),"Simplify",true,"KeepCollinearPoints",true);
            region=xor(region,piece);
        else
            open{end+1}=pts; %#ok<AGROW>
        end
    end
    opacity=c.alpha; if ~isempty(alpha), opacity=alpha; end
    [color,~]=component_plot_style(c); hasSection=false;
    if ~isempty(region.Vertices)
        tr=triangulation(region); xyz=point+tr.Points(:,1)*u+tr.Points(:,2)*v;
        h(end+1)=patch(ax,"Faces",tr.ConnectivityList,"Vertices",xyz, ...
            "FaceColor",color,"FaceAlpha",opacity,"EdgeColor","none", ...
            "HandleVisibility","off","Tag","MSBSGeometryFill","HitTest","off"); %#ok<AGROW>
        [bx,by]=boundary(region); xyz=point+bx*u+by*v;
        % NaN separators are retained, so separate boundaries never connect.
        plot3(ax,xyz(:,1),xyz(:,2),xyz(:,3),"Color",.6*color, ...
            "HandleVisibility","off","Tag","MSBSGeometryOutline","HitTest","off");
        hasSection=true;
    end
    for k=1:numel(open)
        pts=open{k};
        h(end+1)=plot3(ax,pts(:,1),pts(:,2),pts(:,3),"Color",color, ...
            "HandleVisibility","off","Tag","MSBSGeometryOutline","HitTest","off"); %#ok<AGROW>
        hasSection=true;
    end
    if hasSection, register_geometry_legend(ax,c,opacity); end
    if ~isempty(open)
        warning("MSBS:OpenSection","Component '%s' has %d open section contours; drawn without closing chords. Re-export a closed STL for a reliable solid fill.",c.name,numel(open));
    end
end
end
function [point,n]=query_plane(q)
if q.type=="custom_plane", point=q.point(:).'; n=q.normal; return; end
switch q.plane
    case "xy", n=[0 0 1];
    case "xz", n=[0 1 0];
    case "yz", n=[1 0 0];
end
point=q.planeOffset*n;
end
