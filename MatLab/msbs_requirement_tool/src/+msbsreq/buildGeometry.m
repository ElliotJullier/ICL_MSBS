function geometry = buildGeometry(cfg, tunnel)
%BUILDGEOMETRY Build a primitive geometry and nominal projected blockage.
arguments
    cfg (1,1) struct
    tunnel (1,1) struct
end

R_TB = cfg.frames.R_TB_nominal;
% Wind and tunnel axes are identical in v0.3.0; +x_T is downstream.
flowNormalB = R_TB.' * [1;0;0];
flowNormalB = flowNormalB / norm(flowNormalB);

type = cfg.geometry.type;
sizing = cfg.geometry.sizing;
if type == "custom"
    localValidateCustomGeometry(sizing.custom, cfg);
end

if sizing.mode == "blockage"
    [unitShape, unitArea] = localUnitShape(type, sizing, flowNormalB);
    targetArea = sizing.blockage_ratio * tunnel.area_m2;
    scale = sqrt(targetArea / unitArea);
    shape = localScaleShape(unitShape, scale);
else
    shape = localAbsoluteShape(type, sizing);
end

[volume, projectedArea, characteristicLength, outerDimensions] = ...
    localGeometryQuantities(type, shape, flowNormalB, sizing);

if projectedArea > tunnel.area_m2 * (1 + 1e-12)
    error('msbsreq:GeometryExceedsTunnel', ...
        'Nominal projected area exceeds the tunnel cross-sectional area.');
end

geometry = struct();
geometry.type = type;
geometry.shape = shape;
geometry.outer_dimensions_B_m = outerDimensions(:);
geometry.volume_m3 = volume;
geometry.projected_area_nominal_m2 = projectedArea;
geometry.nominal_blockage_ratio = projectedArea / tunnel.area_m2;
geometry.characteristic_length_m = characteristicLength;
geometry.aero_reference_point_B_m = cfg.geometry.aero_reference_point_B_m(:);
geometry.inscribed_cuboid = msbsreq.fitInscribedCuboid(type, shape, sizing);
geometry.reference_area_m2 = localReferenceArea(cfg, projectedArea, type, shape);
geometry.reference_length_m = localReferenceLength(cfg, characteristicLength, type, shape);
geometry.reference_span_m = localReferenceSpan(cfg, type, shape, outerDimensions);
geometry.plot_data = localPlotData(type, shape, cfg);
geometry.metadata = struct( ...
    'sizing_mode', sizing.mode, ...
    'flow_normal_B', flowNormalB, ...
    'blockage_orientation_note', ...
    "Nominal orthographic projection at the configured nominal body attitude relative to +x_T flow.");
end

function [shape, area] = localUnitShape(type, sizing, n)
switch type
    case "sphere"
        shape = struct('diameter_m', 1);
    case "cuboid"
        dims = double(sizing.nominal_dimensions_m(:));
        localPositiveVector(dims, 3, 'nominal_dimensions_m');
        shape = struct('dimensions_m', dims);
    case "ellipsoid"
        dims = double(sizing.nominal_dimensions_m(:));
        localPositiveVector(dims, 3, 'nominal_dimensions_m');
        shape = struct('diameters_m', dims);
    case "cylinder"
        shape = struct('diameter_m', 1, ...
            'length_m', double(sizing.cylinder_length_to_diameter), ...
            'axis', lower(string(sizing.cylinder_axis)));
    case "flat_plate"
        dims = double(sizing.plate_normalised_dimensions(:));
        localPositiveVector(dims, 3, 'plate_normalised_dimensions');
        shape = struct('dimensions_m', dims);
    case "custom"
        custom = sizing.custom;
        required = ["outer_dimensions_m","projected_area_m2", ...
            "reference_area_m2","reference_length_m", ...
            "inscribed_cuboid_dimensions_m"];
        for name = required
            if ~isfield(custom, name)
                error('msbsreq:InvalidCustomGeometry', ...
                    'Custom blockage geometry requires field %s.', name);
            end
        end
        shape = custom;
    otherwise
        error('msbsreq:UnsupportedGeometry', 'Unsupported geometry type.');
end
[~, area] = localGeometryQuantities(type, shape, n, sizing);
end

function shape = localScaleShape(shape, scale)
fields = fieldnames(shape);
for i = 1:numel(fields)
    name = fields{i};
    value = shape.(name);
    if isnumeric(value)
        if strcmp(name,'solid_unit_density_inertia_B_m5')
            shape.(name) = value * scale^5;
        elseif contains(name, 'area')
            shape.(name) = value * scale^2;
        elseif contains(name, 'volume')
            shape.(name) = value * scale^3;
        elseif contains(name, 'dimension') || contains(name, 'diameter') || ...
                contains(name, 'length') || contains(name, 'span') || contains(name, 'radius') || ...
                contains(name, 'centre') || contains(name, 'vertices') || strcmp(name,'solid_centroid_B_m')
            shape.(name) = value * scale;
        end
    end
