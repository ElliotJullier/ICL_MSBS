function dataset = load_comsol_precomputed_dataset(fileName,varargin)
%LOAD_COMSOL_PRECOMPUTED_DATASET COMSOL spreadsheet -> B(y,x,z,component,layer).
% Shared coordinates: x,y,z,Bx1,By1,Bz1,Bx2,By2,Bz2,...
% Also accepts repeated six-column blocks with Layout="blocks6".
% Multi-layer input must identify ONE varied parameter, from the header or
% ParameterName/ParameterValues. Layers are cases, never current bases.
p=inputParser;
addParameter(p,"Layout","auto");
addParameter(p,"ParameterName","");
addParameter(p,"ParameterValues",[]);
addParameter(p,"CoordinateScale",[]);
parse(p,varargin{:}); opts=p.Results;
fileName=resolve_msbs_file(fileName,"datasets");
fid=fopen(fileName,"r"); clean=onCleanup(@()fclose(fid));
comments=strings(0); header=""; headerLines=0;
while ~feof(fid)
    line=string(fgetl(fid));
    if startsWith(strtrim(line),"%") || strlength(strtrim(line))==0
        comments(end+1)=line; headerLines=headerLines+1; %#ok<AGROW>
        if ~isempty(regexp(char(line),'^%\s*x\s*,\s*y\s*,\s*z\s*,','once')), header=line; end
    else
        break
    end
end
clear clean
M=readmatrix(fileName,"FileType","text","Delimiter",",","NumHeaderLines",headerLines);
if size(M,2)<6 || any(~isfinite(M(:,1:3)),"all")
    error("MSBS:ExportFormat","Need finite x,y,z coordinates and Bx,By,Bz columns.");
end
layout=lower(string(opts.Layout));
if layout=="auto"
    layout="shared_xyz";
    if size(M,2)>6 && mod(size(M,2),6)==0
        repeated=true;
        for c=7:6:size(M,2)
            repeated=repeated && isequal(M(:,c:c+2),M(:,1:3));
        end
        if repeated, layout="blocks6"; end
    end
end
switch layout
    case "shared_xyz"
        if mod(size(M,2)-3,3)~=0, error("MSBS:ExportFormat","Expected 3 coordinate columns plus field triplets."); end
        nLayers=(size(M,2)-3)/3;
        columns=reshape(4:size(M,2),3,[]).';
    case "blocks6"
        if mod(size(M,2),6)~=0, error("MSBS:ExportFormat","Repeated blocks must have six columns each."); end
        nLayers=size(M,2)/6; columns=zeros(nLayers,3);
        for k=1:nLayers
            start=6*(k-1);
            if ~isequal(M(:,start+(1:3)),M(:,1:3)), error("MSBS:ExportGrid","Block coordinates must match."); end
            columns(k,:)=start+(4:6);
        end
    otherwise
        error("MSBS:ExportFormat","Layout must be auto, shared_xyz or blocks6.");
end
% Reject unexpected field ordering/extra expressions when headers are present.
if strlength(header)>0
    labels=split(extractAfter(header,"%"),",");
    for k=1:nLayers
        for j=1:3
            expected=["Bx","By","Bz"];
            if isempty(regexp(char(labels(columns(k,j))),['(^|\.)',char(expected(j)),'(\s|\(|$)'],'once'))
                error("MSBS:ExportExpressions","Export only Bx,By,Bz, in that order, for each case.");
            end
            unit=regexp(char(labels(columns(k,j))),'\(([^)]+)\)','tokens','once');
            if ~isempty(unit) && string(unit{1})~="T"
                error("MSBS:FieldUnit","Export magnetic flux density in tesla (T).");
            end
        end
    end
end
name=string(opts.ParameterName); values=string(opts.ParameterValues);
if numel(name)~=1, error("MSBS:MultipleParameters","Only one varied parameter is supported."); end
tokens=regexp(char(header),'(?:@|,)\s*([A-Za-z]\w*)\s*=\s*([^,@]+)','tokens');
if ~isempty(tokens)
    names=unique(string(cellfun(@(t)t{1},tokens,'UniformOutput',false)),"stable");
    if numel(names)>1, error("MSBS:MultipleParameters","Export one varied parameter only."); end
    inferred=strip(string(cellfun(@(t)t{2},tokens,'UniformOutput',false)));
    if numel(inferred)==3*nLayers
        if any(reshape(inferred,3,[])~=reshape(inferred(1:3:end),1,[]),"all")
            error("MSBS:ParameterHeader","Field triplet parameter labels do not match.");
        end
        inferred=inferred(1:3:end);
    elseif numel(inferred)~=nLayers
        error("MSBS:ParameterHeader","Cannot map parameter header to layers; supply a clean single-parameter export.");
    end
    if strlength(name)==0, name=names(1); end
    if isempty(opts.ParameterValues), values=inferred; end
    if name~=names(1), error("MSBS:ParameterHeader","ParameterName disagrees with export header."); end
end
if nLayers>1 && (strlength(name)==0 || numel(values)~=nLayers)
    error("MSBS:ParameterMetadata","Identify the single varied ParameterName and ordered ParameterValues (%d layers).",nLayers);
end
if ~isempty(opts.ParameterValues) && numel(values)~=nLayers
    error("MSBS:ParameterMetadata","ParameterValues must identify every layer.");
end
scale=opts.CoordinateScale;
if isempty(scale)
    scale=1;
    unitLine=comments(contains(comments,"Length unit:"));
    if ~isempty(unitLine)
        unit=strip(extractAfter(unitLine(1),"Length unit:"));
        units=["m","mm","cm","um","µm"]; scales=[1 1e-3 1e-2 1e-6 1e-6];
        idx=find(units==unit,1);
        if isempty(idx), error("MSBS:LengthUnit","Unknown length unit; supply CoordinateScale."); end
        scale=scales(idx);
    end
end
validateattributes(scale,{'numeric'},{'scalar','real','finite','positive'});
xyz=M(:,1:3)*scale;
x=unique(xyz(:,1)).'; y=unique(xyz(:,2)).'; z=unique(xyz(:,3)).';
[~,ix]=ismember(xyz(:,1),x); [~,iy]=ismember(xyz(:,2),y); [~,iz]=ismember(xyz(:,3),z);
indices=sub2ind([numel(y),numel(x),numel(z)],iy,ix,iz);
n=numel(x)*numel(y)*numel(z);
if size(M,1)~=n || numel(unique(indices))~=n
    error("MSBS:ExportGrid","Coordinates must form a complete rectilinear grid without duplicate rows.");
end
B=NaN(numel(y),numel(x),numel(z),3,nLayers);
for k=1:nLayers
    for j=1:3
        field=NaN(numel(y),numel(x),numel(z));
        field(indices)=M(:,columns(k,j)); B(:,:,:,j,k)=field;
    end
end
B(~isfinite(B))=NaN; % Keep invalid points in place; never discard grid rows.
geometry=struct("windTunnel",[min(x) max(x);min(y) max(y);min(z) max(z)], ...
    "coilSpec",struct(),"coil",struct([]));
dataset=struct("source","comsol_precomputed","createdOn",string(datetime("now")), ...
    "inputFile",fileName,"datasetFile",fileName,"supportsSuperposition",false, ...
    "supportsCurrentSolve",false,"geometry",geometry,"grid",struct("x",x,"y",y,"z",z),"B",B);
dataset.parameter=struct("name",name,"values",values(:).',"layerCount",nLayers);
dataset.metadata=struct("header",comments,"layout",layout,"coordinateScale",scale, ...
    "fieldUnits","T","coordinateUnits","m");
end
