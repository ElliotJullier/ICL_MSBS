function geometry = load_comsol_geometry(modelName,varargin)
%LOAD_COMSOL_GEOMETRY Read <dataRoot>/STL/<exact model name>/*.stl directly.
% Prefix files coil_, yoke_ or core_; alternatively supply Components:
% struct("file","coil_left.stl","role","coil","name","Left coil","pose",zeros(1,6)).
% InputScale converts STL lengths to metres. Default pose=identity keeps all
% exported assembly coordinates. Angles use existing coord_local2global.
p=inputParser; addParameter(p,"InputScale",1); addParameter(p,"Components",struct([]));
addParameter(p,"Alpha",0.5); parse(p,varargin{:}); opts=p.Results;
validateattributes(opts.InputScale,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(opts.Alpha,{'numeric'},{'scalar','real','finite','>=',0,'<=',1});
modelName=string(modelName); [parent,base,ext]=fileparts(modelName);
% Accept a folder matching either the basename or the complete .mph filename.
candidates=[modelName,modelName+".mph"];
if ext==".mph", candidates=[modelName,fullfile(parent,base)]; end
paths=msbs_paths(); folder="";
for candidate=candidates
    if isfolder(candidate) || isfolder(fullfile(paths.stl,candidate)) || isfolder(fullfile(paths.project,candidate))
        folder=resolve_msbs_file(candidate,"stl"); break
    end
end
if strlength(folder)==0, folder=resolve_msbs_file(modelName,"stl"); end
defs=opts.Components;
if isempty(defs)
    listing=dir(fullfile(folder,"*.stl"));
    defs=repmat(struct("file","","role","","name","","pose",zeros(1,6)),1,numel(listing));
    for k=1:numel(listing)
        defs(k).file=string(listing(k).name);
        [~,label]=fileparts(defs(k).file); defs(k).name=string(label);
        token=regexp(lower(label),'^(coil|yoke|core)(?:[_\-\s\d]|$)','tokens','once');
        if isempty(token), error("MSBS:ComponentRole","Prefix '%s' with coil_, yoke_ or core_, or supply Components.",listing(k).name); end
        defs(k).role=string(token{1});
    end
end
if isempty(defs), error("MSBS:NoSTL","No STL files in %s.",folder); end
components=repmat(struct("name","","role","","shape",struct(),"sourceFile","", ...
    "pose",zeros(1,6),"color",zeros(1,3),"alpha",opts.Alpha,"closed",false),1,numel(defs));
for k=1:numel(defs)
    def=defs(k); file=fullfile(folder,string(def.file));
    TR=stlread(file);
    V=double(TR.Points)*opts.InputScale; F=double(TR.ConnectivityList);
    [V,~,index]=unique(V,"rows"); F=reshape(index(F),size(F));
    areas=vecnorm(cross(V(F(:,2),:)-V(F(:,1),:),V(F(:,3),:)-V(F(:,1),:),2),2,2);
    F=F(areas>0,:);
    if isempty(F), error("MSBS:EmptyMesh","No nondegenerate triangles: %s",file); end
    pose=zeros(1,6); if isfield(def,"pose") && ~isempty(def.pose), pose=double(def.pose(:).'); end
    validateattributes(pose,{'numeric'},{'real','finite','numel',6});
    V=coord_local2global(V.',pose).';
    role=lower(string(def.role));
    switch role
        case "coil", color=[0.20 0.65 0.30];
        case "yoke", color=[0.25 0.25 0.25];
        case "core", color=[0.60 0.30 0.78];
        otherwise, error("MSBS:ComponentRole","Role must be coil, yoke or core.");
    end
    name=string(def.file); if isfield(def,"name") && strlength(string(def.name))>0, name=string(def.name); end
    [cleaned,report]=clean_component_mesh(struct("Faces",F,"Vertices",V));
    F=cleaned.Faces; closed=report.closed;
    if ~closed, warning("MSBS:OpenMesh","'%s' is not closed/manifold; section contours work but line material intervals will be skipped.",name); end
    components(k)=struct("name",name,"role",role,"shape",struct("Faces",F,"Vertices",V), ...
        "sourceFile",string(file),"pose",pose,"color",color,"alpha",opts.Alpha,"closed",closed);
end
geometry=struct("source","comsol_stl","modelName",modelName,"components",components, ...
    "windTunnel",[],"coilSpec",struct(),"coil",struct([]));
end
