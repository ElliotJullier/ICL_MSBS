function q = create_vector_volume_query(bounds,varargin)
%CREATE_VECTOR_VOLUME_QUERY Full 3D B arrows in a local box, optionally posed.
% bounds=[xmin xmax;ymin ymax;zmin zmax] in metres. [] uses dataset bounds.
% Pose=[x y z yaw pitch roll] reuses coord_local2global, SI/radians.
opts=vector_query_options("volume",varargin{:});
if ~isempty(bounds)
    validateattributes(bounds,{'numeric'},{'real','finite','size',[3 2]});
    if any(bounds(:,2)<=bounds(:,1)), error("MSBS:VectorBounds","All three volume extents must be positive."); end
end
if isempty(bounds) && any(opts.Pose~=0)
    error("MSBS:VectorBounds","Give explicit local Bounds for a posed volume.");
end
q=struct("type","vector_volume","quantity","vector","bounds",bounds, ...
    "resolution",opts.Resolution,"pose",opts.Pose,"name",string(opts.Name), ...
    "vector",opts,"plot",struct("group",opts.Group,"inOverview",false, ...
    "showCoils",logical(opts.ShowGeometry)));
end
