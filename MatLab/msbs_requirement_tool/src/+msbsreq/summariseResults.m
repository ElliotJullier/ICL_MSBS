function summary = summariseResults(resultTable, cfg)
%SUMMARISERESULTS Build pointwise extrema and both magnet-ranking views.
arguments
    resultTable table
    cfg (1,1) struct
end
setIds=unique(resultTable.magnet_set_id,'stable');
setRows=repmat(localEmptySetRow(),numel(setIds),1);
envelopes=repmat(localEmptyEnvelope(),numel(setIds),1);
extremaRows=repmat(localEmptyExtremaRow(),0,1);
for i=1:numel(setIds)
    id=setIds(i); mask=resultTable.magnet_set_id==id; T=resultTable(mask,:);
    [maxForce,iForce]=max(T.force_req_norm_N);
    [maxMoment,iMoment]=max(T.moment_req_norm_Nm);
    [maxB,iB]=max(T.B_norm_T);
    [maxBLocal,iBLocal]=max(T.B_local_max_norm_T);
    [maxG,iG]=max(T.G_frobenius_Tpm);
    [maxGComp,iGC]=max(T.G_max_abs_Tpm);
    [maxCost,iCost]=max(T.magnetic_cost_rms_T);
    [maxEnergy,iEnergy]=max(T.mean_vacuum_energy_density_Jpm3);
    [maxRel,iRel]=max(T.relative_scaled_residual);
    row=localEmptySetRow();
    row.magnet_set_id=id;row.magnet_set_name=T.magnet_set_name(1);
    row.maximum_force_norm_N=maxForce;row.maximum_force_scenario_id=T.scenario_id(iForce);
    row.maximum_moment_norm_Nm=maxMoment;row.maximum_moment_scenario_id=T.scenario_id(iMoment);
    row.maximum_B0_norm_T=maxB;row.maximum_B0_scenario_id=T.scenario_id(iB);
    row.maximum_local_B_norm_T=maxBLocal;row.maximum_local_B_scenario_id=T.scenario_id(iBLocal);
    row.maximum_G_frobenius_Tpm=maxG;row.maximum_G_scenario_id=T.scenario_id(iG);
    row.maximum_G_component_Tpm=maxGComp;row.maximum_G_component_scenario_id=T.scenario_id(iGC);
    row.maximum_magnetic_cost_rms_T=maxCost;row.maximum_magnetic_cost_scenario_id=T.scenario_id(iCost);
    row.maximum_mean_vacuum_energy_density_Jpm3=maxEnergy;row.maximum_energy_density_scenario_id=T.scenario_id(iEnergy);
    row.maximum_relative_scaled_residual=maxRel;row.maximum_residual_scenario_id=T.scenario_id(iRel);
    row.all_scenarios_acceptable=maxRel<=cfg.magnetic.acceptance_relative_residual;
    row.minimum_map_rank=min(T.map_rank);row.maximum_condition_number=max(T.map_condition_number);
    finiteCoupling=T.coupling_ratio(isfinite(T.coupling_ratio));
    if isempty(finiteCoupling)
        if any(isinf(T.coupling_ratio)),row.maximum_coupling_ratio=Inf;else,row.maximum_coupling_ratio=NaN;end
    else
        row.maximum_coupling_ratio=max(finiteCoupling);
        if any(isinf(T.coupling_ratio)),row.maximum_coupling_ratio=Inf;end
    end
    row.coupling_class=localWorstCouplingClass(T.coupling_class);
    row.has_significant_coupling=row.coupling_class=="significant";
    setRows(i)=row;
    envelopes(i)=localComponentEnvelopes(T,id);
    extremaRows=[extremaRows;localScenarioExtrema(T,id,T.magnet_set_name(1))]; %#ok<AGROW>
end

summary=struct();
summary.magnet_set_summary=struct2table(setRows,'AsArray',true);
summary.envelopes=envelopes;
if isempty(extremaRows)
    summary.scenario_extrema=struct2table(localEmptyExtremaRow(),'AsArray',true);summary.scenario_extrema(1,:)=[];
else
    summary.scenario_extrema=struct2table(extremaRows,'AsArray',true);
end

acceptable=find(summary.magnet_set_summary.all_scenarios_acceptable);
if isempty(acceptable)
    summary.best_magnet_set_id="";
    summary.best_magnet_set_name="";
    summary.best_selection_note="No magnet set met the configured dimensionless relative-residual acceptance threshold. Sets are not labelled feasible or best.";
else
    [~,localIndex]=min(summary.magnet_set_summary.maximum_magnetic_cost_rms_T(acceptable));
    bestIndex=acceptable(localIndex);
    summary.best_magnet_set_id=summary.magnet_set_summary.magnet_set_id(bestIndex);
    summary.best_magnet_set_name=summary.magnet_set_summary.magnet_set_name(bestIndex);
    summary.best_selection_note="Fixed-configuration selection: residual-acceptable sets are compared by the minimum of their worst-case primary RMS-field cost.";
