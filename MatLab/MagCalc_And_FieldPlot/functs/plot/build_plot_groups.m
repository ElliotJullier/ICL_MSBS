function groups = build_plot_groups(plot_records)
%BUILD_PLOT_GROUPS Group plotting requests by their plot.group value.
%
% Ungrouped requests are each assigned their own private group. This function
% does not permit line/plane mixing; call validate_plot_group_types before
% splitting or grouping requests.

groups = struct('key', {}, 'requests', {});
if isempty(plot_records)
    return
end

groupMap = containers.Map('KeyType','char', 'ValueType','any');
ungroupedCount = 0;

for k = 1:numel(plot_records)
    record = plot_records{k};

    if isfield(record, 'plot') && isfield(record.plot, 'group') && ~isempty(record.plot.group)
        key = char(string(record.plot.group));
    else
        ungroupedCount = ungroupedCount + 1;
        key = ['ungrouped_' num2str(ungroupedCount)];
    end

    if isKey(groupMap, key)
        tmp = groupMap(key);
        tmp{end+1} = record;
        groupMap(key) = tmp;
    else
        groupMap(key) = {record};
    end
end

keysList = keys(groupMap);
for k = 1:numel(keysList)
    groups(k).key = keysList{k}; %#ok<AGROW>
    groups(k).requests = groupMap(keysList{k}); %#ok<AGROW>
end
end
