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
    massProperties.centre_of_mass_B_m,scenario.additional_wrench_scales);
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
scenario.CD=row.CD; scenario.CL=row.CL; scenario.Cm=row.Cm;
scenario.body_attitude_case=string(row.body_attitude_case);
scenario.wind_orientation_case=string(row.wind_orientation_case);
scenario.motion_case=string(row.motion_case);
scenario.R_TB=row.R_TB{1}; scenario.R_TW=row.R_TW{1}; scenario.R_ET=R_ET;
scenario.a_C_T_mps2=row.a_C_T_mps2{1};
scenario.omega_T_radps=row.omega_T_radps{1};
scenario.alpha_T_radps2=row.alpha_T_radps2{1};
scenario.direct_inertial_demand=row.direct_inertial_demand;
scenario.inertial_force_override_T=row.inertial_force_override_T{1};
scenario.inertial_moment_override_T=row.inertial_moment_override_T{1};
scenario.additional_wrench_scales=row.additional_wrench_scales{1};
scenario.motion_phase_rad=row.motion_phase_rad;
scenario.time_s=row.time_s;
end

function total=localAdditionalWrench(T,scenario,centreOfMassB,scales)
total=zeros(6,1);
if isempty(T),return,end
required={'name','Fx_N','Fy_N','Fz_N','Mx_Nm','My_Nm','Mz_Nm','components_frame','reference_point_B_m'};
if ~all(ismember(required,T.Properties.VariableNames))
    error('msbsreq:InvalidAdditionalWrenches', ...
        'Additional-wrench table is missing one or more required columns.');
end
frames=struct('R_ET',scenario.R_ET,'R_TB',scenario.R_TB,'R_TW',scenario.R_TW);
for i=1:height(T)
    force=[T.Fx_N(i);T.Fy_N(i);T.Fz_N(i)];
    moment=[T.Mx_Nm(i);T.My_Nm(i);T.Mz_Nm(i)];
    point=T.reference_point_B_m{i};
    scale=1;
    if i<=numel(scales),scale=scales(i);end
    total=total+scale*msbsreq.transformWrench(force,moment, ...
        upper(string(T.components_frame(i))),point(:),centreOfMassB,frames);
end
end
