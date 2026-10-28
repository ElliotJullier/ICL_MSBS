function test_mesh_partitions_and_bands()
%TEST_MESH_PARTITIONS_AND_BANDS Repair acceptance, bores, infinite bands/caps.
project=fileparts(fileparts(mfilename("fullpath"))); addpath(genpath(fullfile(project,"functs")));
old=get(groot,"defaultFigureVisible"); set(groot,"defaultFigureVisible","off");
cleanup=onCleanup(@()finish(old)); %#ok<NASGU>
a=cube([-1 -1 -1],[0 1 1]); b=cube([0 -1 -1],[1 1 1]);
V=[a.Vertices;b.Vertices]; F=[a.Faces;b.Faces+8];
[V,~,id]=unique(V,"rows"); F=reshape(id(F),size(F));
raw=struct("Faces",F,"Vertices",V); [cleaned,report]=clean_component_mesh(raw);
assert(report.closed && report.removedFaces==4);
assert(isequal(cleaned.Vertices,V) && size(cleaned.Faces,1)==20);
spans=mesh_line_intervals(cleaned,[-2 0 0],[2 0 0]);
assert(isequal(spans,[1 3]));
broken=cleaned; broken.Faces(1,:)=[];
[untouched,failed]=clean_component_mesh(broken);
assert(~failed.closed && isequaln(untouched,broken)); % Never invent caps.
% A genuinely closed inner cavity is not an internal partition.
outer=cube([-2 -2 -2],[2 2 2]); inner=cube([-.5 -.5 -.5],[.5 .5 .5]);
cavity=struct("Vertices",[outer.Vertices;inner.Vertices], ...
    "Faces",[outer.Faces;fliplr(inner.Faces)+8]);
[preserved,rr]=clean_component_mesh(cavity);
assert(rr.closed && rr.removedFaces==0 && isequaln(preserved,cavity));

coil=tube_mesh(); bore=coil_bore_geometry(coil);
assert(~isempty(bore));
boreSpans=mesh_line_intervals(bore,[0 0 -2],[0 0 2]);
assert(max(abs(boreSpans-[1 3]))<1e-10);
assert(isempty(mesh_line_intervals(coil,[0 0 -2],[0 0 2])));
c=struct("name","Coil","role","coil","shape",coil,"color",[0 1 0],"alpha",.5,"closed",true);
core=c; core.name="Core"; core.role="core"; core.shape=cube([-.2 -.2 -.4],[.2 .2 .4]);
record=struct("X",zeros(7,1),"Y",zeros(7,1),"Z",linspace(-2,2,7).', ...
    "s",linspace(0,4,7).',"plotCoordinates",linspace(-2,2,7).');
fig=figure; ax=axes("Parent",fig); plot(ax,record.Z,record.Z); hold(ax,"on");
geometry=struct("components",[c core]);
add_coil_presence_to_line_plot(ax,record,geometry,[],.5);
material=findall(ax,"Tag","MSBSMaterialBand"); hole=findall(ax,"Tag","MSBSBoreBand");
assert(numel(material)==1 && string(material.UserData.role)=="core");
assert(numel(hole)==1 && ~hole.UserData.material);
assert(max(abs(sort(material.Value(:))-[-.4;.4]))<1e-9);
assert(max(abs(sort(hole.Value(:))-[-1;1]))<1e-9);
hatch=findall(ax,"Tag","MSBSBoreHatch"); assert(numel(hatch)==1);
boundaries=findall(ax,"Tag","MSBSMaterialBoundary"); assert(numel(boundaries)==4);
assert(all(arrayfun(@(h) h.Alpha==1 && string(h.LineStyle)=="-",boundaries)));
ylim(ax,[-7 9]); drawnow;
hatchLines=findall(hatch,"Type","line");
coords=[]; for h=hatchLines.', coords=[coords h.YData]; end %#ok<AGROW>
assert(abs(min(coords)+7)<1e-10 && abs(max(coords)-9)<1e-10);
% Same visible span from another case does not double opacity or hatching.
add_coil_presence_to_line_plot(ax,record,geometry,[],.5);
assert(numel(findall(ax,"Tag","MSBSMaterialBand"))==1);
assert(numel(findall(ax,"Tag","MSBSBoreBand"))==1);
assert(numel(findall(ax,"Tag","MSBSBoreHatch"))==1);
assert(numel(findall(ax,"Tag","MSBSMaterialBoundary"))==4);
assert(string(material.Layer)=="bottom");
close(fig);

data=ones(100); data(1)=1e6;
r=struct("query",struct("quantity","gradient"),"data",data);
[limits,rr]=gradient_colour_limits({r},99);
assert(isequal(limits,[-1 1]) && rr.sampleCount==10000);
assert(abs(rr.saturatedFraction-.0001)<eps);
assert(r.data(1)==1e6); % Display clipping never clips numerical samples.
[limits,~]=gradient_colour_limits({r},100); assert(isequal(limits,[-1e6 1e6]));
fprintf("PASS: partition cleanup, preservation of cavities/open meshes, inferred bores, persistent/deduplicated bands and display-only gradient caps.\n");
end
function shape=cube(lo,hi)
V=[lo;hi(1) lo(2) lo(3);hi(1) hi(2) lo(3);lo(1) hi(2) lo(3); ...
   lo(1) lo(2) hi(3);hi(1) lo(2) hi(3);hi;lo(1) hi(2) hi(3)];
F=[1 3 2;1 4 3;5 6 7;5 7 8;1 2 6;1 6 5;2 3 7;2 7 6;3 4 8;3 8 7;4 1 5;4 5 8];
shape=struct("Faces",F,"Vertices",V);
end
function shape=tube_mesh()
ring=[-1 -1;1 -1;1 1;-1 1;-.5 -.5;.5 -.5;.5 .5;-.5 .5];
V=[ring,-ones(8,1);ring,ones(8,1)]; F=[];
for i=1:4
 j=mod(i,4)+1;
 quads=[i j j+8 i+8;i+4 i+12 j+12 j+4;i i+4 j+4 j;i+8 j+8 j+12 i+12];
 for q=quads.', F=[F;q([1 2 3]).';q([1 3 4]).']; end %#ok<AGROW>
end
shape=struct("Faces",F,"Vertices",V);
end
function finish(old)
close all; set(groot,"defaultFigureVisible",old);
end
