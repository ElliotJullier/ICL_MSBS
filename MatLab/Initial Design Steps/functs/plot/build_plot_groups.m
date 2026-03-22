function groups = build_plot_groups(plot_requests)
groups = struct('key', {}, 'requests', {});
if isempty(plot_requests)
    return
end

groupMap = containers.Map('KeyType','char', 'ValueType','any');
ungroupedCount = 0;

for k = 1:numel(plot_requests)
    r = plot_requests{k};

    if isfield(r, 'group') && ~isempty(r.group)
        key = char(string(r.group));
    else
        ungroupedCount = ungroupedCount + 1;
        key = ['ungrouped_' num2str(ungroupedCount)];
    end

    if isKey(groupMap, key)
        tmp = groupMap(key);
        tmp{end+1} = r;
        groupMap(key) = tmp;
    else
        groupMap(key) = {r};
    end
end

keysList = keys(groupMap);
for k = 1:numel(keysList)
    groups(k).key = keysList{k}; %#ok<AGROW>
    groups(k).requests = groupMap(keysList{k}); %#ok<AGROW>
end
end
