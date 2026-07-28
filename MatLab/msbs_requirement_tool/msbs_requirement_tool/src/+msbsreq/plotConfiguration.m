function fig = plotConfiguration(tunnel, geometry, magnetSet, massProperties, cfg)
%PLOTCONFIGURATION Plot tunnel, model, fitted cuboid, magnets, frames, and references.
arguments
    tunnel (1,1) struct
    geometry (1,1) struct
    magnetSet (1,1) struct
    massProperties (1,1) struct
    cfg (1,1) struct
end
fig=figure('Name','MSBS configuration','Visible','off');
ax=axes(fig);hold(ax,'on');axis(ax,'equal');grid(ax,'on');view(ax,3);
R=cfg.frames.body_attitude_cases(1).R_TB;
origin=cfg.frames.body_origin_T_m;
scale=max([geometry.outer_dimensions_B_m(:);sqrt(tunnel.area_m2)]);

localPlotTunnel(ax,tunnel,scale);
localPlotGeometry(ax,geometry,R,origin,0.22,[0.3 0.6 0.9],"Outer model");
localPlotBox(ax,geometry.inscribed_cuboid.dimensions_B_m, ...
    geometry.inscribed_cuboid.centre_B_m,R,origin,0.08,[0.5 0.5 0.5],"Inscribed cuboid",':');
for i=1:numel(magnetSet.magnets)
    m=magnetSet.magnets(i);
    localPlotBox(ax,m.dimensions_local_m,m.centre_B_m,R*m.R_BM,origin,0.85, ...
        [0.85 0.35 0.2],"Magnet "+i,'-');
    centre=origin+R*m.centre_B_m;
    direction=R*m.dipole_moment_B_Am2;
    localArrow(ax,centre,direction,0.35*scale,[0.8 0.1 0.1],"Magnetisation");
end

axisLength=0.25*scale;
localArrow(ax,origin,R(:,1),axisLength,[0.8 0.2 0.2],"Body x");
localArrow(ax,origin,R(:,2),axisLength,[0.2 0.7 0.2],"Body y");
localArrow(ax,origin,R(:,3),axisLength,[0.2 0.3 0.8],"Body z");
localArrow(ax,[0;0;0],[1;0;0],axisLength,[0.5 0 0],"Tunnel x");
localArrow(ax,[0;0;0],[0;1;0],axisLength,[0 0.5 0],"Tunnel y");
localArrow(ax,[0;0;0],[0;0;1],axisLength,[0 0 0.5],"Tunnel z");
wind=cfg.frames.wind_orientation_cases(1).R_TW(:,1);
localArrow(ax,origin,wind,0.45*scale,[0.1 0.1 0.1],"Wind");
localArrow(ax,origin,tunnel.gravity_T_mps2,0.35*scale,[0.3 0.2 0.1],"Gravity");
comT=origin+R*massProperties.centre_of_mass_B_m;
refT=origin+R*geometry.aero_reference_point_B_m;
plot3(ax,comT(1),comT(2),comT(3),'ko','MarkerFaceColor','k','DisplayName','Centre of mass');
plot3(ax,refT(1),refT(2),refT(3),'ks','MarkerFaceColor','w','DisplayName','Aero reference');

xlabel(ax,'x_T (m)');ylabel(ax,'y_T (m)');zlabel(ax,'z_T (m)');
title(ax,"Configuration: "+cfg.meta.case_id+" — "+magnetSet.name,'Interpreter','none');
legend(ax,'Location','bestoutside');
end

function localPlotTunnel(ax,tunnel,scale)
lengthX=1.4*scale;
if tunnel.cross_section_type=="rectangular"
    localPlotBox(ax,[lengthX;tunnel.width_m;tunnel.height_m],[0;0;0],eye(3),[0;0;0], ...
        0,[0.2 0.2 0.2],"Tunnel test section",'--');
else
    theta=linspace(0,2*pi,80);
    x=[-lengthX/2 lengthX/2];
    R=tunnel.diameter_m/2;
    for k=1:2
        if k==1, visibility='on'; else, visibility='off'; end
        plot3(ax,x(k)*ones(size(theta)),R*cos(theta),R*sin(theta),'k--', ...
            'HandleVisibility',visibility,'DisplayName','Tunnel test section');
    end
    for a=[0 pi/2 pi 3*pi/2]
        plot3(ax,x,R*cos(a)*ones(size(x)),R*sin(a)*ones(size(x)),'k--','HandleVisibility','off');
    end
end
end

function localPlotGeometry(ax,geometry,R,origin,alpha,colour,name)
switch geometry.type
    case {"cuboid","flat_plate","custom"}
        if geometry.type=="custom" && isfield(geometry.plot_data,'vertices_B_m') && ...
                ~isempty(geometry.plot_data.vertices_B_m)
            V=origin+R*geometry.plot_data.vertices_B_m.';
            patch(ax,'Vertices',V.','Faces',geometry.plot_data.faces,'FaceColor',colour, ...
                'FaceAlpha',alpha,'EdgeColor',colour,'DisplayName',name);
        else
            localPlotBox(ax,geometry.outer_dimensions_B_m,[0;0;0],R,origin,alpha,colour,name,'-');
        end
    case {"sphere","ellipsoid"}
        [x,y,z]=sphere(32);
        if geometry.type=="sphere"
            semi=geometry.shape.diameter_m/2*ones(3,1);
        else
            semi=geometry.shape.diameters_m(:)/2;
        end
        P=R*[semi(1)*x(:).';semi(2)*y(:).';semi(3)*z(:).']+origin;
        surf(ax,reshape(P(1,:),size(x)),reshape(P(2,:),size(y)),reshape(P(3,:),size(z)), ...
            'FaceColor',colour,'FaceAlpha',alpha,'EdgeColor','none','DisplayName',name);
    case "cylinder"
        [x,y,z]=cylinder(geometry.shape.diameter_m/2,40);z=(z-0.5)*geometry.shape.length_m;
        P=[x(:).';y(:).';z(:).'];
        switch geometry.shape.axis
            case "x", P=P([3 1 2],:);
            case "y", P=P([1 3 2],:);
        end
        P=R*P+origin;
        surf(ax,reshape(P(1,:),size(x)),reshape(P(2,:),size(y)),reshape(P(3,:),size(z)), ...
            'FaceColor',colour,'FaceAlpha',alpha,'EdgeColor','none','DisplayName',name);
end
end

function localPlotBox(ax,dims,centre,R,origin,alpha,colour,name,lineStyle)
S=[-1 -1 -1;-1 -1 1;-1 1 -1;-1 1 1;1 -1 -1;1 -1 1;1 1 -1;1 1 1].';
V=origin+R*(centre(:)+0.5*dims(:).*S);
F=[1 2 4 3;5 7 8 6;1 5 6 2;3 4 8 7;1 3 7 5;2 6 8 4];
if alpha==0
    patch(ax,'Vertices',V.','Faces',F,'FaceColor','none','EdgeColor',colour, ...
        'LineStyle',lineStyle,'DisplayName',name);
else
    patch(ax,'Vertices',V.','Faces',F,'FaceColor',colour,'FaceAlpha',alpha, ...
        'EdgeColor',colour,'LineStyle',lineStyle,'DisplayName',name);
end
end
function localArrow(ax,start,direction,lengthScale,colour,name)
if norm(direction)==0,return,end
v=direction/norm(direction)*lengthScale;
quiver3(ax,start(1),start(2),start(3),v(1),v(2),v(3),0, ...
    'Color',colour,'LineWidth',1.5,'MaxHeadSize',0.4,'DisplayName',name);
end
