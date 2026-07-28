function [dataset, opRequest, lineQuery] = create_simple_biotsavart_dataset(innerRadius, outerRadius, turns, varargin)
%CREATE_SIMPLE_BIOTSAVART_DATASET Build a minimal dataset for the simple on-axis model.
%
% This function creates the structure required by evaluate_simple_biotsavart_query.
% It does not evaluate the magnetic field itself. The actual calculation is
% performed later by run_field_queries -> evaluate_simple_biotsavart_query.
%
% Required inputs are in SI units:
%   innerRadius : coil inner radius [m]
%   outerRadius : coil outer radius [m]
%   turns       : number of turns [-]
%
% Name-value options:
%   "Currents"   : fixed current for each coil [A]. Default 1.
%   "Pose"       : one row per coil, [x y z yaw pitch roll]. Default [0 0 0 0 0 0].
%   "Height"     : plotting/material-mask coil height [m]. Default outerRadius-innerRadius.
%   "LineStart"  : default query start point [m]. Default [0 0 -0.1].
%   "LineEnd"    : default query end point [m]. Default [0 0 0.1].
%   "NPoints"    : default line-query point count. Default 200.
%   "Component"  : default field component for line query. Default "z".
%   "Group"      : default plot group. Default 1.
%   "QueryName"  : default query name. Default "Simple on-axis Bz".
%   "SaveFile"   : optional .mat file to save variable dataset. Default "".
%   "NTheta"     : mesh resolution for plotting coil bodies. Default 96.
%
% Outputs:
%   dataset   : minimal simple_biotsavart dataset
%   opRequest : fixed-current operating point request
%   lineQuery : standard line field query suitable for caseDefs(k).queries
%
% Example:
%   [dataset, opRequest, q] = create_simple_biotsavart_dataset(0.045, 0.055, 200, ...
%       "Currents", 1.5, ...
%       "LineStart", [0 0 -0.12], ...
%       "LineEnd",   [0 0  0.12], ...
%       "Group", 2, ...
%       "SaveFile", "simple_on_axis_dataset.mat");
%
%   caseDefs(k).model = "simple_biotsavart";
%   caseDefs(k).datasetFile = "simple_on_axis_dataset.mat";
%   caseDefs(k).opRequest = opRequest;
%   caseDefs(k).queries = {q};

p = inputParser;
addParameter(p, "Currents", 1, @(x)isnumeric(x) && ~isempty(x));
addParameter(p, "Pose", [0 0 0 0 0 0], @(x)isnumeric(x) && size(x,2) == 6);
addParameter(p, "Height", [], @(x)isnumeric(x));
addParameter(p, "LineStart", [0 0 -0.1], @(x)isnumeric(x) && numel(x) == 3);
addParameter(p, "LineEnd", [0 0 0.1], @(x)isnumeric(x) && numel(x) == 3);
addParameter(p, "NPoints", 200, @(x)isnumeric(x) && isscalar(x) && x >= 2);
addParameter(p, "Component", "z", @(x)isstring(x) || ischar(x));
addParameter(p, "Group", 1, @(x)isnumeric(x) && isscalar(x));
addParameter(p, "QueryName", "Simple on-axis Bz", @(x)isstring(x) || ischar(x));
addParameter(p, "SaveFile", "", @(x)isstring(x) || ischar(x));
addParameter(p, "NTheta", 96, @(x)isnumeric(x) && isscalar(x) && x >= 12);
parse(p, varargin{:});
opts = p.Results;

