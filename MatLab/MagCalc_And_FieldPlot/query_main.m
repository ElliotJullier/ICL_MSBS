clear
close all;

addpath(genpath("functs"));

% ------------------------- Operating point -------------------------
% mode = "fixed": supply currents directly.
% mode = "solve": supply magnet and target; currents are solved if supported.
% mode = "precomputed": dataset already contains total field for the operating point.
opRequest = struct();
opRequest.mode = "fixed";
opRequest.currents = [1];

% -- Uncomment for solved-current operation:
% magnet.pose = [0 0 0 0 0 0];
% magnet.remanence = 1.5;
% magnet.volume = 30/1000*pi*(10/1000)^2;
% magnet.magnetisation_direction_local = [1;0;0];
%
% target.force = [0.1;0;0];
% target.torque = [0;0;0];
% target.forceFrame = "global";
% target.torqueFrame = "global";
% target.rows_to_control = [];
%
% opRequest.mode = "solve";
% opRequest.magnet = magnet;
% opRequest.target = target;
% -- End Uncomment

% ------------------------- Dataset/run selection -------------------------
datasetFile = "coilfield_run1.mat";
runNumber = parse_run_number(datasetFile);
outputDir = ".";

% ------------------------- External analytical line data -------------------------
% Optional analytical/reference line data.
%
% Required variables in the file:
%   z_mm   : line coordinate in mm
%   Bz_G   : Bz field in Gauss
%
% Conversion:
%   z_mm -> z_m  using 1 mm = 1e-3 m
%   Bz_G -> Bz_T using 1 G  = 1e-4 T
%
% The plotted line coordinate s is tared to the first z position, matching
% the internal line-query convention where s starts at zero.

includeAnalyticalLine = true;

analyticalLineFile = "Morgan_Bz_analytical_2.mat";   % must contain z_mm and Bz_G
analyticalLineGroup = 2;                         % choose the plot group
analyticalCaseName = "Morgan Analytical";
analyticalQueryName = "Morgan Analytical centreline Bz";

% ------------------------- Case-specific query definitions -------------------------
% The operating point is shared, but each case defines its own dataset, model,
% display name, and queries. This avoids putting model-specific labels inside
% shared queries and allows simple_biotsavart/COMSOL cases to reject unsupported
% query types clearly.

caseDefs = struct([]);

current_num = 1;

caseDefs(current_num).caseName = "Simple Biot-Savart (Morgan Layout)";
caseDefs(current_num).model = "simple_biotsavart";
caseDefs(current_num).datasetFile = "Morgan_SimpleBS_2.mat";

caseDefs(current_num).opRequest.mode = "fixed";
caseDefs(current_num).opRequest.currents = [2.57, -2.76];

caseDefs(current_num).queries = { ...
    create_line_field_query([0 0 -120e-3], [0 0 120e-3], "z", ...
        "NPoints", 300, ...
        "Group", 2, ...
        "Overview", false, ...
        "ShowCoils", false, ...
        "Name", "Simple two-coil on-axis Bz") ...
};

% ---------------- Full MATLAB Biot-Savart with fixed currents ----------------
current_num = 2;

caseDefs(current_num).caseName = "COMSOL Circular Prediction";
caseDefs(current_num).model = "comsol_grid";
caseDefs(current_num).datasetFile = "Morgan_Circular_Export2.txt";
caseDefs(current_num).opRequest.mode = "precomputed";
caseDefs(current_num).queries = { ...
    create_plane_field_query("xz", 0, "z", "Overview", true), ...
    create_custom_plane_field_query([0 0 0], [1 1 0], "z", "Overview", true), ...
    create_line_gradient_query([0 0 -120/1000], [0 0 120/1000], "z", "GradientDirection", [0 0 1], "NPoints", 200, "Group", 1, "Name", "Centreline"), ...
    create_line_gradient_query([0.03 0 -120/1000], [0.03 0 120/1000], "z", "GradientDirection", [0 0 1], "NPoints", 200, "Group", 1, "Name", "15 mm Offset"), ...
    create_line_gradient_query([0.045 0 -120/1000], [0.045 0 120/1000], "z", "GradientDirection", [0 0 1], "NPoints", 200, "Group", 1, "Name", "30mm Offset"), ...
    create_line_gradient_query([0.045 0 -120/1000], [0.045 0 120/1000], "z", "GradientDirection", [0 0 1], "NPoints", 200, "Group", 1, "Name", "45 mm Offset"), ...
    create_line_gradient_query([0.06 0 -120/1000], [0.06 0 120/1000], "z", "GradientDirection", [0 0 1], "NPoints", 200, "Group", 1, "Name", "60 mm Offset"), ...
};

current_num = 3;
caseDefs(current_num).caseName = "COMSOL Square Cylinder Prediction";
caseDefs(current_num).model = "comsol_grid";
caseDefs(current_num).datasetFile = "Morgan_Square_Export2.txt";
caseDefs(current_num).opRequest.mode = "precomputed";
caseDefs(current_num).queries = { ...
    create_plane_field_query("xz", 0, "z", "Overview", true), ...
    create_line_field_query([0 0 -120/1000], [0 0 120/1000], "z", "NPoints", 200, "Group", 1) ...
};

