function mask = coil_material_mask(pointsGlobal, geometry)
%COIL_MATERIAL_MASK Test points against coil envelopes/material regions.
%
% pointsGlobal is 3xN. Output masks are 1xN logical arrays.
%
% Two geometry types are supported:
%   1. Analytic annular-cylinder coils with coilSpec fields:
%        outerRadius, innerRadius, height
%      These give proper outer/bore/material masks.
%
%   2. Mesh/STL-derived coils with coil(k).shape.Faces/Vertices but no
%      analytic coilSpec dimensions. These use a conservative global
%      axis-aligned bounding-box fallback. In this fallback there is no bore
%      information, so material == outer.

if isempty(pointsGlobal)
    mask = empty_mask(0);
    return
end

if size(pointsGlobal, 1) ~= 3 && size(pointsGlobal, 2) == 3
    pointsGlobal = pointsGlobal.';
end

if size(pointsGlobal, 1) ~= 3
    error("pointsGlobal must be 3xN or Nx3.");
end

nPts = size(pointsGlobal, 2);
mask = empty_mask(nPts);

if isempty(geometry) || ~isstruct(geometry) || ...
   ~isfield(geometry, "coil") || isempty(geometry.coil)
    return
end

for k = 1:numel(geometry.coil)
    coil = geometry.coil(k);

    [hasSpec, spec] = get_coil_spec(geometry, coil);

    if hasSpec && has_annular_cylinder_fields(spec)
        [insideOuter, insideBore] = mask_annular_cylinder(pointsGlobal, coil, spec);
        insideMaterial = insideOuter & ~insideBore;

    elseif isfield(coil, "shape") && has_shape_vertices(coil.shape)
        % STL/mesh-only fallback. This is deliberately conservative: it
        % marks line samples inside the mesh bounding box as coil hits.
        % Without analytic inner/outer radii or a robust point-in-mesh test,
        % the bore cannot be distinguished from material.
        insideOuter = mask_shape_bounding_box(pointsGlobal, coil.shape);
        insideBore = false(1, nPts);
        insideMaterial = insideOuter;

    else
        % No usable analytic or mesh geometry for this coil.
        continue
    end

    mask.outer = mask.outer | insideOuter;
    mask.bore = mask.bore | insideBore;
    mask.material = mask.material | insideMaterial;
end
end

function mask = empty_mask(nPts)
mask = struct();
mask.outer = false(1, nPts);
mask.bore = false(1, nPts);
mask.material = false(1, nPts);
end

function [hasSpec, spec] = get_coil_spec(geometry, coil)
hasSpec = false;
spec = struct();

if ~isfield(geometry, "coilSpec") || ~isstruct(geometry.coilSpec)
    return
end

if ~isfield(coil, "coilType") || isempty(coil.coilType)
    return
end

coilType = char(string(coil.coilType));
if isfield(geometry.coilSpec, coilType)
    spec = geometry.coilSpec.(coilType);
    hasSpec = isstruct(spec);
end
end

function tf = has_annular_cylinder_fields(spec)
tf = isfield(spec, "outerRadius") && ...
     isfield(spec, "innerRadius") && ...
     isfield(spec, "height") && ...
     isnumeric(spec.outerRadius) && isscalar(spec.outerRadius) && ...
     isnumeric(spec.innerRadius) && isscalar(spec.innerRadius) && ...
     isnumeric(spec.height) && isscalar(spec.height) && ...
     isfinite(spec.outerRadius) && isfinite(spec.innerRadius) && ...
     isfinite(spec.height);
end

function [insideOuter, insideBore] = mask_annular_cylinder(pointsGlobal, coil, spec)
if ~isfield(coil, "pose") || isempty(coil.pose)
    error("Analytic coil geometry requires coil.pose.");
end

ptsLocal = coord_global2local(pointsGlobal, coil.pose);
rho = hypot(ptsLocal(1,:), ptsLocal(2,:));
zc  = ptsLocal(3,:);

insideOuter = (rho <= spec.outerRadius) & (abs(zc) <= spec.height/2);
insideBore  = (rho <  spec.innerRadius) & (abs(zc) <= spec.height/2);
end

function tf = has_shape_vertices(shape)
tf = isstruct(shape) && ...
     isfield(shape, "Vertices") && ...
     isnumeric(shape.Vertices) && ...
     size(shape.Vertices, 2) == 3 && ...
     ~isempty(shape.Vertices);
end

function inside = mask_shape_bounding_box(pointsGlobal, shape)
V = double(shape.Vertices);
xyzMin = min(V, [], 1);
xyzMax = max(V, [], 1);

scale = max(1, max(abs([xyzMin, xyzMax]), [], "all"));
tol = 1000*eps(scale);

inside = pointsGlobal(1,:) >= xyzMin(1) - tol & pointsGlobal(1,:) <= xyzMax(1) + tol & ...
         pointsGlobal(2,:) >= xyzMin(2) - tol & pointsGlobal(2,:) <= xyzMax(2) + tol & ...
         pointsGlobal(3,:) >= xyzMin(3) - tol & pointsGlobal(3,:) <= xyzMax(3) + tol;
end
