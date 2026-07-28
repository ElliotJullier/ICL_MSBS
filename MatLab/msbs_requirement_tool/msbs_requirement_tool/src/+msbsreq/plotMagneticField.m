function fig = plotMagneticField(record)
%PLOTMAGNETICFIELD Plot B0, local fields, and dipole directions for one solution.
arguments
    record (1,1) struct
end
fig=figure('Name','MSBS magnetic requirement','Visible','off');
ax=axes(fig);hold(ax,'on');axis(ax,'equal');grid(ax,'on');view(ax,3);
positions=record.map.positions_T_m;
fields=record.solution.B_at_each_magnet_T;
dipoles=record.map.dipoles_T_Am2;
quiver3(ax,0,0,0,record.solution.B0_T(1),record.solution.B0_T(2),record.solution.B0_T(3),0, ...
    'LineWidth',2,'DisplayName','B_0 (T)');
for i=1:size(positions,2)
    p=positions(:,i);
    plot3(ax,p(1),p(2),p(3),'ko','MarkerFaceColor','k','HandleVisibility','off');
    localUnitArrow(ax,p,fields(:,i),"Local B, magnet "+i,'-');
    localUnitArrow(ax,p,dipoles(:,i),"Dipole, magnet "+i,'--');
end
xlabel(ax,'x_T (m)');ylabel(ax,'y_T (m)');zlabel(ax,'z_T (m)');
title(ax,record.loads.scenario.scenario_id+" magnetic vectors; local arrows show direction",'Interpreter','none');
legend(ax,'Location','bestoutside');
end
function localUnitArrow(ax,p,v,name,style)
if norm(v)==0,return,end
u=v/norm(v);
quiver3(ax,p(1),p(2),p(3),u(1),u(2),u(3),0,'LineWidth',1.5, ...
    'LineStyle',style,'MaxHeadSize',0.35,'DisplayName',name);
end
