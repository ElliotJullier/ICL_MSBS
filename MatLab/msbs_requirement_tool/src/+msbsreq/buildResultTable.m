function resultTable = buildResultTable(records)
%BUILDRESULTTABLE Flatten full calculation records into a CSV-friendly table.
arguments
    records (:,1) struct
end
n=numel(records);rows=repmat(localEmptyRow(),n,1);
for i=1:n
    rec=records(i);s=rec.loads.scenario;sol=rec.solution;G=sol.G_Tpm;
    aero=rec.loads.aero_wrench_T;grav=rec.loads.gravity_wrench_T;other=rec.loads.other_wrench_T;
    inertial=rec.loads.inertial_demand_T;req=rec.loads.required_magnetic_wrench_T;
    row=localEmptyRow();
    row.scenario_id=s.scenario_id;row.scenario_name=s.scenario_name;
    row.magnet_set_id=rec.magnet_set.id;row.magnet_set_name=rec.magnet_set.name;
    row.aero_source_mode=s.aero_source_mode;row.aero_input_frame=s.aero_input_frame;
    row.motion_mode=s.motion_mode;row.speed_mps=s.speed_mps;row.rho_kgm3=s.rho_kgm3;
    row.time_s=s.time_s;row.phase_rad=s.motion_phase_rad;
    row.CD=s.CD;row.CY=s.CY;row.CL=s.CL;row.Cl_roll=s.Cl_roll;row.Cm=s.Cm;row.Cn=s.Cn;
    row.aero_ref_x_B_m=s.aero_reference_point_B_m(1);row.aero_ref_y_B_m=s.aero_reference_point_B_m(2);row.aero_ref_z_B_m=s.aero_reference_point_B_m(3);
    row.a_Cx_T_mps2=s.a_C_T_mps2(1);row.a_Cy_T_mps2=s.a_C_T_mps2(2);row.a_Cz_T_mps2=s.a_C_T_mps2(3);
    row.omega_x_T_radps=s.omega_T_radps(1);row.omega_y_T_radps=s.omega_T_radps(2);row.omega_z_T_radps=s.omega_T_radps(3);
    row.alpha_x_T_radps2=s.alpha_T_radps2(1);row.alpha_y_T_radps2=s.alpha_T_radps2(2);row.alpha_z_T_radps2=s.alpha_T_radps2(3);
    row.Fx_aero_N=aero(1);row.Fy_aero_N=aero(2);row.Fz_aero_N=aero(3);row.Mx_aero_Nm=aero(4);row.My_aero_Nm=aero(5);row.Mz_aero_Nm=aero(6);
    row.Fx_gravity_N=grav(1);row.Fy_gravity_N=grav(2);row.Fz_gravity_N=grav(3);
    row.Fx_other_N=other(1);row.Fy_other_N=other(2);row.Fz_other_N=other(3);row.Mx_other_Nm=other(4);row.My_other_Nm=other(5);row.Mz_other_Nm=other(6);
    row.Fx_inertial_demand_N=inertial(1);row.Fy_inertial_demand_N=inertial(2);row.Fz_inertial_demand_N=inertial(3);
    row.Mx_inertial_demand_Nm=inertial(4);row.My_inertial_demand_Nm=inertial(5);row.Mz_inertial_demand_Nm=inertial(6);
    row.Fx_mag_req_N=req(1);row.Fy_mag_req_N=req(2);row.Fz_mag_req_N=req(3);row.Mx_mag_req_Nm=req(4);row.My_mag_req_Nm=req(5);row.Mz_mag_req_Nm=req(6);
    row.force_req_norm_N=norm(req(1:3));row.moment_req_norm_Nm=norm(req(4:6));
    row.Bx_T=sol.B0_T(1);row.By_T=sol.B0_T(2);row.Bz_T=sol.B0_T(3);
    row.gxx_Tpm=G(1,1);row.gyy_Tpm=G(2,2);row.gzz_Tpm=G(3,3);row.gxy_Tpm=G(1,2);row.gxz_Tpm=G(1,3);row.gyz_Tpm=G(2,3);
    row.B_norm_T=sol.B0_norm_T;row.B_local_max_norm_T=sol.B_local_max_norm_T;row.G_frobenius_Tpm=sol.G_frobenius_Tpm;
    row.G_max_abs_Tpm=sol.G_max_abs_component_Tpm;row.scaled_solution_norm=sol.scaled_solution_norm;
    row.force_residual_norm_N=sol.force_residual_norm_N;row.moment_residual_norm_Nm=sol.moment_residual_norm_Nm;
    row.relative_scaled_residual=sol.relative_scaled_residual;row.controllable=sol.controllable;
    row.map_rank=sol.rank;row.map_condition_number=sol.condition_number;
    rows(i)=row;
