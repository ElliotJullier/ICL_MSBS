function rerun_families(families)
%RERUN_FAMILIES Update chosen families after a source-audit correction.
root=string(fileparts(fileparts(mfilename('fullpath'))));addpath(root,fullfile(root,'src'),fullfile(root,'cases'),fullfile(root,'research'));
out=fullfile(root,'research','outputs');manifest=readtable(fullfile(out,'study_manifest.csv'),'TextType','string');
info=struct('source_type',"research_constructor",'case_function_name',"msbsstudy.makeCase",'case_file_path',"");
for family=string(families)
    for H=[.6 1]
        for beta=[.03 .1 .2]
            for orient=["h","up"]
                for fraction=[1 .1]
                    cfg=msbsstudy.makeCase(family,H,beta,orient,fraction);
                    folder=fullfile(out,cfg.meta.case_id);if ~isfolder(folder),mkdir(folder);end
                    save(fullfile(folder,'study_input.mat'),'cfg');
                    study=msbsreq.run(cfg,root,info);T=study.results;
                    T.case_id=repmat(cfg.meta.case_id,height(T),1);T.family=repmat(family,height(T),1);
                    T.tunnel_side_m=repmat(H,height(T),1);T.orientation=repmat(orient,height(T),1);
                    T.magnet_volume_fraction=repmat(fraction,height(T),1);
                    writetable(T,fullfile(folder,'scenario_results.csv'));
                    writetable(study.summary.fixed_configuration_ranking,fullfile(folder,'fixed_configuration_ranking.csv'));
                    writetable(study.summary.independent_scenario_ranking,fullfile(folder,'independent_scenario_ranking.csv'));
                    writetable(study.summary.scenario_extrema,fullfile(folder,'scenario_extrema.csv'));
                    writetable(study.summary.magnet_set_summary,fullfile(folder,'magnet_set_summary.csv'));
                    if ~isempty(study.sensitivity_results),writetable(study.sensitivity_results,fullfile(folder,'magnetic_cost_sensitivity.csv'));end
                    fid=fopen(fullfile(folder,'warnings.txt'),'w');fprintf(fid,'%s\n',study.warnings);fclose(fid);
                    key=family+"_"+H+"_"+beta+"_"+orient+"_"+fraction;
                    i=find(manifest.requested_configuration==key);manifest.status(i)="ran";manifest.case_id(i)=cfg.meta.case_id;
                    manifest.result_rows(i)=height(T);manifest.best_fixed_set_id(i)=study.summary.best_magnet_set_id;
                    manifest.reason(i)="";
                end
            end
        end
    end
end
writetable(manifest,fullfile(out,'study_manifest.csv'));
end
