function gradeTable = loadMagnetGradeTable(projectRoot)
%LOADMAGNETGRADETABLE Read and validate the editable magnet-grade database.
arguments
    projectRoot (1,1) string
end

filePath = fullfile(projectRoot,'data','magnet_grades.csv');
if ~isfile(filePath)
    error('msbsreq:MissingMagnetDatabase', ...
        'data/magnet_grades.csv is missing from the project.');
end

gradeTable = readtable(filePath, ...
    'Delimiter',',', ...
    'TextType','string', ...
    'VariableNamingRule','preserve');

required = ["grade","Br_nominal_T","Br_min_T","Br_max_T", ...
    "density_kgm3","temperature_C","source_reference","source_note"];
actual = string(gradeTable.Properties.VariableNames);
missing = setdiff(required,actual,'stable');
if ~isempty(missing)
    error('msbsreq:InvalidMagnetDatabase', ...
        'data/magnet_grades.csv is missing required columns: %s.', ...
        strjoin(missing,', '));
end

% Normalise the text columns while preserving the public column names.
gradeTable.("grade") = string(gradeTable.("grade"));
gradeTable.("source_reference") = string(gradeTable.("source_reference"));
gradeTable.("source_note") = string(gradeTable.("source_note"));

numericColumns = ["Br_nominal_T","Br_min_T","Br_max_T", ...
    "density_kgm3","temperature_C"];
for name = numericColumns
    values = gradeTable.(name);
    if ~isnumeric(values) || any(~isfinite(values),'all')
        error('msbsreq:InvalidMagnetDatabase', ...
            'Column %s in data/magnet_grades.csv must contain finite numeric values.',name);
    end
end

if any(strlength(strtrim(gradeTable.("grade")))==0) || ...
        numel(unique(upper(strtrim(gradeTable.("grade")))))~=height(gradeTable)
    error('msbsreq:InvalidMagnetDatabase', ...
        'Magnet grades must be nonempty and unique, ignoring case.');
end
if any(gradeTable.("Br_nominal_T")<=0) || ...
        any(gradeTable.("Br_min_T")<=0) || ...
        any(gradeTable.("Br_max_T")<=0) || ...
        any(gradeTable.("density_kgm3")<=0)
    error('msbsreq:InvalidMagnetDatabase', ...
        'Remanence and density values in the magnet database must be positive.');
end
if any(gradeTable.("Br_min_T") > gradeTable.("Br_nominal_T")) || ...
        any(gradeTable.("Br_nominal_T") > gradeTable.("Br_max_T"))
    error('msbsreq:InvalidMagnetDatabase', ...
        'Each magnet grade must satisfy Br_min_T <= Br_nominal_T <= Br_max_T.');
end
end
