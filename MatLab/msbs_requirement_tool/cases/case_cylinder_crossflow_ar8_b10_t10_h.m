function cfg = case_cylinder_crossflow_ar8_b10_t10_h()
%CASE_CYLINDER_CROSSFLOW_AR8_B10_T10_H Low-speed controlled-cylinder MSBS requirement case.
%
% Geometry:
%   Circular cylinder, axis +y_B, L/D = 8.
%   Nominal projected blockage = 10%.
%   Quasi-2D end condition: two fixed non-contact endplates, g/D = 0.04.
%
% Motion:
%   prescribed cross-flow translation in +z_T
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

cfg.meta.case_id = "case_cylinder_crossflow_ar8_b10_t10_h";
cfg.meta.description = "AR=8 prescribed cross-flow translation in +z_T, blockage=0.10, T=1.0 m, h";
cfg.meta.aspect_ratio = 8;
cfg.meta.requested_blockage_ratio = 0.1;
cfg.meta.free_stream_speed_set_mps = [2.5 7];
cfg.meta.end_condition = "two_fixed_noncontact_endplates";
cfg.meta.endplate_gap_over_D = 0.04;
cfg.meta.magnet_dimension_cap_over_tunnel = 0.15;
cfg.meta.model_mass_over_magnet_mass = 1.5;
cfg.meta.added_mass_treatment = "no_separate_term; negligible_for_MSBS_sizing; source_total_fluid_force_used_where_available";

%% Tunnel
cfg.tunnel.cross_section.type = "rectangular";
cfg.tunnel.cross_section.width_m = 1;
cfg.tunnel.cross_section.height_m = 1;
cfg.tunnel.speed_mps = 2.5; % fallback; scenario speed_mps is authoritative
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
cfg.geometry.sizing.cylinder_diameter_m = 0.1118033988749895;
cfg.geometry.sizing.cylinder_length_m = 0.8944271909999159;
cfg.geometry.sizing.cylinder_axis = "y";
cfg.geometry.aero_reference_area.mode = "manual";
cfg.geometry.aero_reference_area.value_m2 = 0.09999999999999999;
cfg.geometry.aero_reference_length.mode = "manual";
cfg.geometry.aero_reference_length.value_m = 0.1118033988749895;
cfg.geometry.aero_reference_span.mode = "manual";
cfg.geometry.aero_reference_span.value_m = 0.8944271909999159;
cfg.geometry.aero_reference_point_B_m = [0;0;0];

D = cfg.geometry.sizing.cylinder_diameter_m;
L = cfg.geometry.sizing.cylinder_length_m;
S = cfg.geometry.aero_reference_area.value_m2;

%% Manual magnet sets
cfg.magnets.mode = "manual_sets";
cfg.magnets.remanence_selection = "minimum";
cfg.magnets.check_containment = true;

m0.name = "central_N52";
m0.dimensions_local_m = [0.075104094428999; 0.15; 0.075104094428999];
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
speeds = [2.5 7];

% Cross-flow state definitions:
% state, A/D, lambda*=U/(fD), CL peak amplitude, CL phase wrt displacement,
% force-frequency model, source/confidence label.
state_def = {
    "desynchronised", 0.1, 8, 0.6, 0, "natural_shedding", "Ajmal2026_prelock_A010; phase_not_locked";
    "C2S", 0.1, 3.5, 1, 25, "forced_fundamental", "Morse2009_C2S_topology; Ajmal2026_highfreq_force_scale";
    "2S", 0.2, 5, 1.5, 15, "forced_fundamental", "Morse2009_2S; Ajmal2026_A020_lockin; Belloli2012_initial";
    "2P", 0.6, 6.4, 4, 15, "forced_fundamental", "Morse2009_2P_exact_point; Belloli2012_Mandelli2016_Re5e4";
    "2PO", 0.8, 5.6, 4, 10, "forced_fundamental", "Morse2009_2PO_exact_point; highRe_force_envelope_only";
    "PplusS", 1.2, 4, 2, -90, "forced_fundamental", "Morse2009_PplusS_exact_point; lowRe_force_screen_only"
};

rows = table();

for iu = 1:numel(speeds)
    U_free = speeds(iu);
    Re_free = U_free*D/nu_air_m2ps;

    for is = 1:size(state_def,1)
        wake_state = string(state_def{is,1});
        A_over_D = state_def{is,2};
        lambda_star = state_def{is,3};
        CL_amp = state_def{is,4};
        force_phase_deg = state_def{is,5};
        force_model = string(state_def{is,6});
        source_id = string(state_def{is,7});

        A = A_over_D*D;
        f_body = U_free/(lambda_star*D);
        omega = 2*pi*f_body;

        % Body motion.
        z = A*sin(phase);
        vz = A*omega*cos(phase);
        az = -A*omega^2*sin(phase);

        if force_model == "natural_shedding"
            % Deliberately not phase-locked to the imposed body motion.
            % St=0.20 is used only to create an order-of-magnitude natural
            % shedding load; the physical St should be measured on the real rig.
            St_force = 0.20;
            f_force = St_force*U_free/D;
            t = phase/omega;
            CL = CL_amp*sin(2*pi*f_force*t);
            aero_note = "pre-lock/desynchronised; CL oscillates at nominal natural shedding frequency";
        else
            St_force = NaN;
            f_force = f_body;
            CL = CL_amp*sin(phase + deg2rad(force_phase_deg));
            aero_note = "single synchronous lift harmonic used as order-of-magnitude force/phase screen";
        end

        % Mean streamwise drag only. Cross-flow drag harmonics are omitted
        % because lift is the aerodynamic quantity relevant to motion phase.
        CD = 1.20*ones(size(phase));

        n = numel(phase);
        scenario_name = strings(n,1);
        for ip = 1:n
            scenario_name(ip) = "U"+string(U_free)+"_"+wake_state+"_p"+compose("%02d",ip-1);
        end

        one = table( ...
            scenario_name, repmat(U_free,n,1), ...
            CD, zeros(n,1), CL, zeros(n,1), zeros(n,1), zeros(n,1), ...
            zeros(n,1), zeros(n,1), zeros(n,1), ...
            zeros(n,1), zeros(n,1), az, ...
            zeros(n,1), zeros(n,1), zeros(n,1), ...
            zeros(n,1), zeros(n,1), zeros(n,1), ...
            repmat(Re_free,n,1), repmat(A_over_D,n,1), repmat(lambda_star,n,1), ...
            repmat(A,n,1), repmat(f_body,n,1), repmat(CL_amp,n,1), ...
            repmat(force_phase_deg,n,1), repmat(wake_state,n,1), ...
            phase, zeros(n,1), z, zeros(n,1), vz, ...
            repmat(f_force,n,1), repmat(St_force,n,1), ...
            repmat(source_id,n,1), repmat(aero_note,n,1), ...
            'VariableNames',{ ...
            'scenario_name','speed_mps', ...
            'CD','CY','CL','Cl_roll','Cm','Cn', ...
            'yaw_deg','pitch_deg','roll_deg', ...
            'a_x','a_y','a_z','omega_x','omega_y','omega_z','alpha_x','alpha_y','alpha_z', ...
            'Re_free_stream','A_over_D','lambda_star','amplitude_m','body_frequency_Hz', ...
            'CL_peak_screen','CL_phase_deg_screen','wake_state','phase_rad', ...
            'position_x_m','position_z_m','velocity_x_mps','velocity_z_mps', ...
            'aero_force_frequency_Hz','St_force_screen','source_id','aero_model_note'});

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
