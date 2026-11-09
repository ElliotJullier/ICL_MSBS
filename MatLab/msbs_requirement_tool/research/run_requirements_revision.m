function run_requirements_revision(out)
%RUN_REQUIREMENTS_REVISION Reproduce matched-Re study and selection tables.
root=string(fileparts(fileparts(mfilename('fullpath'))));
addpath(root,fullfile(root,'src'),fullfile(root,'cases'),fullfile(root,'research'));
if nargin==0,out=fullfile(root,'research','outputs','revision');end
if ~isfolder(out),mkdir(out);end
inputDir=fullfile(out,'inputs');
if ~isfolder(inputDir),mkdir(inputDir);end
info=struct('source_type',"research_constructor",'case_function_name',"msbsstudy.revisionCase");
results=cell(0,1);
selected=cell(0,1);
ranking=table();
summary=table();
manifest=table();
layouts=table();
for family=["sphere","cuboid","ahmed","naca0012","sc20714","cylinder_crossflow","cylinder_inline"]
    blockageValues=[.03 .10 .20];
    if family=="cylinder_crossflow",blockageValues=[.03 .08 .10 .20];end
    for H=[.6 1]
        for b=blockageValues
            for orient=["h","up"]
                for fraction=[1 .1]
                    status="ran";
                    reason="";
                    id="";
                    try
                        cfg=msbsstudy.revisionCase(family,H,b,orient,fraction);
                        id=cfg.meta.case_id;
                        fprintf('REVISED STUDY %s\n',id);
                        save(fullfile(inputDir,id+".mat"),'cfg');
                        study=msbsreq.run(cfg,root,info);
                        T=study.results;
                        T.Re=cfg.scenarios.Re(repmat((1:height(cfg.scenarios))',numel(study.magnet_sets),1));
                        T.source_phase_rad=nan(height(T),1);
                        if ismember('phase_rad',cfg.scenarios.Properties.VariableNames)
                            T.source_phase_rad=repmat(cfg.scenarios.phase_rad,numel(study.magnet_sets),1);
                        end
                        for field=["case_id","family","orientation","tunnel_side_m","target_maximum_blockage", ...
                                "magnet_volume_fraction","preferred_selection"]
                            T.(field)=repmat(cfg.meta.(field),height(T),1);
                        end
                        T.sizing_eligible=T.controllable;
                        if any(family==["cuboid","ahmed"])
                            T.sizing_eligible=T.sizing_eligible & T.map_rank==6;
                        end
                        results{end+1}=T; %#ok<AGROW>
                        [S,R,W]=localRank(study,T);
                        selected{end+1}=S; %#ok<AGROW>
                        ranking=[ranking;R]; %#ok<AGROW>
                        summary=[summary;W]; %#ok<AGROW>
                        layouts=[layouts;localLayoutTable(study,id)]; %#ok<AGROW>
                    catch err
                        if ~startsWith(string(err.identifier),"msbsstudy:"),rethrow(err);end
                        status="excluded";
                        reason=string(err.message);
                    end
                    M=table(family,H,b,orient,fraction,status,id,reason, ...
                        'VariableNames',{'family','tunnel_side_m','blockage','orientation','magnet_volume_fraction','status','case_id','reason'});
                    manifest=[manifest;M]; %#ok<AGROW>
                end
            end
        end
    end
end
writetable(localUnion(results),fullfile(out,'candidates.csv'));
writetable(localUnion(selected),fullfile(out,'selected_primary.csv'));
writetable(ranking,fullfile(out,'hardware_rankings.csv'));
writetable(summary,fullfile(out,'selection_sensitivity.csv'));
writetable(manifest,fullfile(out,'coverage.csv'));
writetable(layouts,fullfile(out,'installed_magnets_and_mass.csv'));
writetable(msbsstudy.morseInputs(),fullfile(out,'morse_figure_reads.csv'));
end

function [S,R,W]=localRank(study,T)
cfg=study.config_resolved;
metric=study.magnetic_cost_metrics.primary;
L=metric.reference_cube_side_m;
R=table();
W=table();
S=table();
valid=T.sizing_eligible;
for k=1:4
    metric.id=["L_model","L_half","L_double","L_30pct_tunnel"];
    metric.id=metric.id(k);
    lengths=[L,.5*L,2*L,.3*study.tunnel.width_m];
    metric.reference_cube_side_m=lengths(k);
    metric.gradient_equivalent_length_m=lengths(k)/sqrt(12);
    J=T.magnetic_cost_rms_T;
    if k>1
        for i=find(valid).'
            rec=study.records(i);
            sol=msbsreq.solveMagneticRequirement(rec.map,rec.loads.required_magnetic_wrench_T,study.scales,cfg,metric);
            J(i)=sol.magnetic_cost_rms_T;
            assert(sol.controllable,'msbsstudy:SensitivityFeasibility','Cost length changed the residual acceptance.');
        end
    end
    [rows,stats,ranks]=msbsstudy.selectHardware(T,J,valid,metric.id);
    ranks.case_id=repmat(cfg.meta.case_id,height(ranks),1);
    ranks.magnet_set_name=strings(height(ranks),1);
    for i=1:height(ranks)
        ranks.magnet_set_name(i)=T.magnet_set_name(find(T.magnet_set_id==ranks.magnet_set_id(i),1));
    end
    stats.case_id=cfg.meta.case_id;
    stats.L_ref_m=lengths(k);
    winners=rows(rows.selection_mode=="independent_group",:);
    [~,first]=unique(winners.operating_group,'stable');
    stats.independent_winners=strjoin(winners.operating_group(first)+"="+winners.magnet_set_id(first),";");
    if k==1,S=rows;end
    R=[R;ranks]; %#ok<AGROW>
    W=[W;stats]; %#ok<AGROW>
end
end

function T=localLayoutTable(study,id)
T=table();
for i=1:numel(study.magnet_sets)
    set=study.magnet_sets(i);
    mass=study.mass_properties(i);
    extent=msbsstudy.magnetExtent(set.magnets,eye(3));
    maxExtent=max(cellfun(@(R) max(msbsstudy.magnetExtent(set.magnets,R)),study.scenarios.R_TB));
    for j=1:numel(set.magnets)
        m=set.magnets(j);
        c=m.centre_B_m;
        d=m.dimensions_local_m;
        u=m.R_BM*m.magnetisation_direction_M;
        row=table(id,set.id,set.name,m.name,m.volume_m3,m.mass_kg,mass.total_mass_kg,mass.shell_mass_kg, ...
            c(1),c(2),c(3),d(1),d(2),d(3),u(1),u(2),u(3),max(extent),maxExtent, ...
            string(mat2str(mass.centre_of_mass_B_m,10)),string(mat2str(mass.inertia_B_kgm2,10)), ...
            'VariableNames',{'case_id','magnet_set_id','magnet_set_name','part','magnet_volume_m3','magnet_mass_kg', ...
            'total_mass_kg','abs_mass_kg','cx_m','cy_m','cz_m','dx_local_m','dy_local_m','dz_local_m', ...
            'mhat_x_B','mhat_y_B','mhat_z_B','max_body_axis_extent_m','max_tested_tunnel_axis_extent_m','CoM_B_m','I_C_B_kgm2'});
        T=[T;row]; %#ok<AGROW>
    end
end
end

function A=localUnion(tables)
names=strings(0,1);
for k=1:numel(tables)
    names=union(names,string(tables{k}.Properties.VariableNames),'stable');
end
for name=reshape(names,1,[])
    example=find(cellfun(@(t) ismember(name,t.Properties.VariableNames),tables),1);
    exemplar=tables{example}.(name);
    for k=1:numel(tables)
        if ismember(name,tables{k}.Properties.VariableNames),continue,end
        n=height(tables{k});
        if isnumeric(exemplar),tables{k}.(name)=nan(n,1);
        else,tables{k}.(name)=strings(n,1);
        end
    end
end
for k=1:numel(tables),tables{k}=tables{k}(:,cellstr(names));end
A=vertcat(tables{:});
end