% caseDefs(2).caseName = "Simple Biot-Savart";
% caseDefs(2).model = "simple_biotsavart";
% caseDefs(2).datasetFile = datasetFile;  % uses geometry from the same dataset
% caseDefs(2).queries = { ...
%     create_line_field_query([0 0 -120/1000], [0 0 120/1000], "z", ...
%         "NPoints", 200, "Group", 2, "Overview", true, "Name", "Centreline Bz"), ...
%     create_line_gradient_query([0 0 -120/1000], [0 0 120/1000], "z", ...
%         "NPoints", 200, "Group", 3, "Name", "Centreline dBz/ds") ...
% };

% Placeholder for future COMSOL grid case:
% caseDefs(current_num).caseName = "COMSOL";
% caseDefs(current_num).model = "comsol_grid";
% caseDefs(current_num).datasetFile = "comsol_run1.mat";
% caseDefs(current_num).queries = { ...
%     create_plane_field_query("xz", 0, "z", "Overview", true), ...
%     create_line_field_query([0 0 -120/1000], [0 0 120/1000], "z", "NPoints", 200, "Group", 2) ...
% };

% ------------------------- Run query cases -------------------------
% The query process is split into three stages:
%
%   1. Load ordinary datasets and solve/validate their operating points.
%   2. Build any synthetic datasets, such as field differences.
%   3. Run queries and pack Q cases.
%
% A case can define its own opRequest. If it does not, the shared opRequest
% defined at the top of this file is used.

caseData = repmat(struct("dataset", [], "op", []), 1, numel(caseDefs));

% -------- Stage 1: load non-synthetic datasets --------
for c = 1:numel(caseDefs)
    model = lower(string(caseDefs(c).model));

    if model == "synthetic_difference"
        continue
    end

    switch model
        case {"matlab_full_biotsavart", "simple_biotsavart"}
            dataset = load_field_dataset(caseDefs(c).datasetFile);

        case {"comsol_precomputed", "comsol_grid"}
            dataset = load_comsol_precomputed_dataset(caseDefs(c).datasetFile);

        otherwise
            error("Unknown case model: %s", model);
    end

    % Optional plotting geometry override/attachment.
    %
    % This is mainly for precomputed COMSOL datasets, whose field export does
    % not contain coil geometry. geometryFile can point to:
    %   1. a normal coilfield .mat file containing dataset.geometry
    %   2. a standalone .mat file containing variable geometry
    %   3. an STL-derived geometry file produced by stl_to_query_geometry_file
    %
    % MATLAB struct arrays add a field to every element once any element has it.
    % Therefore, cases without a user-defined geometryFile usually contain [].
    % Check for emptiness before converting to string.
    geometryFile = "";
    
    if isfield(caseDefs(c), "geometryFile") && ~isempty(caseDefs(c).geometryFile)
        geometryFile = string(caseDefs(c).geometryFile);
    end
    
    if numel(geometryFile) > 1
        error("caseDefs(%d).geometryFile must be a single file name, not an array.", c);
    end
    
    if strlength(geometryFile) > 0
        dataset = attach_geometry_file_to_dataset(dataset, geometryFile);
    end
    if isfield(caseDefs(c), "opRequest")
        thisOpRequest = caseDefs(c).opRequest;
    else
        thisOpRequest = opRequest;
    end

    op = validate_and_solve_operating_point(dataset, thisOpRequest, model);

    caseData(c).dataset = dataset;
    caseData(c).op = op;
end

% -------- Stage 2: build synthetic datasets --------
for c = 1:numel(caseDefs)
    model = lower(string(caseDefs(c).model));

    if model ~= "synthetic_difference"
        continue
    end

    if ~isfield(caseDefs(c), "difference")
        error("Synthetic difference case '%s' must define caseDefs(%d).difference.", ...
            string(caseDefs(c).caseName), c);
    end

    idxA = caseDefs(c).difference.caseA;
    idxB = caseDefs(c).difference.caseB;

    if isempty(caseData(idxA).dataset) || isempty(caseData(idxB).dataset)
        error("Synthetic difference case '%s' references cases that have not been loaded.", ...
            string(caseDefs(c).caseName));
    end

    gridMode = "intersection_caseA";
    if isfield(caseDefs(c).difference, "gridMode")
        gridMode = caseDefs(c).difference.gridMode;
    end

    [dataset, differenceReport] = create_synthetic_difference_dataset( ...
        caseData(idxA).dataset, caseData(idxA).op, ...
        caseData(idxB).dataset, caseData(idxB).op, ...
        "CaseNameA", caseDefs(idxA).caseName, ...
        "CaseNameB", caseDefs(idxB).caseName, ...
        "DatasetFileA", caseDefs(idxA).datasetFile, ...
        "DatasetFileB", caseDefs(idxB).datasetFile, ...
        "GridMode", gridMode, ...
        "Verbose", true);

    op = struct();
    op.mode = "precomputed";
    op.currents = [];
    op.magnet = [];
    op.target = [];
    op.rowsToControl = [];
    op.residualNorm = [];

    caseData(c).dataset = dataset;
    caseData(c).op = op;
    caseData(c).differenceReport = differenceReport;
