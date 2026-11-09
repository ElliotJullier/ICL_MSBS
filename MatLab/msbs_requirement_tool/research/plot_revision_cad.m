function fig = plot_revision_cad(cfg,setIndex,scenarioIndex,visibility)
%PLOT_REVISION_CAD Opaque exterior and internal assembly at the same attitude.
% Open a saved revision input MAT file and pass its cfg to this function.
arguments
    cfg (1,1) struct
    setIndex (1,1) double {mustBeInteger,mustBePositive} = 1
    scenarioIndex (1,1) double {mustBeInteger,mustBePositive} = 1
    visibility (1,1) string = "on"
end
root=string(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'src'),fullfile(root,'research'));
cfg=msbsreq.resolveConfig(cfg);
tunnel=msbsreq.buildTunnel(cfg);
g=msbsreq.buildGeometry(cfg,tunnel);
scenarios=msbsreq.buildScenarioTable(cfg);
R=scenarios.R_TB{scenarioIndex};
magnets=cfg.magnets.sets(setIndex).magnets;
fig=figure('Visible',visibility,'Color','white','Position',[60 100 1100 470]);
layout=tiledlayout(fig,1,2,'Padding','compact');
title(layout,strrep(cfg.meta.family+"  |  "+cfg.magnets.sets(setIndex).name+"  |  "+ ...
    scenarios.scenario_name(scenarioIndex),"_"," "),'Interpreter','none');
left=nexttile(layout);
right=nexttile(layout);
bodyColor=[.39 .58 .66];
localBody(left,g,R,bodyColor,true);
localBody(right,g,R,bodyColor,false);
hold(right,'on');
for j=1:numel(magnets)
    m=magnets(j);
    color=[.93 .61 .16];
    if j>1,color=[.18 .63 .49];end
    localBox(right,m.dimensions_local_m,R*m.centre_B_m,R*m.R_BM,color,1);
    direction=R*m.R_BM*m.magnetisation_direction_M;
    L=.45*max(m.dimensions_local_m);
    start=R*m.centre_B_m+0.56*sum(abs(m.R_BM.'*R.'*[0;0;1]).*m.dimensions_local_m)*[0;0;1];
    quiver3(right,start(1),start(2),start(3),L*direction(1),L*direction(2),L*direction(3), ...
        0,'Color',[.18 .09 .07],'LineWidth',2,'MaxHeadSize',.75);
end
title(left,'Opaque exterior');
title(right,'Interior assembly and magnetisation');
limits=.58*max(g.outer_dimensions_B_m);
for ax=[left right]
    axis(ax,'equal');
    axis(ax,[-limits limits -limits limits -limits limits]);
    view(ax,42,24);
    xlabel(ax,'x_T [m]');ylabel(ax,'y_T [m]');zlabel(ax,'z_T [m]');
    grid(ax,'on');
end
end

function localBody(ax,g,R,color,opaque)
hold(ax,'on');
switch g.type
    case "sphere"
        [x,y,z]=sphere(30);
        localSurface(ax,x,y,z,R*g.shape.diameter_m/2,color,opaque);
    case "cylinder"
        [x,y,z]=cylinder(g.shape.diameter_m/2,40);
        localSurface(ax,x,(z-.5)*g.shape.length_m,y,R,color,opaque);
        for sign=[-1 1]
            p=R*[x(1,:);repmat(sign*g.shape.length_m/2,1,size(x,2));y(1,:)];
            fill3(ax,p(1,:),p(2,:),p(3,:),color,'FaceAlpha',double(opaque),'EdgeColor',color);
        end
    case "custom"
        xz=g.shape.solid_profile_xz_m;
        n=size(xz,1);
        span=g.outer_dimensions_B_m(2);
        p=R*[xz(:,1) -ones(n,1)*span/2 xz(:,2);xz(:,1) ones(n,1)*span/2 xz(:,2)].';
        i=(1:n).';
        next=[2:n 1].';
        faces=[i next next+n i+n];
        patch(ax,'Vertices',p.','Faces',faces,'FaceColor',color, ...
            'FaceAlpha',double(opaque),'EdgeColor','none');
        fill3(ax,p(1,i),p(2,i),p(3,i),color,'FaceAlpha',double(opaque),'EdgeColor',color);
        fill3(ax,p(1,i+n),p(2,i+n),p(3,i+n),color,'FaceAlpha',double(opaque),'EdgeColor',color);
        for k=unique(round(linspace(1,n,min(n,8))))
            plot3(ax,p(1,[k k+n]),p(2,[k k+n]),p(3,[k k+n]),'-','Color',color);
        end
    otherwise
        localBox(ax,g.outer_dimensions_B_m,zeros(3,1),R,color,double(opaque));
end
end

function localSurface(ax,x,y,z,R,color,opaque)
p=R*[x(:).';y(:).';z(:).'];
surf(ax,reshape(p(1,:),size(x)),reshape(p(2,:),size(y)),reshape(p(3,:),size(z)), ...
    'FaceColor',color,'FaceAlpha',double(opaque),'EdgeColor',color*(.8+.15*opaque),'EdgeAlpha',.25);
end

function localBox(ax,d,c,R,color,alpha)
signs=[-1 -1 -1;1 -1 -1;1 1 -1;-1 1 -1;-1 -1 1;1 -1 1;1 1 1;-1 1 1];
p=(c+R*(d.*signs.'/2)).';
patch(ax,'Vertices',p,'Faces',[1 2 3 4;5 6 7 8;1 2 6 5;2 3 7 6;3 4 8 7;4 1 5 8], ...
    'FaceColor',color,'FaceAlpha',alpha,'EdgeColor',color*.65,'LineWidth',.65);
end
