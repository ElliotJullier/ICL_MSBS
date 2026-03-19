function plot_field(Q_list, plotMode, plotStyle)
% Plots queried field results from one or more Q structs.
%
% Q_list:
%   - single Q struct
%   - or cell array of Q structs
%
% plotMode:
%   "single_axes"
%   "subplots"
%   "separate_figures"

if ~iscell(Q_list)
    Q_list = {Q_list};
end

if ~isfield(plotStyle, 'clim') || isempty(plotStyle.clim)
    Bmax = 0;

    for i = 1:numel(Q_list)
        results = Q_list{i}.plotting;

        for k = 1:numel(results)
            r = results{k};

            if isfield(r, 'B') && ~isempty(r.B)
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
if ~isfield(plotStyle, 'showCoils')
    plotStyle.showCoils = true;
end
if ~isfield(plotStyle, 'showOrientationReadout')
    plotStyle.showOrientationReadout = true;
end
if ~isfield(plotStyle, 'caseNames')
    plotStyle.caseNames = strings(1, numel(Q_list));
    for k = 1:numel(Q_list)
        plotStyle.caseNames(k) = "Case " + k;
    end
end

switch lower(string(plotMode))
    case "single_axes"
        plot_field_single_axes(Q_list, plotStyle)

    case "subplots"
        plot_field_subplots(Q_list, plotStyle)

    case "separate_figures"
        plot_field_separate(Q_list, plotStyle)

    otherwise
        error("Unknown plotMode.");
end

end