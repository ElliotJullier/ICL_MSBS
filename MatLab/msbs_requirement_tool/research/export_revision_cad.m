function export_revision_cad(out,portfolio)
%EXPORT_REVISION_CAD Export representative MAT-ready CAD views and PNGs.
root=string(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'src'),fullfile(root,'cases'),fullfile(root,'research'));
if nargin==0,out=fullfile(root,'research','outputs','revision');end
if nargin<2,portfolio="historical";end
dest=fullfile(out,'cad');
if ~isfolder(dest),mkdir(dest);end
families=["sphere","cuboid","ahmed","naca0012","cylinder_crossflow"];
construct=@msbsstudy.revisionCase;
if portfolio=="standalone"
    families=["sphere","cuboid","ahmed","naca0012","cylinder_parked","cylinder_crossflow"];
    construct=@msbsstudy.standaloneCase;
end
for family=families
    beta=.10;
    if family=="cylinder_crossflow",beta=.08;end
    if family=="cylinder_crossflow" && portfolio=="standalone",beta=.20;end
    for H=[.6 1]
        if family=="ahmed" && H==.6,beta=.20;end
        cfg=construct(family,H,beta,"h",1);
        idx=height(cfg.scenarios);
        toPlot=1;
        if family=="naca0012",toPlot=[1 5 6];end
        if family=="cuboid" || family=="ahmed"
            names=string({cfg.magnets.sets.name});
            toPlot=[1 find(endsWith(names,'main_axis1'))];
            if family=="cuboid" && H==.6,toPlot=1:numel(names);end
        end
        for k=toPlot
            pose=idx;
            if family=="cuboid" && ~endsWith(cfg.magnets.sets(k).name,"last_pose"),pose=3;end
            localSave(cfg,k,pose,dest);
        end
        if family=="ahmed",beta=.10;end
    end
end
end

function localSave(cfg,index,scenarioIndex,dest)
f=plot_revision_cad(cfg,index,scenarioIndex,"off");
stem=fullfile(dest,cfg.meta.case_id+"_"+cfg.magnets.sets(index).name);
savefig(f,stem+".fig");
set(f,'PaperPositionMode','auto');
print(f,stem+".png",'-dpng','-r140');
close(f);
end
