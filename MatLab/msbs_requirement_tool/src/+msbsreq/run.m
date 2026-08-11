function study = run(configRaw, projectRoot, inputInfo)
%RUN Execute a complete validated MSBS requirement study.
arguments
    configRaw (1,1) struct
    projectRoot (1,1) string
    inputInfo (1,1) struct
end

cfg=msbsreq.resolveConfig(configRaw);
warnings=msbsreq.validateConfig(cfg,projectRoot);
localPrintValidation(cfg,warnings);

tunnel=msbsreq.buildTunnel(cfg);
geometry=msbsreq.buildGeometry(cfg,tunnel);
if geometry.nominal_blockage_ratio>cfg.validation.blockage_advisory_limit
    warnings(end+1,1)="Actual nominal blockage exceeds the configured advisory limit.";
end
[magnetSets,magnetWarnings]=msbsreq.buildMagnetSets(cfg,geometry,projectRoot);
warnings=[warnings(:);magnetWarnings(:)];

massProperties=repmat( ...
    msbsreq.calculateMassProperties(cfg,geometry,magnetSets(1)), ...
    numel(magnetSets),1);
for i=2:numel(magnetSets)
    massProperties(i)=msbsreq.calculateMassProperties(cfg,geometry,magnetSets(i));
end
warnings(end+1,1)="Mass properties use the hybrid explicit-magnet plus uniformly distributed shell approximation unless overridden.";
if numel(cfg.frames.body_attitude_cases)>1 || cfg.motion.mode=="harmonic_single_frequency" || cfg.motion.mode=="time_history"
    warnings(end+1,1)="Body attitude can vary while blockage is reported only at the nominal configured orientation.";
end

scenarios=msbsreq.buildScenarioTable(cfg);
recordCount=numel(magnetSets)*height(scenarios);
records=repmat(localEmptyRecord(),recordCount,1);
index=0;
for iSet=1:numel(magnetSets)
    for iScenario=1:height(scenarios)
        index=index+1;
        loads=msbsreq.calculateRequiredMagneticWrench(cfg,tunnel,geometry, ...
            scenarios(iScenario,:),massProperties(iSet));
        map=msbsreq.buildMagneticMap(magnetSets(iSet),loads.scenario.R_TB, ...
            massProperties(iSet).centre_of_mass_B_m);
        records(index).magnet_set=magnetSets(iSet);
        records(index).mass_properties=massProperties(iSet);
        records(index).loads=loads;
        records(index).map=map;
    end
end

requiredWrenches=zeros(6,recordCount);
for i=1:recordCount,requiredWrenches(:,i)=records(i).loads.required_magnetic_wrench_T;end
forceScale=max(cfg.magnetic.minimum_force_scale_N,max(vecnorm(requiredWrenches(1:3,:),2,1)));
momentScale=max(cfg.magnetic.minimum_moment_scale_Nm,max(vecnorm(requiredWrenches(4:6,:),2,1)));
scales=struct('force_N',forceScale,'moment_Nm',momentScale);

for i=1:recordCount
    records(i).solution=msbsreq.solveMagneticRequirement(records(i).map, ...
        records(i).loads.required_magnetic_wrench_T,scales,cfg);
end
results=msbsreq.buildResultTable(records);
resolutionResults=msbsreq.buildResolutionTable(records,scales,cfg);
summary=msbsreq.summariseResults(results,cfg);
numericalWarnings=localNumericalWarnings(records,geometry,cfg);
warnings=[warnings(:);numericalWarnings(:)];
warnings=unique(warnings(strlength(warnings)>0),'stable');

metadata=localMetadata(projectRoot,inputInfo,cfg,height(scenarios),numel(magnetSets),numel(warnings));
study=struct();
study.config_raw=configRaw;
study.config_resolved=cfg;
study.tunnel=tunnel;
study.frames=cfg.frames;
study.geometry=geometry;
study.mass_properties=massProperties;
study.magnet_sets=magnetSets;
study.scenarios=scenarios;
study.records=records;
study.results=results;
study.resolution_results=resolutionResults;
study.summary=summary;
study.warnings=warnings;
study.output_folder="";
study.metadata=metadata;
study.scales=scales;

if cfg.output.enable
    outputFolder=msbsreq.exportResults(study,projectRoot,inputInfo);
    study.output_folder=string(outputFolder);
end
localPrintConsoleSummary(study);
end

function record=localEmptyRecord()
record=struct('magnet_set',struct(),'mass_properties',struct(), ...
    'loads',struct(),'map',struct(),'solution',struct());
end

function warnings=localNumericalWarnings(records,geometry,cfg)
warnings=strings(0,1);
setIds=unique(string(arrayfun(@(r)r.magnet_set.id,records,'UniformOutput',false)),'stable');
for id=setIds(:).'
    indices=find(arrayfun(@(r)r.magnet_set.id==id,records));
    ranks=arrayfun(@(r)r.map.rank,records(indices));
    conditions=arrayfun(@(r)r.map.condition_number,records(indices));
    residuals=arrayfun(@(r)r.solution.relative_scaled_residual,records(indices));
    if min(ranks)<6
        warnings(end+1,1)="Magnet set "+id+" has magnetic-map rank below six; some wrench directions can be uncontrollable.";
    end
    if max(conditions)>cfg.magnetic.condition_warning_threshold
        warnings(end+1,1)="Magnet set "+id+" has a poorly conditioned magnetic map under at least one attitude.";
    end
    if max(residuals)>cfg.magnetic.acceptance_relative_residual
        warnings(end+1,1)="Magnet set "+id+" exceeds the configured dimensionless residual-acceptance threshold.";
    end
    maxB=max(arrayfun(@(r)r.solution.B_local_max_norm_T,records(indices)));
    maxG=max(arrayfun(@(r)r.solution.G_frobenius_Tpm,records(indices)));
    if ~isempty(cfg.magnetic.advisory_B_max_T) && maxB>cfg.magnetic.advisory_B_max_T
        warnings(end+1,1)="Magnet set "+id+" exceeds the user advisory field limit.";
    end
    if ~isempty(cfg.magnetic.advisory_G_max_Tpm) && maxG>cfg.magnetic.advisory_G_max_Tpm
        warnings(end+1,1)="Magnet set "+id+" exceeds the user advisory gradient limit.";
    end
