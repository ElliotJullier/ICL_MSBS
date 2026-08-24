function cfg = case_sc20714_chordmag_a16_t10_h()
% case_sc20714_chordmag_a16_t10_h
% NASA SC(2)-0714, AoA=16 deg, chordmag, 1.0 m horizontal tunnel.
%
% One case file = one fixed physical configuration. Speed remains a scenario-row parameter.
% Positive physical AoA is represented by software pitch_deg = -AoA.

cfg.meta.case_id = "sc20714_chordmag_a16_t10_h";
cfg.meta.description = "NASA SC(2)-0714, AoA=16 deg, chordmag, 1.0 m horizontal tunnel.";

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
% (16 deg) gives exactly 10% projected blockage.
cfg.geometry.type = "custom";
cfg.geometry.sizing.mode = "absolute";
cfg.geometry.sizing.custom.outer_dimensions_m = [0.285058593;0.8551757789;0.03990820302];
cfg.geometry.sizing.custom.projected_area_m2 = 0.1;
cfg.geometry.sizing.custom.reference_area_m2 = 0.2437752043;
cfg.geometry.sizing.custom.reference_length_m = 0.285058593;
cfg.geometry.sizing.custom.volume_m3 = 0.006601570589;
cfg.geometry.sizing.custom.inscribed_cuboid_dimensions_m = [0.1425292965;0.1282763668;0.02594033196];
cfg.geometry.sizing.custom.inscribed_cuboid_centre_m = [0;0;0];
cfg.geometry.aero_reference_area.mode = "manual";
cfg.geometry.aero_reference_area.value_m2 = 0.2437752043;
cfg.geometry.aero_reference_length.mode = "manual";
cfg.geometry.aero_reference_length.value_m = 0.285058593;
cfg.geometry.aero_reference_span.mode = "manual";
cfg.geometry.aero_reference_span.value_m = 0.8551757789;
cfg.geometry.aero_reference_point_B_m = [-0.07126464824;0;0];

%% Magnet
cfg.magnets.mode = "manual_sets";
cfg.magnets.remanence_selection = "minimum";
cfg.magnets.check_containment = true;
m1.name = "chordmag_a16";
m1.dimensions_local_m = [0.1282763668;0.1026210935;0.009977050754];
m1.centre_B_m = [0;0;0];
m1.R_BM = [1 0 0; 0 1 0; 0 0 1];
m1.grade = "N52";
m1.magnetisation_direction_M = [1;0;0];
m1.effective_magnetisation_factor = 1.0;
m1.dipole_moment_override_Am2 = [];
m1.density_override_kgm3 = [];
cfg.magnets.sets(1).name = "chordmag_a16";
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

% Coefficients are plot-read from the lowest-Re experimental curve in NASA TM-81912,
% Re=2.0e6, M=0.15, fixed transition, Fig. 11. They are intentionally used as a
% conservative measured load envelope at the lower MSBS model Reynolds numbers.

cfg.scenarios = table( ...
    ["U10_a16";"U25_a16"], ...
    [10;25], ...
    [0.043;0.043], ...
    zeros(2,1), ...
    [1.84;1.84], ...
    zeros(2,1), ...
    [-0.067;-0.067], ...
    zeros(2,1), ...
    zeros(2,1), ...
    -16*ones(2,1), ...
    zeros(2,1), ...
    [192998.3703;482495.9258], ...
    ["NASA_TM81912_Fig11_Re2e6_M015_fixed_a16";"NASA_TM81912_Fig11_Re2e6_M015_fixed_a16"], ...
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
