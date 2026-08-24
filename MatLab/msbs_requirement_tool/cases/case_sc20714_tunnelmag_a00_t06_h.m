function cfg = case_sc20714_tunnelmag_a00_t06_h()
% case_sc20714_tunnelmag_a00_t06_h
% NASA SC(2)-0714, AoA=0 deg, tunnelmag, 0.6 m horizontal tunnel.
%
% One case file = one fixed physical configuration. Speed remains a scenario-row parameter.
% Positive physical AoA is represented by software pitch_deg = -AoA.

cfg.meta.case_id = "sc20714_tunnelmag_a00_t06_h";
cfg.meta.description = "NASA SC(2)-0714, AoA=0 deg, tunnelmag, 0.6 m horizontal tunnel.";

%% Tunnel
cfg.tunnel.cross_section.type = "rectangular";
cfg.tunnel.cross_section.width_m = 0.6;
cfg.tunnel.cross_section.height_m = 0.6;
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
cfg.geometry.sizing.custom.outer_dimensions_m = [0.1710351558;0.5131054673;0.02394492181];
cfg.geometry.sizing.custom.projected_area_m2 = 0.036;
cfg.geometry.sizing.custom.reference_area_m2 = 0.08775907354;
cfg.geometry.sizing.custom.reference_length_m = 0.1710351558;
cfg.geometry.sizing.custom.volume_m3 = 0.001425939247;
cfg.geometry.sizing.custom.inscribed_cuboid_dimensions_m = [0.08551757789;0.0769658201;0.01556419918];
cfg.geometry.sizing.custom.inscribed_cuboid_centre_m = [0;0;0];
cfg.geometry.aero_reference_area.mode = "manual";
cfg.geometry.aero_reference_area.value_m2 = 0.08775907354;
cfg.geometry.aero_reference_length.mode = "manual";
cfg.geometry.aero_reference_length.value_m = 0.1710351558;
cfg.geometry.aero_reference_span.mode = "manual";
cfg.geometry.aero_reference_span.value_m = 0.5131054673;
cfg.geometry.aero_reference_point_B_m = [-0.04275878895;0;0];

%% Magnet
cfg.magnets.mode = "manual_sets";
cfg.magnets.remanence_selection = "minimum";
cfg.magnets.check_containment = true;
m1.name = "tunnelmag_a00";
m1.dimensions_local_m = [0.0769658201;0.06157265608;0.005986230452];
m1.centre_B_m = [0;0;0];
m1.R_BM = [1 0 0; 0 1 0; 0 0 1];
m1.grade = "N52";
m1.magnetisation_direction_M = [1;0;0];
m1.effective_magnetisation_factor = 1.0;
m1.dipole_moment_override_Am2 = [];
m1.density_override_kgm3 = [];
cfg.magnets.sets(1).name = "tunnelmag_a00";
cfg.magnets.sets(1).magnets = m1;
% At 0 deg the tunnel- and chord-aligned arrangements are physically identical;
% this separate file is retained deliberately for a complete test matrix.

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
    ["U10_a00";"U25_a00";"U40_a00"], ...
    [10;25;40], ...
    [0.012;0.012;0.012], ...
    zeros(3,1), ...
    [0.5;0.5;0.5], ...
    zeros(3,1), ...
    [-0.115;-0.115;-0.115], ...
    zeros(3,1), ...
    zeros(3,1), ...
    -0*ones(3,1), ...
    zeros(3,1), ...
    [115799.0222;289497.5555;463196.0888], ...
    ["NASA_TM81912_Fig11_Re2e6_M015_fixed_a0";"NASA_TM81912_Fig11_Re2e6_M015_fixed_a0";"NASA_TM81912_Fig11_Re2e6_M015_fixed_a0"], ...
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