end

rejected=find(~summary.magnet_set_summary.all_scenarios_acceptable);
acceptedOrder=zeros(0,1);rejectedOrder=zeros(0,1);
if ~isempty(acceptable)
    acceptedKeys=[summary.magnet_set_summary.maximum_magnetic_cost_rms_T(acceptable), ...
        summary.magnet_set_summary.maximum_relative_scaled_residual(acceptable)];
    [~,localOrder]=sortrows(acceptedKeys,[1 2]);acceptedOrder=acceptable(localOrder);
end
if ~isempty(rejected)
    rejectedKeys=[summary.magnet_set_summary.maximum_relative_scaled_residual(rejected), ...
        summary.magnet_set_summary.maximum_magnetic_cost_rms_T(rejected)];
    [~,localOrder]=sortrows(rejectedKeys,[1 2]);rejectedOrder=rejected(localOrder);
end
order=[acceptedOrder(:);rejectedOrder(:)];
summary.fixed_configuration_ranking=summary.magnet_set_summary(order,:);
summary.ranking=summary.fixed_configuration_ranking; % Backward-compatible alias.
summary.fixed_configuration_ranking_note="Minimax view: accepted magnet sets are ordered by their maximum primary RMS-field cost over all scenarios; rejected sets are ordered by residual first.";
summary.ranking_note=summary.fixed_configuration_ranking_note;
summary.independent_scenario_ranking=localIndependentScenarioRanking(resultTable,cfg);
summary.independent_scenario_ranking_note="Independent-scenario view: choose the lowest-cost acceptable magnet set separately for each scenario, then order scenarios hardest-first by that best achievable cost.";
summary.acceptance_relative_residual=cfg.magnetic.acceptance_relative_residual;
end

function T=localIndependentScenarioRanking(results,cfg)
ids=unique(results.scenario_id,'stable');
rows=repmat(localEmptyIndependentRow(),numel(ids),1);
for i=1:numel(ids)
    sub=results(results.scenario_id==ids(i),:);
    row=localEmptyIndependentRow();
    row.scenario_id=ids(i);row.scenario_name=sub.scenario_name(1);
    acceptable=sub.relative_scaled_residual<=cfg.magnetic.acceptance_relative_residual;
    row.number_of_candidate_sets=height(sub);row.number_of_acceptable_sets=sum(acceptable);
    if any(acceptable)
        idxAll=find(acceptable);
        [bestCost,localIdx]=min(sub.magnetic_cost_rms_T(acceptable));
        idx=idxAll(localIdx);
        row.has_acceptable_set=true;
        row.best_magnet_set_id=sub.magnet_set_id(idx);row.best_magnet_set_name=sub.magnet_set_name(idx);
        row.best_magnetic_cost_rms_T=bestCost;
        row.best_mean_vacuum_energy_density_Jpm3=sub.mean_vacuum_energy_density_Jpm3(idx);
        row.best_relative_scaled_residual=sub.relative_scaled_residual(idx);
        row.force_req_norm_N=sub.force_req_norm_N(idx);row.moment_req_norm_Nm=sub.moment_req_norm_Nm(idx);
    else
        row.has_acceptable_set=false;
        [bestResidual,idx]=min(sub.relative_scaled_residual);
        row.best_relative_scaled_residual=bestResidual;
        row.best_magnet_set_id=sub.magnet_set_id(idx);row.best_magnet_set_name=sub.magnet_set_name(idx);
    end
    rows(i)=row;
end
T=struct2table(rows,'AsArray',true);
accepted=find(T.has_acceptable_set);rejected=find(~T.has_acceptable_set);
if ~isempty(accepted)
    [~,ord]=sort(T.best_magnetic_cost_rms_T(accepted),'descend');accepted=accepted(ord);
end
if ~isempty(rejected)
    [~,ord]=sort(T.best_relative_scaled_residual(rejected),'ascend');rejected=rejected(ord);
end
T=T([accepted(:);rejected(:)],:);
T.hardness_rank=(1:height(T)).';
end

function rows=localScenarioExtrema(T,setId,setName)
rows=repmat(localEmptyExtremaRow(),0,1);
quantities={ ...
    'Fx_mag_req_N','Fx magnetic requirement','N'; ...
    'Fy_mag_req_N','Fy magnetic requirement','N'; ...
    'Fz_mag_req_N','Fz magnetic requirement','N'; ...
    'Mx_mag_req_Nm','Mx magnetic requirement','N m'; ...
    'My_mag_req_Nm','My magnetic requirement','N m'; ...
    'Mz_mag_req_Nm','Mz magnetic requirement','N m'};
for i=1:size(quantities,1)
    values=T.(quantities{i,1});[~,idx]=max(abs(values));
    rows(end+1,1)=localMakeExtrema(setId,setName,quantities{i,2},values(idx),quantities{i,3},T,idx); %#ok<AGROW>
