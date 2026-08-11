function T = buildResolutionTable(records, scales, cfg)
%BUILDRESOLUTIONTABLE Evaluate incremental magnetic requirements about baselines.
arguments
    records (:,1) struct
    scales (1,1) struct
    cfg (1,1) struct
end
if ~cfg.requirement_resolution.enable
    T=table();return
end
D=cfg.requirement_resolution.delta_wrench_cases;
n=numel(records)*height(D);
rows=repmat(localEmptyRow(),n,1);index=0;
for iRecord=1:numel(records)
    rec=records(iRecord);scenario=rec.loads.scenario;
    frames=struct('R_ET',scenario.R_ET,'R_TB',scenario.R_TB,'R_TW',scenario.R_TW);
    x0=rec.solution.x;w0=rec.loads.required_magnetic_wrench_T;
    for iDelta=1:height(D)
        index=index+1;
        name=localTableString(D,iDelta,'name',"delta_"+iDelta);
        frame=upper(localTableString(D,iDelta,'frame',"T"));
        dF=[D.dFx_N(iDelta);D.dFy_N(iDelta);D.dFz_N(iDelta)];
        dM=[D.dMx_Nm(iDelta);D.dMy_Nm(iDelta);D.dMz_Nm(iDelta)];
        dW=[msbsreq.transformVector(dF,frame,frames);msbsreq.transformVector(dM,frame,frames)];
        perturbed=msbsreq.solveMagneticRequirement(rec.map,w0+dW,scales,cfg);
        direct=msbsreq.solveMagneticRequirement(rec.map,dW,scales,cfg);
        dx=perturbed.x-x0;dG=msbsreq.constructGradient(dx);
        row=localEmptyRow();
        row.baseline_scenario_id=scenario.scenario_id;
        row.baseline_scenario_name=scenario.scenario_name;
        row.magnet_set_id=rec.magnet_set.id;row.magnet_set_name=rec.magnet_set.name;
        row.delta_case_name=name;row.input_frame=frame;
        row.dFx_T_N=dW(1);row.dFy_T_N=dW(2);row.dFz_T_N=dW(3);
        row.dMx_T_Nm=dW(4);row.dMy_T_Nm=dW(5);row.dMz_T_Nm=dW(6);
        row.delta_Bx_T=dx(1);row.delta_By_T=dx(2);row.delta_Bz_T=dx(3);
        row.delta_gxx_Tpm=dG(1,1);row.delta_gyy_Tpm=dG(2,2);row.delta_gzz_Tpm=dG(3,3);
        row.delta_gxy_Tpm=dG(1,2);row.delta_gxz_Tpm=dG(1,3);row.delta_gyz_Tpm=dG(2,3);
        row.norm_delta_B0_T=norm(dx(1:3));row.norm_delta_G_Tpm=norm(dG,'fro');
        row.relative_incremental_residual=direct.relative_scaled_residual;
        row.baseline_plus_perturbation_consistency_norm=norm(dx-direct.x);
        row.delta_scaled_solution_norm=direct.scaled_solution_norm;
        rows(index)=row;
    end
end
T=struct2table(rows,'AsArray',true);
end

function value=localTableString(T,i,name,default)
if ismember(name,T.Properties.VariableNames),value=string(T.(name)(i));else,value=string(default);end
end

function row=localEmptyRow()
row=struct('baseline_scenario_id',"",'baseline_scenario_name',"", ...
    'magnet_set_id',"",'magnet_set_name',"",'delta_case_name',"",'input_frame',"", ...
    'dFx_T_N',NaN,'dFy_T_N',NaN,'dFz_T_N',NaN, ...
    'dMx_T_Nm',NaN,'dMy_T_Nm',NaN,'dMz_T_Nm',NaN, ...
    'delta_Bx_T',NaN,'delta_By_T',NaN,'delta_Bz_T',NaN, ...
    'delta_gxx_Tpm',NaN,'delta_gyy_Tpm',NaN,'delta_gzz_Tpm',NaN, ...
    'delta_gxy_Tpm',NaN,'delta_gxz_Tpm',NaN,'delta_gyz_Tpm',NaN, ...
    'norm_delta_B0_T',NaN,'norm_delta_G_Tpm',NaN, ...
    'relative_incremental_residual',NaN, ...
    'baseline_plus_perturbation_consistency_norm',NaN, ...
    'delta_scaled_solution_norm',NaN);
end
