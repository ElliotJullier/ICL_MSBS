function warnings = validateConfig(cfg, projectRoot)
%VALIDATECONFIG Validate resolved configuration before calculations.
arguments
    cfg (1,1) struct
    projectRoot (1,1) string
end

warnings = strings(0,1);
rotationTolerance = cfg.validation.rotation_tolerance;
if upper(string(cfg.frames.tunnel_to_earth.sequence))~="ZYX" || upper(string(cfg.frames.body_to_tunnel.sequence))~="ZYX"
    error('msbsreq:UnsupportedEulerSequence','Only intrinsic Z-Y-X yaw-pitch-roll is supported.');
end

mustBeMember(cfg.tunnel.cross_section.type, ["rectangular","circular"]);
if cfg.tunnel.cross_section.type == "rectangular"
    localPositive(cfg.tunnel.cross_section.width_m, 'tunnel width');
    localPositive(cfg.tunnel.cross_section.height_m, 'tunnel height');
else
    localPositive(cfg.tunnel.cross_section.diameter_m, 'tunnel diameter');
end
mustBeMember(cfg.tunnel.air.mode, ["density","ideal_gas"]);
if cfg.tunnel.air.mode == "density"
    localPositive(cfg.tunnel.air.rho_kgm3, 'air density');
else
    localPositive(cfg.tunnel.air.pressure_Pa, 'air pressure');
    localPositive(cfg.tunnel.air.temperature_K, 'air temperature');
    localPositive(cfg.tunnel.air.R_air_JpkgK, 'air gas constant');
end

localValidateRange(cfg.tunnel.speed, false, 'tunnel speed');
localValidateRange(cfg.aero.CD, true, 'CD');
localValidateRange(cfg.aero.CL, true, 'CL');
localValidateRange(cfg.aero.Cm, true, 'Cm');

localPositive(rotationTolerance,'rotation tolerance');
localPositive(cfg.validation.gradient_tolerance,'gradient tolerance');
if numel(cfg.frames.body_origin_T_m)~=3 || any(~isfinite(cfg.frames.body_origin_T_m))
    error('msbsreq:InvalidBodyOrigin','frames.body_origin_T_m must be a finite 3-vector.');
end
localRotation(cfg.frames.R_ET, rotationTolerance, 'R_ET');
for i = 1:numel(cfg.frames.body_attitude_cases)
    localRotation(cfg.frames.body_attitude_cases(i).R_TB, rotationTolerance, ...
        "body attitude " + cfg.frames.body_attitude_cases(i).name);
end
for i = 1:numel(cfg.frames.wind_orientation_cases)
    localRotation(cfg.frames.wind_orientation_cases(i).R_TW, rotationTolerance, ...
        "wind orientation " + cfg.frames.wind_orientation_cases(i).name);
end

mustBeMember(cfg.geometry.type, ["cuboid","sphere","ellipsoid","cylinder","flat_plate","custom"]);
mustBeMember(cfg.geometry.sizing.mode, ["absolute","blockage"]);
mustBeMember(lower(string(cfg.geometry.aero_reference_area.mode)),["projected_nominal","manual"]);
mustBeMember(lower(string(cfg.geometry.aero_reference_length.mode)),["characteristic_default","manual"]);
if cfg.geometry.type=="cylinder"
    mustBeMember(lower(string(cfg.geometry.sizing.cylinder_axis)),["x","y","z"]);
end
if cfg.geometry.sizing.mode == "blockage"
    beta = cfg.geometry.sizing.blockage_ratio;
    if ~(isscalar(beta) && isfinite(beta) && beta > 0 && beta < 1)
        error('msbsreq:InvalidBlockage', 'Blockage ratio must satisfy 0 < beta < 1.');
    end
end

mustBeMember(cfg.magnets.mode, ["automatic","manual_sets"]);
if cfg.magnets.mode == "automatic"
    shrink = cfg.magnets.automatic.linear_shrink_fraction;
    if ~(isscalar(shrink) && isfinite(shrink) && shrink >= 0 && shrink < 1)
        error('msbsreq:InvalidShrink', 'Magnet linear shrink fraction must be in [0,1).');
    end
    directions = cfg.magnets.automatic.direction_candidates_B;
    if size(directions,1) ~= 3 || isempty(directions) || any(~isfinite(directions),'all')
        error('msbsreq:InvalidMagnetDirections', ...
            'Automatic direction_candidates_B must be a finite nonempty 3-by-N matrix.');
    end
    if any(vecnorm(directions,2,1)==0)
        error('msbsreq:InvalidMagnetDirections','Automatic direction columns must be nonzero.');
    end
    localThreeVector(cfg.magnets.automatic.centre_offset_B_m,'automatic magnet centre offset');
    localPositive(cfg.magnets.automatic.effective_magnetisation_factor,'effective magnetisation factor');
    if ~isempty(cfg.magnets.automatic.dipole_moment_override_Am2)
        localPositive(cfg.magnets.automatic.dipole_moment_override_Am2,'automatic dipole override');
    end
