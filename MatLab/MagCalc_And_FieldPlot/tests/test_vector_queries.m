function test_vector_queries()
%TEST_VECTOR_QUERIES Mathematical projection, ROI, masks, seeding and plots.
project=fileparts(fileparts(mfilename("fullpath"))); addpath(genpath(fullfile(project,"functs")));
old=get(groot,"defaultFigureVisible"); set(groot,"defaultFigureVisible","off");
cleanup=onCleanup(@()finish(old)); %#ok<NASGU>
g=struct("x",linspace(-1,1,9),"y",linspace(-1,1,9),"z",linspace(-1,1,9));
[X,Y,Z]=meshgrid(g.x,g.y,g.z);
ds=struct("source","comsol_precomputed","datasetFile","vector_fixture","grid",g, ...
    "B",cat(4,1+X,2+Y,3+Z),"supportsSuperposition",false,"supportsCurrentSolve",false, ...
    "geometry",struct("coil",struct([])));
op=validate_and_solve_operating_point(ds,struct("mode","precomputed"),"comsol_precomputed");
plane=create_vector_plane_query("xy",0,"Resolution",[13 11],"MaxArrows",50,"Group","plane","Name","Projected affine B");
[r,queries]=run_field_queries(ds,op,{plane},"comsol_precomputed"); r=r{1}; plane=queries{1};
assert(max(abs(r.B(:,1)-(1+r.points(:,1))))<1e-9);
assert(max(abs(r.B(:,2)-(2+r.points(:,2))))<1e-9);
assert(max(abs(r.normalComponent-3))<1e-9);
assert(all(abs(r.projectedB(:,3))<1e-10));
assert(max(abs(r.projectedVariation-sqrt(2)),[],"omitnan")<1e-9);
oblique=create_vector_plane_query([.1 0 0],[1 1 1],"ULimits",[-.3 .3],"VLimits",[-.3 .3], ...
    "Resolution",9,"UpVector","z","Mode","3d");
