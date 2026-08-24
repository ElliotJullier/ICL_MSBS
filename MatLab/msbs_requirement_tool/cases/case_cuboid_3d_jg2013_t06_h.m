function cfg = case_cuboid_3d_jg2013_t06_h()
%CASE_CUBOID_3D_JG2013_T06_H MSBS aerodynamic requirement study.
% Generated for requirement-tool v0.3.0. One scenario row = one physical state.
% Replaces the earlier square-prism case with a finite 3D cuboid based on:
% Jann & Geisbauer (2013), AIAA 2013-1282.
%
% Primary aerodynamic data:
% - Body A geometry ratio l:w:h = 110:90:50 = 11:9:5.
% - Forces use aerodynamic/T axes.
% - Source moments Cl,Cm,Cn are body-axis coefficients about the geometric centre.
% - Reference area S = l*w and reference length = l.
% - beta = -45 deg source slice uses the Table 8 Fourier fit.
% - alpha=0,beta=0 baseline uses the Table 2 Fourier fit.
%
% Mapping to this tool:
%   paper alpha = body pitch_T
%   paper beta  = -body yaw_T
% so beta=-45 deg -> yaw_T=+45 deg.
% Body-axis source moments are dimensionalised then rotated to T before use.
% Direct-wrench mode is used because source forces and moments are defined
% in different frames in the paper.

cfg.meta.case_id = "cuboid_3d_jg2013_t06_h";
cfg.meta.description = "DLR 11:9:5 cuboid, five correlated 3D aerodynamic states, maximum selected projected blockage = 10%, 0.6 m tunnel.";

%% Tunnel
cfg.tunnel.cross_section.type = "rectangular";
cfg.tunnel.cross_section.width_m = 0.60;
cfg.tunnel.cross_section.height_m = 0.60;
cfg.tunnel.speed_mps = 10;
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
% Scale the fixed 11:9:5 Body-A shape so the largest projected area among
% the selected attitudes is exactly 10% of the tunnel cross-sectional area.
% The largest selected projected area occurs at alpha=45 deg, beta=-45 deg
% (tool attitude yaw=+45 deg, pitch=+45 deg).
shape_lwh = [11;9;5];
R_max = localRzyxDeg(45,45,0);
Aproj_shape_max = localProjectedAreaCuboid( ...
    shape_lwh(1),shape_lwh(2),shape_lwh(3),R_max);
A_tunnel = cfg.tunnel.cross_section.width_m * cfg.tunnel.cross_section.height_m;
shape_scale_m = sqrt(0.10*A_tunnel/Aproj_shape_max);

l_m = shape_scale_m*shape_lwh(1);
w_m = shape_scale_m*shape_lwh(2);
h_m = shape_scale_m*shape_lwh(3);

cfg.geometry.type = "cuboid";
cfg.geometry.sizing.mode = "absolute";
cfg.geometry.sizing.nominal_dimensions_m = [l_m;w_m;h_m]; % [x_B length; y_B width; z_B height]
cfg.geometry.aero_reference_area.mode = "manual";
cfg.geometry.aero_reference_area.value_m2 = l_m*w_m; % Jann & Geisbauer reference area
cfg.geometry.aero_reference_length.mode = "manual";
cfg.geometry.aero_reference_length.value_m = l_m;    % Jann & Geisbauer moment reference length
cfg.geometry.aero_reference_span.mode = "manual";
cfg.geometry.aero_reference_span.value_m = w_m;      % not used by direct-wrench mode
cfg.geometry.aero_reference_point_B_m = [0;0;0];     % source coefficients about geometric centre

%% Magnets
% Preserved from the earlier bluff-body cases so this patch changes the
% aerodynamic case definition rather than introducing a new magnet-sizing assumption.
% The automatic maximum-fit magnet should be audited separately before final portfolio release.
cfg.magnets.mode = "automatic";
cfg.magnets.remanence_selection = "minimum";
cfg.magnets.check_containment = true;
cfg.magnets.automatic.grade = "N52";
cfg.magnets.automatic.linear_shrink_fraction = 0.0;
cfg.magnets.automatic.centre_offset_B_m = [0;0;0];
cfg.magnets.automatic.effective_magnetisation_factor = 1.0;
cfg.magnets.automatic.direction_candidates_B = eye(3);
cfg.magnets.automatic.dipole_moment_override_Am2 = [];

%% Mass
cfg.mass.shell_mass_factor = 1.30;
cfg.mass.total_mass_override_kg = [];
cfg.mass.centre_of_mass_override_B_m = [];
cfg.mass.inertia_override_B_kgm2 = [];

%% Aerodynamics
cfg.aero.mode = "direct_wrench";
cfg.aero.direct_wrench_frame = "T";

% Five correlated source states.
% Coefficient order is [CD CY CL Cl Cm Cn].
% State 1 is evaluated from Table 2 at alpha=0,beta=0.
% States 2-5 are evaluated from Table 8 at beta=-45 deg.
state_name = ["a00_b00";"a00_bm45";"a25_bm45";"a45_bm45";"a90_bm45"];
alpha_deg = [0;0;25;45;90];
beta_deg  = [0;-45;-45;-45;-45];

CD = [0.375300;0.554500;0.743947;0.894500;1.000900];
CY = [0;0.108900;-0.032449;-0.182400;-0.374500];
CL = [0;0;0.402542;0.300200;0];