end
end

function shape = localAbsoluteShape(type, sizing)
switch type
    case "sphere"
        if ~isempty(sizing.diameter_m)
            diameter = sizing.diameter_m;
        elseif ~isempty(sizing.radius_m)
            diameter = 2*sizing.radius_m;
        else
            error('msbsreq:MissingGeometryDimension', ...
                'Absolute sphere sizing requires diameter_m or radius_m.');
        end
        shape = struct('diameter_m', diameter);
    case "cuboid"
        dims = double(sizing.nominal_dimensions_m(:));
        localPositiveVector(dims,3,'nominal_dimensions_m');
        shape = struct('dimensions_m', dims);
    case "ellipsoid"
        dims = double(sizing.ellipsoid_diameters_m(:));
        localPositiveVector(dims,3,'ellipsoid_diameters_m');
        shape = struct('diameters_m', dims);
    case "cylinder"
        shape = struct('diameter_m', sizing.cylinder_diameter_m, ...
            'length_m', sizing.cylinder_length_m, ...
            'axis', lower(string(sizing.cylinder_axis)));
    case "flat_plate"
        dims = double(sizing.plate_dimensions_m(:));
        localPositiveVector(dims,3,'plate_dimensions_m');
        shape = struct('dimensions_m', dims);
    case "custom"
        shape = sizing.custom;
end
end

function [volume, area, characteristic, outer] = localGeometryQuantities(type, shape, n, sizing)
switch type
    case "sphere"
        D = shape.diameter_m;
        localPositiveScalar(D,'sphere diameter');
        volume = pi*D^3/6;
        area = pi*D^2/4;
        characteristic = D;
        outer = [D;D;D];
    case {"cuboid","flat_plate"}
        d = shape.dimensions_m(:);
        localPositiveVector(d,3,'cuboid dimensions');
        volume = prod(d);
        area = abs(n(1))*d(2)*d(3) + abs(n(2))*d(1)*d(3) + abs(n(3))*d(1)*d(2);
        characteristic = d(1);
        outer = d;
    case "ellipsoid"
        d = shape.diameters_m(:);
        localPositiveVector(d,3,'ellipsoid diameters');
        a = d(1)/2; b = d(2)/2; c = d(3)/2;
        volume = 4*pi*a*b*c/3;
        area = pi*a*b*c*sqrt((n(1)/a)^2 + (n(2)/b)^2 + (n(3)/c)^2);
        characteristic = d(1);
        outer = d;
    case "cylinder"
        D = shape.diameter_m; L = shape.length_m;
        localPositiveScalar(D,'cylinder diameter');
        localPositiveScalar(L,'cylinder length');
        axisIndex = localAxisIndex(shape.axis);
        axisVector = zeros(3,1); axisVector(axisIndex)=1;
        axial = abs(dot(n,axisVector));
        transverse = sqrt(max(0,1-axial^2));
        R = D/2;
        volume = pi*R^2*L;
        area = pi*R^2*axial + 2*R*L*transverse;
        characteristic = D;
        outer = D*ones(3,1); outer(axisIndex)=L;
    case "custom"
        if isfield(shape,'volume_m3') && ~isempty(shape.volume_m3)
            volume = shape.volume_m3;
        else
            volume = NaN;
        end
        area = shape.projected_area_m2;
        outer = shape.outer_dimensions_m(:);
        if isfield(shape,'characteristic_length_m')
            characteristic = shape.characteristic_length_m;
        else
            characteristic = outer(1);
        end
end
end

function value = localReferenceArea(cfg, projectedArea, type, shape)
mode = lower(string(cfg.geometry.aero_reference_area.mode));
if mode == "manual"
    value = cfg.geometry.aero_reference_area.value_m2;
    localPositiveScalar(value,'reference area');
    return
end
switch type
    case "sphere"
        value = pi*shape.diameter_m^2/4;
    case "cylinder"
        value = shape.diameter_m*shape.length_m;
    case "custom"
        value = shape.reference_area_m2;
    otherwise
        value = projectedArea;
end
end

function value = localReferenceLength(cfg, defaultValue, type, shape)
mode = lower(string(cfg.geometry.aero_reference_length.mode));
if mode == "manual"
    value = cfg.geometry.aero_reference_length.value_m;
    localPositiveScalar(value,'reference length');
