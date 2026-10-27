function results = run_sphere_frozen_field_offdesign()
%RUN_SPHERE_5PCT_FROZEN_FIELD_OFFDESIGN
% Frozen-field off-design study for the Re = 250k sphere case.
%
% The existing +msbsreq source is NOT modified.
%
% For each:
%   - tunnel orientation: horizontal, vertical
%   - magnet size: 31.5 mm cube, large cube sized from a 5% blockage sphere
%   - magnetisation: +x_B, +y_B, +z_B
%
% the requirement tool first solves the NOMINAL B0 and G. The solved field is
% then frozen and the magnet/model is perturbed without re-solving B0 or G.
%
% Default perturbations:
%   +1 mm in x_T
%   +1 mm in y_T
%   +1 mm in z_T
%   +1 deg pitch
%   +1 deg yaw
%
% Output moments are referenced to the instantaneous model CoM.
%
% IMPORTANT:
%   The aerodynamic model is a 5% blockage sphere. The large magnet is the
%   maximum cube inscribed in that same 5% blockage sphere.
%
%   Re = 250k is preserved. Because sphere diameter changes with blockage,
%   the wind speed is rescaled from the original 10% blockage reference case
%   using Re = U*D/nu with the same inferred air kinematic viscosity.
%
% The physical imbalance is reported as
%
%   w_imbalance = w_mag_offdesign - w_mag_required_nominal
%
% because w_mag_required_nominal balances the unchanged aerodynamic/gravity
% loads at the nominal state.
%
% The magnetic increment caused by the perturbation is also reported:
%
%   delta_w_mag = w_mag_offdesign - w_mag_nominal_achieved
%
% With an affine field B = B0 + G*r and a centred point dipole:
%   - translations do not change F = G*m;
%   - translation-induced torque change is exactly linear in displacement;
%   - therefore +/- translation increments are exactly antisymmetric;
%   - finite +/- rotations are not exactly antisymmetric because the dipole
%     rotation contains both sine and cosine terms.
%
% Requires the v0.4.1 +msbsreq package and project data/magnet_grades.csv.

%% USER SETTINGS
small_side_m = 31.5e-3;

% Aerodynamic model: 5% blockage sphere.
model_blockage_ratio = 0.05;

% The large magnet is the maximum cube inscribed in this SAME sphere.
large_magnet_reference_blockage_ratio = model_blockage_ratio;

% Preserve the Achenbach Re = 250k operating point.
% Original reference case: 10% blockage sphere at U = 17.25345936 m/s.
reference_blockage_ratio = 0.10;
reference_speed_mps = 17.25345936;

% For a sphere in the same tunnel, D is proportional to sqrt(blockage).
% At fixed Re and fluid properties, U is inversely proportional to D.
speed_mps = reference_speed_mps * ...
    sqrt(reference_blockage_ratio/model_blockage_ratio);

CD = 0.50;
Re = 250000;

translation_offset_m = 1e-3;
rotation_offset_deg = 1.0;

% Start with one-sided perturbations. Change to true later for +/- tests.
include_negative_perturbations = true;

% Save one consolidated CSV and MAT file.
save_results = true;

%% Locate the existing requirement-tool project
projectRoot = fileparts(mfilename('fullpath'));
srcDir = fullfile(projectRoot, "src");

addpath(srcDir);

runPath = which("msbsreq.run");
if isempty(runPath)
    error("run_sphere_frozen_field_offdesign:PackageNotFound", ...
        "Could not find msbsreq.run. Expected package under: %s", srcDir);
end

gradeFile = fullfile(projectRoot, "data", "magnet_grades.csv");
if ~isfile(gradeFile)
    error("run_sphere_frozen_field_offdesign:GradeFileNotFound", ...
        "Expected magnet grade table at: %s", gradeFile);
end

%% Resolve the requested large magnet from the same 5% blockage sphere
large_side_m = localLargeCubeSideFromBlockage( ...
    large_magnet_reference_blockage_ratio);

fprintf("\nFrozen-field off-design study\n");
fprintf("  Small cube side: %.6f mm\n", 1e3*small_side_m);
fprintf("  Large cube side: %.6f mm\n", 1e3*large_side_m);
fprintf("  Large cube reference: maximum inscribed cube in %.3g%% blockage sphere\n", ...
    100*large_magnet_reference_blockage_ratio);
