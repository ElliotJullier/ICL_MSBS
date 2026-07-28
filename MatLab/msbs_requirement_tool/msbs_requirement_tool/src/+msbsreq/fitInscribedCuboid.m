function cuboid = fitInscribedCuboid(type, shape, sizing)
%FITINSCRIBEDCUBOID Return the exact supported axis-aligned inscribed cuboid.
arguments
    type (1,1) string
    shape (1,1) struct
    sizing (1,1) struct
end
switch type
    case {"cuboid","flat_plate"}
        dimensions = shape.dimensions_m(:);
        centre = [0;0;0];
    case "sphere"
        dimensions = (shape.diameter_m/sqrt(3))*ones(3,1);
        centre = [0;0;0];
    case "ellipsoid"
        dimensions = shape.diameters_m(:)/sqrt(3);
        centre = [0;0;0];
    case "cylinder"
        dimensions = sqrt(2)*(shape.diameter_m/2)*ones(3,1);
        switch lower(string(shape.axis))
            case "x", dimensions(1)=shape.length_m;
            case "y", dimensions(2)=shape.length_m;
            case "z", dimensions(3)=shape.length_m;
        end
        centre = [0;0;0];
    case "custom"
        if ~isfield(shape,'inscribed_cuboid_dimensions_m')
            error('msbsreq:InvalidCustomGeometry', ...
                'Custom geometry requires inscribed_cuboid_dimensions_m.');
        end
        dimensions = shape.inscribed_cuboid_dimensions_m(:);
        if isfield(shape,'inscribed_cuboid_centre_m')
            centre = shape.inscribed_cuboid_centre_m(:);
        else
            centre = [0;0;0];
        end
    otherwise
        error('msbsreq:UnsupportedGeometry','Unsupported geometry type.');
end
if any(dimensions<=0) || numel(dimensions)~=3
    error('msbsreq:InvalidInscribedCuboid','Inscribed cuboid dimensions must be positive.');
end
cuboid = struct('dimensions_B_m',dimensions,'centre_B_m',centre);
end
