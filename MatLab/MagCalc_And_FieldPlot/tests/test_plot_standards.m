function test_plot_standards()
%TEST_PLOT_STANDARDS Open outlines, category legends, fonts and signed axes.
project=fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(project,"functs")));
old=get(groot,"defaultFigureVisible"); set(groot,"defaultFigureVisible","off");
cleanup=onCleanup(@()finish(old)); %#ok<NASGU>
style=plotStyle(); style.writeMetadata=false;
% Disconnected closed solids must retain NaN-separated boundaries.
box=cube([-4 -1 -1],[-2 1 1]); other=cube([2 -1 -1],[4 1 1]);
shape=struct("Vertices",[box.Vertices;other.Vertices],"Faces",[box.Faces;other.Faces+8]);
template=struct("name","Bottom coil","role","coil","shape",shape,"color",[0 1 0],"alpha",.5,"closed",true);
cs=template; cs(2)=template; cs(2).name="Top coil";
cs(2).shape.Vertices(:,2)=cs(2).shape.Vertices(:,2)+3;
cs(3)=template; cs(3).name="Yoke"; cs(3).role="yoke"; cs(3).closed=false;
cs(3).shape=struct("Vertices",[-1 -1 -1;1 -1 1;0 1 1],"Faces",[1 2 3]);
geometry=struct("components",cs);
fig=figure; ax=axes("Parent",fig); hold(ax,"on");
warning("off","MSBS:OpenSection");
plot_geometry_sections(ax,geometry,create_plane_field_query("xy",0,"z"));
warning("on","MSBS:OpenSection");
outlines=findall(ax,"Tag","MSBSGeometryOutline");
assert(~isempty(outlines));
assert(all(arrayfun(@(h)string(h.Type)=="line",outlines)));
for h=outlines.'
    assert(string(h.HandleVisibility)=="off");
    x=h.XData; d=abs(diff(x)); assert(all(d(isfinite(d))<=2+1e-8));
end
proxies=findobj(ax,"-regexp","Tag","^MSBSGeometryLegend_");
assert(numel(proxies)==2);
assert(isequal(sort(string({proxies.DisplayName})),["Coils","Yokes"]));
for h=proxies.', assert(string(h.Type)=="patch" && string(h.EdgeColor)=="none"); end
yoke=findobj(ax,"Tag","MSBSGeometryLegend_yoke"); assert(isequal(yoke.FaceColor,[.25 .25 .25]));
xlabel(ax,"$x$ [m]","Interpreter","latex"); ylabel(ax,"$y$ [m]","Interpreter","latex");
bar=set_clrbar(ax,[-1 1],"dBz/dz");
baseAxes=ax.FontSize; baseLabel=ax.XLabel.FontSize;
baseBar=bar.FontSize; baseBarLabel=bar.Label.FontSize;
apply_scientific_plot_style(ax,style);
assert(abs(ax.FontSize-1.5*baseAxes)<1e-10);
assert(abs(ax.XLabel.FontSize-1.5*baseLabel)<1e-10);
assert(abs(bar.FontSize-1.5*baseBar)<1e-10);
assert(abs(bar.Label.FontSize-1.5*baseBarLabel)<1e-10);
assert(contains(string(bar.Label.String),string(char(92))+"mathrm{d}"));
assert(string(ax.Layer)=="top" && string(ax.TickDir)=="out");
assert(strlength(string(ax.Title.String))==0 && string(fig.NumberTitle)=="off");
before=[ax.FontSize ax.XLabel.FontSize bar.FontSize bar.Label.FontSize];
apply_scientific_plot_style(ax,style);
assert(max(abs(before-[ax.FontSize ax.XLabel.FontSize bar.FontSize bar.Label.FontSize]))<1e-10);
drawnow; close(fig);

% Physical coordinate and shading both use z=-1.5..+1.5, not distance 0..3.
record=struct("X",zeros(7,1),"Y",zeros(7,1),"Z",linspace(-1.5,1.5,7).', ...
    "s",linspace(0,3,7).',"data",linspace(-1.5,1.5,7).',"dataName","Bz", ...
    "caseName","Signed axis","queryName","Centreline","geometry",struct("coil",struct([])), ...
    "query",create_line_field_query([0 0 -1.5],[0 0 1.5],"z"));
[x,label,mode]=line_plot_coordinates({record},"auto");
assert(mode=="z" && label=="$z$ [m]" && isequal(x{1},record.Z));
plot_line_group(struct("key","signed","requests",{{record}}),style);
ax=gca; assert(string(ax.XLabel.String)=="$z$ [m]");
assert(max(abs(ax.XLim-[-1.5 1.5]))<1e-10);
record.plotCoordinates=record.Z; cs=template; cs.shape=cube([-.5 -.5 -.5],[.5 .5 .5]);
add_coil_presence_to_line_plot(ax,record,struct("components",cs),[],.5);
fill=findall(ax,"Tag","MSBSMaterialBand"); assert(numel(fill)==1);
assert(max(abs(sort(fill.Value(:))-[-.5;.5]))<1e-10);
assert(string(fill.Layer)=="bottom");
ylim(ax,[-10 10]); assert(max(abs(sort(fill.Value(:))-[-.5;.5]))<1e-10);
close all
fprintf("PASS: open contours, legend categories, upright differentials, 1.5x fonts and physical line/shading axes.\n");
end
function shape=cube(lo,hi)
V=[lo;hi(1) lo(2) lo(3);hi(1) hi(2) lo(3);lo(1) hi(2) lo(3); ...
    lo(1) lo(2) hi(3);hi(1) lo(2) hi(3);hi;lo(1) hi(2) hi(3)];
F=[1 3 2;1 4 3;5 6 7;5 7 8;1 2 6;1 6 5;2 3 7;2 7 6;3 4 8;3 8 7;4 1 5;4 5 8];
shape=struct("Faces",F,"Vertices",V);
end
function finish(old)
close all; set(groot,"defaultFigureVisible",old);
warning("on","MSBS:OpenSection");
end
