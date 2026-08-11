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
mustBeMember(cfg.aero.mode,["legacy_3coeff","coefficients_6dof", ...
    "direct_wrench_cases","wrench_time_history"]);
localValidateRange(cfg.aero.CD, true, 'CD');
localValidateRange(cfg.aero.CY, true, 'CY');
localValidateRange(cfg.aero.CL, true, 'CL');
localValidateRange(cfg.aero.Cl, true, 'Cl');
localValidateRange(cfg.aero.Cm, true, 'Cm');
localValidateRange(cfg.aero.Cn, true, 'Cn');
mustBeMember(cfg.aero.time_sync.mode,["exact"]);
localPositive(cfg.aero.time_sync.tolerance_s,'aerodynamic time synchronization tolerance');

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
mustBeMember(lower(string(cfg.geometry.aero_reference_span.mode)),["characteristic_default","manual"]);
if cfg.geometry.aero_reference_span.mode=="manual"
    localPositive(cfg.geometry.aero_reference_span.value_m,'aerodynamic reference span');
end
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
localValidateAerodynamicTables(cfg);
if cfg.aero.mode=="wrench_time_history" && cfg.motion.mode=="time_history"
    localValidateExactTimeSync(cfg);
elseif cfg.aero.mode=="wrench_time_history" && ~ismember(cfg.motion.mode,["none","time_history"])
    error('msbsreq:UnsupportedTimeHistoryCombination', ...
        ['Aerodynamic wrench_time_history currently supports motion.mode="none" ', ...
         'or "time_history" only. Use matching time-history rows for correlated unsteady motion.']);
end

mustBeMember(cfg.combinations.strategy, ["full_factorial","user_defined"]);
if cfg.combinations.max_cases < 1 || cfg.combinations.max_cases ~= round(cfg.combinations.max_cases)
    error('msbsreq:InvalidCaseLimit', 'max_cases must be a positive integer.');
end
if cfg.combinations.strategy == "user_defined" && ...
        ismember(cfg.aero.mode,["legacy_3coeff","coefficients_6dof"])
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
    numericColumns={'speed_mps','CD','CY','CL','Cl','Cm','Cn'};
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
if cfg.aero.mode=="coefficients_6dof" && cfg.combinations.strategy=="full_factorial" && ...
        ~cfg.combinations.allow_full_factorial_6dof
    varied = cfg.aero.CD.hasVariation || cfg.aero.CY.hasVariation || ...
        cfg.aero.CL.hasVariation || cfg.aero.Cl.hasVariation || ...
        cfg.aero.Cm.hasVariation || cfg.aero.Cn.hasVariation;
    if varied
        error('msbsreq:Explicit6DOFFactorialRequired', ...
            ['Six-DOF coefficient ranges are not expanded as a Cartesian product by default. ', ...
             'Use correlated user_scenarios, or deliberately set ', ...
             'combinations.allow_full_factorial_6dof=true.']);
    end
end
if ~islogical(cfg.combinations.allow_full_factorial_6dof) || ~isscalar(cfg.combinations.allow_full_factorial_6dof)
    error('msbsreq:InvalidFactorialFlag','allow_full_factorial_6dof must be a logical scalar.');
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

if ~islogical(cfg.requirement_resolution.enable) || ~isscalar(cfg.requirement_resolution.enable)
    error('msbsreq:InvalidResolutionEnable','requirement_resolution.enable must be a logical scalar.');
end
if cfg.requirement_resolution.enable
    localValidateResolutionTable(cfg.requirement_resolution.delta_wrench_cases);
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


function localValidateAerodynamicTables(cfg)
switch cfg.aero.mode
    case "direct_wrench_cases"
        localValidateAeroWrenchTable(cfg.aero.direct_wrench_cases,false);
    case "wrench_time_history"
        localValidateAeroWrenchTable(cfg.aero.wrench_time_history,true);
end
end

function localValidateAeroWrenchTable(T, requireTime)
if ~istable(T) || isempty(T)
    error('msbsreq:EmptyAeroWrenchTable','Selected aerodynamic wrench table must be a nonempty MATLAB table.');
end
required={'Fx_N','Fy_N','Fz_N','Mx_Nm','My_Nm','Mz_Nm'};
if requireTime, required=[{'time_s'},required]; end
if ~all(ismember(required,T.Properties.VariableNames))
    error('msbsreq:MissingAeroWrenchColumns','Aerodynamic wrench table is missing required columns.');
end
for name=required
    localFiniteColumn(T.(name{1}),"aerodynamic wrench "+name{1});
end
if requireTime
    if any(diff(T.time_s)<=0)
        error('msbsreq:InvalidAeroTime','Aerodynamic time_s values must be strictly increasing.');
    end
end
if ismember('frame',T.Properties.VariableNames)
    for i=1:height(T)
        mustBeMember(upper(string(T.frame(i))),["W","T","B"]);
    end
end
if ismember('reference_point_B_m',T.Properties.VariableNames)
    if ~iscell(T.reference_point_B_m)
        error('msbsreq:InvalidAeroReferencePoint','reference_point_B_m must be a cell column of 3-vectors.');
    end
    for i=1:height(T)
        point=T.reference_point_B_m{i};
        if numel(point)~=3 || any(~isfinite(point(:)))
            error('msbsreq:InvalidAeroReferencePoint','Each aerodynamic reference point must be a finite 3-vector.');
        end
    end
end
end

function localValidateExactTimeSync(cfg)
Ta=cfg.aero.wrench_time_history;
Tm=cfg.motion.time_history;
if ~ismember('time_s',Tm.Properties.VariableNames)
    error('msbsreq:MissingMotionTime','motion.time_history requires time_s when combined with aerodynamic wrench_time_history.');
end
if height(Ta)~=height(Tm)
    error('msbsreq:TimeHistoryMismatch','Aerodynamic and motion time histories must contain the same number of rows in exact mode.');
end
if any(abs(Ta.time_s-Tm.time_s)>cfg.aero.time_sync.tolerance_s)
    error('msbsreq:TimeHistoryMismatch','Aerodynamic and motion timestamps do not match within aero.time_sync.tolerance_s.');
end
end

function localValidateResolutionTable(T)
if ~istable(T) || isempty(T)
    error('msbsreq:EmptyResolutionTable','Enabled requirement_resolution requires a nonempty delta_wrench_cases table.');
end
required={'dFx_N','dFy_N','dFz_N','dMx_Nm','dMy_Nm','dMz_Nm'};
if ~all(ismember(required,T.Properties.VariableNames))
    error('msbsreq:MissingResolutionColumns','Resolution table is missing one or more delta-wrench columns.');
end
for i=1:numel(required)
    localFiniteColumn(T.(required{i}),"resolution "+required{i});
end
if ismember('frame',T.Properties.VariableNames)
    for i=1:height(T)
        mustBeMember(upper(string(T.frame(i))),["W","T","B"]);
    end
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
