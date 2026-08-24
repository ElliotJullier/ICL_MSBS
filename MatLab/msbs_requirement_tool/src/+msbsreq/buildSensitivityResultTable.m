function T = buildSensitivityResultTable(records)
%BUILDSENSITIVITYRESULTTABLE Flatten alternate magnetic-cost solutions.
% Only records classified as significantly coupled contain sensitivity solves.
arguments
    records (:,1) struct
end
rows=repmat(localEmptyRow(),0,1);
for i=1:numel(records)
    entries=records(i).sensitivity_solutions;
    if isempty(entries),continue,end
    for j=1:numel(entries)
        metric=entries(j).metric;
        sol=entries(j).solution;
        G=sol.G_Tpm;
        row=localEmptyRow();
        row.scenario_id=records(i).loads.scenario.scenario_id;
        row.scenario_name=records(i).loads.scenario.scenario_name;
        row.magnet_set_id=records(i).magnet_set.id;
        row.magnet_set_name=records(i).magnet_set.name;
        row.coupling_class=records(i).map.coupling.classification;
        row.coupling_ratio=records(i).map.coupling.ratio;
        row.metric_id=metric.id;
        row.metric_reference_source=metric.reference_source;
        row.reference_cube_side_m=metric.reference_cube_side_m;
        row.gradient_weight_factor=metric.gradient_weight_factor;
        row.tunnel_length_fraction=metric.tunnel_length_fraction;
        row.Bx_T=sol.B0_T(1);row.By_T=sol.B0_T(2);row.Bz_T=sol.B0_T(3);
        row.gxx_Tpm=G(1,1);row.gyy_Tpm=G(2,2);row.gzz_Tpm=G(3,3);
        row.gxy_Tpm=G(1,2);row.gxz_Tpm=G(1,3);row.gyz_Tpm=G(2,3);
        row.B_norm_T=sol.B0_norm_T;
        row.B_local_max_norm_T=sol.B_local_max_norm_T;
        row.G_frobenius_Tpm=sol.G_frobenius_Tpm;
        row.G_max_abs_Tpm=sol.G_max_abs_component_Tpm;
        row.magnetic_cost_rms_T=sol.magnetic_cost_rms_T;
        row.mean_vacuum_energy_density_Jpm3=sol.mean_vacuum_energy_density_Jpm3;
        row.relative_scaled_residual=sol.relative_scaled_residual;
        row.controllable=sol.controllable;
        rows(end+1,1)=row; %#ok<AGROW>
    end
end
if isempty(rows)
    T=struct2table(localEmptyRow(),'AsArray',true);
    T(1,:)=[];
else
    T=struct2table(rows,'AsArray',true);
end
end

function row=localEmptyRow()
row=struct('scenario_id',"",'scenario_name',"",'magnet_set_id',"",'magnet_set_name',"", ...
    'coupling_class',"",'coupling_ratio',NaN,'metric_id',"",'metric_reference_source',"", ...
    'reference_cube_side_m',NaN,'gradient_weight_factor',NaN,'tunnel_length_fraction',NaN, ...
    'Bx_T',NaN,'By_T',NaN,'Bz_T',NaN, ...
    'gxx_Tpm',NaN,'gyy_Tpm',NaN,'gzz_Tpm',NaN,'gxy_Tpm',NaN,'gxz_Tpm',NaN,'gyz_Tpm',NaN, ...
    'B_norm_T',NaN,'B_local_max_norm_T',NaN,'G_frobenius_Tpm',NaN,'G_max_abs_Tpm',NaN, ...
    'magnetic_cost_rms_T',NaN,'mean_vacuum_energy_density_Jpm3',NaN, ...
    'relative_scaled_residual',NaN,'controllable',false);
end
