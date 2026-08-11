function outputFolder = exportResults(study, projectRoot, inputInfo)
%EXPORTRESULTS Save reproducible MAT, JSON, CSV, Markdown, and figure outputs.
arguments
    study (1,1) struct
    projectRoot (1,1) string
    inputInfo (1,1) struct
end
root=string(study.config_resolved.output.root_folder);
rootChar=char(root);
isAbsolute=startsWith(root,filesep) || ~isempty(regexp(rootChar,'^[A-Za-z]:[\\/]','once'));
if isAbsolute
    outputRoot=root;
else
    outputRoot=fullfile(projectRoot,root);
end
if ~isfolder(outputRoot),mkdir(outputRoot);end
caseFolder=fullfile(outputRoot,localSafeName(study.config_resolved.meta.case_id));
if ~isfolder(caseFolder),mkdir(caseFolder);end
stamp=string(datetime('now','Format','yyyyMMdd_HHmmss'));
outputFolder=fullfile(caseFolder,stamp);
if isfolder(outputFolder)
    if study.config_resolved.output.overwrite_existing
        rmdir(outputFolder,'s');
    else
        suffix=1;
        while isfolder(outputFolder+"_"+compose('%02d',suffix)),suffix=suffix+1;end
        outputFolder=outputFolder+"_"+compose('%02d',suffix);
    end
end
mkdir(outputFolder);

if isfield(inputInfo,'case_file_path') && strlength(string(inputInfo.case_file_path))>0 && isfile(inputInfo.case_file_path)
    copyfile(inputInfo.case_file_path,fullfile(outputFolder,'raw_case_file_copy.m'));
end

config_raw=study.config_raw; %#ok<NASGU>
config_resolved=study.config_resolved; %#ok<NASGU>
save(fullfile(outputFolder,'config_raw.mat'),'config_raw');
save(fullfile(outputFolder,'config_resolved.mat'),'config_resolved');
localWriteJson(fullfile(outputFolder,'config_raw.json'),study.config_raw);
localWriteJson(fullfile(outputFolder,'config_resolved.json'),study.config_resolved);
localWriteJson(fullfile(outputFolder,'run_metadata.json'),study.metadata);
writetable(study.results,fullfile(outputFolder,'scenario_results.csv'));
writetable(study.summary.magnet_set_summary,fullfile(outputFolder,'magnet_set_summary.csv'));
if study.config_resolved.requirement_resolution.enable
    writetable(study.resolution_results,fullfile(outputFolder,'resolution_results.csv'));
end

study.output_folder=string(outputFolder); %#ok<NASGU>
save(fullfile(outputFolder,'results_full.mat'),'study','-v7.3');

warningText=strjoin(study.warnings,newline);
if strlength(warningText)==0,warningText="No warnings.";end
localWriteText(fullfile(outputFolder,'warnings.txt'),warningText+newline);

if study.config_resolved.visualisation.enable
    fig=msbsreq.plotConfiguration(study.tunnel,study.geometry,study.magnet_sets(1), ...
        study.mass_properties(1),study.config_resolved);
    localSaveFigure(fig,fullfile(outputFolder,'configuration'),study.config_resolved.output.save_fig);
    close(fig);
    if study.config_resolved.visualisation.plot_worst_case
        summaryTable=study.summary.magnet_set_summary;
        for i=1:height(summaryTable)
            setId=summaryTable.magnet_set_id(i);
            scenarioId=summaryTable.maximum_effort_scenario_id(i);
            record=localFindRecord(study.records,setId,scenarioId);
            stem="worst_case_"+localSafeName(setId);
            fig=msbsreq.plotScenario(record);
            localSaveFigure(fig,fullfile(outputFolder,stem),study.config_resolved.output.save_fig);
            close(fig);
            if study.config_resolved.visualisation.save_magnetic_field_plot
                fig=msbsreq.plotMagneticField(record);
                localSaveFigure(fig,fullfile(outputFolder,"magnetic_field_"+localSafeName(setId)), ...
                    study.config_resolved.output.save_fig);
                close(fig);
            end
        end
    end
end

study.output_folder=string(outputFolder);
msbsreq.writeRunSummary(study,fullfile(outputFolder,'run_summary.md'));
end

function record=localFindRecord(records,setId,scenarioId)
for i=1:numel(records)
    if records(i).magnet_set.id==setId && records(i).loads.scenario.scenario_id==scenarioId
        record=records(i);return
    end
end
error('msbsreq:MissingWorstRecord','Could not locate worst-case record for export.');
end

function localSaveFigure(fig,stem,saveFig)
exportgraphics(fig,stem+'.png','Resolution',200);
exportgraphics(fig,stem+'.pdf','ContentType','vector');
if saveFig,savefig(fig,stem+'.fig');end
end
function localWriteJson(path,value)
text=jsonencode(localJsonSafe(value),'PrettyPrint',true);
localWriteText(path,text+newline);
end
function value=localJsonSafe(value)
if istable(value)
    value=table2struct(value);
elseif isstruct(value)
    fields=fieldnames(value);
    for k=1:numel(value)
        for i=1:numel(fields)
            value(k).(fields{i})=localJsonSafe(value(k).(fields{i}));
        end
    end
elseif iscell(value)
    for i=1:numel(value),value{i}=localJsonSafe(value{i});end
elseif isa(value,'function_handle')
    value=func2str(value);
elseif isdatetime(value)
    value=string(value);
end
end
function localWriteText(path,text)
fid=fopen(path,'w');
if fid<0,error('msbsreq:FileWrite','Could not write %s.',path);end
cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s',char(text));
end
function name=localSafeName(value)
name=lower(string(matlab.lang.makeValidName(char(string(value)))));
end
