function metadataFile = write_plot_metadata_file(figName, records, plotStyle)
%WRITE_PLOT_METADATA_FILE Write a lightweight text summary for one plot.
%
% The metadata filename is derived from the plot title/figure name so that
% exported figures and metadata files can be matched easily.
%
% plotStyle options:
%   plotStyle.writeMetadata      true/false, default true
%   plotStyle.metadataOutputDir  output folder, default COMSOL/Graphs/plot_metadata

if nargin < 3
    plotStyle = struct();
end

if ~isfield(plotStyle, "writeMetadata")
    plotStyle.writeMetadata = true;
end

if ~logical(plotStyle.writeMetadata)
    metadataFile = "";
    return
end

if ~iscell(records)
    records = {records};
end

if ~isfield(plotStyle, "metadataOutputDir") || strlength(string(plotStyle.metadataOutputDir)) == 0
    plotStyle.metadataOutputDir = msbs_graphs_dir("plot_metadata");
end

outDir = string(plotStyle.metadataOutputDir);
if ~isfolder(outDir)
    mkdir(outDir);
end

queryFile=""; if isfield(plotStyle,"Q_file"), queryFile=plotStyle.Q_file; end
baseName = stable_plot_basename(figName,queryFile);
metadataFile = fullfile(outDir, baseName + ".txt");

fid = fopen(metadataFile, "w");
if fid < 0
    error("Could not create plot metadata file: %s", metadataFile);
end

cleanupObj = onCleanup(@() fclose(fid));

fprintf(fid, "Plot metadata\n");
fprintf(fid, "=============\n\n");
fprintf(fid, "Figure title: %s\n", string(figName));
fprintf(fid, "Created on: %s\n", string(datetime("now", "Format", "yyyy-MM-dd HH:mm:ss")) );

if isfield(plotStyle, "Q_file")
    fprintf(fid, "Q file: %s\n", string(plotStyle.Q_file));
end

fprintf(fid, "Number of plotted records: %d\n\n", numel(records));
if isfield(plotStyle,"vectorDisplayReport")
    fprintf(fid,"Vector display (data remain in SI; glyph lengths are symbolic):\n%s\n\n",jsonencode(plotStyle.vectorDisplayReport));
end
if isfield(plotStyle,"colourScaleClass")
    fprintf(fid,"Colour scale class: %s\nColour limits: %s\n\n", ...
        plotStyle.colourScaleClass,mat2str(plotStyle.colourScaleLimits));
end
if isfield(plotStyle,"gradientColorLimitReport")
    r=plotStyle.gradientColorLimitReport;
    fprintf(fid,"Gradient display clipping: percentile %g; symmetric threshold %.12g T/m; saturated fraction %.12g; raw values unchanged.\n\n", ...
        r.percentile,r.threshold,r.saturatedFraction);
end

for k = 1:numel(records)
    r = records{k};

    fprintf(fid, "Record %d\n", k);
    fprintf(fid, "--------\n");

    write_if_present(fid, r, "caseName", "Case name");
    write_if_present(fid, r, "model", "Model");
    write_if_present(fid, r, "queryName", "Query name");
    write_if_present(fid, r, "dataName", "Data name");
    write_if_present(fid, r, "queryIndex", "Query index");
    write_if_present(fid, r, "resultIndex", "Result index");

    if isfield(r, "query")
        q = r.query;
        write_if_present(fid, q, "type", "Query type");
        write_if_present(fid, q, "quantity", "Quantity");
        write_if_present(fid, q, "component", "Component");

        if isfield(q, "plot")
            write_if_present(fid, q.plot, "group", "Plot group");
            write_if_present(fid, q.plot, "inOverview", "Overview requested");
            write_if_present(fid, q.plot, "showCoils", "ShowCoils requested");
        end
    end

    if isfield(r, "caseMeta")
        m = r.caseMeta;
        write_if_present(fid, m, "source", "Dataset source");
        write_if_present(fid, m, "datasetFile", "Dataset file");
        write_if_present(fid, m, "queryFile", "Query file");
    end

    if isfield(r, "synthetic")
        s = r.synthetic;
        fprintf(fid, "Synthetic dataset: true\n");
        write_if_present(fid, s, "type", "Synthetic type");
        write_if_present(fid, s, "operation", "Synthetic operation");
        write_if_present(fid, s, "caseNameA", "Synthetic case A");
        write_if_present(fid, s, "caseNameB", "Synthetic case B");
        write_if_present(fid, s, "datasetFileA", "Synthetic dataset A");
        write_if_present(fid, s, "datasetFileB", "Synthetic dataset B");
        write_if_present(fid, s, "excludedVolumePercentA", "Excluded volume percent A");
        write_if_present(fid, s, "excludedVolumePercentB", "Excluded volume percent B");
    end

    if isfield(r, "data")
        fprintf(fid, "Data size: %s\n", mat2str(size(r.data)));
        fprintf(fid, "Finite data points: %d\n", nnz(isfinite(r.data)));
    end

    fprintf(fid, "\n");
end
end

function write_if_present(fid, s, fieldName, label)
if isfield(s, fieldName)
    val = s.(fieldName);
    if isnumeric(val) || islogical(val)
        valText = mat2str(val);
    else
        valText = string(val);
    end
    fprintf(fid, "%s: %s\n", label, valText);
end
end