else
    if isempty(cfg.magnets.sets)
        error('msbsreq:NoManualMagnetSets', 'Manual magnet mode requires at least one set.');
    end
end

mustBeMember(cfg.magnets.remanence_selection, ["nominal","minimum","maximum","manual"]);
if cfg.magnets.remanence_selection == "manual"
    localPositive(cfg.magnets.manual_Br_T, 'manual remanence');
end
gradeTable=msbsreq.loadMagnetGradeTable(projectRoot);
if cfg.magnets.mode=="automatic"
    requestedGrades=string(cfg.magnets.automatic.grade);
else
    requestedGrades=strings(0,1);
    for iSet=1:numel(cfg.magnets.sets)
        if ~isfield(cfg.magnets.sets(iSet),'magnets') || isempty(cfg.magnets.sets(iSet).magnets)
            error('msbsreq:EmptyMagnetSet','Every manual magnet set requires a nonempty magnets field.');
        end
        for iMagnet=1:numel(cfg.magnets.sets(iSet).magnets)
            magnet=cfg.magnets.sets(iSet).magnets(iMagnet);
            required={'dimensions_local_m','centre_B_m','R_BM','grade','magnetisation_direction_M'};
            for iField=1:numel(required)
                if ~isfield(magnet,required{iField})
                    error('msbsreq:InvalidManualMagnet', ...
                        'Manual magnet %d in set %d lacks %s.',iMagnet,iSet,required{iField});
                end
            end
            requestedGrades(end+1,1)=string(magnet.grade); %#ok<AGROW>
        end
    end
end
for grade=requestedGrades(:).'
    if ~any(strcmpi(gradeTable.("grade"),grade))
        error('msbsreq:UnknownMagnetGrade','Unknown magnet grade %s.',grade);
    end
end

localPositive(cfg.mass.shell_mass_factor, 'shell mass factor');
if ~isempty(cfg.mass.total_mass_override_kg),localPositive(cfg.mass.total_mass_override_kg,'total mass override');end
if ~isempty(cfg.mass.centre_of_mass_override_B_m) && ...
        (numel(cfg.mass.centre_of_mass_override_B_m)~=3 || any(~isfinite(cfg.mass.centre_of_mass_override_B_m)))
    error('msbsreq:InvalidCentreOfMass','Centre-of-mass override must be a finite 3-vector.');
end
if cfg.mass.shell_mass_factor < 1 && isempty(cfg.mass.total_mass_override_kg)
    warnings(end+1,1) = "shell_mass_factor is below 1; the default total mass is below magnet mass.";
