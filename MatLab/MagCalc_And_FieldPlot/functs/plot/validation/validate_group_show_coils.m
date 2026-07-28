function showCoils = validate_group_show_coils(records)
%VALIDATE_GROUP_SHOW_COILS Check coil-display consistency in one plot group.
%
% For one plane or line plot group:
%   all false/absent -> showCoils = false
%   all true         -> showCoils = true
%   mixed true/false -> error
%
% This prevents ambiguous grouped plots where only some overlaid records ask
% for coil geometry or coil-hit annotation.

if isempty(records)
    showCoils = false;
    return
end

flags = false(1, numel(records));

for k = 1:numel(records)
    record = records{k};

    if isfield(record, "plot") && ...
       isfield(record.plot, "showCoils") && ...
       ~isempty(record.plot.showCoils)

        flags(k) = logical(record.plot.showCoils);

    elseif isfield(record, "query") && ...
           isfield(record.query, "plot") && ...
           isfield(record.query.plot, "showCoils") && ...
           ~isempty(record.query.plot.showCoils)

        flags(k) = logical(record.query.plot.showCoils);
    else
        flags(k) = false;
    end
end

if any(flags) && ~all(flags)
    error("Inconsistent ShowCoils settings within one plot group. Either set ShowCoils=true for every query in the group, or leave it false/absent for every query.");
end

showCoils = all(flags);
end