end
norms={ ...
    'force_req_norm_N','force requirement norm','N'; ...
    'moment_req_norm_Nm','moment requirement norm','N m'; ...
    'B_norm_T','B0 norm','T'; ...
    'B_local_max_norm_T','maximum local B norm','T'; ...
    'G_frobenius_Tpm','G Frobenius norm','T/m'; ...
    'G_max_abs_Tpm','maximum absolute G component','T/m'; ...
    'magnetic_cost_rms_T','primary RMS-field cost','T'; ...
    'relative_scaled_residual','relative scaled residual','1'};
for i=1:size(norms,1)
    values=T.(norms{i,1});[value,idx]=max(values);
    rows(end+1,1)=localMakeExtrema(setId,setName,norms{i,2},value,norms{i,3},T,idx); %#ok<AGROW>
end
end

function row=localMakeExtrema(setId,setName,quantity,value,units,T,idx)
row=localEmptyExtremaRow();
row.magnet_set_id=setId;row.magnet_set_name=setName;row.quantity=string(quantity);row.value=value;row.units=string(units);
row.scenario_id=T.scenario_id(idx);row.scenario_name=T.scenario_name(idx);
end

function class=localWorstCouplingClass(values)
values=string(values);
if any(values=="significant"),class="significant";elseif any(values=="insignificant"),class="insignificant";else,class="zero";end
end

function env=localEmptyEnvelope()
env=struct('magnet_set_id',"", ...
    'force_min',zeros(1,3),'force_min_scenario_id',strings(1,3), ...
    'force_max',zeros(1,3),'force_max_scenario_id',strings(1,3), ...
    'force_abs_max',zeros(1,3),'force_abs_max_scenario_id',strings(1,3), ...
    'moment_min',zeros(1,3),'moment_min_scenario_id',strings(1,3), ...
    'moment_max',zeros(1,3),'moment_max_scenario_id',strings(1,3), ...
    'moment_abs_max',zeros(1,3),'moment_abs_max_scenario_id',strings(1,3));
end

function env=localComponentEnvelopes(T,id)
forceVars={'Fx_mag_req_N','Fy_mag_req_N','Fz_mag_req_N'};
momentVars={'Mx_mag_req_Nm','My_mag_req_Nm','Mz_mag_req_Nm'};
env=localEmptyEnvelope();env.magnet_set_id=id;
[env.force_min,env.force_min_scenario_id]=localExtrema(T,forceVars,@min);
[env.force_max,env.force_max_scenario_id]=localExtrema(T,forceVars,@max);
[env.force_abs_max,env.force_abs_max_scenario_id]=localAbsExtrema(T,forceVars);
[env.moment_min,env.moment_min_scenario_id]=localExtrema(T,momentVars,@min);
[env.moment_max,env.moment_max_scenario_id]=localExtrema(T,momentVars,@max);
[env.moment_abs_max,env.moment_abs_max_scenario_id]=localAbsExtrema(T,momentVars);
end

function [values,ids]=localExtrema(T,names,fn)
values=zeros(1,3);ids=strings(1,3);
for j=1:3,[values(j),idx]=fn(T.(names{j}));ids(j)=T.scenario_id(idx);end
end
function [values,ids]=localAbsExtrema(T,names)
values=zeros(1,3);ids=strings(1,3);
for j=1:3
    raw=T.(names{j});[~,idx]=max(abs(raw));values(j)=raw(idx);ids(j)=T.scenario_id(idx);
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
'maximum_magnetic_cost_rms_T',NaN,'maximum_magnetic_cost_scenario_id',"", ...
'maximum_mean_vacuum_energy_density_Jpm3',NaN,'maximum_energy_density_scenario_id',"", ...
'maximum_relative_scaled_residual',NaN,'maximum_residual_scenario_id',"", ...
'all_scenarios_acceptable',false,'minimum_map_rank',NaN,'maximum_condition_number',NaN, ...
'coupling_class',"",'maximum_coupling_ratio',NaN,'has_significant_coupling',false);
end

function row=localEmptyExtremaRow()
row=struct('magnet_set_id',"",'magnet_set_name',"",'quantity',"",'value',NaN,'units',"",'scenario_id',"",'scenario_name',"");
end

function row=localEmptyIndependentRow()
row=struct('hardness_rank',NaN,'scenario_id',"",'scenario_name',"",'has_acceptable_set',false, ...
'number_of_candidate_sets',0,'number_of_acceptable_sets',0,'best_magnet_set_id',"",'best_magnet_set_name',"", ...
'best_magnetic_cost_rms_T',NaN,'best_mean_vacuum_energy_density_Jpm3',NaN,'best_relative_scaled_residual',NaN, ...
'force_req_norm_N',NaN,'moment_req_norm_Nm',NaN);
end
