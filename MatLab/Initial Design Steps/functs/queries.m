function q = queries()
% QUERIES  Template and documentation for entries in the queries cell array.
%
%   q = queries() returns an example query struct.
%
%   General fields:
%       q.type
%           Required.
%           Allowed values:
%               "fundamental_plane"
%               "custom_plane"
%               "line"
%
%       q.component
%           Required for all query types.
%           Allowed values:
%               "x", "y", "z"
%
%       q.group
%           Optional.
%           Numeric or string group tag.
%           Requests with the same group are plotted together by type.
%           For grouped planes, all requests must share the same component.
%
%       q.inOverview
%           Optional logical.
%           For planes:
%               true  -> include in 3D overview
%               false -> omit from overview
%           For lines:
%               all lines are shown in overview whenever an overview exists,
%               but keeping this field is still allowed for consistency.
%
%       q.legendName
%           Optional.
%           Used for line legends in grouped line plots.
%
%   Type-specific fields:
%
%   1) Fundamental plane:
%       q.type = "fundamental_plane"
%       q.plane   Required: "xy", "xz", or "yz"
%       q.value   Required: plane coordinate value
%
%       Example:
%           q = struct("type","fundamental_plane", ...
%                      "plane","xz", ...
%                      "value",0, ...
%                      "component","z", ...
%                      "group",1, ...
%                      "inOverview",true);
%
%   2) Custom plane:
%       q.type = "custom_plane"
%       q.point       Required: [x y z]
%       q.normal      Required: [nx ny nz]
%       q.resolution  Optional: scalar or [Nu Nv]
%
%       Example:
%           q = struct("type","custom_plane", ...
%                      "point",[0 0 0], ...
%                      "normal",[0.2 1 1], ...
%                      "component","z", ...
%                      "resolution",[150 150], ...
%                      "group",2, ...
%                      "inOverview",true);
%
%   3) Line:
%       q.type = "line"
%       q.start    Required: [x y z]
%       q.end      Required: [x y z]
%       q.nPoints  Optional: number of sample points
%
%       Example:
%           q = struct("type","line", ...
%                      "start",[0.5 0 0], ...
%                      "end",[-0.5 0 0], ...
%                      "component","x", ...
%                      "nPoints",200, ...
%                      "group",3, ...
%                      "legendName","Full Biot-Savart");
%
%   Typical usage:
%       q1 = struct("type","fundamental_plane","plane","xz","value",0,"component","z");
%       q2 = struct("type","line","start",[0.5 0 0],"end",[-0.5 0 0],"component","x");
%       queries = {q1, q2};

q = struct();
q.type = "line";
q.start = [0 0 0];
q.end = [1 0 0];
q.component = "x";
q.nPoints = 200;
q.group = [];
q.inOverview = false;
q.legendName = "";
end