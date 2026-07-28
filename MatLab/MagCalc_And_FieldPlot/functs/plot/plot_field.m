function plot_field(Q, plotStyle)
%PLOT_FIELD Plot the contents of one loaded query output Q.
%
% Q is the single variable saved by query_main and loaded by load_Q_case.
% It is normally a cell array where each Q{k} is one case/model.
%
% Overviews are generated per case only. A case gets an overview only if at
% least one of that case's queries has Overview=true. Overview plots always
% show coils. Non-overview plane/line coil annotations are controlled per
% query using the ShowCoils name-value option.

if nargin < 2
    plotStyle = struct();
end

if ~iscell(Q)
    Q = {Q};
end

plotRecords = build_plot_records_from_Q(Q);

validate_plot_group_types(plotRecords);

if ~isfield(plotStyle, 'showOrientationReadout')
    plotStyle.showOrientationReadout = true;
end

if ~isfield(plotStyle, 'clim') || isempty(plotStyle.clim)
    plotStyle.clim = choose_symmetric_colour_limits(plotRecords);

elseif isnumeric(plotStyle.clim)
    % Backwards compatibility: a numeric clim applies to both fields and
    % gradients, although separate limits are usually preferred.
    tmp = plotStyle.clim;
    plotStyle.clim = struct("field", tmp, "gradient", tmp);

elseif isstruct(plotStyle.clim)
    if ~isfield(plotStyle.clim, "field") || isempty(plotStyle.clim.field)
        autoClim = choose_symmetric_colour_limits(plotRecords);
        plotStyle.clim.field = autoClim.field;
    end

    if ~isfield(plotStyle.clim, "gradient") || isempty(plotStyle.clim.gradient)
        autoClim = choose_symmetric_colour_limits(plotRecords);
        plotStyle.clim.gradient = autoClim.gradient;
    end
else
    error("plotStyle.clim must be empty, numeric [min max], or a struct with field/gradient limits.");
end

if ~isfield(plotStyle, 'Q_file')
    plotStyle.Q_file = "";
end

% ------------------------- Case-specific overviews -------------------------
for c = 1:numel(Q)

    % plotRecords is a flat cell array containing every result from this one
    % loaded Q variable. Each record stores which Q case it came from using
    % record.caseIndex.
    %
    % caseMask is therefore a logical array the same length as plotRecords:
    %   true  -> this record belongs to Q{c}
    %   false -> this record belongs to another case
    caseMask = cellfun(@(record) record.caseIndex == c, plotRecords);
    recordsForThisCase = plotRecords(caseMask);

    % overviewMask is a logical array the same length as recordsForThisCase:
    %   true  -> this query explicitly requested Overview=true
    %   false -> do not include this result in the 3D overview
    %
    % This keeps overviews case-specific. A query from another Q case cannot
    % appear in this case's overview.
    % A result is included in the 3D overview only if:
    %   1. the user requested Overview=true, and
    %   2. the result is a field query, not a gradient query.
    %
    % Gradient quantities are deliberately excluded from overviews because
    % mixing B-field values and field-gradient values in the same 3D overview
    % is visually misleading.
    overviewMask = cellfun(@(record) ...
        isfield(record.query, 'plot') && ...
        isfield(record.query.plot, 'inOverview') && ...
        logical(record.query.plot.inOverview) && ...
        lower(string(record.query.quantity)) == "field", ...
        recordsForThisCase);

    requestedGradientOverview = cellfun(@(record) ...
        isfield(record.query, 'plot') && ...
        isfield(record.query.plot, 'inOverview') && ...
        logical(record.query.plot.inOverview) && ...
        lower(string(record.query.quantity)) == "gradient", ...
        recordsForThisCase);
    
    if any(requestedGradientOverview)
        error("Gradient overview requests were ignored. Overviews only display field quantities.");
    end

    overviewRecords = recordsForThisCase(overviewMask);

    if isempty(overviewRecords)
        continue
    end

    planeOverview = {};
    lineOverview = {};

    for k = 1:numel(overviewRecords)
        record = overviewRecords{k};
        queryType = lower(string(record.query.type));

        if contains(queryType, "plane")
            planeOverview{end+1} = record; %#ok<AGROW>
        elseif contains(queryType, "line")
            lineOverview{end+1} = record; %#ok<AGROW>
        else
            error("Unknown overview query type: %s", queryType);
        end
    end

    % Q is a cell array, so use Q{c}, not Q(c).
    plot_overview(planeOverview, lineOverview, Q{c}, plotStyle);
end

% ------------------------- Standard plane/line plots -------------------------
plane_records = {};
line_records  = {};

for k = 1:numel(plotRecords)

    % Each plot record contains both:
    %   record.result data: X, Y, Z, data, etc.
    %   record.query data: type, component, plot options, etc.
    %
    % Here we split the flat list into plane-type plots and line-type plots.
    % This happens after overview handling because the same result may need
    % to appear both in an overview and as its own 2D/line plot.
    record = plotRecords{k};
    queryType = lower(string(record.query.type));

    if contains(queryType, "plane")
        plane_records{end+1} = record; %#ok<AGROW>
    elseif contains(queryType, "line")
        line_records{end+1} = record; %#ok<AGROW>
    else
        error("Unknown plotting request type: %s", queryType);
    end
end

plane_groups = build_plot_groups(plane_records);
line_groups  = build_plot_groups(line_records);

for k = 1:numel(plane_groups)
    plot_plane_group(plane_groups(k), plotStyle);
end

for k = 1:numel(line_groups)
    plot_line_group(line_groups(k), plotStyle);
end

end
% -------------------------- LOCAL HELPER FUNCTION -----------------------

function clim = choose_symmetric_colour_limits(plot_records)
%CHOOSE_SYMMETRIC_COLOUR_LIMITS Pick separate field and gradient limits.
%
% Field and gradient values have different units, so they must not share the
% same colour scale. This returns:
%   clim.field    = [-maxAbsField, maxAbsField]
%   clim.gradient = [-maxAbsGrad,  maxAbsGrad]

fieldMax = 0;
gradMax  = 0;

for k = 1:numel(plot_records)
    r = plot_records{k};

    % Skip line records; colour limits are only for surface/plane data.
    if isfield(r, 's') || ~isfield(r, 'data') || isempty(r.data)
        continue
    end

    thisMax = max(abs(r.data), [], "all", "omitnan");
    if isempty(thisMax) || ~isfinite(thisMax)
        continue
    end

    quantityClass = get_plot_quantity_class(r);

    if quantityClass == "gradient"
        gradMax = max(gradMax, thisMax);
    else
        fieldMax = max(fieldMax, thisMax);
    end
end

if fieldMax <= 0
    fieldMax = 1;
end
if gradMax <= 0
    gradMax = 1;
end

clim = struct();
clim.field = [-fieldMax, fieldMax];
clim.gradient = [-gradMax, gradMax];
end

function quantityClass = get_plot_quantity_class(record)
%GET_PLOT_QUANTITY_CLASS Classify a plot record as field or gradient.

if isfield(record, "query") && isfield(record.query, "quantity")
    q = lower(string(record.query.quantity));
else
    q = "";
end

if q == "gradient" || startsWith(string(record.dataName), "dB")
    quantityClass = "gradient";
else
    quantityClass = "field";
end
end