end
if ~isempty(cfg.mass.inertia_override_B_kgm2)
    I = double(cfg.mass.inertia_override_B_kgm2);
    if ~isequal(size(I), [3 3]) || any(~isfinite(I),'all') || norm(I-I.', 'fro') > 1e-10
        error('msbsreq:InvalidInertia', 'Inertia override must be a symmetric 3-by-3 matrix.');
    end
    if any(eig((I+I.')/2) <= 0)
        error('msbsreq:InvalidInertia', 'Inertia override must be positive definite.');
    end
end

mustBeMember(cfg.motion.mode, ["none","direct_kinematics_cases", ...
    "harmonic_single_frequency","time_history","direct_required_wrench"]);
if cfg.motion.mode == "harmonic_single_frequency"
    localPositive(cfg.motion.harmonic.frequency_Hz, 'harmonic frequency');
    samples = cfg.motion.harmonic.samples_per_cycle;
    if samples < 4 || samples ~= round(samples)
        error('msbsreq:InvalidHarmonicSamples', ...
            'samples_per_cycle must be an integer of at least 4.');
    end
    localThreeVector(cfg.motion.harmonic.translation_amplitude_m,'translation amplitude');
    localThreeVector(cfg.motion.harmonic.angular_amplitude_rad,'angular amplitude');
    if max(abs(cfg.motion.harmonic.angular_amplitude_rad(:)))>deg2rad(10)
        warnings(end+1,1)="Harmonic angular amplitude exceeds 10 degrees; use a validated time history for large or strongly coupled rotations.";
    end
end
localValidateMotionTables(cfg,rotationTolerance);

mustBeMember(cfg.combinations.strategy, ["full_factorial","user_defined"]);
if cfg.combinations.max_cases < 1 || cfg.combinations.max_cases ~= round(cfg.combinations.max_cases)
    error('msbsreq:InvalidCaseLimit', 'max_cases must be a positive integer.');
end
if cfg.combinations.strategy == "user_defined"
    T=cfg.combinations.user_scenarios;
    if ~istable(T) || isempty(T)
        error('msbsreq:EmptyScenarioSet', 'user_defined strategy requires a nonempty table.');
    end
    if ~ismember('scenario_name',T.Properties.VariableNames)
        error('msbsreq:MissingScenarioName','User-defined scenarios require scenario_name.');
    end
    if any(strlength(string(T.scenario_name))==0)
        error('msbsreq:MissingScenarioName','Every user-defined scenario requires a nonempty name.');
    end
    numericColumns={'speed_mps','CD','CL','Cm'};
    for iColumn=1:numel(numericColumns)
        name=numericColumns{iColumn};
        if ismember(name,T.Properties.VariableNames)
            localFiniteColumn(T.(name),"user scenario "+name);
            if strcmp(name,'speed_mps') && any(T.(name)<0)
                error('msbsreq:InvalidScenarioValue','User-defined speed_mps cannot be negative.');
            end
        end
    end
    scaleNames=string(T.Properties.VariableNames);
    scaleNames=scaleNames(startsWith(scaleNames,"scale_"));
    for name=scaleNames
        localFiniteColumn(T.(name),"user scenario "+name);
    end
end

mustBeMember(cfg.magnetic.model,["source_free_first_order"]);
localPositive(cfg.magnetic.field_scale_T, 'field scale');
localPositive(cfg.magnetic.gradient_scale_Tpm, 'gradient scale');
localPositive(cfg.magnetic.condition_warning_threshold,'condition warning threshold');
localPositive(cfg.magnetic.minimum_force_scale_N,'minimum force scale');
localPositive(cfg.magnetic.minimum_moment_scale_Nm,'minimum moment scale');
if ~isempty(cfg.magnetic.advisory_B_max_T),localPositive(cfg.magnetic.advisory_B_max_T,'advisory B limit');end
if ~isempty(cfg.magnetic.advisory_G_max_Tpm),localPositive(cfg.magnetic.advisory_G_max_Tpm,'advisory gradient limit');end
threshold = cfg.magnetic.acceptance_relative_residual;
if ~(isscalar(threshold) && isfinite(threshold) && threshold >= 0 && threshold < 1)
    error('msbsreq:InvalidResidualThreshold', ...
        'acceptance_relative_residual must be dimensionless and in [0,1).');
end

if ~isempty(cfg.additional_wrenches)
    required={'name','Fx_N','Fy_N','Fz_N','Mx_Nm','My_Nm','Mz_Nm','components_frame','reference_point_B_m'};
    if ~all(ismember(required,cfg.additional_wrenches.Properties.VariableNames))
        error('msbsreq:InvalidAdditionalWrenches','Additional-wrench table is missing required columns.');
    end
    numericNames={'Fx_N','Fy_N','Fz_N','Mx_Nm','My_Nm','Mz_Nm'};
    for iName=1:numel(numericNames)
        localFiniteColumn(cfg.additional_wrenches.(numericNames{iName}), ...
            "additional wrench "+numericNames{iName});
    end
    if ~iscell(cfg.additional_wrenches.reference_point_B_m)
        error('msbsreq:InvalidAdditionalWrenches', ...
            'reference_point_B_m must be a table cell column of 3-vectors.');
    end
    for i=1:height(cfg.additional_wrenches)
        mustBeMember(upper(string(cfg.additional_wrenches.components_frame(i))),["E","T","B","W"]);
        point=cfg.additional_wrenches.reference_point_B_m{i};
        if numel(point)~=3 || any(~isfinite(point(:)))
            error('msbsreq:InvalidAdditionalWrenches','Each reference point must be a finite 3-vector stored in a table cell.');
        end
    end
end
mustBeMember(string(cfg.visualisation.vector_scale_mode),["normalised"]);
if strlength(string(cfg.output.root_folder))==0,error('msbsreq:InvalidOutputFolder','Output root folder cannot be empty.');end

if cfg.geometry.sizing.mode == "blockage" && ...
        cfg.geometry.sizing.blockage_ratio > cfg.validation.blockage_advisory_limit
    warnings(end+1,1) = "Requested nominal blockage exceeds the configured advisory limit.";
end
end

function localValidateMotionTables(cfg,rotationTolerance)
switch cfg.motion.mode
    case {"direct_kinematics_cases","time_history"}
        if cfg.motion.mode=="direct_kinematics_cases"
            T=cfg.motion.direct_kinematics_cases;
        else
            T=cfg.motion.time_history;
        end
        if ~istable(T)
            error('msbsreq:InvalidMotionTable','The selected motion input must be a MATLAB table.');
        end
        required={'a_x','a_y','a_z','omega_x','omega_y','omega_z', ...
            'alpha_x','alpha_y','alpha_z'};
        if ~all(ismember(required,T.Properties.VariableNames))
            error('msbsreq:MissingMotionColumns','Kinematics table is missing required vector columns.');
        end
        for iName=1:numel(required)
            localFiniteColumn(T.(required{iName}),"motion "+required{iName});
        end
        if ismember('time_s',T.Properties.VariableNames)
            localFiniteColumn(T.time_s,'motion time_s');
        end
        if ismember('frame',T.Properties.VariableNames)
            for i=1:height(T)
                mustBeMember(upper(string(T.frame(i))),["E","T","B","W"]);
            end
        end
        if cfg.motion.mode=="time_history"
            attitudeNames={'yaw_deg','pitch_deg','roll_deg'};
            present=ismember(attitudeNames,T.Properties.VariableNames);
            if any(present) && ~all(present)
                error('msbsreq:InvalidTimeHistoryAttitude', ...
                    'Time-history Euler attitude requires yaw_deg, pitch_deg, and roll_deg together.');
            end
            if all(present)
                for iName=1:numel(attitudeNames)
                    localFiniteColumn(T.(attitudeNames{iName}), ...
                        "time-history "+attitudeNames{iName});
                end
            end
            if ismember('R_TB',T.Properties.VariableNames)
                if ~iscell(T.R_TB)
                    error('msbsreq:InvalidTimeHistoryAttitude','The R_TB table variable must be a cell array of 3-by-3 matrices.');
                end
                for i=1:height(T)
                    if ~isempty(T.R_TB{i})
                        localRotation(T.R_TB{i},rotationTolerance,"time-history R_TB row "+i);
                    end
                end
            end
        end
    case "direct_required_wrench"
        T=cfg.motion.direct_required_wrench;
        if ~istable(T)
            error('msbsreq:InvalidMotionTable','direct_required_wrench must be a MATLAB table.');
        end
        required={'F_x','F_y','F_z','M_x','M_y','M_z'};
        if ~all(ismember(required,T.Properties.VariableNames))
            error('msbsreq:MissingMotionColumns','Direct required-wrench table is missing F and M columns.');
        end
        for iName=1:numel(required)
            localFiniteColumn(T.(required{iName}),"direct demand "+required{iName});
        end
        if ismember('frame',T.Properties.VariableNames)
            for i=1:height(T)
                mustBeMember(upper(string(T.frame(i))),["E","T","B","W"]);
            end
        end
end
end

function localPositive(value, name)
if isempty(value) || ~isscalar(value) || ~isfinite(value) || value <= 0
    error('msbsreq:InvalidPositiveValue', '%s must be a finite positive scalar.', name);
end
end

function localValidateRange(spec, signedAllowed, name)
values = [spec.nominal spec.lower spec.upper];
if any(~isfinite(values)) || spec.lower > spec.upper || ...
        spec.nominal < spec.lower || spec.nominal > spec.upper
    error('msbsreq:InvalidRange', '%s range is inconsistent.', name);
end
if ~signedAllowed && any(values < 0)
    error('msbsreq:InvalidRange', '%s cannot have negative values.', name);
end
end

function localFiniteColumn(value,name)
if ~isnumeric(value) || any(~isfinite(value(:)))
    error('msbsreq:InvalidNumericInput','%s must contain only finite numeric values.',name);
end
end

function localThreeVector(value,name)
if numel(value)~=3 || any(~isfinite(value(:)))
    error('msbsreq:InvalidVector','%s must be a finite 3-vector.',name);
end
end

function localRotation(R, tolerance, name)
if ~isequal(size(R),[3 3]) || any(~isfinite(R),'all') || ...
        norm(R.'*R-eye(3),'fro') > tolerance || abs(det(R)-1) > tolerance
    error('msbsreq:InvalidRotation', '%s is not a proper orthonormal rotation matrix.', name);
end
end
