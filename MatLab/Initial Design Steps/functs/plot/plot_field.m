function plot_field(Q_list, plotStyle)

if ~iscell(Q_list)
    Q_list = {Q_list};
end

if ~isfield(plotStyle, 'showCoils')
    plotStyle.showCoils = true;
end
if ~isfield(plotStyle, 'showOrientationReadout')
    plotStyle.showOrientationReadout = true;
end
if ~isfield(plotStyle, 'showCoilsInPlaneFigures')
    plotStyle.showCoilsInPlaneFigures = false;
end

if ~isfield(plotStyle, 'clim') || isempty(plotStyle.clim)
    Bmax = 0;
    for i = 1:numel(Q_list)
        reqs = Q_list{i}.plotting;
        for k = 1:numel(reqs)
            r = reqs{k};
            if isfield(r,'B') && ~isempty(r.B) && ~isfield(r,'s')
                thisMax = max(abs(r.B), [], "all", "omitnan");
                if ~isempty(thisMax) && isfinite(thisMax)
                    Bmax = max(Bmax, thisMax);
                end
            end
        end
    end
    if Bmax <= 0
        Bmax = 1;
    end
    plotStyle.clim = [-Bmax, Bmax];
end

plot_requests = flatten_plot_requests(Q_list);

plane_requests = {};
line_requests  = {};

for k = 1:numel(plot_requests)
    r = plot_requests{k};
    t = lower(char(string(r.type)));

    if contains(t, 'plane')
        plane_requests{end+1} = r; %#ok<AGROW>
    elseif contains(t, 'line')
        line_requests{end+1} = r; %#ok<AGROW>
    else
        error("Unknown plotting request type: " + string(r.type));
    end
end

hasAnyLine = ~isempty(line_requests);
hasMarkedOverview = any(cellfun(@(r) isfield(r,'inOverview') && logical(r.inOverview), plot_requests));

doOverview = hasAnyLine || hasMarkedOverview;

if doOverview
    plot_overview(plane_requests, line_requests, Q_list, plotStyle);
end

plane_groups = build_plot_groups(plane_requests);
line_groups  = build_plot_groups(line_requests);

for k = 1:numel(plane_groups)
    plot_plane_group(plane_groups(k), Q_list, plotStyle);
end

for k = 1:numel(line_groups)
    plot_line_group(line_groups(k), plotStyle);
end

end