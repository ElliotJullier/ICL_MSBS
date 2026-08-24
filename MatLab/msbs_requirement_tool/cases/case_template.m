function cfg = case_template()
%CASE_TEMPLATE Streamlined v0.4.1 MSBS requirement-study template.
% Copy this file, rename the file/function identically, and edit USER INPUTS.

%% USER INPUT 1 — Case identity
cfg.meta.case_id = "my_experiment";
cfg.meta.description = "Describe the wind-tunnel experiment";

%% USER INPUT 2 — Tunnel, speed and air
cfg.tunnel.cross_section.type = "rectangular"; % rectangular or circular
cfg.tunnel.cross_section.width_m = 0.60;
cfg.tunnel.cross_section.height_m = 0.60;
% cfg.tunnel.cross_section.diameter_m = 0.60;
cfg.tunnel.speed_mps = 30; % default used when a scenario row omits speed_mps
cfg.tunnel.air.mode = "density";
cfg.tunnel.air.rho_kgm3 = 1.225;

%% USER INPUT 3 — E/T/B frames
% Intrinsic Z-Y-X [yaw pitch roll] in degrees. +x_T is downstream flow.
% Horizontal tunnel example: [0 0 0]. A vertical tunnel is obtained by
% rotating T relative to E; gravity is always [0 0 -g] in E.
cfg.frames.tunnel_to_earth.yaw_pitch_roll_deg = [0 0 0];
cfg.frames.body_to_tunnel.yaw_pitch_roll_deg = [0 0 0];
cfg.frames.body_origin_T_m = [0;0;0];

%% USER INPUT 4 — Geometry
cfg.geometry.type = "sphere"; % cuboid, sphere, ellipsoid, cylinder, flat_plate, custom
cfg.geometry.sizing.mode = "blockage"; % blockage or absolute
cfg.geometry.sizing.blockage_ratio = 0.10;
% cfg.geometry.sizing.diameter_m = 0.20; % absolute sphere example
cfg.geometry.aero_reference_area.mode = "projected_nominal";
cfg.geometry.aero_reference_length.mode = "characteristic_default"; % c for Cm
cfg.geometry.aero_reference_span.mode = "characteristic_default";   % b for Cl_roll/Cn
cfg.geometry.aero_reference_point_B_m = [0;0;0];

%% USER INPUT 5 — Permanent magnet arrangement
cfg.magnets.mode = "automatic"; % automatic or manual_sets
cfg.magnets.remanence_selection = "minimum";
cfg.magnets.automatic.grade = "N52";
cfg.magnets.automatic.linear_shrink_fraction = 0;
cfg.magnets.automatic.centre_offset_B_m = [0;0;0];
cfg.magnets.automatic.effective_magnetisation_factor = 1;
cfg.magnets.automatic.direction_candidates_B = eye(3); % +x_B, +y_B, +z_B candidates
% Manual sets may contain multiple spatially separated magnets; see UserGuide.md.

%% USER INPUT 6 — Mass properties
cfg.mass.shell_mass_factor = 1.30;
cfg.mass.total_mass_override_kg = [];
cfg.mass.centre_of_mass_override_B_m = [];
cfg.mass.inertia_override_B_kgm2 = [];

%% USER INPUT 7 — Aerodynamic source
% coefficients: qS[CD CY CL] and qS[b*Cl_roll c*Cm b*Cn]. Moment
% coefficients are optional in practice: leave any unknown channel at zero.
cfg.aero.mode = "coefficients"; % coefficients or direct_wrench
cfg.aero.CD = 0.50;
cfg.aero.CY = 0;
cfg.aero.CL = 0;
cfg.aero.Cl_roll = 0; % rolling-moment coefficient C_l; not lift CL
cfg.aero.Cm = 0;
cfg.aero.Cn = 0;
cfg.aero.direct_wrench_frame = "T"; % E, T or B; used only by direct_wrench

%% USER INPUT 8 — Motion
cfg.motion.mode = "none"; % none, specified, harmonic
cfg.motion.frame = "T";   % E, T or B for specified scenario kinematics
% Harmonic helper (small angular amplitudes, body-axis amplitudes):
% cfg.motion.mode = "harmonic";
% cfg.motion.harmonic.frequency_Hz = 2;
% cfg.motion.harmonic.translation_amplitude_m = [0;0;0.002];
% cfg.motion.harmonic.translation_phase_rad = [0;0;0];
% cfg.motion.harmonic.angular_amplitude_rad = deg2rad([0;2;0]); % [roll;pitch;yaw]
% cfg.motion.harmonic.angular_phase_rad = [0;0;0];
% cfg.motion.harmonic.samples_per_cycle = 24;

