function warnings = validateConfig(cfg, projectRoot)
%VALIDATECONFIG Validate the streamlined v0.3.0 configuration.
arguments
    cfg (1,1) struct
    projectRoot (1,1) string
end

warnings=strings(0,1);
rotationTolerance=cfg.validation.rotation_tolerance;
if upper(string(cfg.frames.tunnel_to_earth.sequence))~="ZYX" || ...
        upper(string(cfg.frames.body_to_tunnel.sequence))~="ZYX"
    error('msbsreq:UnsupportedEulerSequence','Only intrinsic Z-Y-X yaw-pitch-roll is supported.');
end

mustBeMember(cfg.tunnel.cross_section.type,["rectangular","circular"]);
if cfg.tunnel.cross_section.type=="rectangular"
    localPositive(cfg.tunnel.cross_section.width_m,'tunnel width');
    localPositive(cfg.tunnel.cross_section.height_m,'tunnel height');
else
    localPositive(cfg.tunnel.cross_section.diameter_m,'tunnel diameter');
end
localNonnegative(cfg.tunnel.speed_mps,'tunnel speed');
mustBeMember(cfg.tunnel.air.mode,["density","ideal_gas"]);
if cfg.tunnel.air.mode=="density"
    localPositive(cfg.tunnel.air.rho_kgm3,'air density');
else
    localPositive(cfg.tunnel.air.pressure_Pa,'air pressure');
    localPositive(cfg.tunnel.air.temperature_K,'air temperature');
    localPositive(cfg.tunnel.air.R_air_JpkgK,'air gas constant');
end

localPositive(rotationTolerance,'rotation tolerance');
localPositive(cfg.validation.gradient_tolerance,'gradient tolerance');
localRotation(cfg.frames.R_ET,rotationTolerance,'R_ET');
localRotation(cfg.frames.R_TB_nominal,rotationTolerance,'R_TB_nominal');
localThreeVector(cfg.frames.body_origin_T_m,'frames.body_origin_T_m');

mustBeMember(cfg.geometry.type,["cuboid","sphere","ellipsoid","cylinder","flat_plate","custom"]);
mustBeMember(cfg.geometry.sizing.mode,["absolute","blockage"]);
mustBeMember(cfg.geometry.aero_reference_area.mode,["projected_nominal","manual"]);
mustBeMember(cfg.geometry.aero_reference_length.mode,["characteristic_default","manual"]);
mustBeMember(cfg.geometry.aero_reference_span.mode,["characteristic_default","manual"]);
if cfg.geometry.aero_reference_area.mode=="manual",localPositive(cfg.geometry.aero_reference_area.value_m2,'aerodynamic reference area');end
if cfg.geometry.aero_reference_length.mode=="manual",localPositive(cfg.geometry.aero_reference_length.value_m,'aerodynamic reference length');end
if cfg.geometry.aero_reference_span.mode=="manual",localPositive(cfg.geometry.aero_reference_span.value_m,'aerodynamic reference span');end
localThreeVector(cfg.geometry.aero_reference_point_B_m,'aerodynamic reference point');
if cfg.geometry.type=="cylinder"
    mustBeMember(lower(string(cfg.geometry.sizing.cylinder_axis)),["x","y","z"]);
end
if cfg.geometry.sizing.mode=="blockage"
    beta=cfg.geometry.sizing.blockage_ratio;
    if ~(isscalar(beta)&&isfinite(beta)&&beta>0&&beta<1)
        error('msbsreq:InvalidBlockage','Blockage ratio must satisfy 0 < beta < 1.');
    end
end

mustBeMember(cfg.magnets.mode,["automatic","manual_sets"]);
if cfg.magnets.mode=="automatic"
    shrink=cfg.magnets.automatic.linear_shrink_fraction;
    if ~(isscalar(shrink)&&isfinite(shrink)&&shrink>=0&&shrink<1)
        error('msbsreq:InvalidShrink','Magnet linear shrink fraction must be in [0,1).');
    end
    directions=cfg.magnets.automatic.direction_candidates_B;
    if size(directions,1)~=3 || isempty(directions) || any(~isfinite(directions),'all') || any(vecnorm(directions,2,1)==0)
        error('msbsreq:InvalidMagnetDirections','Automatic direction_candidates_B must be a finite nonzero 3-by-N matrix.');
    end
    localThreeVector(cfg.magnets.automatic.centre_offset_B_m,'automatic magnet centre offset');
    localPositive(cfg.magnets.automatic.effective_magnetisation_factor,'effective magnetisation factor');
    if ~isempty(cfg.magnets.automatic.dipole_moment_override_Am2)
        localPositive(cfg.magnets.automatic.dipole_moment_override_Am2,'automatic dipole override');
    end