fprintf("  Aerodynamic model blockage: %.3g%%\n", 100*model_blockage_ratio);
fprintf("  Re: %.0f\n", Re);
fprintf("  U: %.9g m/s\n\n", speed_mps);

%% Study definitions
tunnelNames = ["horizontal"; "vertical"];
magnetSizeNames = ["small_31p5mm"; "large_5pct_sphere_max"];
magnetSides = [small_side_m; large_side_m];

perturbations = localPerturbations(translation_offset_m, ...
    rotation_offset_deg, include_negative_perturbations);

rows = repmat(localEmptyRow(), 0, 1);
studies = cell(numel(tunnelNames), numel(magnetSizeNames));

for iTunnel = 1:numel(tunnelNames)
    for iSize = 1:numel(magnetSizeNames)

        cfg = localNominalConfig( ...
            tunnelNames(iTunnel), ...
            magnetSizeNames(iSize), ...
            magnetSides(iSize), ...
            model_blockage_ratio, ...
            speed_mps, CD, Re);

        inputInfo = struct();
        inputInfo.source_type = "generated_offdesign_nominal";
        inputInfo.case_function_name = "run_sphere_frozen_field_offdesign";

        % Nominal requirement solve only. No package source is changed.
        study = msbsreq.run(cfg, projectRoot, inputInfo);
        studies{iTunnel,iSize} = study;

        if height(study.scenarios) ~= 1
            error("run_sphere_frozen_field_offdesign:UnexpectedScenarioCount", ...
                "Expected exactly one nominal scenario.");
        end
        if numel(study.records) ~= 3
            error("run_sphere_frozen_field_offdesign:UnexpectedRecordCount", ...
                "Expected exactly three x/y/z magnetisation records.");
        end

        for iRecord = 1:numel(study.records)
            record = study.records(iRecord);

            for iPert = 1:numel(perturbations)
                row = localEvaluateFrozenField( ...
                    tunnelNames(iTunnel), ...
                    magnetSizeNames(iSize), ...
                    magnetSides(iSize), ...
                    record, ...
                    perturbations(iPert));

                rows(end+1,1) = row; %#ok<AGROW>
            end
        end
    end
end

results = struct2table(rows);

%% Save
if save_results
    outputFolder = fullfile(projectRoot, "results", "offdesign_sphere_5pct_Re250k");
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end

    csvPath = fullfile(outputFolder, "frozen_field_offdesign.csv");
    matPath = fullfile(outputFolder, "frozen_field_offdesign.mat");

    writetable(results, csvPath);

    settings = struct();
    settings.small_side_m = small_side_m;
    settings.large_side_m = large_side_m;
    settings.model_blockage_ratio = model_blockage_ratio;
    settings.large_magnet_reference_blockage_ratio = ...
        large_magnet_reference_blockage_ratio;
    settings.reference_blockage_ratio = reference_blockage_ratio;
    settings.reference_speed_mps = reference_speed_mps;
    settings.speed_mps = speed_mps;
    settings.CD = CD;
    settings.Re = Re;
    settings.translation_offset_m = translation_offset_m;
    settings.rotation_offset_deg = rotation_offset_deg;
    settings.include_negative_perturbations = include_negative_perturbations;

    save(matPath, "results", "settings", "studies");

    fprintf("Saved:\n");
    fprintf("  %s\n", csvPath);
    fprintf("  %s\n\n", matPath);
end

%% Concise console summary
fprintf("Rows generated: %d\n", height(results));
fprintf("Design points: %d tunnel/size/magnetisation combinations\n", ...
    numel(tunnelNames)*numel(magnetSizeNames)*3);
fprintf("Perturbations per design point: %d\n\n", numel(perturbations));

end


function cfg = localNominalConfig(tunnelName, sizeName, side_m, ...
    blockageRatio, speed_mps, CD, Re)

cfg = msbsreq.defaultConfig();

cfg.meta.case_id = "sphere_Re250k_" + tunnelName + "_" + sizeName;
cfg.meta.description = ...
    "Re250k sphere nominal solve for frozen-field off-design evaluation.";