end
largeMagnet=false;
for iRecord=1:numel(records)
    for iMagnet=1:numel(records(iRecord).magnet_set.magnets)
        ratio=max(records(iRecord).magnet_set.magnets(iMagnet).dimensions_local_m)/geometry.characteristic_length_m;
        if ratio > 0.5
            largeMagnet = true;
            break
        end
    end
    if largeMagnet
        break
    end
end
if largeMagnet
    warnings(end+1,1)="At least one magnet is large relative to the model characteristic length; the point-dipole approximation should be checked.";
end
for i=1:numel(records)
    positions=records(i).map.positions_T_m;
    if size(positions,2)>1
        separations=pdistEquivalent(positions);
        if max(separations)>geometry.characteristic_length_m
            warnings(end+1,1)="At least one multi-magnet set spans more than one model characteristic length; a common first-order field may be inadequate.";
            break
        end
    end
end
end

function distances=pdistEquivalent(points)
n=size(points,2);distances=zeros(n*(n-1)/2,1);k=0;
for i=1:n-1
    for j=i+1:n
        k=k+1;distances(k)=norm(points(:,i)-points(:,j));
    end
end
end

function metadata=localMetadata(projectRoot,inputInfo,cfg,nScenarios,nSets,nWarnings)
metadata=struct();
metadata.timestamp=string(datetime('now','TimeZone','local','Format','yyyy-MM-dd HH:mm:ss Z'));
metadata.matlab_version=string(version);
metadata.operating_system=string(computer);
versionFile=fullfile(projectRoot,'VERSION');
if isfile(versionFile)
    metadata.project_version = strtrim(string(fileread(versionFile)));
else
    metadata.project_version = "unknown";
end
command=sprintf('git -C "%s" rev-parse HEAD 2>&1',char(projectRoot));
[status,hash]=system(command);
if status == 0
    metadata.git_commit_hash = strtrim(string(hash));
else
    metadata.git_commit_hash = "unavailable";
end
metadata.input_source_type=string(inputInfo.source_type);
metadata.raw_case_function_name=string(inputInfo.case_function_name);
metadata.warning_count=nWarnings;
metadata.magnetic_model=cfg.magnetic.model;
metadata.number_of_scenarios=nScenarios;
metadata.number_of_magnet_sets=nSets;
end

function localPrintValidation(cfg,warnings)
fprintf('\nMSBS requirement study validation\n');
fprintf('  Case: %s\n',cfg.meta.case_id);
fprintf('  Geometry: %s (%s sizing)\n',cfg.geometry.type,cfg.geometry.sizing.mode);
fprintf('  Magnet mode: %s\n',cfg.magnets.mode);
fprintf('  Motion mode: %s\n',cfg.motion.mode);
fprintf('  Aerodynamic mode: %s\n',cfg.aero.mode);
fprintf('  Relative residual acceptance threshold: %.3g (dimensionless)\n', ...
    cfg.magnetic.acceptance_relative_residual);
fprintf('  Initial validation warnings: %d\n\n',numel(warnings));
end

function localPrintConsoleSummary(study)
S=study.summary.magnet_set_summary;
fprintf('\nMSBS requirement study complete\n');
fprintf('  Case ID: %s\n',study.config_resolved.meta.case_id);
fprintf('  Scenarios: %d\n',height(study.scenarios));
fprintf('  Magnet sets: %d\n',numel(study.magnet_sets));
fprintf('  Model dimensions (m): [%.4g %.4g %.4g]\n',study.geometry.outer_dimensions_B_m);
fprintf('  Nominal blockage: %.4g (%.3g%%)\n',study.geometry.nominal_blockage_ratio,100*study.geometry.nominal_blockage_ratio);
fprintf('  Estimated total mass, first set: %.6g kg\n',study.mass_properties(1).total_mass_kg);
fprintf('  Magnet volume, first set: %.6g m^3\n',sum([study.magnet_sets(1).magnets.volume_m3]));
fprintf('  Dipole magnitude, first set: %.6g A m^2\n',sum([study.magnet_sets(1).magnets.dipole_moment_magnitude_Am2]));
fprintf('  Worst required force: %.6g N\n',max(S.maximum_force_norm_N));
fprintf('  Worst required moment: %.6g N m\n',max(S.maximum_moment_norm_Nm));
if study.config_resolved.requirement_resolution.enable
    fprintf('  Incremental resolution rows: %d\n',height(study.resolution_results));
end
for i=1:height(S)
    fprintf('  %s: max local B %.6g T, max ||G||F %.6g T/m, max relative residual %.3g\n', ...
        S.magnet_set_name(i),S.maximum_local_B_norm_T(i),S.maximum_G_frobenius_Tpm(i), ...
        S.maximum_relative_scaled_residual(i));
end
if strlength(study.summary.best_magnet_set_id)>0
    fprintf('  Best residual-accepted set: %s\n',study.summary.best_magnet_set_name);
else
    fprintf('  Best set: none met the residual threshold\n');
end
if strlength(study.output_folder) > 0
    fprintf('  Results: %s\n', char(study.output_folder));
end
fprintf('\n');
end