elseif isempty(cfg.magnets.sets)
    error('msbsreq:NoManualMagnetSets','Manual magnet mode requires at least one set.');
end

mustBeMember(cfg.magnets.remanence_selection,["nominal","minimum","maximum","manual"]);
if cfg.magnets.remanence_selection=="manual",localPositive(cfg.magnets.manual_Br_T,'manual remanence');end
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
                    error('msbsreq:InvalidManualMagnet','Manual magnet %d in set %d lacks %s.',iMagnet,iSet,required{iField});
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

localPositive(cfg.mass.shell_mass_factor,'shell mass factor');
if ~isempty(cfg.mass.total_mass_override_kg),localPositive(cfg.mass.total_mass_override_kg,'total mass override');end
if ~isempty(cfg.mass.centre_of_mass_override_B_m),localThreeVector(cfg.mass.centre_of_mass_override_B_m,'centre-of-mass override');end
if cfg.mass.shell_mass_factor<1 && isempty(cfg.mass.total_mass_override_kg)
    warnings(end+1,1)="shell_mass_factor is below 1; the default total mass is below magnet mass.";
end
if ~isempty(cfg.mass.inertia_override_B_kgm2)
    I=double(cfg.mass.inertia_override_B_kgm2);
    if ~isequal(size(I),[3 3]) || any(~isfinite(I),'all') || norm(I-I.','fro')>1e-10 || any(eig((I+I.')/2)<=0)
        error('msbsreq:InvalidInertia','Inertia override must be finite, symmetric, and positive definite.');
    end
end

mustBeMember(cfg.aero.mode,["coefficients","direct_wrench"]);
for name=["CD","CY","CL","Cl_roll","Cm","Cn"]
    localFiniteScalar(cfg.aero.(name),"aerodynamic coefficient "+name);
end
mustBeMember(cfg.aero.direct_wrench_frame,["E","T","B"]);

mustBeMember(cfg.motion.mode,["none","specified","harmonic"]);
mustBeMember(cfg.motion.frame,["E","T","B"]);
if cfg.motion.mode=="harmonic"
    localPositive(cfg.motion.harmonic.frequency_Hz,'harmonic frequency');
    samples=cfg.motion.harmonic.samples_per_cycle;
    if ~(isscalar(samples)&&isfinite(samples)&&samples>=4&&samples==round(samples))
        error('msbsreq:InvalidHarmonicSamples','samples_per_cycle must be an integer of at least 4.');
    end
    localThreeVector(cfg.motion.harmonic.translation_amplitude_m,'translation amplitude');
    localThreeVector(cfg.motion.harmonic.angular_amplitude_rad,'angular amplitude');
    localExpand3(cfg.motion.harmonic.translation_phase_rad,'translation phase');
    localExpand3(cfg.motion.harmonic.angular_phase_rad,'angular phase');
    if max(abs(cfg.motion.harmonic.angular_amplitude_rad(:)))>deg2rad(10)
        warnings(end+1,1)="Harmonic angular amplitude exceeds 10 degrees; supply explicit kinematics for large rotations.";
    end
end

if ~(isscalar(cfg.max_scenarios)&&isfinite(cfg.max_scenarios)&&cfg.max_scenarios>=1&&cfg.max_scenarios==round(cfg.max_scenarios))
    error('msbsreq:InvalidCaseLimit','max_scenarios must be a positive integer.');
end
localValidateScenarios(cfg);