end
resultTable=struct2table(rows,'AsArray',true);
resultTable=localAppendMetadata(resultTable,records);
end

function T=localAppendMetadata(T,records)
keys=strings(0,1);
for i=1:numel(records),keys=unique([keys;string(fieldnames(records(i).loads.scenario.metadata))],'stable');end
for key=keys(:).'
    if ismember(key,T.Properties.VariableNames),continue,end
    values=cell(numel(records),1);
    for i=1:numel(records),meta=records(i).loads.scenario.metadata;field=char(key);if isfield(meta,field),values{i}=meta.(field);else,values{i}=[];end,end
    provided=~cellfun(@isempty,values);numericScalar=cellfun(@(v)isempty(v)||(isnumeric(v)&&isscalar(v)),values);
    if all(numericScalar)&&any(provided)
        out=nan(numel(values),1);for i=1:numel(values),if provided(i),out(i)=double(values{i});end,end;T.(char(key))=out;
    elseif all(cellfun(@(v)islogical(v)&&isscalar(v),values))
        T.(char(key))=cellfun(@logical,values);
    else
        out=strings(numel(values),1);for i=1:numel(values),if ~isempty(values{i}),out(i)=localMetadataText(values{i});end,end;T.(char(key))=out;
    end
end
end
function text=localMetadataText(value)
if isnumeric(value)||islogical(value),if isscalar(value),text=string(value);else,text=string(mat2str(value));end
elseif ischar(value),text=string(value);
elseif isstring(value)||iscategorical(value),value=string(value);if isscalar(value),text=value;else,text=strjoin(value(:).',"|");end
else,text=string(value);if ~isscalar(text),text=strjoin(text(:).',"|");end
end
end
function row=localEmptyRow()
row=struct('scenario_id',"",'scenario_name',"",'magnet_set_id',"",'magnet_set_name',"", ...
'aero_source_mode',"",'aero_input_frame',"",'motion_mode',"",'speed_mps',NaN,'rho_kgm3',NaN,'time_s',NaN,'phase_rad',NaN, ...
'CD',NaN,'CY',NaN,'CL',NaN,'Cl_roll',NaN,'Cm',NaN,'Cn',NaN, ...
'aero_ref_x_B_m',NaN,'aero_ref_y_B_m',NaN,'aero_ref_z_B_m',NaN, ...
'a_Cx_T_mps2',NaN,'a_Cy_T_mps2',NaN,'a_Cz_T_mps2',NaN, ...
'omega_x_T_radps',NaN,'omega_y_T_radps',NaN,'omega_z_T_radps',NaN, ...
'alpha_x_T_radps2',NaN,'alpha_y_T_radps2',NaN,'alpha_z_T_radps2',NaN, ...
'Fx_aero_N',NaN,'Fy_aero_N',NaN,'Fz_aero_N',NaN,'Mx_aero_Nm',NaN,'My_aero_Nm',NaN,'Mz_aero_Nm',NaN, ...
'Fx_gravity_N',NaN,'Fy_gravity_N',NaN,'Fz_gravity_N',NaN, ...
'Fx_other_N',NaN,'Fy_other_N',NaN,'Fz_other_N',NaN,'Mx_other_Nm',NaN,'My_other_Nm',NaN,'Mz_other_Nm',NaN, ...
'Fx_inertial_demand_N',NaN,'Fy_inertial_demand_N',NaN,'Fz_inertial_demand_N',NaN, ...
'Mx_inertial_demand_Nm',NaN,'My_inertial_demand_Nm',NaN,'Mz_inertial_demand_Nm',NaN, ...
'Fx_mag_req_N',NaN,'Fy_mag_req_N',NaN,'Fz_mag_req_N',NaN,'Mx_mag_req_Nm',NaN,'My_mag_req_Nm',NaN,'Mz_mag_req_Nm',NaN, ...
'force_req_norm_N',NaN,'moment_req_norm_Nm',NaN,'Bx_T',NaN,'By_T',NaN,'Bz_T',NaN, ...
'gxx_Tpm',NaN,'gyy_Tpm',NaN,'gzz_Tpm',NaN,'gxy_Tpm',NaN,'gxz_Tpm',NaN,'gyz_Tpm',NaN, ...
'B_norm_T',NaN,'B_local_max_norm_T',NaN,'G_frobenius_Tpm',NaN,'G_max_abs_Tpm',NaN,'scaled_solution_norm',NaN, ...
'force_residual_norm_N',NaN,'moment_residual_norm_Nm',NaN,'relative_scaled_residual',NaN,'controllable',false,'map_rank',NaN,'map_condition_number',NaN);
end
