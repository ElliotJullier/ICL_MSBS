function cfg = case_sphere_drag_crisis_t06_h_smallMagnet()

%CASE_SPHERE_DRAG_CRISIS_T06_H_CUBE40P8 MSBS aerodynamic requirement study.
%
% Smooth 10% blockage sphere drag-crisis screen in a 0.6 m horizontal
% tunnel. Uses three explicit manual magnet sets. Each set contains one
% centred 40.8 mm N52 cube magnet, magnetised along +x_B, +y_B or +z_B.

cfg.meta.case_id = "sphere_drag_crisis_t06_h_smallMagnet";
cfg.meta.description = "Smooth 5% blockage sphere drag-crisis screen in 0.6 m tunnel, horizontal; centred 34.4 mm cube magnet with x/y/z magnetisation sets.";

%% Tunnel
cfg.tunnel.cross_section.type = "rectangular";
cfg.tunnel.cross_section.width_m = 0.60;
cfg.tunnel.cross_section.height_m = 0.60;
cfg.tunnel.speed_mps = 25.53512;

cfg.tunnel.air.mode = "density";
cfg.tunnel.air.rho_kgm3 = 1.225;

%% Frames
cfg.frames.tunnel_to_earth.sequence = "ZYX";
cfg.frames.tunnel_to_earth.yaw_pitch_roll_deg = [0 0 0];

cfg.frames.body_to_tunnel.sequence = "ZYX";
cfg.frames.body_to_tunnel.yaw_pitch_roll_deg = [0 0 0];

cfg.frames.body_origin_T_m = [0;0;0];

% Horizontal tunnel: +x_T = +x_E downstream, +z_T = +z_E upward.

%% Geometry
cfg.geometry.type = "sphere";

cfg.geometry.sizing.mode = "blockage";
cfg.geometry.sizing.blockage_ratio = 0.05;

cfg.geometry.aero_reference_area.mode = "projected_nominal";
cfg.geometry.aero_reference_length.mode = "characteristic_default";
cfg.geometry.aero_reference_span.mode = "characteristic_default";
cfg.geometry.aero_reference_point_B_m = [0;0;0];

% Resolved sphere diameter is approximately 0.2141 m.

%% Magnets
% Three explicit manual sets, analogous to automatic eye(3) candidates.
% Each set contains the same 40.8 mm cube centred at the body origin.

cfg.magnets.mode = "manual_sets";
cfg.magnets.remanence_selection = "minimum";
cfg.magnets.check_containment = true;

% Common cube definition.
m_base.name = "cube_40p8mm";
m_base.dimensions_local_m = [0.0315;0.0315;0.0315];
m_base.centre_B_m = [0;0;0];
m_base.R_BM = eye(3);
m_base.grade = "N52";
m_base.effective_magnetisation_factor = 1.0;
m_base.dipole_moment_override_Am2 = [];
m_base.density_override_kgm3 = [];

% Set 1: magnetisation along +x_B.
m_x = m_base;
m_x.name = "cube_40p8mm_x";
m_x.magnetisation_direction_M = [1;0;0];

cfg.magnets.sets(1).name = "cube_40p8mm_x";
cfg.magnets.sets(1).magnets = m_x;

% Set 2: magnetisation along +y_B.
m_y = m_base;
m_y.name = "cube_40p8mm_y";
m_y.magnetisation_direction_M = [0;1;0];

cfg.magnets.sets(2).name = "cube_40p8mm_y";
cfg.magnets.sets(2).magnets = m_y;

% Set 3: magnetisation along +z_B.
m_z = m_base;
m_z.name = "cube_40p8mm_z";
m_z.magnetisation_direction_M = [0;0;1];

cfg.magnets.sets(3).name = "cube_40p8mm_z";
cfg.magnets.sets(3).magnets = m_z;

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

% Approximate smooth-sphere drag-crisis points read from
% Achenbach (1972), Figure 4.

cfg.scenarios = table( ...
    ["Re150k";"Re250k";"Re370k";"Re500k";"Re600k"], ...
    [14.64;24.4001;36.1121;48.8002;58.5602], ...
    [0.51;0.50;0.07;0.08;0.085], ...
    [150000;250000;370000;500000;600000], ...
    repmat("Achenbach_1972_Fig4_approx",5,1), ...
    'VariableNames',{'scenario_name','speed_mps','CD','Re','source_id'});

%% Motion and additional loads
cfg.motion.mode = "none";

cfg.additional_wrenches = table();
cfg.max_scenarios = 4096;

%% Magnetic model and cost settings — v0.4.1
cfg.magnetic.model = "source_free_first_order";

cfg.magnetic.cost.primary_mode = "model_characteristic_cube_rms";
cfg.magnetic.cost.sensitivity_when_significant = true;
cfg.magnetic.cost.sensitivity_relative_length_scales_m = [0.01 0.10 1 10];
cfg.magnetic.cost.sensitivity_tunnel_length_fractions = [0.20 0.50];

cfg.magnetic.coupling.zero_ratio_tolerance = 1e-10;
cfg.magnetic.coupling.insignificant_ratio = 1/50;

cfg.magnetic.acceptance_relative_residual = 1e-6;
cfg.magnetic.condition_warning_threshold = 1e10;

cfg.magnetic.advisory_B_max_T = [];
cfg.magnetic.advisory_G_max_Tpm = [];

cfg.magnetic.minimum_force_scale_N = 1e-9;
cfg.magnetic.minimum_moment_scale_Nm = 1e-9;

%% Validation
cfg.validation.rotation_tolerance = 1e-10;
cfg.validation.gradient_tolerance = 1e-10;
cfg.validation.blockage_advisory_limit = 0.15;

%% Visualisation
cfg.visualisation.enable = true;
cfg.visualisation.plot_worst_case = true;
cfg.visualisation.vector_scale_mode = "normalised";
cfg.visualisation.save_magnetic_field_plot = true;

%% Output
cfg.output.enable = true;
cfg.output.root_folder = "results";
cfg.output.save_fig = false;
cfg.output.overwrite_existing = false;

end
