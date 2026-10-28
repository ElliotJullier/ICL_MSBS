function dataset = create_virtual_field_dataset(datasets,ops,weights,poses,varargin)
%CREATE_VIRTUAL_FIELD_DATASET Lazy weighted sum of transformed source fields.
% E.g. {A,B},{opA,opB},[0.1,-1] means A/10-B.
% Poses: one [x y z yaw pitch roll] row per source, using the existing
% coord_local2global convention (SI/radians). R is obtained from that helper.
% NaN from any nonzero term propagates. Sources/ops may themselves be virtual.
% ReferenceGrid only defines sampling coordinates, not additional field data.
if nargin<4 || isempty(poses), poses=zeros(numel(datasets),6); end
p=inputParser; addParameter(p,"ReferenceGrid",[]); addParameter(p,"CaseNames",strings(0)); parse(p,varargin{:});
if ~iscell(datasets) || ~iscell(ops) || numel(datasets)~=numel(ops)
    error("MSBS:VirtualInputs","Supply equally sized dataset and operating-point cell arrays.");
end
n=numel(datasets);
validateattributes(weights,{'numeric'},{'real','finite','vector','numel',n});
validateattributes(poses,{'numeric'},{'real','finite','size',[n,6]});
terms=struct("dataset",{},"op",{},"weight",{},"rotation",{},"translation",{});
sources=struct("caseName",{},"geometry",{},"hasUsableGeometry",{});
inputCases=struct("sourceIndex",{},"datasetFile",{},"layerIndex",{},"parameter",{},"synthetic",{});
names=string(p.Results.CaseNames);
if ~isempty(names) && numel(names)~=n, error("MSBS:VirtualInputs","CaseNames must match source count."); end
for k=1:n
    if weights(k)==0, continue; end
    R=coord_local2global(eye(3),[0 0 0 poses(k,4:6)]); t=poses(k,1:3).';
    terms(end+1)=struct("dataset",datasets{k},"op",ops{k},"weight",weights(k),"rotation",R,"translation",t); %#ok<AGROW>
    layer=[]; parameter=[]; synthetic=[];
    if isfield(ops{k},"layerIndex"), layer=ops{k}.layerIndex; end
    if isfield(datasets{k},"parameter"), parameter=datasets{k}.parameter; end
    if isfield(datasets{k},"synthetic"), synthetic=datasets{k}.synthetic; end
    inputCases(end+1)=struct("sourceIndex",k,"datasetFile",string(datasets{k}.datasetFile), ...
        "layerIndex",layer,"parameter",parameter,"synthetic",synthetic); %#ok<AGROW>
    geometry=datasets{k}.geometry;
    if isfield(datasets{k},"synthetic") && isfield(datasets{k}.synthetic,"coilGeometrySources")
        raw=datasets{k}.synthetic.coilGeometrySources;
    else
        name="Source "+k; if ~isempty(names), name=names(k); end
        raw=struct("caseName",name,"geometry",geometry);
    end
    for source=raw
        c=geometry_components(source.geometry);
        for j=1:numel(c), c(j).shape.Vertices=(R*c(j).shape.Vertices.'+t).'; end
        g=struct("components",c,"coil",struct([]),"coilSpec",struct(),"windTunnel",[]);
        sources(end+1)=struct("caseName",string(source.caseName),"geometry",g,"hasUsableGeometry",~isempty(c)); %#ok<AGROW>
    end
end
if isempty(terms), error("MSBS:VirtualInputs","At least one weight must be nonzero."); end
grid=p.Results.ReferenceGrid;
if isempty(grid)
    src=terms(1).dataset.grid; R=terms(1).rotation; t=terms(1).translation;
    % Preserve exact axes under identity; for rotations use their world bounds.
    if norm(R-eye(3),"fro")<1e-12
        grid=struct("x",src.x+t(1),"y",src.y+t(2),"z",src.z+t(3));
    else
        [X,Y,Z]=ndgrid([min(src.x),max(src.x)],[min(src.y),max(src.y)],[min(src.z),max(src.z)]);
        xyz=R*[X(:).';Y(:).';Z(:).']+t;
        counts=[numel(src.x),numel(src.y),numel(src.z)];
        % Rotation can move a planar extent into a formerly singleton axis.
        for j=1:3
            if max(xyz(j,:))-min(xyz(j,:))>1e-12 && counts(j)==1, counts(j)=max(counts); end
        end
        grid=struct("x",linspace(min(xyz(1,:)),max(xyz(1,:)),counts(1)), ...
            "y",linspace(min(xyz(2,:)),max(xyz(2,:)),counts(2)), ...
            "z",linspace(min(xyz(3,:)),max(xyz(3,:)),counts(3)));
        % Collapse dimensions made constant by a right-angle rotation.
        for name=["x","y","z"]
            axisValues=grid.(name);
            if max(axisValues)-min(axisValues)<1e-12, grid.(name)=axisValues(1); end
        end
    end
end
geometry=sources(1).geometry;
dataset=struct("source","virtual_field","createdOn",string(datetime("now")), ...
    "datasetFile","virtual_field","supportsSuperposition",false,"supportsCurrentSolve",false, ...
    "geometry",geometry,"grid",grid,"virtualTerms",terms);
dataset.synthetic=struct("type","weighted_transformed_sum","weights",weights,"poses",poses, ...
    "coilGeometrySources",sources,"inputCases",inputCases);
end
