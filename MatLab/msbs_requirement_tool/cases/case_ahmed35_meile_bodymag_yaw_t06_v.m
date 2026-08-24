function cfg = case_ahmed35_meile_bodymag_yaw_t06_v()
%CASE_AHMED35_MEILE_BODYMAG_YAW_T06_V MSBS aerodynamic requirement study.
% Requirement-tool v0.3.0 syntax. One scenario row = one simultaneous physical state.
% Aerodynamic source: Meile et al. (2016), 35 deg rear slant, Figs. 18 and 20.
% Coefficients below are graph-digitised engineering values at U_inf=30 m/s; use for load sizing, not precision reproduction.
% Meile moments are supplied about the force-balance origin on the test-section floor between the stilts.
% This case passes that source point explicitly; the tool shifts the complete aerodynamic wrench to its calculated CoM.

cfg.meta.case_id = "ahmed35_meile_bodymag_yaw_t06_v";
cfg.meta.description = "35 deg Ahmed body, Meile beta=0/15 deg loads, magnet aligned +x_B, 0.6 m tunnel.";

cfg.tunnel.cross_section.type = "rectangular";
cfg.tunnel.cross_section.width_m = 0.6;
cfg.tunnel.cross_section.height_m = 0.6;
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
cfg.geometry.sizing.custom.outer_dimensions_m = [0.45925649225;0.171121432457;0.126691446138];
cfg.geometry.sizing.custom.projected_area_m2 = 0.0216796217432; % head-on geometric frontal area
cfg.geometry.sizing.custom.reference_area_m2 = 0.0216734293348; % Meile A_ref=0.112 m^2 scaled by s^2
cfg.geometry.sizing.custom.reference_length_m = 0.45925649225;
cfg.geometry.sizing.custom.volume_m3 = 0.00856259605015; % legacy Ahmed custom-proxy volume; not exact CAD volume
cfg.geometry.sizing.custom.inscribed_cuboid_dimensions_m = [0.317608417054;0.171121432457;0.126691446138];
cfg.geometry.sizing.custom.inscribed_cuboid_centre_m = [-0.0268339521334;0;0];
cfg.geometry.aero_reference_area.mode = "manual";
cfg.geometry.aero_reference_area.value_m2 = 0.0216734293348;
cfg.geometry.aero_reference_length.mode = "manual";
cfg.geometry.aero_reference_length.value_m = 0.206753401683; % Meile pitch/yaw moment reference = 0.470 m scaled
cfg.geometry.aero_reference_span.mode = "manual";
cfg.geometry.aero_reference_span.value_m = 0.143847579469; % Meile roll moment reference = 0.327 m scaled
cfg.geometry.aero_reference_point_B_m = [-0.0373915726448;0;-0.0853407658012];
% Standard-geometry scale s=0.439900855. Ground clearance corresponding to Meile is 0.021995043 m (aerodynamic/fake-floor requirement, not explicitly modelled).
% Head-on blockage = 0.060221; conservative bounding-silhouette blockage at beta=15 deg = 0.100000.
% The supplied inscribed cuboid is the constant full-section prism from x=100 mm (front-radius tangency) to x=822 mm (rear-slant start) in the source geometry.

cfg.magnets.mode = "automatic";
cfg.magnets.remanence_selection = "minimum";
cfg.magnets.check_containment = true;
cfg.magnets.automatic.grade = "N52";
cfg.magnets.automatic.linear_shrink_fraction = 0.0;
cfg.magnets.automatic.centre_offset_B_m = [0;0;0];
cfg.magnets.automatic.effective_magnetisation_factor = 1.0;
cfg.magnets.automatic.direction_candidates_B = [1;0;0]; % local-body x magnet only
cfg.magnets.automatic.dipole_moment_override_Am2 = [];

cfg.mass.shell_mass_factor = 1.30;
cfg.mass.total_mass_override_kg = [];
cfg.mass.centre_of_mass_override_B_m = [];
cfg.mass.inertia_override_B_kgm2 = [];
% The default hybrid mass model computes a CoM from the offset magnet plus the distributed shell proxy. For a final model, override CoM and inertia with designed/measured values.

cfg.aero.mode = "direct_wrench";
cfg.aero.direct_wrench_frame = "B";
% IMPORTANT: direct B-frame wrench is used because Meile transforms the measured wind-fixed loads into the model-fixed frame.
% Do NOT pre-shift the moment to the CoM here; aero_reference_point_B_m tells the tool where Meile defined the moment.

speeds = [10 25 40].';
rho = 1.225;
Sref = 0.0216734293348;
lroll = 0.143847579469;
lpy = 0.206753401683;
P_B = [-0.0373915726448;0;-0.0853407658012];
C0=[0.29 0 0 0 0.08 0];
C15=[0.43 0.81 0.57 0.53 -0.17 0.26];
nU=numel(speeds); n=2*nU;
names=strings(n,1); U=zeros(n,1); Fx=zeros(n,1); Fy=zeros(n,1); Fz=zeros(n,1); Mx=zeros(n,1); My=zeros(n,1); Mz=zeros(n,1); yaw=zeros(n,1); Re_L=zeros(n,1); beta_deg=zeros(n,1);
for k=1:nU
    for j=1:2
        ii=2*(k-1)+j; C=C0; b=0; if j==2, C=C15; b=15; end
        q=0.5*rho*speeds(k)^2; U(ii)=speeds(k); yaw(ii)=b; beta_deg(ii)=b;
        names(ii)="U"+string(speeds(k))+"_beta"+compose("%02d",b)+"_bodymag";
        Fx(ii)=q*Sref*C(1); Fy(ii)=q*Sref*C(2); Fz(ii)=q*Sref*C(3);
        Mx(ii)=q*Sref*lroll*C(4); My(ii)=q*Sref*lpy*C(5); Mz(ii)=q*Sref*lpy*C(6);
        Re_L(ii)=speeds(k)*0.45925649225/1.5e-05;
    end
end
refs=repmat({P_B},n,1);
cfg.scenarios = table(names,U,Fx,Fy,Fz,Mx,My,Mz,repmat("B",n,1),refs,yaw,zeros(n,1),zeros(n,1),Re_L,beta_deg, ...
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
