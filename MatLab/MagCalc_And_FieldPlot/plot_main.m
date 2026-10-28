close all
projectDir=fileparts(mfilename("fullpath"));
addpath(genpath(fullfile(projectDir,"functs")));
paths=msbs_paths();

% Set Q_file explicitly to reproduce a particular query batch.
% Empty uses the newest Q output for convenience.
Q_file="";
if strlength(Q_file)==0
    files=dir(fullfile(paths.queryOutputs,"Q_*.mat"));
    if isempty(files), error("MSBS:NoQ","Run query_main first."); end
    [~,latest]=max([files.datenum]);
    Q_file=fullfile(files(latest).folder,files(latest).name);
end
Q=load_Q_case(Q_file);
style=plotStyle();
style.Q_file=Q_file;
style.geometryAlpha=0.5; % 50% opacity (=50% transparency), review here.
style.metadataOutputDir=paths.metadata;
% style.clim=struct("field",[-1 1]*1e-3,"gradient",[-1 1]*1e-3);
plot_field(Q,style);