if ~isempty(cfg.additional_wrenches)
    if ~istable(cfg.additional_wrenches),error('msbsreq:InvalidAdditionalWrenches','additional_wrenches must be a table.');end
    required={'name','Fx_N','Fy_N','Fz_N','Mx_Nm','My_Nm','Mz_Nm','components_frame','reference_point_B_m'};
    if ~all(ismember(required,cfg.additional_wrenches.Properties.VariableNames))
        error('msbsreq:InvalidAdditionalWrenches','Additional-wrench table is missing required columns.');
    end
    for name={'Fx_N','Fy_N','Fz_N','Mx_Nm','My_Nm','Mz_Nm'}
        localFiniteColumn(cfg.additional_wrenches.(name{1}),"additional wrench "+string(name{1}));
    end
    if ~iscell(cfg.additional_wrenches.reference_point_B_m)
        error('msbsreq:InvalidAdditionalWrenches','reference_point_B_m must be a cell column of 3-vectors.');
    end
    for i=1:height(cfg.additional_wrenches)
        mustBeMember(upper(string(cfg.additional_wrenches.components_frame(i))),["E","T","B"]);
        localThreeVector(cfg.additional_wrenches.reference_point_B_m{i},'additional-wrench reference point');
    end
end

mustBeMember(cfg.magnetic.model,["source_free_first_order"]);
localPositive(cfg.magnetic.field_scale_T,'field scale');
localPositive(cfg.magnetic.gradient_scale_Tpm,'gradient scale');
localPositive(cfg.magnetic.condition_warning_threshold,'condition warning threshold');
localPositive(cfg.magnetic.minimum_force_scale_N,'minimum force scale');
localPositive(cfg.magnetic.minimum_moment_scale_Nm,'minimum moment scale');
if ~isempty(cfg.magnetic.advisory_B_max_T),localPositive(cfg.magnetic.advisory_B_max_T,'advisory B limit');end
if ~isempty(cfg.magnetic.advisory_G_max_Tpm),localPositive(cfg.magnetic.advisory_G_max_Tpm,'advisory gradient limit');end
threshold=cfg.magnetic.acceptance_relative_residual;
if ~(isscalar(threshold)&&isfinite(threshold)&&threshold>=0&&threshold<1)
    error('msbsreq:InvalidResidualThreshold','acceptance_relative_residual must be dimensionless and in [0,1).');
end

mustBeMember(string(cfg.visualisation.vector_scale_mode),["normalised"]);
if strlength(string(cfg.output.root_folder))==0,error('msbsreq:InvalidOutputFolder','Output root folder cannot be empty.');end
if cfg.geometry.sizing.mode=="blockage" && cfg.geometry.sizing.blockage_ratio>cfg.validation.blockage_advisory_limit
    warnings(end+1,1)="Requested nominal blockage exceeds the configured advisory limit.";
end
end

function localValidateScenarios(cfg)
T=cfg.scenarios;
if ~istable(T),error('msbsreq:InvalidScenarioTable','cfg.scenarios must be a MATLAB table.');end
if height(T)>cfg.max_scenarios,error('msbsreq:TooManyScenarios','cfg.scenarios exceeds max_scenarios.');end
if isempty(T)
    if cfg.aero.mode=="direct_wrench"
        error('msbsreq:EmptyScenarioSet','Direct aerodynamic wrench mode requires explicit cfg.scenarios rows.');
    end
    return
end
if ismember('scenario_name',T.Properties.VariableNames) && any(strlength(string(T.scenario_name))==0)
    error('msbsreq:MissingScenarioName','Scenario names, when supplied, must be nonempty.');
end
numericOptional={'speed_mps','CD','CY','CL','Cl_roll','Cm','Cn','time_s','phase_rad'};
for name=numericOptional
    if ismember(name{1},T.Properties.VariableNames),localFiniteColumn(T.(name{1}),"scenario "+string(name{1}));end
end
if ismember('speed_mps',T.Properties.VariableNames) && any(T.speed_mps<0)
    error('msbsreq:InvalidScenarioValue','Scenario speed_mps cannot be negative.');
end

attitude={'yaw_deg','pitch_deg','roll_deg'};
present=ismember(attitude,T.Properties.VariableNames);
if any(present) && ~all(present)
    error('msbsreq:InvalidScenarioAttitude','Scenario attitude requires yaw_deg, pitch_deg, and roll_deg together.');
