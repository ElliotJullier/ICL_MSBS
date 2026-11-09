function export_revision_cad(out)
%EXPORT_REVISION_CAD Export representative MAT-ready CAD views and PNGs.
root=string(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'src'),fullfile(root,'cases'),fullfile(root,'research'));
if nargin==0,out=fullfile(root,'research','outputs','revision');end
dest=fullfile(out,'cad');
if ~isfolder(dest),mkdir(dest);end
families=["sphere","cuboid","ahmed","naca0012","cylinder_crossflow"];
for family=families
    beta=.10;
    if family=="cylinder_crossflow",beta=.08;end
    for H=[.6 1]
        if family=="ahmed" && H==.6,beta=.20;end
        cfg=msbsstudy.revisionCase(family,H,beta,"h",1);
        idx=height(cfg.scenarios);
        toPlot=1;
        if family=="naca0012",toPlot=[1 5 6];end
        if family=="cuboid" || family=="ahmed"
            names=string({cfg.magnets.sets.name});
            toPlot=[1 find(endsWith(names,'main_axis1'))];
        end
        for k=toPlot
            localSave(cfg,k,idx,dest);
        end
        if family=="ahmed",beta=.10;end
    end
end
cfg=msbsreq.defaultConfig();
cfg.meta.family="sc20714_geometry_only";
cfg.meta.case_id="sc20714_geometry_only";
[cfg,~]=msbsstudy.revisionWing(cfg,1,.10,"sc20714",3);
cfg.tunnel.cross_section.width_m=1;
cfg.tunnel.cross_section.height_m=1;
cfg=msbsreq.resolveConfig(cfg);
cfg.scenarios=table("geometry_only",7,0,0,'VariableNames',{'scenario_name','pitch_deg','yaw_deg','roll_deg'});
g=msbsreq.buildGeometry(cfg,msbsreq.buildTunnel(cfg));
cfg.magnets.sets=msbsstudy.cappedMagnets(g,1,{msbsreq.rotationZYX([0 7 0],"deg")},1,false);
save(fullfile(dest,'sc20714_geometry_only_input.mat'),'cfg');
localSave(cfg,1,1,dest);
end

function localSave(cfg,index,scenarioIndex,dest)
f=plot_revision_cad(cfg,index,scenarioIndex,"off");
stem=fullfile(dest,cfg.meta.case_id+"_"+cfg.magnets.sets(index).name);
savefig(f,stem+".fig");
exportgraphics(f,stem+".png",'Resolution',140);
close(f);
end
