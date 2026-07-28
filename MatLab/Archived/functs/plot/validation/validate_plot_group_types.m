function validate_plot_group_types(plot_records)
%VALIDATE_PLOT_GROUP_TYPES Prevent one plot group mixing lines and planes.
%
% This validation applies within one loaded Q variable. It prevents a user
% from assigning, for example, group 1 to both a line query and a plane query.

groupFamily = containers.Map('KeyType', 'char', 'ValueType', 'char');

for k = 1:numel(plot_records)
    r = plot_records{k};

    if ~isfield(r, 'plot') || ~isfield(r.plot, 'group') || isempty(r.plot.group)
        continue
    end

    key = char(string(r.plot.group));
    qtype = lower(string(r.query.type));

    if contains(qtype, "line")
        family = "line";
    elseif contains(qtype, "plane")
        family = "plane";
    else
        family = "unknown";
    end

    if isKey(groupFamily, key)
        if string(groupFamily(key)) ~= family
            error("Plot group %s contains both line and plane queries. Use separate group numbers.", key);
        end
    else
        groupFamily(key) = char(family);
    end
end
end
