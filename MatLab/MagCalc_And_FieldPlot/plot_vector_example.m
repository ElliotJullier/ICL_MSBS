%% plot_vector_example.m
clear; close all
SAVE_PLOTS=true;
projectDir=fileparts(mfilename("fullpath"));
addpath(genpath(fullfile(projectDir,"functs")));
paths=msbs_paths();
files=dir(fullfile(paths.queryOutputs,"Q_VectorExample*_QueryBatch*.mat"));
if isempty(files), error("MSBS:NoQ","Run query_vector_example first."); end
[~,latest]=max([files.datenum]); Q_file=fullfile(files(latest).folder,files(latest).name);
Q=load_Q_case(Q_file);
style=plotStyle(); style.Q_file=Q_file; style.metadataOutputDir=paths.metadata;
% Display-only overrides, without reopening the COMSOL dataset:
% style.vector=struct("MaxArrows",200,"Seeding","magnitude","LengthMode","sqrt", ...
%     "ColorScale","log","ColorBy","magnitude","ExcludeMaterials",true);
% style.vector=struct("ColorBy","none"); % Uniform navy arrows, no colorbar.
plot_field(Q,style);
if SAVE_PLOTS
    exportDir=msbs_graphs_dir("VectorExample");
    if ~isfolder(exportDir), mkdir(exportDir); end
    for fig=findall(groot,"Type","figure").'
        base=stable_plot_basename(string(fig.Name),Q_file);
        exportgraphics(fig,fullfile(exportDir,base+".png"),"Resolution",300);
    end
end
