function fig = plotScenario(record)
%PLOTSCENARIO Plot force and moment vectors for one resolved scenario.
arguments
    record (1,1) struct
end
fig=figure('Name','MSBS scenario','Visible','off');
t=tiledlayout(fig,1,2,'TileSpacing','compact');
axF=nexttile(t);hold(axF,'on');axis(axF,'equal');grid(axF,'on');view(axF,3);
axM=nexttile(t);hold(axM,'on');axis(axM,'equal');grid(axM,'on');view(axM,3);
loads=record.loads;
forceVectors=[loads.aero_wrench_T(1:3),loads.gravity_wrench_T(1:3), ...
    loads.other_wrench_T(1:3),loads.inertial_demand_T(1:3), ...
    loads.required_magnetic_wrench_T(1:3),loads.resultant_external_wrench_T(1:3)];
momentVectors=[loads.aero_wrench_T(4:6),loads.gravity_wrench_T(4:6), ...
    loads.other_wrench_T(4:6),loads.inertial_demand_T(4:6), ...
    loads.required_magnetic_wrench_T(4:6),loads.resultant_external_wrench_T(4:6)];
names=["Aerodynamic","Gravity","Other external","Inertial demand","Required magnetic","External resultant"];
styles={'-','-','-','--','-','--'};
for i=1:size(forceVectors,2)
    localNormalisedArrow(axF,forceVectors(:,i),names(i),styles{i});
    localNormalisedArrow(axM,momentVectors(:,i),names(i),styles{i});
end
xlabel(axF,'x_T');ylabel(axF,'y_T');zlabel(axF,'z_T');title(axF,'Force directions (independently normalised)');
xlabel(axM,'x_T');ylabel(axM,'y_T');zlabel(axM,'z_T');title(axM,'Moment directions (independently normalised)');
legend(axM,'Location','bestoutside');
title(t,record.loads.scenario.scenario_id+" — "+record.magnet_set.name,'Interpreter','none');
end
function localNormalisedArrow(ax,v,name,lineStyle)
if norm(v)==0
    plot3(ax,NaN,NaN,NaN,'LineStyle',lineStyle,'DisplayName',name);return
end
u=v/norm(v);
quiver3(ax,0,0,0,u(1),u(2),u(3),0,'LineWidth',1.5,'LineStyle',lineStyle, ...
    'MaxHeadSize',0.4,'DisplayName',name);
end
