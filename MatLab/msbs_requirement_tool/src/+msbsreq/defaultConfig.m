function cfg = defaultConfig()
%DEFAULTCONFIG Return the complete documented default configuration.

cfg = struct();

cfg.meta.case_id = "unnamed_case";
cfg.meta.description = "MSBS requirement study";

cfg.tunnel.cross_section.type = "rectangular";
cfg.tunnel.cross_section.width_m = 0.60;
cfg.tunnel.cross_section.height_m = 0.60;
cfg.tunnel.cross_section.diameter_m = [];
cfg.tunnel.speed_mps = 0;
cfg.tunnel.air.mode = "density";
cfg.tunnel.air.rho_kgm3 = 1.225;
cfg.tunnel.air.pressure_Pa = 101325;
cfg.tunnel.air.temperature_K = 288.15;
cfg.tunnel.air.R_air_JpkgK = 287.05;

cfg.frames.tunnel_to_earth.sequence = "ZYX";
cfg.frames.tunnel_to_earth.yaw_pitch_roll_deg = [0 0 0];
cfg.frames.body_to_tunnel.sequence = "ZYX";
cfg.frames.body_to_tunnel.yaw_pitch_roll_deg = [0 0 0];
cfg.frames.body_origin_T_m = [0;0;0];

cfg.geometry.type = "sphere";
cfg.geometry.sizing.mode = "blockage";
cfg.geometry.sizing.blockage_ratio = 0.10;
cfg.geometry.sizing.nominal_dimensions_m = [1;1;1];
cfg.geometry.sizing.diameter_m = [];
cfg.geometry.sizing.radius_m = [];
cfg.geometry.sizing.ellipsoid_diameters_m = [];
cfg.geometry.sizing.cylinder_diameter_m = [];
cfg.geometry.sizing.cylinder_length_m = [];
cfg.geometry.sizing.cylinder_axis = "x";
cfg.geometry.sizing.cylinder_length_to_diameter = 2.0;
cfg.geometry.sizing.plate_dimensions_m = [];
cfg.geometry.sizing.plate_normalised_dimensions = [1;1;0.05];
cfg.geometry.sizing.custom = struct();
cfg.geometry.aero_reference_area.mode = "projected_nominal";
cfg.geometry.aero_reference_area.value_m2 = [];
cfg.geometry.aero_reference_length.mode = "characteristic_default";
cfg.geometry.aero_reference_length.value_m = [];
cfg.geometry.aero_reference_span.mode = "characteristic_default";
cfg.geometry.aero_reference_span.value_m = [];
cfg.geometry.aero_reference_point_B_m = [0;0;0];
cfg.geometry.custom_plot_vertices_B_m = [];
cfg.geometry.custom_plot_faces = [];

cfg.magnets.mode = "automatic";
cfg.magnets.remanence_selection = "nominal";
cfg.magnets.manual_Br_T = [];
cfg.magnets.check_containment = true;
cfg.magnets.automatic.grade = "N52";
cfg.magnets.automatic.linear_shrink_fraction = 0.0;
cfg.magnets.automatic.centre_offset_B_m = [0;0;0];
cfg.magnets.automatic.effective_magnetisation_factor = 1.0;
cfg.magnets.automatic.direction_candidates_B = eye(3);
cfg.magnets.automatic.dipole_moment_override_Am2 = [];
cfg.magnets.sets = struct([]);

cfg.mass.shell_mass_factor = 1.30;
cfg.mass.non_magnet_mass_kg = []; % Fixed residual mass for magnet-size comparisons.
cfg.mass.solid_abs_density_kgm3 = []; % Full body with disjoint magnet cavities, when supplied.
cfg.mass.total_mass_override_kg = [];
cfg.mass.centre_of_mass_override_B_m = [];
cfg.mass.inertia_override_B_kgm2 = [];

% Aerodynamic source. Coefficients are defined in the tunnel/wind-aligned axes.
cfg.aero.mode = "coefficients";
cfg.aero.CD = 0;
cfg.aero.CY = 0;
cfg.aero.CL = 0;
cfg.aero.Cl_roll = 0;
cfg.aero.Cm = 0;
cfg.aero.Cn = 0;
cfg.aero.direct_wrench_frame = "T";

% One table row is one simultaneous physical state. Empty means one nominal
% static row, except harmonic motion where samples_per_cycle rows are generated.
cfg.scenarios = table();
cfg.max_scenarios = 4096;
cfg.scenario_set.relationship = "fixed_envelope";
% Absolute CoM coordinates in T, independent of plotting body_origin_T_m.
cfg.position.mode = "nominal"; % nominal | specified | harmonic_analytic
cfg.position.reference_C_T_m = [0;0;0];

% Motion is either absent, explicitly specified in cfg.scenarios, or generated
% from a small-angle single-frequency harmonic definition.
cfg.motion.mode = "none";
cfg.motion.frame = "T";
cfg.motion.harmonic.frequency_Hz = 1.0;
cfg.motion.harmonic.translation_amplitude_m = [0;0;0];
cfg.motion.harmonic.translation_phase_rad = [0;0;0];
cfg.motion.harmonic.angular_amplitude_rad = [0;0;0];
cfg.motion.harmonic.angular_phase_rad = [0;0;0];
cfg.motion.harmonic.samples_per_cycle = 72;

cfg.additional_wrenches = table();

cfg.magnetic.model = "source_free_first_order";
cfg.magnetic.cost.primary_mode = "model_characteristic_cube_rms";
cfg.magnetic.cost.sensitivity_when_significant = true;
cfg.magnetic.cost.sensitivity_relative_length_scales_m = [0.01 0.10 1.0 10.0];
cfg.magnetic.cost.sensitivity_tunnel_length_fractions = [0.20 0.50];
cfg.magnetic.coupling.zero_ratio_tolerance = 1e-10;
cfg.magnetic.coupling.insignificant_ratio = 1/50;
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
