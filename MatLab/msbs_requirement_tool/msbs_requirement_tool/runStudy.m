function study = runStudy(caseInput)
%RUNSTUDY Run an MSBS aerodynamic-load-to-magnetic-requirement study.
%   STUDY = RUNSTUDY("case_name") loads a case function from cases/.
%   STUDY = RUNSTUDY(@case_function) uses a function handle.
%   STUDY = RUNSTUDY(CFG) uses a configuration struct directly.

arguments
    caseInput
end

projectRoot = fileparts(mfilename('fullpath'));
addpath(fullfile(projectRoot, 'src'));
addpath(fullfile(projectRoot, 'cases'));

[configRaw, inputInfo] = localLoadInput(caseInput, projectRoot);
study = msbsreq.run(configRaw, projectRoot, inputInfo);
end

function [cfg, info] = localLoadInput(caseInput, projectRoot)
info = struct('source_type', "", 'case_function_name', "", ...
    'case_file_path', "");

if isstruct(caseInput)
    cfg = caseInput;
    info.source_type = "struct";
    return
end

if isa(caseInput, 'function_handle')
    cfg = caseInput();
    info.source_type = "function_handle";
    info.case_function_name = string(func2str(caseInput));
    resolvedPath = which(char(info.case_function_name));
    if ~isempty(resolvedPath)
        info.case_file_path = string(resolvedPath);
    end
    return
end

if ischar(caseInput) || (isstring(caseInput) && isscalar(caseInput))
    caseName = string(caseInput);
    if endsWith(caseName, ".m")
        caseName = extractBefore(caseName, strlength(caseName) - 1);
    end
    casePath = fullfile(projectRoot, 'cases', caseName + ".m");
    if ~isfile(casePath)
        resolvedPath = which(char(caseName));
        if isempty(resolvedPath)
            error('msbsreq:CaseNotFound', ...
                'Case function "%s" was not found in cases/ or on the MATLAB path.', caseName);
        end
        casePath = resolvedPath;
    end
    caseFunction = str2func(char(caseName));
    cfg = caseFunction();
    info.source_type = "case_function";
    info.case_function_name = caseName;
    info.case_file_path = string(casePath);
    return
end

error('msbsreq:InvalidStudyInput', ...
    'Input must be a case-name string, function handle, or configuration struct.');
end