[t,~]=run_field_queries(ds,op,{oblique},"comsol_precomputed"); t=t{1};
assert(max(abs((t.points-oblique.point)*oblique.normal.'))<1e-10);
assert(max(abs(t.projectedB*oblique.normal.'))<1e-10);
pose=[.1 .1 .05 .2 -.3 .4]; bounds=[-.3 .3;-.25 .25;-.2 .2];
volume=create_vector_volume_query(bounds,"Resolution",[7 6 5],"Pose",pose,"MaxArrows",70,"Group","volume");
[v,~]=run_field_queries(ds,op,{volume},"comsol_precomputed"); v=v{1};
R=coord_local2global(eye(3),[0 0 0 pose(4:6)]);
back=(R.'*(v.points.'-pose(1:3).')).';
assert(all(back>=bounds(:,1).'-1e-10 & back<=bounds(:,2).'+1e-10,"all"));
assert(max(abs(v.B(:,3)-(3+v.points(:,3))))<1e-9);
assert(max(abs(v.variation-sqrt(3)),[],"omitnan")<1e-9);
% A planar export supports plane vectors, never a true volume.
flat=ds; flat.grid.y=0; flat.B=ds.B(5,:,:,:);
must_error(@()run_field_queries(flat,op,{volume},"comsol_precomputed"),"MSBS:VectorVolume");
outside=create_vector_plane_query([0 .1 0],[0 1 0],"Resolution",7);
[n,~]=run_field_queries(flat,op,{outside},"comsol_precomputed");
assert(~any(n{1}.valid));
must_error(@()run_field_queries(ds,op,{plane},"simple_biotsavart"),"MSBS:VectorModel");
% Out-of-plane-only variation must not drive projected variation seeding.
normalOnly=ds; normalOnly.B=cat(4,ones(size(X)),zeros(size(X)),X);
[n,~]=run_field_queries(normalOnly,op,{plane},"comsol_precomputed");
assert(max(abs(n{1}.projectedVariation),[],"omitnan")<1e-9);
assert(max(abs(n{1}.variation-1),[],"omitnan")<1e-9);
% A virtual difference with a rotated source must rotate B as well as points.
sourcePose=[0 0 0 .2 -.1 .15]; rotation=coord_local2global(eye(3),sourcePose);
virtual=create_virtual_field_dataset({ds,ds},{op,op},[1 -.2],[zeros(1,6);sourcePose]);
vq=create_vector_plane_query("xy",0,"ULimits",[-.3 .3],"VLimits",[-.3 .3],"Resolution",7);
[vr,~]=run_field_queries(virtual,struct(),{vq},"virtual_field"); vr=vr{1};
local=(rotation.'*vr.points.').';
sourceB=[1+local(:,1),2+local(:,2),3+local(:,3)];
expected=[1+vr.points(:,1),2+vr.points(:,2),3+vr.points(:,3)]-.2*(rotation*sourceB.').';
assert(max(abs(vr.B-expected),[],"all")<1e-9);

component=struct("name","Cube core","role","core","shape",cube(), ...
    "color",[.6 .3 .78],"alpha",.5,"closed",true);
withCore=ds; withCore.geometry=struct("components",component);
dense=plane; dense.resolution=[21 21]; dense.vector.Resolution=[21 21]; dense.vector.MaxArrows=1000;
[m,~]=run_field_queries(withCore,op,{dense},"comsol_precomputed"); m=m{1};
assert(any(m.inMaterial));
record=make_record(m,dense); style=plotStyle(); style.writeMetadata=false;
display=vector_display_data(record,style); indices=select_vector_seeds(record,display);
assert(~any(m.inMaterial(indices)));
style.vector=struct("ExcludeMaterials",false);
display=vector_display_data(record,style); indices=select_vector_seeds(record,display);
assert(any(m.inMaterial(indices)));

record=make_record(r,plane); style=plotStyle(); style.writeMetadata=false;
display=vector_display_data(record,style);
uniform=select_vector_seeds(record,display);
assert(numel(uniform)<=50 && all(display.eligible(uniform)));
for strategy=["magnitude","variation"]
 style.vector=struct("Seeding",strategy);
 d=vector_display_data(record,style);
 first=select_vector_seeds(record,d); second=select_vector_seeds(record,d);
 assert(isequal(first,second) && numel(first)<=50 && all(d.eligible(first)));
end
style.vector=struct("Mode","3d","ColorScale","log");
d=vector_display_data(record,style);
assert(~d.projected && max(abs(d.vectors(:,3)-3))<1e-9);
style.vector=struct("Resolution",[5 5]);
must_error(@()vector_display_data(record,style),"MSBS:VectorRequery");

Q1=pack_query_case(ds,op,{plane},{r},struct("caseName","Vector plane","model","comsol_precomputed"));
Q2=pack_query_case(ds,op,{volume},{v},struct("caseName","Vector volume","model","comsol_precomputed"));
style=plotStyle(); style.writeMetadata=false;
plot_field({Q1,Q2},style); figs=findall(groot,"Type","figure"); assert(numel(figs)==2);
for fig=figs.'
 report=getappdata(fig,"MSBSVectorDisplay"); assert(report.arrowCount<=400 && report.arrowCount>0);
 arrows=findall(fig,"Tag","MSBSVectorArrows"); assert(~isempty(arrows));
 lengths=[];
 for h=arrows.'
  assert(string(h.AutoScale)=="off");
  z=h.WData; if isempty(z), z=zeros(size(h.UData)); end
  lengths=[lengths;sqrt(h.UData(:).^2+h.VData(:).^2+z(:).^2)]; %#ok<AGROW>
 end
 assert(max(lengths)-min(lengths)<1e-10);
 assert(strlength(string(findall(fig,"Type","axes").Title.String))==0);
end
close all
style.vector=struct("ColorScale","log"); plot_field({Q1},style);
assert(string(gca().ColorScale)=="log"); close all
style.vector=struct();
% Vector magnitudes never set signed scalar-field colour limits.
scalar=Q1; scalar.queries={create_plane_field_query("xy",0,"z","Group","scalar")};
scalar.results={struct("queryIndex",1,"X",[-1 1;-1 1],"Y",[-1 -1;1 1], ...
    "Z",zeros(2),"data",1e-9*ones(2),"dataName","Bz","plot",scalar.queries{1}.plot)};
records=build_plot_records_from_Q({scalar,Q1});
resolved=resolve_plot_colour_limits(records,style); assert(resolved.clim.field(2)==1e-9);
diff=make_record(r,plane); diff.synthetic=struct("weights",[1 -1],"type","weighted_transformed_sum");
dd=vector_display_data(diff,style); assert(dd.key=="vectorProjectedDifference");
assert(contains(dd.colourLabel,string(char(92))+"Delta"));
fprintf("PASS: vector projection, normal retention, posed volume, no extrapolation, virtual-compatible sampling, masks, deterministic seeding and graphics.\n");
end
function record=make_record(result,query)
record=result; record.query=query; record.caseName="Fixture"; record.queryName=query.name;
record.model="comsol_precomputed"; record.caseMeta=struct(); record.geometry=struct("coil",struct([]));
end
function shape=cube()
V=[-.25 -.25 -.25;.25 -.25 -.25;.25 .25 -.25;-.25 .25 -.25; ...
    -.25 -.25 .25;.25 -.25 .25;.25 .25 .25;-.25 .25 .25];
F=[1 3 2;1 4 3;5 6 7;5 7 8;1 2 6;1 6 5;2 3 7;2 7 6;3 4 8;3 8 7;4 1 5;4 5 8];
shape=struct("Faces",F,"Vertices",V);
end
function must_error(f,id)
try
 f();
catch e
 assert(string(e.identifier)==id,"Unexpected error: "+e.message); return
end
error("Expected error %s was not raised.",id);
end
function finish(old)
close all; set(groot,"defaultFigureVisible",old);
end
