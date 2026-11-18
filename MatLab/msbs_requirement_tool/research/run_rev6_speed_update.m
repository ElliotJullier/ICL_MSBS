function run_rev6_speed_update(rev6Folder, outputFolder)
%RUN_REV6_SPEED_UPDATE Re-run the supplied Rev6 steady inputs at 15 and 35 m/s.
arguments
    rev6Folder (1,1) string
    outputFolder (1,1) string
end
toolRoot=string(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(toolRoot,'src'));
if ~isfolder(fullfile(outputFolder,'inputs')),mkdir(fullfile(outputFolder,'inputs'));end
files=dir(fullfile(rev6Folder,'inputs','*.mat'));
assert(numel(files)==31,'Expected the 30 sizing configurations and the Sawada benchmark.');

% Existing approximate Fig. 4 reads, plus the matching curve values used
% in the three Rev6 sphere geometries. Interpolate on its log-Re axis.
smallSphere=msbsstudy.makeCase("sphere",1,.03,"h",1);
reCurve=smallSphere.scenarios.Re;
cdCurve=smallSphere.scenarios.CD;
for f=files(startsWith({files.name},'sphere_') & endsWith({files.name},'_v100.mat')).'
    original=load(fullfile(f.folder,f.name),'cfg');
    reCurve(end+1)=original.cfg.scenarios.Re;
    cdCurve(end+1)=original.cfg.scenarios.CD;
end
[reCurve,order]=sort(reCurve);
cdCurve=cdCurve(order);
writetable(table(reCurve,cdCurve,'VariableNames',{'Re','CD'}),fullfile(outputFolder,'sphere_drag_curve.csv'));

combined=table();
for f=files.'
    if startsWith(f.name,'sawada'),continue,end
    original=load(fullfile(f.folder,f.name),'cfg');
    cfg=original.cfg;
    base=cfg.scenarios;
    assert(all(base.speed_mps==50) && cfg.mass.solid_body_density_kgm3==320);
    scenarios=base;
    for speed=[15 35]
        rows=base;
        rows.speed_mps(:)=speed;
        rows.Re=base.Re.*(speed./base.speed_mps);
        if ismember('Re_L',base.Properties.VariableNames),rows.Re_L=rows.Re;end
        if cfg.aero.mode=="direct_wrench"
            names={'Fx_aero_N','Fy_aero_N','Fz_aero_N','Mx_aero_Nm','My_aero_Nm','Mz_aero_Nm'};
            rows{:,names}=base{:,names}.*(speed./base.speed_mps).^2;
        end
        if cfg.meta.family=="sphere"
            rows.CD=interp1(log(reCurve),cdCurve,log(rows.Re),'linear');
            assert(all(isfinite(rows.CD)));
            rows.scenario_name(:)="U"+speed;
            rows.operating_group=rows.scenario_name;
        end
        if cfg.meta.family=="square_prism"
            rows.Re_basis(rows.Re<1e5)="below_source_Re_range_coefficient_transfer";
        end
        scenarios=[scenarios;rows]; %#ok<AGROW>
    end
    cfg.scenarios=scenarios;
    % The supplied source solve is aerodynamic-only. Gravity biases are
    % evaluated separately on the same geometry, pose and magnet layout.
    cfg.output.enable=false;
    cfg.visualisation.enable=false;
    inputInfo=struct('source_type',"struct",'case_function_name',"");
    baseline=original.cfg;
    baseline.output.enable=false;
    baseline.visualisation.enable=false;
    baseStudy=msbsreq.run(baseline,toolRoot,inputInfo);
    cfg.scenarios=scenarios(height(base)+1:end,:);
    save(fullfile(outputFolder,'inputs',f.name),'cfg');
    study=msbsreq.run(cfg,toolRoot,inputInfo);
    result=[aerodynamicResults(baseStudy);aerodynamicResults(study)];
    result.case_id(:)=cfg.meta.case_id;
    ids=str2double(extractAfter(result.scenario_id,1));
    result.rev6_scenario_id=compose("S%05d",mod(ids-1,height(base))+1);
    % Keep only the common result fields, independent of family metadata.
    if isempty(combined)
        combined=result;
    else
        common=intersect(combined.Properties.VariableNames,result.Properties.VariableNames,'stable');
        combined=[combined(:,common);result(:,common)]; %#ok<AGROW>
    end
end
writetable(combined,fullfile(outputFolder,'matlab_steady_solves.csv'));
end

function result=aerodynamicResults(study)
% Use the unchanged tool's maps, geometry and cost for Rev6's separate
% aerodynamic component. The regular study solve includes gravity.
records=study.records;
cfg=study.config_resolved;
loads=[records.loads];
wrenches=-[loads.aero_wrench_T];
scales=struct('force_N',max(cfg.magnetic.minimum_force_scale_N,max(vecnorm(wrenches(1:3,:)))), ...
    'moment_Nm',max(cfg.magnetic.minimum_moment_scale_Nm,max(vecnorm(wrenches(4:6,:)))));
for k=1:numel(records)
    records(k).loads.required_magnetic_wrench_T=wrenches(:,k);
    records(k).solution=msbsreq.solveMagneticRequirement(records(k).map,wrenches(:,k), ...
        scales,cfg,study.magnetic_cost_metrics.primary);
    records(k).solution.coupling_class=records(k).map.coupling.classification;
    records(k).solution.coupling_ratio=records(k).map.coupling.ratio;
end
result=msbsreq.buildResultTable(records);
result.B_at_magnets_T=arrayfun(@(r) string(mat2str(r.solution.B_at_each_magnet_T.',15)),records);
end
