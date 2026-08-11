function cfg = case_template()
%CASE_TEMPLATE Fully commented template for an MSBS requirement study.
% Copy this file, rename the function and file identically, then edit USER INPUTS.

%% USER INPUT 1 — Case identity
cfg.meta.case_id = "my_experiment";
cfg.meta.description = "Describe the wind-tunnel experiment";

%% USER INPUT 2 — Wind tunnel and air
cfg.tunnel.cross_section.type = "rectangular"; % rectangular or circular
cfg.tunnel.cross_section.width_m = 0.60;
cfg.tunnel.cross_section.height_m = 0.60;
% cfg.tunnel.cross_section.diameter_m = 0.60; % circular only
cfg.tunnel.speed = msbsreq.rangeSpec(30, 5, "absolute");
cfg.tunnel.air.mode = "density"; % density or ideal_gas
cfg.tunnel.air.rho_kgm3 = 1.225;
% cfg.tunnel.air.pressure_Pa = 101325;
% cfg.tunnel.air.temperature_K = 288.15;
% cfg.tunnel.air.R_air_JpkgK = 287.05;

%% USER INPUT 3 — Frames and named attitude cases
% Intrinsic Z-Y-X yaw-pitch-roll, entered [yaw pitch roll] in degrees.
cfg.frames.tunnel_to_earth.yaw_pitch_roll_deg = [0 0 0];
cfg.frames.body_to_tunnel.yaw_pitch_roll_deg = [0 0 0];
cfg.frames.body_origin_T_m = [0;0;0];
cfg.frames.wind_to_tunnel.R_TW = eye(3);
% Optional named cases:
% cfg.frames.body_attitude_cases(1).name = "nominal";
% cfg.frames.body_attitude_cases(1).yaw_pitch_roll_deg = [0 0 0];
% cfg.frames.body_attitude_cases(2).name = "yaw_5deg";
% cfg.frames.body_attitude_cases(2).yaw_pitch_roll_deg = [5 0 0];
% cfg.frames.wind_orientation_cases(1).name = "nominal";
% cfg.frames.wind_orientation_cases(1).R_TW = eye(3);

%% USER INPUT 4 — Geometry
cfg.geometry.type = "sphere"; % cuboid, sphere, ellipsoid, cylinder, flat_plate, custom
cfg.geometry.sizing.mode = "blockage"; % blockage or absolute
cfg.geometry.sizing.blockage_ratio = 0.10; % fraction, not percent
% Absolute and normalised shape examples:
% cfg.geometry.sizing.diameter_m = 0.20;                 % sphere absolute
% cfg.geometry.sizing.nominal_dimensions_m = [1;0.5;0.3]; % cuboid blockage ratios or cuboid absolute dimensions
% cfg.geometry.sizing.ellipsoid_diameters_m = [0.20;0.12;0.08];
% cfg.geometry.sizing.cylinder_diameter_m = 0.10;
% cfg.geometry.sizing.cylinder_length_m = 0.30;
% cfg.geometry.sizing.cylinder_axis = "y";
% cfg.geometry.sizing.cylinder_length_to_diameter = 3;  % blockage mode
% cfg.geometry.sizing.plate_dimensions_m = [0.20;0.30;0.005];
% cfg.geometry.sizing.plate_normalised_dimensions = [1;1.5;0.025];
% Custom proxy example (all quantities are for the nominal unit/absolute proxy):
% cfg.geometry.sizing.custom.outer_dimensions_m = [1;0.6;0.3];
% cfg.geometry.sizing.custom.projected_area_m2 = 0.18;
% cfg.geometry.sizing.custom.reference_area_m2 = 0.18;
% cfg.geometry.sizing.custom.reference_length_m = 1.0;
% cfg.geometry.sizing.custom.volume_m3 = 0.04; % may be omitted only with total-mass override
% cfg.geometry.sizing.custom.inscribed_cuboid_dimensions_m = [0.8;0.4;0.2];
% cfg.geometry.sizing.custom.inscribed_cuboid_centre_m = [0;0;0];
% cfg.geometry.sizing.custom.plot_vertices_B_m = [...]; % optional N-by-3
% cfg.geometry.sizing.custom.plot_faces = [...];        % optional faces
cfg.geometry.aero_reference_area.mode = "projected_nominal"; % or manual
% cfg.geometry.aero_reference_area.value_m2 = 0.01;
cfg.geometry.aero_reference_length.mode = "characteristic_default"; % pitch reference c, or manual
% cfg.geometry.aero_reference_length.value_m = 0.20;
cfg.geometry.aero_reference_span.mode = "characteristic_default"; % roll/yaw reference b, or manual
% cfg.geometry.aero_reference_span.value_m = 0.30;
cfg.geometry.aero_reference_point_B_m = [0;0;0];

