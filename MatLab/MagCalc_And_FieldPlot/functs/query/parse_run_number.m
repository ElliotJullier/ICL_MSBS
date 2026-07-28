function runNumber = parse_run_number(fileName)
%PARSE_RUN_NUMBER Extract the number following "run" in a filename.

tok = regexp(char(string(fileName)), 'run(\d+)', 'tokens', 'once');
if isempty(tok)
    error("Could not parse run number from filename: %s", string(fileName));
end
runNumber = str2double(tok{1});
end
