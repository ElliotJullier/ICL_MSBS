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

% ------------------------- Case-specific query definitions -------------------------
% The operating point is shared, but each case defines its own dataset, model,
% display name, and queries. This avoids putting model-specific labels inside
% shared queries and allows simple_biotsavart/COMSOL cases to reject unsupported
% query types clearly.

caseDefs = struct([]);

current_num = 1;
caseDefs(current_num).caseName = "90 cm case";
caseDefs(current_num).model = "matlab_full_biotsavart";
caseDefs(current_num).datasetFile = datasetFile;
caseDefs(current_num).queries = { ...
    create_plane_field_query("xz", 0, "z", "Overview", true,  "Group", 4, "ShowCoils", true, "Name", "Bz on xz plane"), ...
    create_plane_gradient_query("xz", 0, "z", [0 0 1], "Overview", false, "Name", "dBz/dz in xz plane", "ShowCoils", true), ...
    create_plane_field_query("yz", 0, "z", "Overview", true, "Group", 1, "Name", "Bz on yz plane"), ...
    create_plane_field_query("xy", 0, "z", "Overview", true, "Group", 1, "Name", "Bz on xy plane"), ...
    create_line_field_query([0 0 -120/1000], [0 0 120/1000], "z", ...
        "NPoints", 200, "Group", 2, "Overview", true, "Name", "Centreline Bz", "ShowCoils", true), ...
    create_line_field_query([0 0 -120/1000], [0 0 120/1000], "z", ...
        "NPoints", 200, "Group", 6, "Overview", true, "Name", "Centreline Bz", "ShowCoils", true), ...
    create_line_gradient_query([0 0 -120/1000], [0 0 120/1000], "z", ...
        "NPoints", 200, "Group", 3, "Name", "Centreline dBz/ds", "ShowCoils", true) ...
};

current_num = 2;
caseDefs(current_num).caseName = "70cm case";
caseDefs(current_num).model = "matlab_full_biotsavart";
caseDefs(current_num).datasetFile = "coilfield_run2.mat";
caseDefs(current_num).queries = { ...
    create_plane_field_query("xz", 0, "z",  "Group", 4, "Overview", true,  "ShowCoils", true, "Name", "Bz on xz plane"), ...
    create_line_field_query([0 0 -120/1000], [0 0 120/1000], "z", ...
        "NPoints", 200, "Group", 2, "Overview", true, "Name", "Centreline Bz", "ShowCoils", true), ...
    create_line_gradient_query([0 0 -120/1000], [0 0 120/1000], "z", ...
        "NPoints", 200, "Group", 3, "Name", "Centreline dBz/ds", "ShowCoils", true) ...
};

current_num = 3;
caseDefs(current_num).caseName = "90cm vs 70cm comparison";
caseDefs(current_num).model = "synthetic_difference";
caseDefs(current_num).difference.caseA = 2;   
caseDefs(current_num).difference.caseB = 1;  
caseDefs(current_num).difference.gridMode = "intersection_caseA";
caseDefs(current_num).queries = { ...
    create_plane_field_query("xz", 0, "z", "Overview", true, "Name", "Difference Bz on xz plane"), ...
    create_plane_gradient_query("xz", 0, "z", [0 0  1], "ShowCoils", true, "Name", "dBz/dz on xz plane"), ...
    create_line_field_query([0 0 -120/1000], [0 0 120/1000], "z", ...
        "NPoints", 200, "Group", 2, "Overview", true, "Name", "Difference centreline Bz", "ShowCoils", true) ...
};


stl_to_query_geometry_file( ...
    "COMSOL_geometry.mat", ...
    "COMSOL_Tester_Coil.stl", ...
    [0, 0, 90/1000, 0, 0, 0], ...
    "InputScale", 1e-3, ...
    "CentreMode", "none");

current_num = 4;
caseDefs(current_num).caseName = "COMSOL";
caseDefs(current_num).model = "comsol_grid";
caseDefs(current_num).datasetFile = "SolverTesting_1.txt";
caseDefs(current_num).geometryFile = "COMSOL_geometry.mat";
caseDefs(current_num).queries = { ...
    create_plane_field_query("xz", 0, "z", "Overview", true, "ShowCoils", true), ...
    create_line_field_query([0 0 -120/1000], [0 0 120/1000], "z", "NPoints", 200, "Group", 6, "ShowCoils", true) ...
};

current_num = 5;
caseDefs(current_num).caseName = "Comsol vs matlab comparison";
caseDefs(current_num).model = "synthetic_difference";
caseDefs(current_num).difference.caseA = 4;   
caseDefs(current_num).difference.caseB = 1;  
caseDefs(current_num).difference.gridMode = "intersection_caseA";
caseDefs(current_num).queries = { ...
    create_plane_field_query("xz", 0, "z", "Overview", true, "Name", "Difference Bz on xz plane"), ...
    create_plane_gradient_query("xz", 0, "z", [0 0  1], "Name", "dBz/dz on xz plane"), ...
    create_line_field_query([0 0 -120/1000], [0 0 120/1000], "z", ...
        "NPoints", 200, "Group", 6, "Overview", true, "Name", "Difference centreline Bz") ...
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
% caseDefs(3).caseName = "COMSOL";
% caseDefs(3).model = "comsol_grid";
% caseDefs(3).datasetFile = "comsol_run1.mat";
% caseDefs(3).queries = { ...
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