else
    if type == "custom"
        value = shape.reference_length_m;
    else
        value = defaultValue;
    end
end
end

function value = localReferenceSpan(cfg, type, shape, outerDimensions)
mode = lower(string(cfg.geometry.aero_reference_span.mode));
if mode == "manual"
    value = cfg.geometry.aero_reference_span.value_m;
    localPositiveScalar(value,'reference span');
    return
end
switch type
    case "sphere"
        value = shape.diameter_m;
    case "custom"
        if isfield(shape,'reference_span_m') && ~isempty(shape.reference_span_m)
            value = shape.reference_span_m;
        else
            % Default to the body-y outer extent; override manually when the
            % aerodynamic coefficient source uses a different reference span.
            value = outerDimensions(2);
        end
    otherwise
        % Body-y extent is the documented default span for primitive geometries.
        value = outerDimensions(2);
end
localPositiveScalar(value,'reference span');
end

function plotData = localPlotData(type, shape, cfg)
plotData = struct('type',type,'shape',shape);
if type == "custom"
    if isfield(shape,'plot_vertices_B_m') && ~isempty(shape.plot_vertices_B_m)
        plotData.vertices_B_m = shape.plot_vertices_B_m;
        plotData.faces = shape.plot_faces;
    else
        plotData.vertices_B_m = cfg.geometry.custom_plot_vertices_B_m;
        plotData.faces = cfg.geometry.custom_plot_faces;
    end
end
end

function localValidateCustomGeometry(custom,cfg)
required=["outer_dimensions_m","projected_area_m2","reference_area_m2", ...
    "reference_length_m","inscribed_cuboid_dimensions_m"];
for name=required
    if ~isfield(custom,name) || isempty(custom.(name))
        error('msbsreq:InvalidCustomGeometry','Custom geometry requires field %s.',name);
    end
end
localPositiveVector(double(custom.outer_dimensions_m(:)),3,'custom outer_dimensions_m');
localPositiveScalar(custom.projected_area_m2,'custom projected_area_m2');
localPositiveScalar(custom.reference_area_m2,'custom reference_area_m2');
localPositiveScalar(custom.reference_length_m,'custom reference_length_m');
localPositiveVector(double(custom.inscribed_cuboid_dimensions_m(:)),3, ...
    'custom inscribed_cuboid_dimensions_m');
if isfield(custom,'volume_m3') && ~isempty(custom.volume_m3)
    localPositiveScalar(custom.volume_m3,'custom volume_m3');
elseif isempty(cfg.mass.total_mass_override_kg)
    error('msbsreq:InvalidCustomGeometry', ...
        'Custom geometry requires volume_m3 or mass.total_mass_override_kg.');
end
if isfield(custom,'inscribed_cuboid_centre_m') && ...
        numel(custom.inscribed_cuboid_centre_m)~=3
    error('msbsreq:InvalidCustomGeometry', ...
        'custom inscribed_cuboid_centre_m must be a 3-vector.');
end
if isempty(custom)
    error('msbsreq:InvalidCustomGeometry','geometry.sizing.custom cannot be empty for custom geometry.');
end
if isfield(custom,'plot_vertices_B_m') && ~isempty(custom.plot_vertices_B_m)
    if size(custom.plot_vertices_B_m,2)~=3
        error('msbsreq:InvalidCustomGeometry', ...
            'custom plot_vertices_B_m must be N-by-3.');
    end
    if ~isfield(custom,'plot_faces') || isempty(custom.plot_faces)
        error('msbsreq:InvalidCustomGeometry', ...
            'custom plot_faces is required when plot vertices are supplied.');
    end
end
if ~isempty(cfg.geometry.custom_plot_vertices_B_m)
    if size(cfg.geometry.custom_plot_vertices_B_m,2)~=3 || isempty(cfg.geometry.custom_plot_faces)
        error('msbsreq:InvalidCustomGeometry', ...
            'geometry.custom_plot_vertices_B_m must be N-by-3 and accompanied by custom_plot_faces.');
    end
end
end

function index = localAxisIndex(axisName)
switch lower(string(axisName))
    case "x", index=1;
    case "y", index=2;
    case "z", index=3;
    otherwise, error('msbsreq:InvalidCylinderAxis','Cylinder axis must be x, y, or z.');
end
end

function localPositiveScalar(value,name)
if isempty(value) || ~isscalar(value) || ~isfinite(value) || value<=0
    error('msbsreq:InvalidGeometryDimension','%s must be positive.',name);
end
end
function localPositiveVector(value,n,name)
if numel(value)~=n || any(~isfinite(value)) || any(value<=0)
    error('msbsreq:InvalidGeometryDimension','%s must contain %d positive values.',name,n);
end
end