%% USER INPUT 9 — Exact simultaneous physical states
% Empty table -> one nominal static state. In harmonic mode, empty -> the
% configured phase samples. There is no factorial expansion or interpolation.
cfg.scenarios = table();
cfg.max_scenarios = 4096;
%
% Coefficient operating-point sweep: omitted coefficient columns use USER INPUT 7.
% cfg.scenarios = table(["U20";"U30";"U40"],[20;30;40],[0.7;0.55;0.50], ...
%     'VariableNames',{'scenario_name','speed_mps','CD'});
%
% Direct aerodynamic wrench: six dimensional aerodynamic components are
% supplied in the same row as any motion data.
% cfg.aero.mode = "direct_wrench";
% cfg.scenarios = table("CFD_1",10,0,-2,0,0.1,0,"T",12345,"CFD_A", ...
%     'VariableNames',{'scenario_name','Fx_aero_N','Fy_aero_N','Fz_aero_N', ...
%     'Mx_aero_Nm','My_aero_Nm','Mz_aero_Nm','aero_frame','Re','source_id'});
%
% Specified motion: append all nine kinematic columns to the SAME rows and set
% cfg.motion.mode="specified". If no kinematic columns are supplied, motion is zero.
% Required names: a_x,a_y,a_z, omega_x,omega_y,omega_z, alpha_x,alpha_y,alpha_z.
% Optional yaw_deg,pitch_deg,roll_deg set the body attitude for that row.
%
% Matched harmonic aero: provide phase_rad (or time_s) in each aero row; the
% harmonic helper calculates the motion at that same row. No timestamp matching
% or interpolation occurs because aero and motion are already one physical state.

%% USER INPUT 10 — Optional static external wrenches
cfg.additional_wrenches = table();
% point = {[0;0;0]};
% cfg.additional_wrenches = table("cable",0,0,-0.1,0,0,0,"B",point, ...
%   'VariableNames',{'name','Fx_N','Fy_N','Fz_N','Mx_Nm','My_Nm','Mz_Nm','components_frame','reference_point_B_m'});

%% USER INPUT 11 — Magnetic requirement solve
cfg.magnetic.model = "source_free_first_order";
cfg.magnetic.cost.primary_mode = "model_characteristic_cube_rms";
% Primary cost is RMS field over a centred cube whose side is the largest
% resolved model dimension. Significant B/G coupling triggers the optional
% sensitivity suite below. Relative-length scales are a separate, deliberately
% non-energy B/G weighting study: Jrel^2=||B0||^2+ell^2||G||F^2.
cfg.magnetic.cost.sensitivity_when_significant = true;
cfg.magnetic.cost.sensitivity_relative_length_scales_m = [0.01 0.10 1.0 10.0];
cfg.magnetic.cost.sensitivity_tunnel_length_fractions = [0.20 0.50];
cfg.magnetic.coupling.zero_ratio_tolerance = 1e-10;
cfg.magnetic.coupling.insignificant_ratio = 1/50;
cfg.magnetic.acceptance_relative_residual = 1e-6;
cfg.magnetic.advisory_B_max_T = [];
cfg.magnetic.advisory_G_max_Tpm = [];
cfg.magnetic.condition_warning_threshold = 1e10;
cfg.magnetic.minimum_force_scale_N = 1e-9;
cfg.magnetic.minimum_moment_scale_Nm = 1e-9;

%% USER INPUT 12 — Validation and output
cfg.validation.rotation_tolerance = 1e-10;
cfg.validation.gradient_tolerance = 1e-10;
cfg.validation.blockage_advisory_limit = 0.15;
cfg.visualisation.enable = true;
cfg.visualisation.plot_worst_case = true;
cfg.visualisation.vector_scale_mode = "normalised";
cfg.visualisation.save_magnetic_field_plot = true;
cfg.output.enable = true;
cfg.output.root_folder = "results";
cfg.output.save_fig = false;
cfg.output.overwrite_existing = false;
end
