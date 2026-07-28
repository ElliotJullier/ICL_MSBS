function Q = load_Q_case(fileName)
%LOAD_Q_CASE Load one query output file containing variable Q.
%
% query_main saves one variable named Q. Q is normally a cell array:
%
%   Q{1}, Q{2}, ...
%
% where each Q{k} is one case/model from the same query output file.
%
% If the file contains one Q case struct instead of a cell array, it is
% wrapped as {Q} so plot_field can always loop over cases consistently.

fileName = string(fileName);
if ~endsWith(fileName, ".mat")
    fileName = fileName + ".mat";
end

if ~exist(fileName, 'file')
    error("Could not find Q file: %s", fileName);
end

S = load(fileName, "Q");
if ~isfield(S, "Q")
    error("%s must contain a variable named Q.", fileName);
end

Q = S.Q;
if ~iscell(Q)
    Q = {Q};
end
end