%% USER INPUT 5 — Automatic magnet
cfg.magnets.mode = "automatic"; % automatic or manual_sets
cfg.magnets.remanence_selection = "minimum"; % nominal, minimum, maximum, manual
% cfg.magnets.manual_Br_T = 1.43; % required only when selection is manual
cfg.magnets.check_containment = true;
cfg.magnets.automatic.grade = "N52";
cfg.magnets.automatic.linear_shrink_fraction = 0.0; % 0.10 makes every fitted length 90%
cfg.magnets.automatic.centre_offset_B_m = [0;0;0];
cfg.magnets.automatic.effective_magnetisation_factor = 1.0;
cfg.magnets.automatic.direction_candidates_B = eye(3); % columns are +xB, +yB, +zB
% cfg.magnets.automatic.dipole_moment_override_Am2 = 10;

%% Alternative USER INPUT 5 — Explicit manual magnet sets
% cfg.magnets.mode = "manual_sets";
% m1.name = "front";
% m1.dimensions_local_m = [0.04;0.02;0.02];
% m1.centre_B_m = [0.04;0;0];
% m1.R_BM = eye(3);
% m1.grade = "N52";
% m1.magnetisation_direction_M = [1;0;0];
% m1.effective_magnetisation_factor = 1.0;
% m1.dipole_moment_override_Am2 = [];
% m1.density_override_kgm3 = [];
% m2 = m1; m2.name = "rear"; m2.centre_B_m = [-0.04;0;0];
% cfg.magnets.sets(1).name = "two_parallel_magnets";
% cfg.magnets.sets(1).magnets = [m1 m2];

%% USER INPUT 6 — Mass properties
cfg.mass.shell_mass_factor = 1.30;
% The default hybrid model treats magnets explicitly and distributes the
% remaining shell mass uniformly through the outer primitive.
cfg.mass.total_mass_override_kg = [];
cfg.mass.centre_of_mass_override_B_m = [];
cfg.mass.inertia_override_B_kgm2 = [];

%% USER INPUT 7 — Aerodynamics
cfg.aero.mode = "legacy_3coeff"; % legacy_3coeff, coefficients_6dof, direct_wrench_cases, wrench_time_history
cfg.aero.CD = msbsreq.rangeSpec(0.50, 0.05, "absolute");
cfg.aero.CY = msbsreq.rangeSpec(0.00, [], "absolute");
cfg.aero.CL = msbsreq.rangeSpec(0.00, [], "absolute");
cfg.aero.Cl = msbsreq.rangeSpec(0.00, [], "absolute");
cfg.aero.Cm = msbsreq.rangeSpec(0.00, [], "absolute");
cfg.aero.Cn = msbsreq.rangeSpec(0.00, [], "absolute");
% Six-DOF coefficient mode uses [CD CY CL Cl Cm Cn] and moment references [b c b].
% For physically correlated coefficients prefer combinations.strategy="user_defined".
%
% Direct aerodynamic wrench example (external aerodynamic wrench, not inertia):
% cfg.aero.mode = "direct_wrench_cases";
% p = {[0;0;0]};
% cfg.aero.direct_wrench_cases = table("CFD_case",10,0,-2,0,0.1,0,"T",p,12345,"CFD_A", ...
%   'VariableNames',{'case_name','Fx_N','Fy_N','Fz_N','Mx_Nm','My_Nm','Mz_Nm', ...
%   'frame','reference_point_B_m','Re','source_id'});
%
% Aerodynamic wrench time history. When motion.mode="time_history", time_s must match exactly
% within cfg.aero.time_sync.tolerance_s; no silent interpolation is performed.
% cfg.aero.mode = "wrench_time_history";
% cfg.aero.wrench_time_history = table(...);
cfg.aero.time_sync.mode = "exact";
cfg.aero.time_sync.tolerance_s = 1e-9;

