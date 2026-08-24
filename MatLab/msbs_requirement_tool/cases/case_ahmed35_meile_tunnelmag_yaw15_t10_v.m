function cfg = case_ahmed35_meile_tunnelmag_yaw15_t10_v()
%CASE_AHMED35_MEILE_TUNNELMAG_YAW15_T10_V MSBS aerodynamic requirement study.
% Requirement-tool v0.3.0 syntax. One scenario row = one simultaneous physical state.
% Aerodynamic source: Meile et al. (2016), 35 deg rear slant, Figs. 18 and 20.
% Coefficients below are graph-digitised engineering values at U_inf=30 m/s; use for load sizing, not precision reproduction.
% Meile moments are supplied about the force-balance origin on the test-section floor between the stilts.
% This case passes that source point explicitly; the tool shifts the complete aerodynamic wrench to its calculated CoM.
% At beta=15 deg, the magnet cuboid is counter-yawed inside B so its magnetisation remains parallel to +x_T.
% Its dimensions are the maximum centred rectangle at 15 deg that remains inside the supplied Ahmed central prism.

cfg.meta.case_id = "ahmed35_meile_tunnelmag_yaw15_t10_v";
cfg.meta.description = "35 deg Ahmed body, Meile beta=15 deg loads, magnet physically aligned +x_T, 1.0 m tunnel.";

cfg.tunnel.cross_section.type = "rectangular";
cfg.tunnel.cross_section.width_m = 1;
cfg.tunnel.cross_section.height_m = 1;
cfg.tunnel.speed_mps = 10;
cfg.tunnel.air.mode = "density";
cfg.tunnel.air.rho_kgm3 = 1.225;

cfg.frames.tunnel_to_earth.sequence = "ZYX";
cfg.frames.tunnel_to_earth.yaw_pitch_roll_deg = [0 -90 0];
% Vertical tunnel: +x_T is mapped to +z_E (upward flow); gravity is therefore -x_T.
cfg.frames.body_to_tunnel.sequence = "ZYX";
cfg.frames.body_to_tunnel.yaw_pitch_roll_deg = [0 0 0];
cfg.frames.body_origin_T_m = [0;0;0];

cfg.geometry.type = "custom";
cfg.geometry.sizing.mode = "absolute";
cfg.geometry.sizing.custom.outer_dimensions_m = [0.765427487083;0.285202387428;0.21115241023];
cfg.geometry.sizing.custom.projected_area_m2 = 0.0602211715088; % head-on geometric frontal area
cfg.geometry.sizing.custom.reference_area_m2 = 0.0602039703744; % Meile A_ref=0.112 m^2 scaled by s^2
cfg.geometry.sizing.custom.reference_length_m = 0.765427487083;
cfg.geometry.sizing.custom.volume_m3 = 0.0396416483803; % legacy Ahmed custom-proxy volume; not exact CAD volume
cfg.geometry.sizing.custom.inscribed_cuboid_dimensions_m = [0.529347361756;0.285202387428;0.21115241023];
cfg.geometry.sizing.custom.inscribed_cuboid_centre_m = [-0.0447232535556;0;0];
cfg.geometry.aero_reference_area.mode = "manual";
cfg.geometry.aero_reference_area.value_m2 = 0.0602039703744;
cfg.geometry.aero_reference_length.mode = "manual";
cfg.geometry.aero_reference_length.value_m = 0.344589002805; % Meile pitch/yaw moment reference = 0.470 m scaled
cfg.geometry.aero_reference_span.mode = "manual";
cfg.geometry.aero_reference_span.value_m = 0.239745965782; % Meile roll moment reference = 0.327 m scaled
cfg.geometry.aero_reference_point_B_m = [-0.0623192877414;0;-0.142234609669];
% Standard-geometry scale s=0.733168091. Ground clearance corresponding to Meile is 0.036658405 m (aerodynamic/fake-floor requirement, not explicitly modelled).
% Head-on blockage = 0.060221; conservative bounding-silhouette blockage at beta=15 deg = 0.100000.
% The supplied inscribed cuboid is the constant full-section prism from x=100 mm (front-radius tangency) to x=822 mm (rear-slant start) in the source geometry.

