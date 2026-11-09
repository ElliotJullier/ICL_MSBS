function manifest = run_portfolio()
%RUN_PORTFOLIO Author, run and export every permitted study configuration.
root=string(fileparts(fileparts(mfilename('fullpath'))));addpath(root,fullfile(root,'src'),fullfile(root,'cases'),fullfile(root,'research'));
out=fullfile(root,'research','outputs');if ~isfolder(out),mkdir(out);end
families=["sphere","cuboid","ahmed","naca0012","sc20714","cylinder_crossflow","cylinder_inline"];
manifest=table();allResults=table();allBest=table();ii=0;
info=struct('source_type',"research_constructor",'case_function_name',"msbsstudy.makeCase",'case_file_path',string(fullfile(root,'research','+msbsstudy','makeCase.m')));
for family=families
    for H=[.6 1]
        for beta=[.03 .10 .20]
            for orient=["h","up"]
                for fraction=[1 .1]
                    ii=ii+1;key=family+"_"+H+"_"+beta+"_"+orient+"_"+fraction;
                    fprintf('PORTFOLIO %d: %s\n',ii,key);
                    try
                        cfg=msbsstudy.makeCase(family,H,beta,orient,fraction);
                        caseDir=fullfile(out,cfg.meta.case_id);if ~isfolder(caseDir),mkdir(caseDir);end
                        save(fullfile(caseDir,'study_input.mat'),'cfg');
                        % Avoid repeated large rendering/MAT exports; retain reproducible input,
                        % pointwise primary/sensitivity outputs and all ranking tables.
                        study=msbsreq.run(cfg,root,info);T=study.results;
                        T.case_id=repmat(cfg.meta.case_id,height(T),1);T.family=repmat(family,height(T),1);
                        T.tunnel_side_m=repmat(H,height(T),1);T.orientation=repmat(orient,height(T),1);
                        T.magnet_volume_fraction=repmat(fraction,height(T),1);
                        writetable(T,fullfile(caseDir,'scenario_results.csv'));
                        writetable(study.summary.fixed_configuration_ranking,fullfile(caseDir,'fixed_configuration_ranking.csv'));
                        writetable(study.summary.independent_scenario_ranking,fullfile(caseDir,'independent_scenario_ranking.csv'));
                        writetable(study.summary.scenario_extrema,fullfile(caseDir,'scenario_extrema.csv'));
                        writetable(study.summary.magnet_set_summary,fullfile(caseDir,'magnet_set_summary.csv'));
                        if ~isempty(study.sensitivity_results),writetable(study.sensitivity_results,fullfile(caseDir,'magnetic_cost_sensitivity.csv'));end
                        fid=fopen(fullfile(caseDir,'warnings.txt'),'w');fprintf(fid,'%s\n',study.warnings);fclose(fid);
                        if strlength(study.summary.best_magnet_set_id)>0
                            best=T(T.magnet_set_id==study.summary.best_magnet_set_id,:);
                            allBest=localUnion(allBest,best);
                        end
                        allResults=localUnion(allResults,T);
                        row=table(key,"ran",string(cfg.meta.case_id),height(T),string(study.summary.best_magnet_set_id),"", ...
                            'VariableNames',{'requested_configuration','status','case_id','result_rows','best_fixed_set_id','reason'});
                    catch err
                        row=table(key,"rejected","",0,"",string(err.identifier)+": "+string(err.message), ...
                            'VariableNames',{'requested_configuration','status','case_id','result_rows','best_fixed_set_id','reason'});
                        if ~startsWith(string(err.identifier),"msbsstudy:"),rethrow(err);end
                    end
                    manifest=[manifest;row]; %#ok<AGROW>
                    writetable(manifest,fullfile(out,'study_manifest.csv'));
                end
            end
        end
    end
end
writetable(allResults,fullfile(out,'all_scenario_results.csv'));
writetable(allBest,fullfile(out,'selected_fixed_configuration_results.csv'));
end
function A=localUnion(A,B)
if isempty(A),A=B;return,end
names=union(string(A.Properties.VariableNames),string(B.Properties.VariableNames),'stable');
for name=names
    if ~ismember(name,A.Properties.VariableNames),A.(name)=localMissing(B.(name),height(A));end
    if ~ismember(name,B.Properties.VariableNames),B.(name)=localMissing(A.(name),height(B));end
end
A=[A(:,cellstr(names));B(:,cellstr(names))];
end
function col=localMissing(example,n)
if isnumeric(example),col=nan(n,size(example,2));elseif islogical(example),col=false(n,1);else,col=repmat("",n,1);end
end
