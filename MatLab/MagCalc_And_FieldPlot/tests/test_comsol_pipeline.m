function test_comsol_pipeline()
%TEST_COMSOL_PIPELINE Numerical, geometry, import and plotting regressions.
project=fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(project,"functs")));
temp=tempname(fullfile(project,"tests")); mkdir(temp);
cleanup=onCleanup(@()cleanup_test(temp)); %#ok<NASGU>
oldVisible=get(groot,"defaultFigureVisible");
set(groot,"defaultFigureVisible","off");
visibility=onCleanup(@()set(groot,"defaultFigureVisible",oldVisible)); %#ok<NASGU>

% Plane interpolation must never extrude data or snap requested offsets.
g=struct("x",linspace(-1,1,9),"y",0,"z",linspace(-1,1,9));
[X,Y,Z]=meshgrid(g.x,g.y,g.z); scalar=2*X+3*Z;
F=build_scalar_grid_interpolant(g,scalar);
assert(abs(F(0,0.13,0.21)-0.89)<1e-10);
assert(isnan(F(0.01,0.13,0.21)));
q=create_plane_field_query("xz",0.02,"z");
r=sample_fundamental_plane_from_grid(g,scalar,q,1);
assert(all(isnan(r.data),"all") && all(r.Y==0.02,"all"));
q=create_custom_plane_field_query([0 0 0],"y","z","Resolution",[17 13],"UpVector","z");
r=sample_custom_plane_from_grid(g,scalar,q,1);
assert(max(abs(r.data-(2*r.X+3*r.Z)),[],"all")<1e-9);
q=create_line_field_query([-1 0 -1],[1 0 1],"z","NPoints",51);
r=sample_line_from_grid(g,scalar,q,1); assert(max(abs(r.data-(2*r.X+3*r.Z)))<1e-9);
[d,~]=compute_directional_gradient_grid(g,scalar,"Bz",[2 0 3]);
assert(max(abs(d(:)-sqrt(13)))<1e-10);
% A real volume, a non-grid-aligned cut and coordinate-weighted gradients.
volumeGrid=struct("x",linspace(-1,1,7),"y",linspace(-1,1,6),"z",linspace(-1,1,8));
[vx,vy,vz]=meshgrid(volumeGrid.x,volumeGrid.y,volumeGrid.z);
volumeScalar=vx+2*vy+3*vz;
[vd,~]=compute_directional_gradient_grid(volumeGrid,volumeScalar,"Ba",[1 2 3]);
assert(max(abs(vd(:)-sqrt(14)))<1e-10);
cut=create_plane_field_query("xy",0.17,"z");
vr=sample_fundamental_plane_from_grid(volumeGrid,volumeScalar,cut,1);
assert(max(abs(vr.data-(vr.X+2*vr.Y+3*.17)),[],"all")<1e-9);
ng=struct("x",[-1 -.4 0 .2 .7 1],"y",0,"z",0);
[nd,~]=compute_directional_gradient_grid(ng,reshape(ng.x.^2,1,[],1),"Ba","x");
assert(max(abs(nd(2:end-1)-2*ng.x(2:end-1)))<1e-10);
lastwarn(""); warning("off","MSBS:ShallowGradient");
missing=compute_directional_gradient_grid(g,scalar,"Bz","y");
assert(all(isnan(missing),"all"));
warning("on","MSBS:ShallowGradient");
thin=struct("x",[-1 1],"y",0,"z",[-1 1]);
[tx,~,tz]=meshgrid(thin.x,thin.y,thin.z);
lastwarn(""); compute_directional_gradient_grid(thin,tx+tz,"Bz","x");
[~,id]=lastwarn; assert(string(id)=="MSBS:ShallowGradient");
[direction,~]=normalise_direction([0 0 10]); assert(isequal(direction,[0 0 1]));

