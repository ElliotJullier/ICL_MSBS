function plot_requests = flatten_plot_requests(Q_list)

plot_requests = {};

for i = 1:numel(Q_list)
    reqs = Q_list{i}.plotting;

    for k = 1:numel(reqs)
        r = reqs{k};

        if ~isfield(r, 'inOverview')
            r.inOverview = false;
        end

        plot_requests{end+1} = r; %#ok<AGROW>
    end
end

end