%% Tunnel
cfg.tunnel.cross_section.type = "rectangular";
cfg.tunnel.cross_section.width_m = 0.60;
cfg.tunnel.cross_section.height_m = 0.60;
cfg.tunnel.speed_mps = speed_mps;

cfg.tunnel.air.mode = "density";
cfg.tunnel.air.rho_kgm3 = 1.225;

%% Frames
cfg.frames.tunnel_to_earth.sequence = "ZYX";
if tunnelName == "horizontal"
    cfg.frames.tunnel_to_earth.yaw_pitch_roll_deg = [0 0 0];
elseif tunnelName == "vertical"
    cfg.frames.tunnel_to_earth.yaw_pitch_roll_deg = [0 -90 0];
else
    error("run_sphere_frozen_field_offdesign:UnknownTunnel", ...
        "Unknown tunnel orientation: %s", tunnelName);
end

cfg.frames.body_to_tunnel.sequence = "ZYX";
cfg.frames.body_to_tunnel.yaw_pitch_roll_deg = [0 0 0];
cfg.frames.body_origin_T_m = [0;0;0];

%% Sphere geometry: 5% blockage aerodynamic model
cfg.geometry.type = "sphere";
cfg.geometry.sizing.mode = "blockage";
cfg.geometry.sizing.blockage_ratio = blockageRatio;

cfg.geometry.aero_reference_area.mode = "projected_nominal";
cfg.geometry.aero_reference_length.mode = "characteristic_default";
cfg.geometry.aero_reference_span.mode = "characteristic_default";
cfg.geometry.aero_reference_point_B_m = [0;0;0];

%% Explicit centred cube magnet sets
cfg.magnets.mode = "manual_sets";
cfg.magnets.remanence_selection = "minimum";
cfg.magnets.check_containment = true;
cfg.magnets.sets = localThreeAxisCubeSets(side_m, sizeName);

%% Mass
% Preserve the requirement tool's existing hybrid-mass behaviour.
% Therefore small and large magnets generally have different total masses.
cfg.mass.shell_mass_factor = 1.30;
cfg.mass.total_mass_override_kg = [];
cfg.mass.centre_of_mass_override_B_m = [];
cfg.mass.inertia_override_B_kgm2 = [];

%% Aerodynamics: one exact Re = 250k state only
cfg.aero.mode = "coefficients";
cfg.aero.CD = 0;
cfg.aero.CY = 0;
cfg.aero.CL = 0;
cfg.aero.Cl_roll = 0;
cfg.aero.Cm = 0;
cfg.aero.Cn = 0;

cfg.scenarios = table( ...
    "Re250k", ...
    speed_mps, ...
    CD, ...
    Re, ...
    "Achenbach_1972_Fig4_approx", ...
    'VariableNames', {'scenario_name','speed_mps','CD','Re','source_id'});

cfg.motion.mode = "none";
cfg.additional_wrenches = table();
cfg.max_scenarios = 4096;

%% Magnetic requirement solve
cfg.magnetic.model = "source_free_first_order";

% Centred single magnets have zero gradient-to-moment coupling, so the
% alternate sensitivity suite is unnecessary for this off-design runner.
cfg.magnetic.cost.sensitivity_when_significant = false;

cfg.magnetic.acceptance_relative_residual = 1e-6;
cfg.magnetic.condition_warning_threshold = 1e10;
cfg.magnetic.advisory_B_max_T = [];
cfg.magnetic.advisory_G_max_Tpm = [];

%% No normal study plots/exports; this runner writes its own consolidated data.
cfg.visualisation.enable = false;
cfg.visualisation.plot_worst_case = false;
cfg.visualisation.save_magnetic_field_plot = false;

cfg.output.enable = false;

end


function sets = localThreeAxisCubeSets(side_m, sizeName)

directions = eye(3);
axisNames = ["x"; "y"; "z"];

sets = repmat(struct('name',"",'magnets',struct()), 3, 1);

for i = 1:3
    magnet = struct();
    magnet.name = sizeName + "_cube_" + axisNames(i);
    magnet.dimensions_local_m = side_m*[1;1;1];
    magnet.centre_B_m = [0;0;0];
    magnet.R_BM = eye(3);
    magnet.grade = "N52";
    magnet.magnetisation_direction_M = directions(:,i);
    magnet.effective_magnetisation_factor = 1.0;
    magnet.dipole_moment_override_Am2 = [];
    magnet.density_override_kgm3 = [];

    sets(i).name = sizeName + "_mag_" + axisNames(i);
    sets(i).magnets = magnet;
