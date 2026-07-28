function [fileName, batchNumber] = next_Q_filename(outputDir, runOrLabel, label)
%NEXT_Q_FILENAME Create a non-overwriting filename for a saved Q batch.
%
% Numeric runOrLabel:
%   next_Q_filename(".", 1, "QueryBatch")
%   -> Q_case1_batch1_QueryBatch.mat
%
% Text runOrLabel:
%   next_Q_filename(".", "Comparison", "QueryBatch")
%   -> Q_Comparison_batch1_QueryBatch.mat
%
% Existing files with the same prefix are scanned and the new batch number
% is chosen as max(existing batch numbers) + 1.

if nargin < 1 || strlength(string(outputDir)) == 0
    outputDir = ".";
end

if nargin < 2 || strlength(string(runOrLabel)) == 0
    runOrLabel = "Comparison";
end

if nargin < 3 || strlength(string(label)) == 0
    label = "QueryBatch";
end

label = sanitise_filename_token(label);

if isnumeric(runOrLabel)
    prefix = sprintf("Q_case%d", runOrLabel);
else
    prefix = "Q_" + sanitise_filename_token(runOrLabel);
end

pattern = prefix + "_batch*_*.mat";
files = dir(fullfile(outputDir, pattern));

batchNumbers = [];

escapedPrefix = regexptranslate("escape", char(prefix));

for k = 1:numel(files)
    tok = regexp(files(k).name, ...
        ['^' escapedPrefix '_batch(\d+)_'], ...
        'tokens', 'once');

    if ~isempty(tok)
        batchNumbers(end+1) = str2double(tok{1}); %#ok<AGROW>
    end
end

batchNumber = max([0, batchNumbers]) + 1;

fileName = fullfile(outputDir, ...
    sprintf("%s_batch%d_%s.mat", prefix, batchNumber, label));
end

function token = sanitise_filename_token(token)
%SANITISE_FILENAME_TOKEN Convert text into a safe filename token.

token = string(token);
token = regexprep(token, '[^A-Za-z0-9_\-]+', '_');
token = regexprep(token, '_+', '_');
token = strip(token, '_');

if strlength(token) == 0
    token = "QueryBatch";
end
end