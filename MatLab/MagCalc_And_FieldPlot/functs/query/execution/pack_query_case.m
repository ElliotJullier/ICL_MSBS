function Qcase = pack_query_case(dataset, op, queries, results, caseDef, queryFile)
%PACK_QUERY_CASE Build one Q case struct for saving and plotting.
%
% The saved Q case keeps the user-facing label (caseName), the backend model
% keyword (model), the dataset provenance (source), and the sampled results.

if nargin < 6
    queryFile = "";
end

Qcase = struct();
Qcase.meta = struct();
Qcase.meta.caseName = string(caseDef.caseName);
Qcase.meta.model = string(caseDef.model);
Qcase.meta.source = string(dataset.source);

if isfield(caseDef, "datasetFile")
    Qcase.meta.datasetFile = string(caseDef.datasetFile);
elseif isfield(dataset, "datasetFile")
    Qcase.meta.datasetFile = string(dataset.datasetFile);
elseif isfield(dataset, "inputFile")
    Qcase.meta.datasetFile = string(dataset.inputFile);
else
    Qcase.meta.datasetFile = "";
end

if isfield(caseDef, "geometryFile")
    Qcase.meta.geometryFile = string(caseDef.geometryFile);
elseif isfield(dataset, "geometryFile")
    Qcase.meta.geometryFile = string(dataset.geometryFile);
else
    Qcase.meta.geometryFile = "";
end

Qcase.meta.queryFile = string(queryFile);
Qcase.meta.createdOn = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));

if isfield(dataset, "geometry")
    Qcase.geometry = dataset.geometry;
else
    Qcase.geometry = struct("coil", struct([]), "coilSpec", struct(), "windTunnel", []);
end

Qcase.current = struct();
Qcase.current.values = op.currents;
Qcase.current.mode = op.mode;
Qcase.current.rowsToControl = op.rowsToControl;
Qcase.current.residualNorm = op.residualNorm;

if isfield(op, "magnet")
    Qcase.magnet = op.magnet;
else
    Qcase.magnet = [];
end
if isfield(op, "target")
    Qcase.target = op.target;
else
    Qcase.target = [];
end

if isfield(dataset, "synthetic")
    Qcase.synthetic = dataset.synthetic;
end

Qcase.queries = queries;
Qcase.results = results;
end
