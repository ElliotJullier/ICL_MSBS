function plot_requests = flatten_plot_requests(Q_list)

plot_requests = {};

for i = 1:numel(Q_list)
    reqs = Q_list{i}.plotting;

    for k = 1:numel(reqs)
        r = reqs{k};

        if ~isfield(r, 'inOverview')
            r.inOverview = false;
        end

        if isfield(Q_list{i}, 'input') && isfield(Q_list{i}.input, 'load_filename')
            r.source_load_filename = Q_list{i}.input.load_filename;
        else
            r.source_load_filename = "";
        end

        plot_requests{end+1} = r; %#ok<AGROW>
    end
end

end