end

end


function perturbations = localPerturbations(dx_m, angle_deg, includeNegative)

perturbations = repmat(localEmptyPerturbation(), 0, 1);

perturbations(end+1,1) = localPerturbation( ...
    "nominal", [0;0;0], [0 0 0]);

perturbations(end+1,1) = localPerturbation( ...
    "x_plus_1mm", [dx_m;0;0], [0 0 0]);
perturbations(end+1,1) = localPerturbation( ...
    "y_plus_1mm", [0;dx_m;0], [0 0 0]);
perturbations(end+1,1) = localPerturbation( ...
    "z_plus_1mm", [0;0;dx_m], [0 0 0]);

% rotation vector is [yaw pitch roll] in degrees
perturbations(end+1,1) = localPerturbation( ...
    "pitch_plus_1deg", [0;0;0], [0 angle_deg 0]);
perturbations(end+1,1) = localPerturbation( ...
    "yaw_plus_1deg", [0;0;0], [angle_deg 0 0]);

if includeNegative
    perturbations(end+1,1) = localPerturbation( ...
        "x_minus_1mm", [-dx_m;0;0], [0 0 0]);
    perturbations(end+1,1) = localPerturbation( ...
        "y_minus_1mm", [0;-dx_m;0], [0 0 0]);
    perturbations(end+1,1) = localPerturbation( ...
        "z_minus_1mm", [0;0;-dx_m], [0 0 0]);

    perturbations(end+1,1) = localPerturbation( ...
        "pitch_minus_1deg", [0;0;0], [0 -angle_deg 0]);
    perturbations(end+1,1) = localPerturbation( ...
        "yaw_minus_1deg", [0;0;0], [-angle_deg 0 0]);
end

end


function p = localPerturbation(name, displacement_T_m, yawPitchRoll_deg)
p = localEmptyPerturbation();
p.name = name;
p.displacement_T_m = displacement_T_m(:);
p.yaw_pitch_roll_deg = yawPitchRoll_deg;
end


function p = localEmptyPerturbation()
p = struct( ...
    'name',"", ...
    'displacement_T_m',zeros(3,1), ...
    'yaw_pitch_roll_deg',[0 0 0]);
end


function row = localEvaluateFrozenField(tunnelName, sizeName, side_m, ...
    record, perturbation)

if numel(record.magnet_set.magnets) ~= 1
    error("run_sphere_frozen_field_offdesign:ExpectedSingleMagnet", ...
        "This evaluator currently expects exactly one centred magnet per set.");
end

xNom = record.solution.x;
B0Nom = record.solution.B0_T;
G = record.solution.G_Tpm;

mNom = record.map.dipoles_T_Am2(:,1);

% -------------------------------------------------------------------------
% TRANSLATION
%
% The requirement tool normally expresses r from the instantaneous CoM.
% For this frozen-field test, the coil field origin is fixed at the NOMINAL
% suspension point. A whole-model translation d therefore changes the field
% at the new CoM to B0 + G*d.
%
% To report moment about the instantaneous CoM, evaluate the centred dipole
% at r=0 using the shifted local B0. This intentionally avoids adding d x F,
% which would instead be the moment about the fixed nominal origin.
% -------------------------------------------------------------------------
d = perturbation.displacement_T_m;
BAtPerturbedCoM = B0Nom + G*d;

xFrozenAtPerturbedCoM = xNom;
xFrozenAtPerturbedCoM(1:3) = BAtPerturbedCoM;

% -------------------------------------------------------------------------
% ROTATION
%
% B0 and G remain fixed in T. Only the rigidly body-fixed dipole rotates.
% At the nominal body attitude B and T coincide, so the requested yaw/pitch
% offsets can be applied directly with the project's ZYX rotation helper.
% -------------------------------------------------------------------------
Rdelta = msbsreq.rotationZYX(perturbation.yaw_pitch_roll_deg, "deg");
mOff = Rdelta*mNom;