% Two field layers, explicit one-parameter identities, shared coordinates.
matrix=[X(:),Y(:),Z(:),X(:),zeros(numel(X),1),Z(:),2*X(:),zeros(numel(X),1),2*Z(:)];
file=fullfile(temp,"layers.txt"); writematrix(matrix,file);
dataset=load_comsol_precomputed_dataset(file,"ParameterName","I","ParameterValues",[1 2]);
assert(size(dataset.B,5)==2);
must_error(@()validate_and_solve_operating_point(dataset,struct("mode","precomputed"),"comsol_precomputed"),"MSBS:LayerSelection");
op=validate_and_solve_operating_point(dataset,struct("mode","precomputed","layerIndex",2),"comsol_precomputed");
projected=get_total_component_field_grid(dataset,op,[1 0 1]);
assert(max(abs(projected(:)-sqrt(2)*(X(:)+Z(:))))<1e-10);
must_error(@()load_comsol_precomputed_dataset(file),"MSBS:ParameterMetadata");
must_error(@()load_comsol_precomputed_dataset(file,"ParameterName",["I","gap"],"ParameterValues",[1 2]),"MSBS:MultipleParameters");
% Repeated coordinate blocks, NaN retained, unit conversion from header.
blocks=[matrix(:,1:6),matrix(:,[1:3,7:9])]; blocks(1,4)=NaN;
file2=fullfile(temp,"blocks.txt"); writematrix(blocks,file2);
ds2=load_comsol_precomputed_dataset(file2,"Layout","blocks6","ParameterName","I","ParameterValues",[1 2]);
assert(size(ds2.B,5)==2 && isnan(ds2.B(1,1,1,1,1)));
headerFile=fullfile(temp,"header.txt"); fid=fopen(headerFile,"w");
fprintf(fid,"%% Length unit: mm\n%% x,y,z,mf.Bx (T) @ I=1,mf.By (T) @ I=1,mf.Bz (T) @ I=1,mf.Bx (T) @ I=2,mf.By (T) @ I=2,mf.Bz (T) @ I=2\n"); fclose(fid);
writematrix(matrix,headerFile,"WriteMode","append");
header=load_comsol_precomputed_dataset(headerFile);
assert(header.parameter.name=="I" && isequal(header.parameter.values,["1","2"]));
assert(max(header.grid.x)==1e-3);

% Watertight hollow rectangular solid: sections and intervals must preserve bore.
outer=cube_mesh([-1 -1 -1],[1 1 1]); inner=cube_mesh([-.5 -.5 -2],[.5 .5 2]);
% Use a closed square tube (four walls), not intersecting outer/inner shells.
shape=tube_mesh();
spans=mesh_line_intervals(shape,[-2 0 0],[2 0 0]);
assert(isequal(size(spans),[2 2]) && max(abs(spans-[1 1.5;2.5 3]),[],"all")<1e-8);
assert(isempty(mesh_line_intervals(shape,[0 0 -2],[0 0 2])));
assert(isempty(mesh_line_intervals(outer,[-2 1 0],[2 1 0]))); % tangent surface
spans=mesh_line_intervals(outer,[0 0 0],[2 0 0]); assert(max(abs(spans-[0 1]))<1e-8);
loops=mesh_plane_sections(shape,[0 0 0],"z"); assert(numel(loops)==2);
for k=1:numel(loops), assert(norm(loops{k}(1,:)-loops{k}(end,:))<1e-8); end
face=mesh_plane_sections(outer,[0 0 1],"z"); assert(numel(face)==1);
assert(isempty(mesh_plane_sections(inner,[5 0 0],"x")));
stlFolder=fullfile(temp,"TestModel"); mkdir(stlFolder);
stlwrite(triangulation(shape.Faces,shape.Vertices),fullfile(stlFolder,"coil_tube.stl"));
stlwrite(triangulation(outer.Faces,outer.Vertices),fullfile(stlFolder,"yoke_block.stl"),"text");
stlwrite(triangulation(inner.Faces,inner.Vertices),fullfile(stlFolder,"core_block.stl"));
geometry=load_comsol_geometry(stlFolder,"InputScale",1);
geometryByMphName=load_comsol_geometry(string(stlFolder)+".mph","InputScale",1);
assert(isequaln(geometry.components,geometryByMphName.components));
assert(numel(geometry.components)==3 && all([geometry.components.closed]));
assert(all([geometry.components.alpha]==.5));
dataset.geometry=geometry;

