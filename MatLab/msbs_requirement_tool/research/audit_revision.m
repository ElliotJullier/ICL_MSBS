function audit_revision(out)
%AUDIT_REVISION Check phase sampling and the excluded P+S trace sensitivity.
root=string(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'src'),fullfile(root,'cases'),fullfile(root,'research'));
if nargin==0,out=fullfile(root,'research','outputs','revision');end
info=struct('source_type',"research_audit",'case_function_name',"audit_revision");
caseId="cylinder_crossflow_T060_b03_h_v10";
summary=readtable(fullfile(out,'selection_sensitivity.csv'),'TextType','string');
winner=summary.fixed_winner(summary.case_id==caseId&summary.metric=="L_model");
id=str2double(extractAfter(winner,"MANUAL_"));
R=table();
for N=[72 144 288]
    cfg=msbsstudy.revisionCase("cylinder_crossflow",.6,.03,"h",.1,N);
    cfg.magnets.sets=cfg.magnets.sets(id);
    study=msbsreq.run(cfg,root,info);
    T=study.results;
    [G,i]=max(T.G_frobenius_Tpm);
    R=[R;table(N,G,max(T.G_max_abs_Tpm),T.operating_group(i),T.time_s(i), ...
        'VariableNames',{'samples_per_cycle','G_frobenius_Tpm','G_max_abs_Tpm','wake','time_s'})]; %#ok<AGROW>
end
writetable(R,fullfile(out,'phase_resolution_check.csv'));

% Use the fixed winner of the reconstructed histories for every geometry.
inputs=dir(fullfile(out,'inputs','cylinder_crossflow_*.mat'));
bound=cell(numel(inputs),1);
for k=1:numel(inputs)
    loaded=load(fullfile(inputs(k).folder,inputs(k).name),'cfg');
    cfg=loaded.cfg;
    winner=summary.fixed_winner(summary.case_id==cfg.meta.case_id&summary.metric=="L_model");
    index=str2double(extractAfter(winner,"MANUAL_"));
    bound{k}=localPplusS(cfg,index,root,info);
end
writetable(vertcat(bound{:}),fullfile(out,'PplusS_trace_sensitivity.csv'));
end

function T=localPplusS(cfg,id,root,info)
% Fig. 8 P+S trace reaches approximately 12 in vortex coefficient. Round
% to 13 and add the maximum potential component of Eq. 3. Sweep both
% force signs at both acceleration peaks without assuming their phase.
cfg.magnets.sets=cfg.magnets.sets(id);
cfg.scenario_set.relationship="fixed_envelope";
T=cfg.scenarios([19 55 19 55],:);
T.scenario_name="PplusS_trace_bound_"+(1:4)';
T.operating_group=T.scenario_name;
T.scenario_group_id=T.scenario_name;
D=T.Re_length_m(1);
AoverD=1.34;
lambda=4.4;
f=T.speed_mps(1)/(D*lambda);
theta=[pi/2;3*pi/2;pi/2;3*pi/2];
T.phase_rad=theta;
T.time_s=theta/(2*pi*f);
T.A_over_D(:)=AoverD;
T.fD_over_U(:)=1/lambda;
T.frequency_Hz(:)=f;
T.z_C_T_m=D*AoverD*sin(theta);
T.vz_C_T_mps=2*pi*f*D*AoverD*cos(theta);
T.a_z=-(2*pi*f)^2*T.z_C_T_m;
H=cfg.meta.tunnel_side_m;
T.wall_envelope_fraction=max(10*D,D+2*abs(T.z_C_T_m))/H;
assert(all(T.wall_envelope_fraction<1));
potential=2*pi^3*AoverD/lambda^2;
T.CL=[1;1;-1;-1]*(13+potential);
T.source_id(:)="MorseWilliamson2009_Fig8_p707_and_Eq3_trace_screen";
T.source_condition(:)="P+S phase-independent screen conditional on trace allowance";
cfg.scenarios=T;
study=msbsreq.run(cfg,root,info);
T=study.results;
T.drive_phase_rad=theta;
T.CV_trace_abs_assumed=repmat(13,4,1);
T.Cpotential_amp=repmat(potential,4,1);
T.status=repmat("conditional_trace_sensitivity_excluded_from_targets",4,1);
for key=["case_id","orientation","tunnel_side_m","target_maximum_blockage","magnet_volume_fraction"]
    T.(key)=repmat(cfg.meta.(key),height(T),1);
end
end
