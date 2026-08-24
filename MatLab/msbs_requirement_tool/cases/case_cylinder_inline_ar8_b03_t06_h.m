function cfg = case_cylinder_inline_ar8_b03_t06_h()
%CASE_CYLINDER_INLINE_AR8_B03_T06_H Low-speed controlled-cylinder MSBS requirement case.
%
% Geometry:
%   Circular cylinder, axis +y_B, L/D = 8.
%   Nominal projected blockage = 3%.
%   Quasi-2D end condition: two fixed non-contact endplates, g/D = 0.04.
%
% Motion:
%   prescribed in-line translation in +x_T
%
% Aerodynamic intent:
%   Cover distinct wake organisations rather than impose one common KC.
%   Cross-flow uses (A/D, lambda*) wake-map states.
%   In-line uses Nishihara et al. A/D=0.05 reduced-velocity states.
%
% Load fidelity:
%   Aerodynamic coefficients are order-of-magnitude correlated screening loads.
%   They are deliberately source-labelled. No separate added-mass term is added.
%
% Magnet:
%   Largest centred cuboid permitted by both cylinder containment and
%   a 15%-of-tunnel dimension cap. +x_B, +y_B and +z_B magnetisation
%   are compared as separate manual magnet sets.
%
% Mass:
%   Screening total model mass = 1.5 times summed magnet mass.

cfg.meta.case_id = "case_cylinder_inline_ar8_b03_t06_h";
cfg.meta.description = "AR=8 prescribed in-line translation in +x_T, blockage=0.03, T=0.6 m, h";
cfg.meta.aspect_ratio = 8;
cfg.meta.requested_blockage_ratio = 0.03;
cfg.meta.free_stream_speed_set_mps = [4 7];
cfg.meta.end_condition = "two_fixed_noncontact_endplates";
cfg.meta.endplate_gap_over_D = 0.04;
cfg.meta.magnet_dimension_cap_over_tunnel = 0.15;
cfg.meta.model_mass_over_magnet_mass = 1.5;
cfg.meta.added_mass_treatment = "no_separate_term; negligible_for_MSBS_sizing; source_total_fluid_force_used_where_available";

%% Tunnel
cfg.tunnel.cross_section.type = "rectangular";
cfg.tunnel.cross_section.width_m = 0.6;
cfg.tunnel.cross_section.height_m = 0.6;
cfg.tunnel.speed_mps = 4; % fallback; scenario speed_mps is authoritative
cfg.tunnel.air.mode = "density";
cfg.tunnel.air.rho_kgm3 = 1.225;

%% Frames
cfg.frames.tunnel_to_earth.sequence = "ZYX";
cfg.frames.tunnel_to_earth.yaw_pitch_roll_deg = [0 0 0];
cfg.frames.body_to_tunnel.sequence = "ZYX";
cfg.frames.body_to_tunnel.yaw_pitch_roll_deg = [0 0 0];
cfg.frames.body_origin_T_m = [0;0;0];
% Horizontal: +x_T=+x_E downstream, +y_T=+y_E, +z_T=+z_E.

%% Geometry
cfg.geometry.type = "cylinder";
cfg.geometry.sizing.mode = "absolute";
cfg.geometry.sizing.cylinder_diameter_m = 0.03674234614174767;
cfg.geometry.sizing.cylinder_length_m = 0.2939387691339814;
cfg.geometry.sizing.cylinder_axis = "y";
cfg.geometry.aero_reference_area.mode = "manual";
cfg.geometry.aero_reference_area.value_m2 = 0.0108;
cfg.geometry.aero_reference_length.mode = "manual";
cfg.geometry.aero_reference_length.value_m = 0.03674234614174767;
cfg.geometry.aero_reference_span.mode = "manual";
cfg.geometry.aero_reference_span.value_m = 0.2939387691339814;
cfg.geometry.aero_reference_point_B_m = [0;0;0];

D = cfg.geometry.sizing.cylinder_diameter_m;
L = cfg.geometry.sizing.cylinder_length_m;
S = cfg.geometry.aero_reference_area.value_m2;

%% Manual magnet sets
cfg.magnets.mode = "manual_sets";
cfg.magnets.remanence_selection = "minimum";
cfg.magnets.check_containment = true;

m0.name = "central_N52";
m0.dimensions_local_m = [0.0246817240078565; 0.09; 0.0246817240078565];
m0.centre_B_m = [0;0;0];
m0.R_BM = eye(3);
m0.grade = "N52";
m0.effective_magnetisation_factor = 1.0;
m0.dipole_moment_override_Am2 = [];
m0.density_override_kgm3 = [];

