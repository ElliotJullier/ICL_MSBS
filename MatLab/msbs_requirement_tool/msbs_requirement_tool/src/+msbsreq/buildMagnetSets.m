function [magnetSets, warnings] = buildMagnetSets(cfg, geometry, projectRoot)
%BUILDMAGNETSETS Build automatic candidates or explicit manual magnet sets.
arguments
    cfg (1,1) struct
    geometry (1,1) struct
    projectRoot (1,1) string
end

gradeTable = readtable(fullfile(projectRoot,'data','magnet_grades.csv'), ...
    'TextType','string');
warnings = strings(0,1);
warnings(end+1) = "Magnet remanence values are editable generic placeholders; verify the exact Magnet Store product datasheet.";
if ~cfg.magnets.check_containment
    warnings(end+1) = "Magnet containment checking is disabled; the user is responsible for confirming every magnet fits inside the model.";
end

switch cfg.magnets.mode
    case "automatic"
        directions = double(cfg.magnets.automatic.direction_candidates_B);
        count = size(directions,2);
        magnetSets = repmat(localEmptySet(), count, 1);
        baseDimensions = geometry.inscribed_cuboid.dimensions_B_m .* ...
            (1-cfg.magnets.automatic.linear_shrink_fraction);
        baseCentre = geometry.inscribed_cuboid.centre_B_m + ...
            cfg.magnets.automatic.centre_offset_B_m(:);
        for i = 1:count
            direction = directions(:,i);
            direction = localUnit(direction, 'automatic magnetisation direction');
            magnet = struct();
            magnet.name = "automatic_magnet";
            magnet.dimensions_local_m = baseDimensions;
            magnet.centre_B_m = baseCentre;
            magnet.R_BM = eye(3);
            magnet.grade = string(cfg.magnets.automatic.grade);
            magnet.magnetisation_direction_M = direction;
            magnet.effective_magnetisation_factor = ...
                cfg.magnets.automatic.effective_magnetisation_factor;
            magnet.dipole_moment_override_Am2 = ...
                cfg.magnets.automatic.dipole_moment_override_Am2;
            magnet.density_override_kgm3 = [];
            magnet = localResolveMagnet(magnet,cfg,gradeTable);
            localCheckContainment(magnet,geometry,cfg.magnets.check_containment);
            magnetSets(i).id = "AUTO_" + upper(localDirectionLabel(direction,i));
            magnetSets(i).name = "Automatic " + localDirectionLabel(direction,i);
            magnetSets(i).magnets = magnet;
            magnetSets(i).automatic_candidate = true;
        end
        warnings(end+1) = "Automatic axis comparison assumes each candidate magnetisation direction is manufacturable for the selected cuboid.";
    case "manual_sets"
        count = numel(cfg.magnets.sets);
        magnetSets = repmat(localEmptySet(), count, 1);
        for i = 1:count
            sourceSet = cfg.magnets.sets(i);
            if ~isfield(sourceSet,'name') || strlength(string(sourceSet.name))==0
                setName = "manual_set_" + i;
            else
                setName = string(sourceSet.name);
            end
            if ~isfield(sourceSet,'magnets') || isempty(sourceSet.magnets)
                error('msbsreq:EmptyMagnetSet','Manual magnet set %s is empty.',setName);
            end
            resolvedMagnets = repmat(localEmptyMagnet(),numel(sourceSet.magnets),1);
            for j = 1:numel(sourceSet.magnets)
                magnet = localApplyManualDefaults(sourceSet.magnets(j),j);
                magnet = localResolveMagnet(magnet,cfg,gradeTable);
                localCheckContainment(magnet,geometry,cfg.magnets.check_containment);
                resolvedMagnets(j) = magnet;
            end
            magnetSets(i).id = "MANUAL_" + compose('%02d',i);
            magnetSets(i).name = setName;
            magnetSets(i).magnets = resolvedMagnets;
            magnetSets(i).automatic_candidate = false;
        end
end
end

function set = localEmptySet()
set = struct('id',"",'name',"",'magnets',struct([]),'automatic_candidate',false);
end
function magnet = localEmptyMagnet()
magnet = struct('name',"",'dimensions_local_m',zeros(3,1),'centre_B_m',zeros(3,1), ...
    'R_BM',eye(3),'grade',"",'magnetisation_direction_M',zeros(3,1), ...
    'effective_magnetisation_factor',1,'dipole_moment_override_Am2',[], ...
    'density_override_kgm3',[],'Br_selected_T',NaN,'density_kgm3',NaN, ...
    'volume_m3',NaN,'mass_kg',NaN,'dipole_moment_magnitude_Am2',NaN, ...
    'dipole_moment_M_Am2',zeros(3,1),'dipole_moment_B_Am2',zeros(3,1), ...
    'grade_source_reference',"",'grade_source_note',"");
end

function magnet = localApplyManualDefaults(source,index)
magnet = source;
required = {'dimensions_local_m','centre_B_m','R_BM','grade','magnetisation_direction_M'};
for i=1:numel(required)
    if ~isfield(magnet,required{i})
        error('msbsreq:InvalidManualMagnet','Manual magnet %d lacks %s.',index,required{i});
    end
end
if ~isfield(magnet,'name'), magnet.name="magnet_"+index; end
if ~isfield(magnet,'effective_magnetisation_factor'), magnet.effective_magnetisation_factor=1; end
if ~isfield(magnet,'dipole_moment_override_Am2'), magnet.dipole_moment_override_Am2=[]; end
if ~isfield(magnet,'density_override_kgm3'), magnet.density_override_kgm3=[]; end
end

