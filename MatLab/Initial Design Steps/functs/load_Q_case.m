function Q = load_Q_case(nameOrFile)
% Load a Q case from workspace variable name or .mat filename.

nameOrFile = string(nameOrFile);

if evalin('base', "exist('" + nameOrFile + "','var')")
    Q = evalin('base', nameOrFile);
    return
end

if endsWith(nameOrFile, ".mat")
    matfile_name = nameOrFile;
    [~, defaultVar] = fileparts(matfile_name);
else
    matfile_name = nameOrFile + ".mat";
    defaultVar = nameOrFile;
end

if ~exist(matfile_name, 'file')
    error("Could not find %s in workspace or as file %s.", nameOrFile, matfile_name);
end

S = load(matfile_name);

if isfield(S, defaultVar)
    Q = S.(defaultVar);
elseif isfield(S, 'Q')
    Q = S.Q;
else
    vars = fieldnames(S);
    if numel(vars) == 1
        Q = S.(vars{1});
    else
        error("File %s does not contain variable '%s' or 'Q'.", matfile_name, defaultVar);
    end
end

end
