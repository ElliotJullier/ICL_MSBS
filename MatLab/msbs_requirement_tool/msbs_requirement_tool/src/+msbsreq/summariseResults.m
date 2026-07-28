function summary = summariseResults(resultTable, cfg)
%SUMMARISERESULTS Build per-magnet-set envelopes and select an acceptable best set.
arguments
    resultTable table
    cfg (1,1) struct
end
setIds=unique(resultTable.magnet_set_id,'stable');
setRows=repmat(localEmptySetRow(),numel(setIds),1);
envelopes=repmat(struct(),numel(setIds),1);
for i=1:numel(setIds)
    id=setIds(i); mask=resultTable.magnet_set_id==id; T=resultTable(mask,:);
    [maxForce,iForce]=max(T.force_req_norm_N);
    [maxMoment,iMoment]=max(T.moment_req_norm_Nm);
    [maxB,iB]=max(T.B_norm_T);
    [maxBLocal,iBLocal]=max(T.B_local_max_norm_T);
    [maxG,iG]=max(T.G_frobenius_Tpm);
    [maxGComp,iGC]=max(T.G_max_abs_Tpm);
    [maxEffort,iEff]=max(T.scaled_solution_norm);
    [maxRel,iRel]=max(T.relative_scaled_residual);
    row=localEmptySetRow();
    row.magnet_set_id=id;row.magnet_set_name=T.magnet_set_name(1);
    row.maximum_force_norm_N=maxForce;row.maximum_force_scenario_id=T.scenario_id(iForce);
    row.maximum_moment_norm_Nm=maxMoment;row.maximum_moment_scenario_id=T.scenario_id(iMoment);
    row.maximum_B0_norm_T=maxB;row.maximum_B0_scenario_id=T.scenario_id(iB);
    row.maximum_local_B_norm_T=maxBLocal;row.maximum_local_B_scenario_id=T.scenario_id(iBLocal);
    row.maximum_G_frobenius_Tpm=maxG;row.maximum_G_scenario_id=T.scenario_id(iG);
    row.maximum_G_component_Tpm=maxGComp;row.maximum_G_component_scenario_id=T.scenario_id(iGC);
    row.maximum_scaled_solution_norm=maxEffort;row.maximum_effort_scenario_id=T.scenario_id(iEff);
    row.maximum_relative_scaled_residual=maxRel;row.maximum_residual_scenario_id=T.scenario_id(iRel);
    row.all_scenarios_acceptable=maxRel<=cfg.magnetic.acceptance_relative_residual;
    row.minimum_map_rank=min(T.map_rank);row.maximum_condition_number=max(T.map_condition_number);
    setRows(i)=row;
    envelopes(i)=localComponentEnvelopes(T,id);
end
summary=struct();
summary.magnet_set_summary=struct2table(setRows,'AsArray',true);
summary.envelopes=envelopes;
acceptable=find(summary.magnet_set_summary.all_scenarios_acceptable);
if isempty(acceptable)
    summary.best_magnet_set_id="";
    summary.best_magnet_set_name="";
    summary.best_selection_note="No magnet set met the configured dimensionless relative-residual acceptance threshold. Sets are not labelled feasible or best.";
else
    [~,localIndex]=min(summary.magnet_set_summary.maximum_scaled_solution_norm(acceptable));
    bestIndex=acceptable(localIndex);
    summary.best_magnet_set_id=summary.magnet_set_summary.magnet_set_id(bestIndex);
    summary.best_magnet_set_name=summary.magnet_set_summary.magnet_set_name(bestIndex);
    summary.best_selection_note="Selected among residual-acceptable sets by minimum worst-case scaled magnetic requirement.";
end
rejected=find(~summary.magnet_set_summary.all_scenarios_acceptable);
acceptedOrder=zeros(0,1);
rejectedOrder=zeros(0,1);
if ~isempty(acceptable)
    acceptedKeys=[summary.magnet_set_summary.maximum_scaled_solution_norm(acceptable), ...
        summary.magnet_set_summary.maximum_relative_scaled_residual(acceptable)];
    [~,localOrder]=sortrows(acceptedKeys,[1 2]);
    acceptedOrder=acceptable(localOrder);
end
if ~isempty(rejected)
    rejectedKeys=[summary.magnet_set_summary.maximum_relative_scaled_residual(rejected), ...
        summary.magnet_set_summary.maximum_scaled_solution_norm(rejected)];
    [~,localOrder]=sortrows(rejectedKeys,[1 2]);
    rejectedOrder=rejected(localOrder);
end
order=[acceptedOrder(:);rejectedOrder(:)];
summary.ranking=summary.magnet_set_summary(order,:);
summary.ranking_note="Residual-accepted sets are ordered by magnetic effort; rejected sets are ordered by residual first, then effort.";
summary.acceptance_relative_residual=cfg.magnetic.acceptance_relative_residual;
end

function env=localComponentEnvelopes(T,id)
forceVars={'Fx_mag_req_N','Fy_mag_req_N','Fz_mag_req_N'};
momentVars={'Mx_mag_req_Nm','My_mag_req_Nm','Mz_mag_req_Nm'};
env=struct('magnet_set_id',id);
[env.force_min,env.force_min_scenario_id]=localExtrema(T,forceVars,@min);
[env.force_max,env.force_max_scenario_id]=localExtrema(T,forceVars,@max);
[env.moment_min,env.moment_min_scenario_id]=localExtrema(T,momentVars,@min);
[env.moment_max,env.moment_max_scenario_id]=localExtrema(T,momentVars,@max);
end
function [values,ids]=localExtrema(T,names,fn)
values=zeros(1,3);ids=strings(1,3);
for j=1:3
    [values(j),idx]=fn(T.(names{j}));ids(j)=T.scenario_id(idx);
end
end
function row=localEmptySetRow()
row=struct('magnet_set_id',"",'magnet_set_name',"", ...
'maximum_force_norm_N',NaN,'maximum_force_scenario_id',"", ...
'maximum_moment_norm_Nm',NaN,'maximum_moment_scenario_id',"", ...
'maximum_B0_norm_T',NaN,'maximum_B0_scenario_id',"", ...
'maximum_local_B_norm_T',NaN,'maximum_local_B_scenario_id',"", ...
'maximum_G_frobenius_Tpm',NaN,'maximum_G_scenario_id',"", ...
'maximum_G_component_Tpm',NaN,'maximum_G_component_scenario_id',"", ...
'maximum_scaled_solution_norm',NaN,'maximum_effort_scenario_id',"", ...
'maximum_relative_scaled_residual',NaN,'maximum_residual_scenario_id',"", ...
'all_scenarios_acceptable',false,'minimum_map_rank',NaN,'maximum_condition_number',NaN);
end