Cl_body = [0;0;0.025319;0.021991;0.043100];
Cm_body = [0;0;0.046606;0.037300;0];
Cn_body = [0;0.014200;0.015231;0.019104;0.000100];

source_id_state = [ ...
    "JannGeisbauer2013_Table2_beta0_Fourier"; ...
    "JannGeisbauer2013_Table8_beta_m45_Fourier"; ...
    "JannGeisbauer2013_Table8_beta_m45_Fourier"; ...
    "JannGeisbauer2013_Table8_beta_m45_Fourier"; ...
    "JannGeisbauer2013_Table8_beta_m45_Fourier"];

speeds_mps = [10;25;40];
rho = cfg.tunnel.air.rho_kgm3;
mu_Pas = 1.81e-5;
S_ref = cfg.geometry.aero_reference_area.value_m2;
l_ref = cfg.geometry.aero_reference_length.value_m;

nState = numel(state_name);
nSpeed = numel(speeds_mps);
nRow = nState*nSpeed;

scenario_name = strings(nRow,1);
speed_mps = zeros(nRow,1);
Fx_aero_N = zeros(nRow,1);
Fy_aero_N = zeros(nRow,1);
Fz_aero_N = zeros(nRow,1);
Mx_aero_Nm = zeros(nRow,1);
My_aero_Nm = zeros(nRow,1);
Mz_aero_Nm = zeros(nRow,1);
yaw_deg = zeros(nRow,1);
pitch_deg = zeros(nRow,1);
roll_deg = zeros(nRow,1);
Re = zeros(nRow,1);
projected_blockage_ratio = zeros(nRow,1);
source_CD = zeros(nRow,1);
source_CY = zeros(nRow,1);
source_CL = zeros(nRow,1);
source_Cl_body = zeros(nRow,1);
source_Cm_body = zeros(nRow,1);
source_Cn_body = zeros(nRow,1);
source_alpha_deg = zeros(nRow,1);
source_beta_deg = zeros(nRow,1);
source_id = strings(nRow,1);

k = 0;
for iU = 1:nSpeed
    U = speeds_mps(iU);
    q = 0.5*rho*U^2;

    for iS = 1:nState
        k = k + 1;

        % Paper relation for zero roll: alpha=theta, beta=-psi.
        yaw_i = -beta_deg(iS);
        pitch_i = alpha_deg(iS);
        R_TB = localRzyxDeg(yaw_i,pitch_i,0);

        % Source force coefficients are aerodynamic axes = T.
        F_T = q*S_ref*[CD(iS);CY(iS);CL(iS)];

        % Source moment coefficients are BODY axes and all use q*S*l.
        M_B = q*S_ref*l_ref*[Cl_body(iS);Cm_body(iS);Cn_body(iS)];
        M_T = R_TB*M_B;

        Aproj = localProjectedAreaCuboid(l_m,w_m,h_m,R_TB);

        scenario_name(k) = "U" + string(U) + "_" + state_name(iS);
        speed_mps(k) = U;
        Fx_aero_N(k) = F_T(1);
        Fy_aero_N(k) = F_T(2);
        Fz_aero_N(k) = F_T(3);
        Mx_aero_Nm(k) = M_T(1);
        My_aero_Nm(k) = M_T(2);
        Mz_aero_Nm(k) = M_T(3);
        yaw_deg(k) = yaw_i;
        pitch_deg(k) = pitch_i;
        roll_deg(k) = 0;
        Re(k) = rho*U*l_m/mu_Pas;
        projected_blockage_ratio(k) = Aproj/A_tunnel;

        source_CD(k) = CD(iS);
        source_CY(k) = CY(iS);
        source_CL(k) = CL(iS);
        source_Cl_body(k) = Cl_body(iS);
        source_Cm_body(k) = Cm_body(iS);
        source_Cn_body(k) = Cn_body(iS);
        source_alpha_deg(k) = alpha_deg(iS);
        source_beta_deg(k) = beta_deg(iS);
        source_id(k) = source_id_state(iS);
    end
end

cfg.scenarios = table( ...
    scenario_name,speed_mps, ...
    Fx_aero_N,Fy_aero_N,Fz_aero_N,Mx_aero_Nm,My_aero_Nm,Mz_aero_Nm, ...
    yaw_deg,pitch_deg,roll_deg,Re,projected_blockage_ratio, ...
    source_CD,source_CY,source_CL,source_Cl_body,source_Cm_body,source_Cn_body, ...
    source_alpha_deg,source_beta_deg,source_id);

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

function R = localRzyxDeg(yaw_deg,pitch_deg,roll_deg)
% Intrinsic Z-Y-X rotation mapping body components into tunnel components.
cy = cosd(yaw_deg);   sy = sind(yaw_deg);
cp = cosd(pitch_deg); sp = sind(pitch_deg);
cr = cosd(roll_deg);  sr = sind(roll_deg);

Rz = [cy -sy 0; sy cy 0; 0 0 1];
Ry = [cp 0 sp; 0 1 0; -sp 0 cp];
Rx = [1 0 0; 0 cr -sr; 0 sr cr];
R = Rz*Ry*Rx;
end

function Aproj = localProjectedAreaCuboid(l,w,h,R_TB)
% Orthogonal projected area normal to +x_T for a rectangular cuboid.
% Sum of the three face areas weighted by the absolute x_T component
% of each body-axis face normal.
Aproj = w*h*abs(R_TB(1,1)) + l*h*abs(R_TB(1,2)) + l*w*abs(R_TB(1,3));
end