innerRadius = double(innerRadius(:).');
outerRadius = double(outerRadius(:).');
turns = double(turns(:).');

nCoils = max([numel(innerRadius), numel(outerRadius), numel(turns), size(opts.Pose,1), numel(opts.Currents)]);
innerRadius = expand_to_n(innerRadius, nCoils, "innerRadius");
outerRadius = expand_to_n(outerRadius, nCoils, "outerRadius");
turns = expand_to_n(turns, nCoils, "turns");
currents = expand_to_n(double(opts.Currents(:).'), nCoils, "Currents");
pose = expand_pose_to_n(double(opts.Pose), nCoils);

if isempty(opts.Height)
    height = outerRadius - innerRadius;
else
    height = expand_to_n(double(opts.Height(:).'), nCoils, "Height");
end

if any(innerRadius < 0) || any(outerRadius <= 0) || any(turns <= 0) || any(height <= 0)
    error("Radii, turns, and height must be positive, except innerRadius may be zero.");
end

if any(outerRadius <= innerRadius)
    error("Each outerRadius must be larger than the corresponding innerRadius.");
end

geometry = struct();
geometry.coilSpec = struct();
geometry.coil = repmat(struct("coilName", "", "coilType", "", "pose", [], "shape", []), 1, nCoils);

nTheta = round(opts.NTheta);
for k = 1:nCoils
    coilType = sprintf("simpleLoop_%d", k);

    spec = struct();
    spec.outerRadius = outerRadius(k);
    spec.innerRadius = innerRadius(k);
    spec.height = height(k);
    spec.turns = turns(k);
    spec.averageRadius = 0.5*(innerRadius(k) + outerRadius(k));

    geometry.coilSpec.(coilType) = spec;
    geometry.coil(k).coilName = sprintf("Simple loop %d", k);
    geometry.coil(k).coilType = coilType;
    geometry.coil(k).pose = pose(k, :);
    geometry.coil(k).shape = make_annular_cylinder_shape(spec, pose(k, :), nTheta);
end

lineStart = double(opts.LineStart(:).');
lineEnd = double(opts.LineEnd(:).');
maxR = max(outerRadius);
margin = max(1e-6, 1.25*maxR);
allPts = [lineStart; lineEnd; pose(:,1:3)];

geometry.windTunnel = [min(allPts(:,1))-margin, max(allPts(:,1))+margin; ...
                       min(allPts(:,2))-margin, max(allPts(:,2))+margin; ...
                       min(allPts(:,3))-margin, max(allPts(:,3))+margin];

% The simple evaluator does not use dataset.B, but load_field_dataset still
% requires compact grid vectors to exist. These are metadata/domain supports only.
grid = struct();
grid.x = unique([geometry.windTunnel(1,1), 0, geometry.windTunnel(1,2)]);
grid.y = unique([geometry.windTunnel(2,1), 0, geometry.windTunnel(2,2)]);
grid.z = linspace(geometry.windTunnel(3,1), geometry.windTunnel(3,2), max(3, round(opts.NPoints)));

dataset = struct();
dataset.source = "simple_biotsavart";
dataset.createdOn = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
dataset.saveFile = string(opts.SaveFile);
dataset.supportsSuperposition = false;
dataset.supportsCurrentSolve = false;
dataset.geometry = geometry;
dataset.grid = grid;

opRequest = struct();
opRequest.mode = "fixed";
opRequest.currents = currents;

component = lower(string(opts.Component));
if ~any(component == ["x", "y", "z"])
    error("Component must be 'x', 'y', or 'z'.");
end

% Use the existing query builder when available so defaults remain consistent
% with the rest of the project. Otherwise build the minimal equivalent struct.
if exist("create_line_field_query", "file") == 2
    lineQuery = create_line_field_query(lineStart, lineEnd, component, ...
        "NPoints", round(opts.NPoints), ...
        "Group", opts.Group, ...
        "Overview", false, ...
        "ShowCoils", false, ...
        "Name", string(opts.QueryName));
else
    lineQuery = struct();
    lineQuery.type = "line";
    lineQuery.quantity = "field";
    lineQuery.component = component;
    lineQuery.start = lineStart;
    lineQuery.end = lineEnd;
    lineQuery.nPoints = round(opts.NPoints);
    lineQuery.name = string(opts.QueryName);
    lineQuery.plot = struct("group", opts.Group, "inOverview", false, "showCoils", false);
end

saveFile = string(opts.SaveFile);
if strlength(saveFile) > 0
    if ~endsWith(saveFile, ".mat")
        saveFile = saveFile + ".mat";
    end
    dataset.saveFile = saveFile;
    save(saveFile, "dataset");
end
end

function values = expand_to_n(values, n, name)
if isscalar(values)
    values = repmat(values, 1, n);
elseif numel(values) ~= n
    error("%s must be scalar or have one value per coil.", name);
end
end

function pose = expand_pose_to_n(pose, n)
if size(pose,1) == 1
    pose = repmat(pose, n, 1);
elseif size(pose,1) ~= n
    error("Pose must have one row or one row per coil.");
end
end

function shape = make_annular_cylinder_shape(spec, pose, nTheta)
theta = linspace(0, 2*pi, nTheta+1);
theta(end) = [];

ro = spec.outerRadius;
ri = spec.innerRadius;
hh = spec.height/2;

outerTop = [ro*cos(theta); ro*sin(theta);  hh*ones(1,nTheta)];
outerBot = [ro*cos(theta); ro*sin(theta); -hh*ones(1,nTheta)];
innerTop = [ri*cos(theta); ri*sin(theta);  hh*ones(1,nTheta)];
innerBot = [ri*cos(theta); ri*sin(theta); -hh*ones(1,nTheta)];

Vlocal = [outerTop, outerBot, innerTop, innerBot];
Vglobal = coord_local2global(Vlocal, pose).';

faces = zeros(4*nTheta, 4);
row = 0;
for i = 1:nTheta
    j = i + 1;
    if j > nTheta
        j = 1;
    end

    ot_i = i;
    ot_j = j;
    ob_i = nTheta + i;
    ob_j = nTheta + j;
    it_i = 2*nTheta + i;
    it_j = 2*nTheta + j;
    ib_i = 3*nTheta + i;
    ib_j = 3*nTheta + j;

    % Outer cylindrical wall.
    row = row + 1;
    faces(row,:) = [ot_i, ot_j, ob_j, ob_i];

    % Inner cylindrical wall.
    row = row + 1;
    faces(row,:) = [it_j, it_i, ib_i, ib_j];

    % Top annular face.
    row = row + 1;
    faces(row,:) = [ot_i, ot_j, it_j, it_i];

    % Bottom annular face.
    row = row + 1;
    faces(row,:) = [ob_j, ob_i, ib_i, ib_j];
end

shape = struct();
shape.Faces = faces;
shape.Vertices = Vglobal;
end
