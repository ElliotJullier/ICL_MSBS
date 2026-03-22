function plot_requests = flatten_plot_requests(Q_list, plotStyle)
plot_requests = {};

for i = 1:numel(Q_list)
    results = Q_list{i}.plotting.results;
    caseName = plotStyle.caseNames(i);

    for k = 1:numel(results)
        r = results{k};
        r.caseName = caseName;
        if ~isfield(r, 'inOverview')
            r.inOverview = false;
        end
        plot_requests{end+1} = r; %#ok<AGROW>
    end
end
end
