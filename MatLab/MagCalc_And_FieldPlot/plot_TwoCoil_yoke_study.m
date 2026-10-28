%% plot_TwoCoil_yoke_study.m
% Replot the most recent query batch. Set this one switch true to export PNGs.
clear; close all;
SAVE_PLOTS = true;
leakageYLim = [0 2.5e-5]; % Preserve limits from the original z=1.3..2.0 m leakage plot.

projectDir = fileparts(mfilename("fullpath"));
addpath(genpath(fullfile(projectDir,"functs")));
paths = msbs_paths();
qFiles = dir(fullfile(paths.queryOutputs,"Q_TwoCoil_yoke_study*_QueryBatch*.mat"));
if isempty(qFiles)
    error("No TwoCoil_yoke_study query output found. Run query_TwoCoil_yoke_study.m first.");
end
[~,newest] = max([qFiles.datenum]);
Q_file = fullfile(qFiles(newest).folder,qFiles(newest).name);
Q = load_Q_case(Q_file);

% Smooth only the full-span centreline dBz/dz traces. The requested 30-point
% Savitzky-Golay window is used exactly (cubic local polynomial).
for c = 2:4
    for r = 1:numel(Q{c}.results)
        query = Q{c}.queries{Q{c}.results{r}.queryIndex};
        if string(query.name) == "Centreline dBz/dz"
            Q{c}.results{r}.data = localSgolaySmooth(Q{c}.results{r}.data,30,3);
        end
    end
end

style = plotStyle();
style.Q_file = Q_file;
style.geometryAlpha = 0.5;
style.metadataOutputDir = paths.metadata;
% plot_field assigns line colours in case order, so Bz and dBz/dz use the
% same three colours and legend ordering.
plot_field(Q,style);

% Keep the leakage field scale fixed as the yoke intersection is extended.
figs = findall(groot,"Type","figure");
for k = 1:numel(figs)
    if contains(string(get(figs(k),"Name")),"leakage_Bz")
        ax = findall(figs(k),"Type","axes");
        if ~isempty(ax), ylim(ax(1),leakageYLim); end
    end
end

% Each gradient/difference class has its own display-cap report.
figs = findall(groot,"Type","figure");
for k = 1:numel(figs)
    if isappdata(figs(k),"MSBSGradientColorLimitReport")
        capReport=getappdata(figs(k),"MSBSGradientColorLimitReport");
        caption=sprintf("Planar-gradient colour cap: symmetric %gth percentile, +/-%.6g T/m; %.3g%% saturated. Raw query values unchanged.", ...
            capReport.percentile,capReport.threshold,100*capReport.saturatedFraction);
        annotation(figs(k),"textbox",[0.08 0.005 0.84 0.035], ...
            "String",caption,"EdgeColor","none","HorizontalAlignment","center", ...
            "VerticalAlignment","middle","Interpreter","none");
    end
end

if SAVE_PLOTS
    exportDir = fullfile(projectDir,"Fig Exports","TwoCoil_yoke_study");
    if ~isfolder(exportDir), mkdir(exportDir); end
    figs = findall(groot,"Type","figure");
    for k = 1:numel(figs)
        name = string(get(figs(k),"Name"));
        if strlength(name)==0, name = "Figure_" + k; end
        % Stable plot/study name: successive Q batches overwrite this PNG.
        safeName = stable_plot_basename(name,Q_file);
        exportgraphics(figs(k),fullfile(exportDir,safeName+".png"),"Resolution",300);
    end
    fprintf("Saved figures to %s (matching filenames overwritten; no batch counter).\n",exportDir);
else
    fprintf("Plot export disabled. Set SAVE_PLOTS = true to save PNGs.\n");
end
fprintf("Plotted query batch: %s\n",Q_file);

function smoothed = localSgolaySmooth(values,windowLength,polynomialOrder)
% Local least-squares Savitzky-Golay smoothing; supports an even window.
values = values(:);
smoothed = values;
valid = isfinite(values);
edges = diff([false;valid;false]);
starts = find(edges==1);
stops = find(edges==-1)-1;
for segment = 1:numel(starts)
    first = starts(segment); last = stops(segment);
    y = values(first:last); n = numel(y);
    w = min(windowLength,n);
    if mod(w,2)==1 && windowLength<=n, w=windowLength; end
    if w<=polynomialOrder, continue; end
    for i = 1:n
        left = min(max(i-floor(w/2),1),n-w+1);
        indices = left:(left+w-1);
        offsets = indices-i;
        design = offsets(:).^(0:polynomialOrder);
        weights = pinv(design);
        smoothed(first+i-1) = weights(1,:)*y(indices);
    end
end
smoothed = reshape(smoothed,size(values));
end
