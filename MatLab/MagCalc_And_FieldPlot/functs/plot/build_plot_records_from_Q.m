function plotRecords = build_plot_records_from_Q(Q)
%BUILD_PLOT_RECORDS_FROM_Q Convert one loaded Q variable into plot records.
%
% Q is the single variable saved by query_main and loaded by load_Q_case.
% It is normally a cell array:
%
%   Q{1} = first case
%   Q{2} = second case
%   ...
%
% Each Q case contains:
%   Q{caseIndex}.queries
%   Q{caseIndex}.results
%   Q{caseIndex}.caseName
%   Q{caseIndex}.model
%   Q{caseIndex}.geometry
%
% The output plotRecords is a flat cell array. Each record corresponds to
% one result, but also carries the matching query and case information. This
% avoids repeatedly looking up Q{caseIndex}.queries{queryIndex} during
% plotting.

if ~iscell(Q)
    Q = {Q};
end

plotRecords = {};

for caseIndex = 1:numel(Q)
    Qcase = Q{caseIndex};

    for resultIndex = 1:numel(Qcase.results)
        result = Qcase.results{resultIndex};

        if isfield(result, "queryIndex")
            queryIndex = result.queryIndex;
        else
            queryIndex = resultIndex;
        end

        query = Qcase.queries{queryIndex};

        record = result;

        % Attach the query that generated this result.
        record.query = query;
        record.queryIndex = queryIndex;
        record.resultIndex = resultIndex;

        % Attach the parent case context.
        record.caseIndex = caseIndex;
        record.caseName = Qcase.meta.caseName;
        record.model = Qcase.meta.model;
        record.geometry = Qcase.geometry;
        record.caseMeta = Qcase.meta;
        
        % Synthetic difference datasets can contain source geometries from both
        % input cases. These are needed so plotting can show both coil layouts
        % rather than only the retained dataset.geometry.
        if isfield(Qcase, "synthetic")
            record.synthetic = Qcase.synthetic;
        end
        
        if isfield(Qcase, "differenceStats")
            record.differenceStats = Qcase.differenceStats;
        end

        % Create a readable query name for legends and overview labels.
        if isfield(query, "name") && strlength(string(query.name)) > 0
            record.queryName = string(query.name);
        else
            record.queryName = sprintf("%s query %d", string(query.type), queryIndex);
        end
        
        if isfield(Qcase, "queryFile")
            record.queryFile = string(Qcase.queryFile);
        elseif isfield(Qcase, "meta") && isfield(Qcase.meta, "queryFile")
            record.queryFile = string(Qcase.meta.queryFile);
        else
            record.queryFile = "";
        end

        plotRecords{end+1} = record; %#ok<AGROW>
    end
end
end