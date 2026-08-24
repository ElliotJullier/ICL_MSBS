function cfg = case_sphere_drag_crisis_t10_h()
%CASE_SPHERE_DRAG_CRISIS_T10_H MSBS aerodynamic requirement study.
% Generated for requirement-tool v0.3.0. One scenario row = one physical state.
% Smooth 10% blockage sphere drag-crisis screen in 1.0 m tunnel, horizontal.

cfg.meta.case_id = "sphere_drag_crisis_t10_h";
cfg.meta.description = "Smooth 10% blockage sphere drag-crisis screen in 1.0 m tunnel, horizontal.";

cfg.tunnel.cross_section.type = "rectangular";
cfg.tunnel.cross_section.width_m = 1.00;
cfg.tunnel.cross_section.height_m = 1.00;
cfg.tunnel.speed_mps = 15.321072;
cfg.tunnel.air.mode = "density";
cfg.tunnel.air.rho_kgm3 = 1.225;

cfg.frames.tunnel_to_earth.sequence = "ZYX";
cfg.frames.tunnel_to_earth.yaw_pitch_roll_deg = [0 0 0];
cfg.frames.body_to_tunnel.sequence = "ZYX";
cfg.frames.body_to_tunnel.yaw_pitch_roll_deg = [0 0 0];
cfg.frames.body_origin_T_m = [0;0;0];
% Horizontal tunnel: +x_T = +x_E downstream, +z_T = +z_E upward.

cfg.geometry.type = "sphere";
cfg.geometry.sizing.mode = "blockage";
cfg.geometry.sizing.blockage_ratio = 0.10;
cfg.geometry.aero_reference_area.mode = "projected_nominal";
cfg.geometry.aero_reference_length.mode = "characteristic_default";
cfg.geometry.aero_reference_span.mode = "characteristic_default";
cfg.geometry.aero_reference_point_B_m = [0;0;0];
% Resolved sphere diameter is approximately 0.3568 m.

cfg.magnets.mode = "automatic";
cfg.magnets.remanence_selection = "minimum";
cfg.magnets.check_containment = true;
cfg.magnets.automatic.grade = "N52";
cfg.magnets.automatic.linear_shrink_fraction = 0.0;
cfg.magnets.automatic.centre_offset_B_m = [0;0;0];
cfg.magnets.automatic.effective_magnetisation_factor = 1.0;
cfg.magnets.automatic.direction_candidates_B = eye(3);
cfg.magnets.automatic.dipole_moment_override_Am2 = [];

cfg.mass.shell_mass_factor = 1.30;
cfg.mass.total_mass_override_kg = [];
cfg.mass.centre_of_mass_override_B_m = [];
cfg.mass.inertia_override_B_kgm2 = [];

cfg.aero.mode = "coefficients";
cfg.aero.CD = 0;
cfg.aero.CY = 0;
cfg.aero.CL = 0;
cfg.aero.Cl_roll = 0;
cfg.aero.Cm = 0;
cfg.aero.Cn = 0;

% Approximate smooth-sphere drag-crisis points read from Achenbach (1972), Figure 4.
cfg.scenarios = table( ...
    ["Re150k";"Re250k";"Re370k";"Re500k";"Re600k"], ...
    [6.211245368;10.35207561;15.32107191;20.70415123;24.84498147], ...
    [0.51;0.50;0.07;0.08;0.085], ...
    [150000;250000;370000;500000;600000], ...
    repmat("Achenbach_1972_Fig4_approx",5,1), ...
    'VariableNames',{'scenario_name','speed_mps','CD','Re','source_id'});

cfg.motion.mode = "none";
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