cfg.magnets.mode = "manual_sets";
cfg.magnets.remanence_selection = "minimum";
cfg.magnets.check_containment = true;
m1.name = "tunnel_aligned_N52";
m1.dimensions_local_m = [0.505175109542;0.159901975662;0.21115241023];
m1.centre_B_m = [-0.0447232535556;0;0];
m1.R_BM = [0.965925826289 0.258819045103 0; -0.258819045103 0.965925826289 0; 0 0 1];
m1.grade = "N52";
m1.magnetisation_direction_M = [1;0;0];
m1.effective_magnetisation_factor = 1.0;
m1.dipole_moment_override_Am2 = [];
m1.density_override_kgm3 = [];
cfg.magnets.sets(1).name = "tunnel_aligned_N52";
cfg.magnets.sets(1).magnets = m1;
% With R_TB=Rz(+15 deg) in the yawed scenario and R_BM=Rz(-15 deg), R_TB*R_BM=I in yaw: m remains +x_T.
% Rotated magnet local dimensions are 0.505175110 x 0.159901976 x 0.211152410 m; volume is 0.535 of the body-aligned maximum magnet volume.

cfg.mass.shell_mass_factor = 1.30;
cfg.mass.total_mass_override_kg = [];
cfg.mass.centre_of_mass_override_B_m = [];
cfg.mass.inertia_override_B_kgm2 = [];
% The default hybrid mass model computes a CoM from the offset magnet plus the distributed shell proxy. For a final model, override CoM and inertia with designed/measured values.

cfg.aero.mode = "direct_wrench";
cfg.aero.direct_wrench_frame = "B";
% IMPORTANT: direct B-frame wrench is used because Meile transforms the measured wind-fixed loads into the model-fixed frame.
% Do NOT pre-shift the moment to the CoM here; aero_reference_point_B_m tells the tool where Meile defined the moment.

speeds = [10 25].';
rho = 1.225;
Sref = 0.0602039703744;
lroll = 0.239745965782;
lpy = 0.344589002805;
P_B = [-0.0623192877414;0;-0.142234609669];
CD=0.43; CS=0.81; CL=0.57; CMR=0.53; CMP=-0.17; CMY=0.26;
q = 0.5*rho*speeds.^2;
Fx=q*Sref*CD; Fy=q*Sref*CS; Fz=q*Sref*CL;
Mx=q*Sref*lroll*CMR; My=q*Sref*lpy*CMP; Mz=q*Sref*lpy*CMY;
Re_L = speeds*0.765427487083/1.5e-05;
n=numel(speeds); names="U"+string(speeds)+"_beta15_tunnelmag";
refs=repmat({P_B},n,1);
cfg.scenarios = table(names,speeds,Fx,Fy,Fz,Mx,My,Mz,repmat("B",n,1),refs,15*ones(n,1),zeros(n,1),zeros(n,1),Re_L,15*ones(n,1), ...
 'VariableNames',{'scenario_name','speed_mps','Fx_aero_N','Fy_aero_N','Fz_aero_N','Mx_aero_Nm','My_aero_Nm','Mz_aero_Nm','aero_frame','aero_reference_point_B_m','yaw_deg','pitch_deg','roll_deg','Re_L','beta_deg'});

% Use specified mode with explicit zero kinematics so the documented v0.3.0
% per-row yaw_deg/pitch_deg/roll_deg attitude path is exercised. These are
% static aerodynamic states: all rigid-body acceleration/rate terms are zero.
zkin = zeros(height(cfg.scenarios),1);
cfg.scenarios.a_x = zkin;
cfg.scenarios.a_y = zkin;
cfg.scenarios.a_z = zkin;
cfg.scenarios.omega_x = zkin;
cfg.scenarios.omega_y = zkin;
cfg.scenarios.omega_z = zkin;
cfg.scenarios.alpha_x = zkin;
cfg.scenarios.alpha_y = zkin;
cfg.scenarios.alpha_z = zkin;
cfg.motion.mode = "specified";
cfg.motion.frame = "T";
cfg.additional_wrenches = table();
cfg.max_scenarios = 4096;

cfg.magnetic.model = "source_free_first_order";
cfg.magnetic.field_scale_T = 0.10;
cfg.magnetic.gradient_scale_Tpm = 1.0;
cfg.magnetic.acceptance_relative_residual = 1e-6;
cfg.magnetic.condition_warning_threshold = 1e10;
cfg.magnetic.advisory_B_max_T = [];
cfg.magnetic.advisory_G_max_Tpm = [];
cfg.magnetic.minimum_force_scale_N = 1e-9;
cfg.magnetic.minimum_moment_scale_Nm = 1e-9;

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
