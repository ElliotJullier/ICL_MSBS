function loads = calculateRequiredMagneticWrench(cfg, tunnel, geometry, scenarioRow, massProperties)
%CALCULATEREQUIREDMAGNETICWRENCH Resolve all loads and required magnetic wrench.
arguments
    cfg (1,1) struct
    tunnel (1,1) struct
    geometry (1,1) struct
    scenarioRow table
    massProperties (1,1) struct
end

scenario=localScenarioStruct(scenarioRow,tunnel.rho_kgm3,cfg.frames.R_ET);
aero=msbsreq.calculateAeroWrench(scenario,geometry,massProperties);
gravity=msbsreq.calculateGravityWrench(tunnel,massProperties);
inertial=msbsreq.calculateInertialDemand(scenario,massProperties);
other=localAdditionalWrench(cfg.additional_wrenches,scenario, ...
    massProperties.centre_of_mass_B_m);
required=inertial-aero-gravity-other;

loads=struct('scenario',scenario,'aero_wrench_T',aero,'gravity_wrench_T',gravity, ...
    'other_wrench_T',other,'inertial_demand_T',inertial, ...
    'required_magnetic_wrench_T',required, ...
    'resultant_external_wrench_T',aero+gravity+other);
end

function scenario=localScenarioStruct(row,rho,R_ET)
scenario=struct();
scenario.scenario_id=string(row.scenario_id);
scenario.scenario_name=string(row.scenario_name);
scenario.speed_mps=row.speed_mps;
scenario.rho_kgm3=rho;
scenario.aero_source_mode=string(row.aero_source_mode);
scenario.CD=row.CD;scenario.CY=row.CY;scenario.CL=row.CL;
scenario.Cl_roll=row.Cl_roll;scenario.Cm=row.Cm;scenario.Cn=row.Cn;
scenario.motion_mode=string(row.motion_mode);
scenario.R_TB=row.R_TB{1};scenario.R_ET=R_ET;
scenario.a_C_T_mps2=row.a_C_T_mps2{1};
scenario.omega_T_radps=row.omega_T_radps{1};
scenario.alpha_T_radps2=row.alpha_T_radps2{1};
scenario.aero_force_input=row.aero_force_input{1};
scenario.aero_moment_input=row.aero_moment_input{1};
scenario.aero_input_frame=string(row.aero_input_frame);
scenario.aero_reference_point_B_m=row.aero_reference_point_B_m{1};
scenario.metadata=row.metadata{1};
scenario.motion_phase_rad=row.motion_phase_rad;
scenario.time_s=row.time_s;
scenario.r_C_T_m=row.r_C_T_m{1}(:);
scenario.v_C_T_mps=row.v_C_T_mps{1}(:);
scenario.scenario_relationship=string(row.scenario_relationship);
end

function total=localAdditionalWrench(T,scenario,centreOfMassB)
total=zeros(6,1);
if isempty(T),return,end
required={'name','Fx_N','Fy_N','Fz_N','Mx_Nm','My_Nm','Mz_Nm','components_frame','reference_point_B_m'};
if ~all(ismember(required,T.Properties.VariableNames))
    error('msbsreq:InvalidAdditionalWrenches', ...
        'Additional-wrench table is missing one or more required columns.');
end
frames=struct('R_ET',scenario.R_ET,'R_TB',scenario.R_TB);
for i=1:height(T)
    force=[T.Fx_N(i);T.Fy_N(i);T.Fz_N(i)];
    moment=[T.Mx_Nm(i);T.My_Nm(i);T.Mz_Nm(i)];
    point=T.reference_point_B_m{i};
    total=total+msbsreq.transformWrench(force,moment, ...
        upper(string(T.components_frame(i))),point(:),centreOfMassB,frames);
end
end