[wMagOff, localField] = msbsreq.evaluateMagneticWrench( ...
    xFrozenAtPerturbedCoM, zeros(3,1), mOff);

wRequiredNom = record.loads.required_magnetic_wrench_T;
wMagNom = record.solution.achieved_wrench_T;

% Physical total imbalance under unchanged external loads.
wImbalance = wMagOff - wRequiredNom;

% Pure change caused by leaving the nominal magnetic operating point.
deltaWMag = wMagOff - wMagNom;

magnet = record.magnet_set.magnets(1);
massProps = record.mass_properties;

axisName = localMagnetisationAxis(magnet.magnetisation_direction_M);

row = localEmptyRow();

row.tunnel_orientation = tunnelName;
row.magnet_size = sizeName;
row.magnet_side_mm = 1e3*side_m;
row.magnetisation_axis = axisName;
row.perturbation = perturbation.name;

row.dx_mm = 1e3*d(1);
row.dy_mm = 1e3*d(2);
row.dz_mm = 1e3*d(3);

row.yaw_deg = perturbation.yaw_pitch_roll_deg(1);
row.pitch_deg = perturbation.yaw_pitch_roll_deg(2);
row.roll_deg = perturbation.yaw_pitch_roll_deg(3);

row.magnet_mass_kg = magnet.mass_kg;
row.total_mass_kg = massProps.total_mass_kg;
row.dipole_magnitude_Am2 = magnet.dipole_moment_magnitude_Am2;

row.nominal_relative_residual = record.solution.relative_scaled_residual;

row.B0x_nom_T = B0Nom(1);
row.B0y_nom_T = B0Nom(2);
row.B0z_nom_T = B0Nom(3);

row.Gxx_Tpm = G(1,1);
row.Gyy_Tpm = G(2,2);
row.Gzz_Tpm = G(3,3);
row.Gxy_Tpm = G(1,2);
row.Gxz_Tpm = G(1,3);
row.Gyz_Tpm = G(2,3);

row.Bx_local_T = localField(1);
row.By_local_T = localField(2);
row.Bz_local_T = localField(3);

row.mx_Am2 = mOff(1);
row.my_Am2 = mOff(2);
row.mz_Am2 = mOff(3);

row.Fx_required_nom_N = wRequiredNom(1);
row.Fy_required_nom_N = wRequiredNom(2);
row.Fz_required_nom_N = wRequiredNom(3);
row.Mx_required_nom_Nm = wRequiredNom(4);
row.My_required_nom_Nm = wRequiredNom(5);
row.Mz_required_nom_Nm = wRequiredNom(6);

row.Fx_mag_N = wMagOff(1);
row.Fy_mag_N = wMagOff(2);
row.Fz_mag_N = wMagOff(3);
row.Mx_mag_Nm = wMagOff(4);
row.My_mag_Nm = wMagOff(5);
row.Mz_mag_Nm = wMagOff(6);

row.delta_Fx_mag_N = deltaWMag(1);
row.delta_Fy_mag_N = deltaWMag(2);
row.delta_Fz_mag_N = deltaWMag(3);
row.delta_Mx_mag_Nm = deltaWMag(4);
row.delta_My_mag_Nm = deltaWMag(5);
row.delta_Mz_mag_Nm = deltaWMag(6);

row.imbalance_Fx_N = wImbalance(1);
row.imbalance_Fy_N = wImbalance(2);
row.imbalance_Fz_N = wImbalance(3);
row.imbalance_Mx_Nm = wImbalance(4);
row.imbalance_My_Nm = wImbalance(5);
row.imbalance_Mz_Nm = wImbalance(6);

row.delta_force_norm_N = norm(deltaWMag(1:3));
row.delta_moment_norm_Nm = norm(deltaWMag(4:6));
row.imbalance_force_norm_N = norm(wImbalance(1:3));
row.imbalance_moment_norm_Nm = norm(wImbalance(4:6));

end


function axisName = localMagnetisationAxis(directionM)

directionM = directionM(:);

if norm(directionM-[1;0;0]) < 1e-10
    axisName = "x";
elseif norm(directionM-[0;1;0]) < 1e-10
    axisName = "y";
elseif norm(directionM-[0;0;1]) < 1e-10
    axisName = "z";
