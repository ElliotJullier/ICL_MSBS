function q = create_vector_plane_query(pointOrPlane,normalOrOffset,varargin)
%CREATE_VECTOR_PLANE_QUERY Projected 2D or full 3D B arrows sampled on a plane.
% create_vector_plane_query("xz",0,"ULimits",[-.5 .5],"VLimits",[-1 1])
% create_vector_plane_query([0 0 0],[1 1 0],"Mode","3d","UpVector","z")
opts=vector_query_options("plane",varargin{:});
if ischar(pointOrPlane) || isstring(pointOrPlane)
    plane=validatestring(pointOrPlane,{'xy','xz','yz'});
    validateattributes(normalOrOffset,{'numeric'},{'scalar','real','finite'});
    switch plane
        case 'xy', n=[0 0 1]; up=[0 1 0];
        case 'xz', n=[0 -1 0]; up=[0 0 1];
        case 'yz', n=[1 0 0]; up=[0 0 1];
    end
    % Offset is the world coordinate (xz has normal -y for intuitive u=x,v=z).
    point=zeros(1,3); point(find(n~=0,1))=normalOrOffset;
    if isempty(opts.UpVector), opts.UpVector=up; end
else
    validateattributes(pointOrPlane,{'numeric'},{'real','finite','numel',3});
    point=pointOrPlane(:).'; n=normalise_direction(normalOrOffset);
end
q=struct("type","vector_plane","quantity","vector","point",point,"normal",n, ...
    "upVector",opts.UpVector,"uLimits",opts.ULimits,"vLimits",opts.VLimits, ...
    "resolution",opts.Resolution,"name",string(opts.Name),"vector",opts, ...
    "plot",struct("group",opts.Group,"inOverview",false,"showCoils",logical(opts.ShowGeometry)));
end