end
if all(present)
    for name=attitude,localFiniteColumn(T.(name{1}),"scenario "+string(name{1}));end
    if cfg.motion.mode=="harmonic"
        error('msbsreq:AmbiguousHarmonicAttitude','Harmonic motion calculates attitude; do not also supply scenario Euler angles.');
    end
end

kinematics={'a_x','a_y','a_z','omega_x','omega_y','omega_z','alpha_x','alpha_y','alpha_z'};
present=ismember(kinematics,T.Properties.VariableNames);
if any(present) && ~all(present)
    error('msbsreq:MissingMotionColumns','If any kinematics are supplied, all acceleration, omega, and alpha columns are required.');
end
if all(present)
    for name=kinematics,localFiniteColumn(T.(name{1}),"scenario "+string(name{1}));end
    if cfg.motion.mode~="specified"
        error('msbsreq:UnexpectedMotionColumns','Scenario kinematics require motion.mode="specified".');
    end
end
if cfg.motion.mode=="specified" && ~all(present)
    % Missing kinematics are deliberately interpreted as zero demand.
end
if cfg.motion.mode=="harmonic" && ~ismember('phase_rad',T.Properties.VariableNames) && ~ismember('time_s',T.Properties.VariableNames)
    error('msbsreq:MissingHarmonicPhase','Explicit harmonic scenario rows require phase_rad or time_s.');
end

if cfg.aero.mode=="direct_wrench"
    required={'Fx_aero_N','Fy_aero_N','Fz_aero_N','Mx_aero_Nm','My_aero_Nm','Mz_aero_Nm'};
    if ~all(ismember(required,T.Properties.VariableNames))
        error('msbsreq:MissingAeroWrenchColumns','Direct aerodynamic scenarios require all six aero wrench columns.');
    end
    for name=required,localFiniteColumn(T.(name{1}),"direct aerodynamic "+string(name{1}));end
    if ismember('aero_frame',T.Properties.VariableNames)
        for i=1:height(T),mustBeMember(upper(string(T.aero_frame(i))),["E","T","B"]);end
    end
    if ismember('aero_reference_point_B_m',T.Properties.VariableNames)
        if ~iscell(T.aero_reference_point_B_m)
            error('msbsreq:InvalidAeroReferencePoint','aero_reference_point_B_m must be a cell column of 3-vectors.');
        end
        for i=1:height(T),localThreeVector(T.aero_reference_point_B_m{i},'aerodynamic reference point');end
    end
end
end

function localPositive(value,name)
if isempty(value)||~isscalar(value)||~isfinite(value)||value<=0
    error('msbsreq:InvalidPositiveValue','%s must be a finite positive scalar.',name);
end
end
function localNonnegative(value,name)
if isempty(value)||~isscalar(value)||~isfinite(value)||value<0
    error('msbsreq:InvalidNonnegativeValue','%s must be a finite nonnegative scalar.',name);
end
end
function localFiniteScalar(value,name)
if isempty(value)||~isscalar(value)||~isfinite(value)
    error('msbsreq:InvalidNumericInput','%s must be a finite scalar.',name);
end
end
function localFiniteColumn(value,name)
if ~isnumeric(value)||any(~isfinite(value(:)))
    error('msbsreq:InvalidNumericInput','%s must contain only finite numeric values.',name);
end
end
function localThreeVector(value,name)
if numel(value)~=3||any(~isfinite(value(:)))
    error('msbsreq:InvalidVector','%s must be a finite 3-vector.',name);
end
end
function localExpand3(value,name)
value=double(value(:));
if ~(isscalar(value)||numel(value)==3)||any(~isfinite(value))
    error('msbsreq:InvalidVector','%s must be a finite scalar or 3-vector.',name);
end
end
function localRotation(R,tolerance,name)
if ~isequal(size(R),[3 3])||any(~isfinite(R),'all')||norm(R.'*R-eye(3),'fro')>tolerance||abs(det(R)-1)>tolerance
    error('msbsreq:InvalidRotation','%s is not a proper orthonormal rotation matrix.',name);
end
end