function magnet = localResolveMagnet(source,cfg,gradeTable)
magnet=localEmptyMagnet();
magnet.name = string(source.name);
magnet.grade = string(source.grade);
magnet.dimensions_local_m = double(source.dimensions_local_m(:));
magnet.centre_B_m = double(source.centre_B_m(:));
magnet.R_BM = double(source.R_BM);
magnet.magnetisation_direction_M = localUnit( ...
    double(source.magnetisation_direction_M(:)),'magnetisation direction');
magnet.effective_magnetisation_factor=source.effective_magnetisation_factor;
magnet.dipole_moment_override_Am2=source.dipole_moment_override_Am2;
magnet.density_override_kgm3=source.density_override_kgm3;
if numel(magnet.dimensions_local_m)~=3 || any(~isfinite(magnet.dimensions_local_m)) || any(magnet.dimensions_local_m<=0)
    error('msbsreq:InvalidMagnetDimensions','Magnet dimensions must be three finite positive values.');
end
if numel(magnet.centre_B_m)~=3 || any(~isfinite(magnet.centre_B_m))
    error('msbsreq:InvalidMagnetCentre','Magnet centre must be a finite 3-vector.');
end
if ~isequal(size(magnet.R_BM),[3 3]) || any(~isfinite(magnet.R_BM),'all') || ...
        norm(magnet.R_BM.'*magnet.R_BM-eye(3),'fro')>1e-10 || abs(det(magnet.R_BM)-1)>1e-10
    error('msbsreq:InvalidMagnetRotation','R_BM must be a proper rotation matrix.');
end
row = find(strcmpi(gradeTable.grade,magnet.grade),1);
if isempty(row)
    error('msbsreq:UnknownMagnetGrade','Unknown magnet grade %s.',magnet.grade);
end
switch cfg.magnets.remanence_selection
    case "nominal", Br = gradeTable.Br_nominal_T(row);
    case "minimum", Br = gradeTable.Br_min_T(row);
    case "maximum", Br = gradeTable.Br_max_T(row);
    case "manual", Br = cfg.magnets.manual_Br_T;
end
if isempty(magnet.density_override_kgm3)
    density = gradeTable.density_kgm3(row);
else
    density = magnet.density_override_kgm3;
end
if ~(isscalar(Br) && isfinite(Br) && Br>0) || ...
        ~(isscalar(density) && isfinite(density) && density>0) || ...
        ~(isscalar(magnet.effective_magnetisation_factor) && ...
        isfinite(magnet.effective_magnetisation_factor) && magnet.effective_magnetisation_factor>0)
    error('msbsreq:InvalidMagnetProperty', ...
        'Magnet remanence, density, and effective factor must be finite positive scalars.');
end
volume = prod(magnet.dimensions_local_m);
if isempty(magnet.dipole_moment_override_Am2)
    magnitude = magnet.effective_magnetisation_factor * Br/(4*pi*1e-7) * volume;
else
    magnitude = magnet.dipole_moment_override_Am2;
    if ~(isscalar(magnitude) && isfinite(magnitude) && magnitude>0)
        error('msbsreq:InvalidDipoleOverride','Dipole moment override must be positive.');
    end
end
magnet.Br_selected_T = Br;
magnet.density_kgm3 = density;
magnet.volume_m3 = volume;
magnet.mass_kg = density*volume;
magnet.dipole_moment_magnitude_Am2 = magnitude;
magnet.dipole_moment_M_Am2 = magnitude*magnet.magnetisation_direction_M;
magnet.dipole_moment_B_Am2 = magnet.R_BM*magnet.dipole_moment_M_Am2;
magnet.grade_source_reference = gradeTable.source_reference(row);
magnet.grade_source_note = gradeTable.source_note(row);
end

function value = localUnit(value,name)
if numel(value)~=3 || any(~isfinite(value)) || norm(value)==0
    error('msbsreq:InvalidDirection','%s must be a finite nonzero 3-vector.',name);
end
value=value(:)/norm(value);
end

function label = localDirectionLabel(direction,index)
axes = eye(3);
names = ["+x_B","+y_B","+z_B"];
for k=1:3
    if norm(direction-axes(:,k))<1e-10
        label=names(k); return
    end
end
label="direction_"+index;
end

function localCheckContainment(magnet,geometry,enabled)
if ~enabled, return, end
signs = [-1 -1 -1;-1 -1 1;-1 1 -1;-1 1 1;1 -1 -1;1 -1 1;1 1 -1;1 1 1].';
localCorners = 0.5*magnet.dimensions_local_m.*signs;
points = magnet.centre_B_m + magnet.R_BM*localCorners;
tolerance = 1e-10*max(1,max(geometry.outer_dimensions_B_m));
switch geometry.type
    case {"cuboid","flat_plate"}
        inside = all(abs(points)<=0.5*geometry.shape.dimensions_m+tolerance,1);
    case "sphere"
        inside = vecnorm(points,2,1)<=geometry.shape.diameter_m/2+tolerance;
    case "ellipsoid"
        semi=geometry.shape.diameters_m(:)/2;
        inside=sum((points./semi).^2,1)<=1+tolerance;
    case "cylinder"
        switch geometry.shape.axis
            case "x", axial=points(1,:); radial=vecnorm(points(2:3,:),2,1);
            case "y", axial=points(2,:); radial=vecnorm(points([1 3],:),2,1);
            case "z", axial=points(3,:); radial=vecnorm(points(1:2,:),2,1);
        end
        inside=abs(axial)<=geometry.shape.length_m/2+tolerance & ...
            radial<=geometry.shape.diameter_m/2+tolerance;
    case "custom"
        half=geometry.outer_dimensions_B_m/2;
        inside=all(abs(points)<=half+tolerance,1);
end
if ~all(inside)
    error('msbsreq:MagnetOutsideGeometry', ...
        'Magnet %s is not contained in the supported geometry proxy.',magnet.name);
end
end