% Virtual arithmetic and rotation transform both coordinates and vectors.
op1=validate_and_solve_operating_point(dataset,struct("mode","precomputed","layerIndex",1),"comsol_precomputed");
[difference,report]=create_synthetic_difference_dataset(dataset,op1,dataset,op,"Verbose",false);
assert(report.measureDimension==2);
assert(max(abs(difference.B(:,:,:,1)+X),[],"all")<1e-10);
virtual=create_virtual_field_dataset({dataset,dataset},{op1,op},[0.1,-1],zeros(2,6));
values=sample_dataset_points(virtual,struct(),[.2;0;.3],"z",[]);
assert(abs(values+.57)<1e-9);
rotated=create_virtual_field_dataset({dataset},{op1},1,[0 0 0 pi/2 0 0]);
R=coord_local2global(eye(3),[0 0 0 pi/2 0 0]);
point=R*[.2;0;.3]; v=sample_dataset_points(rotated,struct(),point,R*[1;0;0],[]);
assert(abs(v-.2)<1e-9);
v=sample_dataset_points(rotated,struct(),point,R*[1;0;0],R*[1;0;0]);
assert(abs(v-1)<1e-9);
% General Euler composition, not only a right-angle rotation.
pose=[.12 -.23 .34 .2 -.3 .4]; R=coord_local2global(eye(3),[0 0 0 pose(4:6)]);
transformed=create_virtual_field_dataset({dataset},{op1},1,pose);
world=R*[.2;0;.3]+pose(1:3).';
v=sample_dataset_points(transformed,struct(),world,R*[0;0;1],R*[0;0;1]);
assert(abs(v-1)<1e-9);
[vr,~]=run_field_queries(virtual,struct(),{create_line_field_query([-.5 0 0],[.5 0 0],"x")},"virtual_field");
assert(max(abs(vr{1}.data+1.9*vr{1}.X))<1e-8);

% End-to-end Q packing and graphics (no metadata writes outside test folder).
queries={create_plane_field_query("xz",0,[1 0 1],"ShowGeometry",true,"Overview",true), ...
    create_line_field_query([-1 0 0],[1 0 0],"x","Group",2,"ShowGeometry",true), ...
    create_line_gradient_query([-1 0 0],[1 0 0],"x","Group",2,"GradientDirection","x","ShowGeometry",true)};
[results,queries]=run_field_queries(dataset,op1,queries,"comsol_precomputed");
Q=pack_query_case(dataset,op1,queries,results,struct("caseName","Regression","model","comsol_precomputed","datasetFile","fixture"));
assert(Q.meta.layerIndex==1);
style=plotStyle(); style.writeMetadata=false; style.geometryAlpha=.5;
plot_field({Q},style);
% A coil-only perpendicular section must have area 3, not area 4 (the bore).
coilOnly=geometry; coilOnly.components=geometry.components(1);
ax=axes("Parent",figure); hold(ax,"on");
handles=plot_geometry_sections(ax,coilOnly,create_plane_field_query("xy",0,"z"));
tri=get(handles(1),"Faces"); vertices=get(handles(1),"Vertices");
area=sum(vecnorm(cross(vertices(tri(:,2),:)-vertices(tri(:,1),:), ...
    vertices(tri(:,3),:)-vertices(tri(:,1),:),2),2,2))/2;
assert(abs(area-3)<1e-8); close(ancestor(ax,"figure"));
assert(numel(findall(groot,"Type","figure"))>=3);
figs=findall(groot,"Type","figure");
for k=1:numel(figs), exportgraphics(figs(k),fullfile(temp,"plot_"+k+".png")); end
% Make reviewed renderings available without leaving numeric fixtures around.
previewDir=fullfile(project,"tests","preview");
if ~isfolder(previewDir), mkdir(previewDir); end
copyfile(fullfile(temp,"plot_*.png"),previewDir);
close all
fprintf("PASS: COMSOL import, planes, directions, gradients, virtual fields, STL sections, line intervals and plots.\n");
end

function shape=cube_mesh(lo,hi)
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
 quads=[i j j+8 i+8;i+4 i+12 j+12 j+4; i i+4 j+4 j; i+8 j+8 j+12 i+12];
 for q=quads.', F=[F;q([1 2 3]).';q([1 3 4]).']; end %#ok<AGROW>
end
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
function cleanup_test(folder)
if isfolder(folder), rmdir(folder,"s"); end
close all
end
