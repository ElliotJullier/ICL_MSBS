function cfg = case_naca0012_chordmag_a12_t10_h()
% case_naca0012_chordmag_a12_t10_h
% NACA 0012, AoA=12 deg, chordmag, 1.0 m horizontal tunnel.
%
% One case file = one fixed physical configuration. Speed remains a scenario-row parameter.
% Positive physical AoA is represented by software pitch_deg = -AoA.

cfg.meta.case_id = "naca0012_chordmag_a12_t10_h";
cfg.meta.description = "NACA 0012, AoA=12 deg, chordmag, 1.0 m horizontal tunnel.";

%% Tunnel
cfg.tunnel.cross_section.type = "rectangular";
cfg.tunnel.cross_section.width_m = 1;
cfg.tunnel.cross_section.height_m = 1;
cfg.tunnel.speed_mps = 10;
cfg.tunnel.air.mode = "density";
cfg.tunnel.air.rho_kgm3 = 1.225;

%% Frames
cfg.frames.tunnel_to_earth.sequence = "ZYX";
cfg.frames.tunnel_to_earth.yaw_pitch_roll_deg = [0 0 0];
cfg.frames.body_to_tunnel.sequence = "ZYX";
cfg.frames.body_to_tunnel.yaw_pitch_roll_deg = [0 0 0];
cfg.frames.body_origin_T_m = [0;0;0];
% +x_T = +x_E downstream; +z_T = +z_E upward.

%% Geometry
% AR=3 is retained from the previous airfoil portfolio.
% The common geometry for this airfoil/tunnel is sized so the highest selected AoA
% (12 deg) gives exactly 10% projected blockage.
cfg.geometry.type = "custom";
cfg.geometry.sizing.mode = "absolute";
cfg.geometry.sizing.custom.outer_dimensions_m = [0.3201138134;0.9603414401;0.0384136576];
cfg.geometry.sizing.custom.projected_area_m2 = 0.1;
cfg.geometry.sizing.custom.reference_area_m2 = 0.3074185605;
cfg.geometry.sizing.custom.reference_length_m = 0.3201138134;
cfg.geometry.sizing.custom.volume_m3 = 0.008069532073;
cfg.geometry.sizing.custom.inscribed_cuboid_dimensions_m = [0.1600569067;0.144051216;0.02496887744];
cfg.geometry.sizing.custom.inscribed_cuboid_centre_m = [0;0;0];
cfg.geometry.aero_reference_area.mode = "manual";
cfg.geometry.aero_reference_area.value_m2 = 0.3074185605;
cfg.geometry.aero_reference_length.mode = "manual";
cfg.geometry.aero_reference_length.value_m = 0.3201138134;
cfg.geometry.aero_reference_span.mode = "manual";
cfg.geometry.aero_reference_span.value_m = 0.9603414401;
cfg.geometry.aero_reference_point_B_m = [-0.08002845334;0;0];

%% Magnet
cfg.magnets.mode = "manual_sets";
cfg.magnets.remanence_selection = "minimum";
cfg.magnets.check_containment = true;
m1.name = "chordmag_a12";
m1.dimensions_local_m = [0.144051216;0.1152409728;0.009603414401];
m1.centre_B_m = [0;0;0];
m1.R_BM = [1 0 0; 0 1 0; 0 0 1];
m1.grade = "N52";
m1.magnetisation_direction_M = [1;0;0];
m1.effective_magnetisation_factor = 1.0;
m1.dipole_moment_override_Am2 = [];
m1.density_override_kgm3 = [];
cfg.magnets.sets(1).name = "chordmag_a12";
cfg.magnets.sets(1).magnets = m1;
% Magnet local +x/magnetisation is aligned with the body chord.

%% Mass
cfg.mass.shell_mass_factor = 1.30;
cfg.mass.total_mass_override_kg = [];
cfg.mass.centre_of_mass_override_B_m = [];
cfg.mass.inertia_override_B_kgm2 = [];

%% Aerodynamics
cfg.aero.mode = "coefficients";
cfg.aero.CD = 0;
cfg.aero.CY = 0;
cfg.aero.CL = 0;
cfg.aero.Cl_roll = 0;
cfg.aero.Cm = 0;
cfg.aero.Cn = 0;

% At 12 deg, CL is read/interpolated from the Reynolds-dependent reference LCM curves
% reproduced in Oruganti & Narsipur Fig. 17. This is exact/near stall depending on Re:
% LCM stall is about 11 deg at Re=170k/330k and 12 deg at Re=500k/550k.
% CD=0.053 is an engineering continuation of the Vaddi passive drag trend; Cm=0 is
% an explicit symmetric-airfoil screening assumption because the low-Re stall source has no Cm.

cfg.scenarios = table( ...
    ["U10_a12";"U25_a12"], ...
    [10;25], ...
    [0.053;0.053], ...
    zeros(2,1), ...
    [0.8316831099;1.031831099], ...
    zeros(2,1), ...
    [0;0], ...
    zeros(2,1), ...
    zeros(2,1), ...
    -12*ones(2,1), ...
    zeros(2,1), ...
    [216732.4397;541831.0991], ...
    ["Oruganti_Fig17_LCM_a12_interp_Re170_330k";"Oruganti_Fig17_LCM_a12_interp_Re500_550k"], ...
    'VariableNames',{'scenario_name','speed_mps','CD','CY','CL','Cl_roll','Cm','Cn', ...
                      'yaw_deg','pitch_deg','roll_deg','Re','source_id'});

cfg.motion.mode = "none";
cfg.additional_wrenches = table();
cfg.max_scenarios = 4096;

%% Magnetic solve
cfg.magnetic.model = "source_free_first_order";
cfg.magnetic.field_scale_T = 0.10;
cfg.magnetic.gradient_scale_Tpm = 1.0;
cfg.magnetic.acceptance_relative_residual = 1e-6;
cfg.magnetic.condition_warning_threshold = 1e10;
cfg.magnetic.advisory_B_max_T = [];
cfg.magnetic.advisory_G_max_Tpm = [];
cfg.magnetic.minimum_force_scale_N = 1e-9;
cfg.magnetic.minimum_moment_scale_Nm = 1e-9;

%% Output
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