%% USER INPUT 8 — Motion
cfg.motion.mode = "none"; % none, direct_kinematics_cases, harmonic_single_frequency, time_history, direct_required_wrench
% Harmonic small-angle example. Angular components are [roll; pitch; yaw].
% cfg.motion.mode = "harmonic_single_frequency";
% cfg.motion.harmonic.frequency_Hz = 2;
% cfg.motion.harmonic.translation_amplitude_m = [0;0;0.002];
% cfg.motion.harmonic.translation_phase_rad = [0;0;0];
% cfg.motion.harmonic.angular_amplitude_rad = deg2rad([0;2;0]);
% cfg.motion.harmonic.angular_phase_rad = [0;0;0];
% cfg.motion.harmonic.samples_per_cycle = 72;
% Direct kinematics table example:
% cfg.motion.mode = "direct_kinematics_cases";
% cfg.motion.direct_kinematics_cases = table("case1",0,0,1,0,0,0,0,0,0,"T", ...
%   'VariableNames',{'case_name','a_x','a_y','a_z','omega_x','omega_y','omega_z', ...
%   'alpha_x','alpha_y','alpha_z','frame'});
% Time-history tables use the same vector columns, optionally time_s and attitude:
% cfg.motion.mode = "time_history";
% cfg.motion.time_history = table(...);
% Optional yaw_deg/pitch_deg/roll_deg or an R_TB cell column sets row attitude.
% Direct required inertial wrench about CoM:
% cfg.motion.mode = "direct_required_wrench";
% cfg.motion.direct_required_wrench = table("demand1",1,0,0,0,0.1,0,"T", ...
%   'VariableNames',{'case_name','F_x','F_y','F_z','M_x','M_y','M_z','frame'});

%% USER INPUT 9 — Additional static wrench table
cfg.additional_wrenches = table();
% point = {[0;0;0]};
% cfg.additional_wrenches = table("cable",0,0,-0.1,0,0,0,"B",point, ...
%   'VariableNames',{'name','Fx_N','Fy_N','Fz_N','Mx_Nm','My_Nm','Mz_Nm','components_frame','reference_point_B_m'});

%% USER INPUT 10 — Scenario combinations
cfg.combinations.strategy = "full_factorial"; % or user_defined
cfg.combinations.include_nominal_case = true;
cfg.combinations.max_cases = 4096;
cfg.combinations.allow_full_factorial_6dof = false; % set true only to deliberately expand six coefficient ranges
% Correlated user-defined example (omitted columns use nominal/first cases):
% cfg.combinations.strategy = "user_defined";
% cfg.combinations.user_scenarios = table(["cruise";"pitch_peak"],[30;25],[0.5;0.55], ...
%   'VariableNames',{'scenario_name','speed_mps','CD'});

%% USER INPUT 11 — Magnetic solve and interpretation
cfg.magnetic.model = "source_free_first_order";
cfg.magnetic.field_scale_T = 0.10;
cfg.magnetic.gradient_scale_Tpm = 1.0;
cfg.magnetic.acceptance_relative_residual = 1e-6;
% This dimensionless threshold compares the scaled unachieved wrench with
% the scaled requested wrench. Lower is stricter; 1e-6 is a numerical-quality
% criterion, not a hardware tolerance.
cfg.magnetic.advisory_B_max_T = [];
cfg.magnetic.advisory_G_max_Tpm = [];
cfg.magnetic.condition_warning_threshold = 1e10;
cfg.magnetic.minimum_force_scale_N = 1e-9;
cfg.magnetic.minimum_moment_scale_Nm = 1e-9;

%% USER INPUT 12 — Incremental force/moment requirement study
cfg.requirement_resolution.enable = false;
cfg.requirement_resolution.delta_wrench_cases = table();
% cfg.requirement_resolution.enable = true;
% cfg.requirement_resolution.delta_wrench_cases = table("1mN_x",1e-3,0,0,0,0,0,"T", ...
%   'VariableNames',{'name','dFx_N','dFy_N','dFz_N','dMx_Nm','dMy_Nm','dMz_Nm','frame'});
% This reports the incremental B0/G needed about every loaded baseline. It is
% a magnetic-command requirement, not a claim of hardware-achievable resolution.

%% USER INPUT 13 — Validation warnings
cfg.validation.rotation_tolerance = 1e-10;
cfg.validation.gradient_tolerance = 1e-10;
cfg.validation.blockage_advisory_limit = 0.15;

%% USER INPUT 14 — Outputs and figures
cfg.visualisation.enable = true;
cfg.visualisation.plot_worst_case = true;
cfg.visualisation.vector_scale_mode = "normalised";
cfg.visualisation.save_magnetic_field_plot = true;
cfg.output.enable = true;
cfg.output.root_folder = "results";
cfg.output.save_fig = false;
cfg.output.overwrite_existing = false;
end