else
    axisName = "other";
end

end


function side_m = localLargeCubeSideFromBlockage(blockageRatio)
% Use the requirement tool's own geometry resolution and exact sphere
% inscribed-cuboid rule rather than hard-coding 87.4 mm.

cfg = msbsreq.defaultConfig();

cfg.tunnel.cross_section.type = "rectangular";
cfg.tunnel.cross_section.width_m = 0.60;
cfg.tunnel.cross_section.height_m = 0.60;

cfg.frames.tunnel_to_earth.sequence = "ZYX";
cfg.frames.tunnel_to_earth.yaw_pitch_roll_deg = [0 0 0];
cfg.frames.body_to_tunnel.sequence = "ZYX";
cfg.frames.body_to_tunnel.yaw_pitch_roll_deg = [0 0 0];

cfg.geometry.type = "sphere";
cfg.geometry.sizing.mode = "blockage";
cfg.geometry.sizing.blockage_ratio = blockageRatio;

cfg = msbsreq.resolveConfig(cfg);
tunnel = msbsreq.buildTunnel(cfg);
geometry = msbsreq.buildGeometry(cfg, tunnel);

dims = geometry.inscribed_cuboid.dimensions_B_m;

if max(abs(dims-dims(1))) > 1e-12
    error("run_sphere_frozen_field_offdesign:UnexpectedLargeMagnetShape", ...
        "Expected a cubic inscribed magnet for the sphere.");
end

side_m = dims(1);

end


function row = localEmptyRow()

row = struct( ...
    'tunnel_orientation',"", ...
    'magnet_size',"", ...
    'magnet_side_mm',NaN, ...
    'magnetisation_axis',"", ...
    'perturbation',"", ...
    'dx_mm',NaN, ...
    'dy_mm',NaN, ...
    'dz_mm',NaN, ...
    'yaw_deg',NaN, ...
    'pitch_deg',NaN, ...
    'roll_deg',NaN, ...
    'magnet_mass_kg',NaN, ...
    'total_mass_kg',NaN, ...
    'dipole_magnitude_Am2',NaN, ...
    'nominal_relative_residual',NaN, ...
    'B0x_nom_T',NaN, ...
    'B0y_nom_T',NaN, ...
    'B0z_nom_T',NaN, ...
    'Gxx_Tpm',NaN, ...
    'Gyy_Tpm',NaN, ...
    'Gzz_Tpm',NaN, ...
    'Gxy_Tpm',NaN, ...
    'Gxz_Tpm',NaN, ...
    'Gyz_Tpm',NaN, ...
    'Bx_local_T',NaN, ...
    'By_local_T',NaN, ...
    'Bz_local_T',NaN, ...
    'mx_Am2',NaN, ...
    'my_Am2',NaN, ...
    'mz_Am2',NaN, ...
    'Fx_required_nom_N',NaN, ...
    'Fy_required_nom_N',NaN, ...
    'Fz_required_nom_N',NaN, ...
    'Mx_required_nom_Nm',NaN, ...
    'My_required_nom_Nm',NaN, ...
    'Mz_required_nom_Nm',NaN, ...
    'Fx_mag_N',NaN, ...
    'Fy_mag_N',NaN, ...
    'Fz_mag_N',NaN, ...
    'Mx_mag_Nm',NaN, ...
    'My_mag_Nm',NaN, ...
    'Mz_mag_Nm',NaN, ...
    'delta_Fx_mag_N',NaN, ...
    'delta_Fy_mag_N',NaN, ...
    'delta_Fz_mag_N',NaN, ...
    'delta_Mx_mag_Nm',NaN, ...
    'delta_My_mag_Nm',NaN, ...
    'delta_Mz_mag_Nm',NaN, ...
    'imbalance_Fx_N',NaN, ...
    'imbalance_Fy_N',NaN, ...
    'imbalance_Fz_N',NaN, ...
    'imbalance_Mx_Nm',NaN, ...
    'imbalance_My_Nm',NaN, ...
    'imbalance_Mz_Nm',NaN, ...
    'delta_force_norm_N',NaN, ...
    'delta_moment_norm_Nm',NaN, ...
    'imbalance_force_norm_N',NaN, ...
    'imbalance_moment_norm_Nm',NaN);

end