end

% -------- Stage 3: run queries and pack Q --------
Q = cell(1, numel(caseDefs));

for c = 1:numel(caseDefs)
    dataset = caseData(c).dataset;
    op = caseData(c).op;

    [results, queriesUsed] = run_field_queries(dataset, op, caseDefs(c).queries, caseDefs(c).model);

    Q{c} = pack_query_case(dataset, op, queriesUsed, results, caseDefs(c));

    if isfield(caseData(c), "differenceReport")
        Q{c}.differenceReport = caseData(c).differenceReport;
        Q{c}.differenceStats = compute_field_difference_statistics(dataset);
    end
end

% -------- Stage 4: append external analytical/reference line data --------
if includeAnalyticalLine
    analyticalQcase = create_analytical_Bz_line_Qcase( ...
        analyticalLineFile, ...
        analyticalLineGroup, ...
        analyticalCaseName, ...
        analyticalQueryName);

    Q{end+1} = analyticalQcase;
end

% ------------------------- Save Q batch -------------------------
% If this query compares multiple dataset files/runs, a text label is clearer
% than pretending the Q output belongs to one run number.
querySetLabel = "Comparison";

[queryFile, batchNumber] = next_Q_filename(outputDir, querySetLabel, "QueryBatch");

for c = 1:numel(Q)
    Q{c}.meta.queryFile = string(queryFile);
    Q{c}.queryFile = string(queryFile);
    Q{c}.batchNumber = batchNumber;
end

save(queryFile, "Q");
fprintf("Saved query batch: %s\n", queryFile);



%% ------------------------------------------------------------------------------

function Qcase = create_analytical_Bz_line_Qcase(dataFile, groupNumber, caseName, queryName)
%CREATE_ANALYTICAL_BZ_LINE_QCASE Pack measured/analytical Bz line data into Q format.
%
% The input .mat file must contain:
%   z_mm : z coordinate in mm
%   Bz_G : Bz field in Gauss
%
% Output units:
%   s    : metres, tared to the first z position
%   data : Tesla

raw = load(dataFile);

if ~isfield(raw, "z_mm")
    error("Analytical line file '%s' must contain variable z_mm.", string(dataFile));
end

if ~isfield(raw, "Bz_G")
    error("Analytical line file '%s' must contain variable Bz_G.", string(dataFile));
end

z_mm = raw.z_mm(:);
Bz_G = raw.Bz_G(:);

if numel(z_mm) ~= numel(Bz_G)
    error("Analytical line data must have the same number of z_mm and Bz_G entries.");
end

if numel(z_mm) < 2
    error("Analytical line data must contain at least two points.");
end

if any(~isfinite(z_mm)) || any(~isfinite(Bz_G))
    error("Analytical line data contains NaN or Inf values.");
end

% Unit conversion.
z_m = z_mm * 1e-3;
Bz_T = Bz_G * 1e-4;

% Internal line plots use s = distance from the start of the line.
% Because this is a 1D z-only dataset, tare to the first z value.
s = abs(z_m - z_m(1));

% Use a notional z-axis line for compatibility with plot/overview records.
% The plotted line group uses s and data; X/Y/Z are included for structural
% consistency with normal query results.
X = zeros(size(s));
Y = zeros(size(s));
Z = z_m - z_m(1);

q = struct();
q.type = "line";
q.quantity = "field";
q.component = "z";
q.start = [0 0 Z(1)];
q.end = [0 0 Z(end)];
q.nPoints = numel(s);
q.name = string(queryName);
q.plot = struct( ...
    "group", groupNumber, ...
    "inOverview", false, ...
    "showCoils", false);

result = struct();
result.queryIndex = 1;
result.X = X;
result.Y = Y;
result.Z = Z;
result.s = s;
result.data = Bz_T;
result.inside = true(size(Bz_T));
result.dataName = "Bz";
result.plot = q.plot;

Qcase = struct();

Qcase.meta = struct();
Qcase.meta.caseName = string(caseName);
Qcase.meta.model = "analytical_line";
Qcase.meta.source = "external_analytical_line";
Qcase.meta.datasetFile = string(dataFile);
Qcase.meta.geometryFile = "";
Qcase.meta.queryFile = "";
Qcase.meta.createdOn = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));

Qcase.geometry = struct( ...
    "coil", struct([]), ...
    "coilSpec", struct(), ...
    "windTunnel", []);

Qcase.current = struct();
Qcase.current.values = [];
Qcase.current.mode = "external";
Qcase.current.rowsToControl = [];
Qcase.current.residualNorm = [];

Qcase.magnet = [];
Qcase.target = [];

Qcase.queries = {q};
Qcase.results = {result};
end