mxB = m0;
mxB.name = "central_N52_mag_xB";
mxB.magnetisation_direction_M = [1;0;0];
cfg.magnets.sets(1).name = "mag_xB";
cfg.magnets.sets(1).magnets = mxB;

myB = m0;
myB.name = "central_N52_mag_yB";
myB.magnetisation_direction_M = [0;1;0];
cfg.magnets.sets(2).name = "mag_yB";
cfg.magnets.sets(2).magnets = myB;

mzB = m0;
mzB.name = "central_N52_mag_zB";
mzB.magnetisation_direction_M = [0;0;1];
cfg.magnets.sets(3).name = "mag_zB";
cfg.magnets.sets(3).magnets = mzB;

%% Mass
cfg.mass.shell_mass_factor = 1.5;
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

%% Scenario constants
rho_air_kgm3 = cfg.tunnel.air.rho_kgm3;
nu_air_m2ps = 1.5e-05; % metadata only
phase = (0:71)'*(2*pi/72);
speeds = [4 7];

% Nishihara et al. forced-streamwise states.
% A/D = 0.05 exactly. Vr = U/(fD) = lambda*.
% CD_mean, |CD_unsteady| and phase are approximate graph reads from Figs. 8-9.
state_def = {
    "symmetric_first_excitation", 1.7, 0.95, 1.05, 5;
    "mixed_competition", 2.2, 1.27, 0.5, 20;
    "organised_alternate", 2.7, 1.45, 0.25, 0;
    "second_excitation", 3.5, 1.2, 0.12, 35;
    "stationary_like", 5, 1.03, 0.1, -90
};

A_over_D = 0.05;
A = A_over_D*D;
rows = table();

for iu = 1:numel(speeds)
    U_free = speeds(iu);
    Re_free = U_free*D/nu_air_m2ps;

    for is = 1:size(state_def,1)
        wake_state = string(state_def{is,1});
        Vr = state_def{is,2};
        CD_mean = state_def{is,3};
        CD_amp = state_def{is,4};
        drag_phase_deg = state_def{is,5};

        f_body = U_free/(Vr*D);
        omega = 2*pi*f_body;

        x = A*sin(phase);
        vx = A*omega*cos(phase);
        ax = -A*omega^2*sin(phase);

        % Measured total fluid drag represented as mean + synchronous harmonic.
        % This includes whatever apparent/added-mass contribution exists in the
        % source measurement; no separate added-mass term is added.
        CD = CD_mean + CD_amp*sin(phase + deg2rad(drag_phase_deg));

        n = numel(phase);
        scenario_name = strings(n,1);
        for ip = 1:n
            scenario_name(ip) = "U"+string(U_free)+"_"+wake_state+"_p"+compose("%02d",ip-1);
        end

        source_id = repmat("Nishihara2005_Fig8_Fig9_approx",n,1);
        aero_note = repmat("mean + synchronous unsteady drag; source graph-read order-of-magnitude representation",n,1);

        one = table( ...
            scenario_name, repmat(U_free,n,1), ...
            CD, zeros(n,1), zeros(n,1), zeros(n,1), zeros(n,1), zeros(n,1), ...
            zeros(n,1), zeros(n,1), zeros(n,1), ...
            ax, zeros(n,1), zeros(n,1), ...
            zeros(n,1), zeros(n,1), zeros(n,1), ...
            zeros(n,1), zeros(n,1), zeros(n,1), ...
            repmat(Re_free,n,1), repmat(A_over_D,n,1), repmat(Vr,n,1), ...
            repmat(A,n,1), repmat(f_body,n,1), ...
            repmat(CD_mean,n,1), repmat(CD_amp,n,1), repmat(drag_phase_deg,n,1), ...
            repmat(wake_state,n,1), phase, x, zeros(n,1), vx, zeros(n,1), ...
            source_id, aero_note, ...
            'VariableNames',{ ...
            'scenario_name','speed_mps', ...
            'CD','CY','CL','Cl_roll','Cm','Cn', ...
            'yaw_deg','pitch_deg','roll_deg', ...
            'a_x','a_y','a_z','omega_x','omega_y','omega_z','alpha_x','alpha_y','alpha_z', ...
            'Re_free_stream','A_over_D','lambda_star','amplitude_m','body_frequency_Hz', ...
            'CD_mean_source','CD_unsteady_peak_source','drag_phase_deg_source', ...
            'wake_state','phase_rad','position_x_m','position_z_m','velocity_x_mps','velocity_z_mps', ...
            'source_id','aero_model_note'});

        rows = [rows; one]; %#ok<AGROW>
    end
end

cfg.scenarios = rows;

cfg.motion.mode = "specified";
cfg.motion.frame = "T";
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

%% Validation / output
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
