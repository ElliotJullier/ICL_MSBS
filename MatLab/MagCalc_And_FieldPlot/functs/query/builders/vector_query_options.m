function opts = vector_query_options(domain,varargin)
%VECTOR_QUERY_OPTIONS Shared candidate sampling and vector display contract.
domain=string(domain); plane=domain=="plane";
p=inputParser;
if plane, resolution=[41 41]; budget=300; mode="2d"; else, resolution=[13 13 13]; budget=400; mode="3d"; end
addParameter(p,"Mode",mode); addParameter(p,"Resolution",resolution);
addParameter(p,"MaxArrows",budget); addParameter(p,"Seeding","uniform");
addParameter(p,"UniformFraction",.7); addParameter(p,"LengthMode","uniform");
addParameter(p,"ColorBy","magnitude"); addParameter(p,"ColorMagnitude","display");
addParameter(p,"ColorScale","linear"); addParameter(p,"ColorLimits",[]);
addParameter(p,"MinMagnitude",0); addParameter(p,"ArrowFraction",.65);
addParameter(p,"ExcludeMaterials",true); addParameter(p,"LineWidth",1);
addParameter(p,"Group",[]); addParameter(p,"Name",""); addParameter(p,"ShowGeometry",true);
addParameter(p,"UpVector",[]); addParameter(p,"ULimits",[]); addParameter(p,"VLimits",[]);
addParameter(p,"Pose",zeros(1,6));
parse(p,varargin{:}); opts=p.Results;
opts.Mode=validatestring(opts.Mode,{'2d','3d'});
opts.Seeding=validatestring(opts.Seeding,{'uniform','magnitude','variation'});
opts.LengthMode=validatestring(opts.LengthMode,{'uniform','linear','sqrt'});
opts.ColorBy=validatestring(opts.ColorBy,{'magnitude','none'});
opts.ColorMagnitude=validatestring(opts.ColorMagnitude,{'display','total'});
opts.ColorScale=validatestring(opts.ColorScale,{'linear','log'});
validateattributes(opts.Resolution,{'numeric'},{'real','finite','integer','>=',2});
if isscalar(opts.Resolution), opts.Resolution=repmat(opts.Resolution,1,2+~plane); end
if numel(opts.Resolution)~=2+~plane, error("MSBS:VectorResolution","Plane resolution has two counts; volume has three."); end
opts.Resolution=opts.Resolution(:).';
if prod(opts.Resolution)>50000, error("MSBS:VectorBudget","At most 50,000 candidate points per vector query."); end
validateattributes(opts.MaxArrows,{'numeric'},{'scalar','integer','>=',1,'<=',2000});
validateattributes(opts.UniformFraction,{'numeric'},{'scalar','real','finite','>=',.5,'<=',1});
validateattributes(opts.MinMagnitude,{'numeric'},{'scalar','real','finite','>=',0});
validateattributes(opts.ArrowFraction,{'numeric'},{'scalar','real','finite','>',0,'<=',.8});
validateattributes(opts.LineWidth,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(opts.Pose,{'numeric'},{'real','finite','numel',6});
opts.Pose=opts.Pose(:).';
validateattributes(opts.ExcludeMaterials,{'logical','numeric'},{'scalar'});
validateattributes(opts.ShowGeometry,{'logical','numeric'},{'scalar'});
for name=["ULimits","VLimits","ColorLimits"]
    value=opts.(name);
    if ~isempty(value)
        validateattributes(value,{'numeric'},{'real','finite','numel',2});
        if value(2)<=value(1), error("MSBS:VectorLimits","Limits must increase."); end
        opts.(name)=value(:).';
    end
end
if ~plane && string(opts.Mode)~="3d", error("MSBS:VectorMode","A volume requires Mode='3d'."); end
if plane && any(opts.Pose~=0), error("MSBS:VectorPose","Define a plane by point/normal; Pose applies to volume boxes."); end
end
