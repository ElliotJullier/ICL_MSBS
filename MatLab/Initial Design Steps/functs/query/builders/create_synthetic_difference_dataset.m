function [diffDataset, report] = create_synthetic_difference_dataset(datasetA, opA, datasetB, opB, varargin)
%CREATE_SYNTHETIC_DIFFERENCE_DATASET Create a precomputed field-difference dataset.
%
% [diffDataset, report] = create_synthetic_difference_dataset(datasetA, opA, datasetB, opB)
%
% The difference is:
%   diffDataset.B = totalFieldA - totalFieldB
%
% Both inputs may be either:
%   - superposable datasets, where total field is formed from op.currents, or
%   - precomputed datasets, where dataset.B(:,:,:,:,1) is already total field.
%
% Default comparison behaviour:
%   - use the intersection of the two grid bounding boxes
%   - use case A's grid points inside the intersection as the comparison grid
%
% Name-value options:
%   "CaseNameA"      label for dataset A in metadata
%   "CaseNameB"      label for dataset B in metadata
%   "DatasetFileA"   source filename for dataset A
%   "DatasetFileB"   source filename for dataset B
%   "GridMode"       currently only "intersection_caseA"
%   "Verbose"        true/false, print excluded-domain information
%
% Geometry/provenance note:
%   The synthetic field itself is one gridded dataset, but coil plotting needs
%   to know the source coil layouts. Therefore both source geometries are
%   stored under:
%       diffDataset.synthetic.coilGeometrySources
%   so plotting can show one overlay for matching layouts and separate
%   overlays for different layouts.

p = inputParser;
addParameter(p, "CaseNameA", "caseA", @(x)isstring(x) || ischar(x));
addParameter(p, "CaseNameB", "caseB", @(x)isstring(x) || ischar(x));
addParameter(p, "DatasetFileA", "", @(x)isstring(x) || ischar(x));
addParameter(p, "DatasetFileB", "", @(x)isstring(x) || ischar(x));
addParameter(p, "GridMode", "intersection_caseA", @(x)isstring(x) || ischar(x));
addParameter(p, "Verbose", true, @(x)islogical(x) || isnumeric(x));
parse(p, varargin{:});
opts = p.Results;

gridMode = lower(string(opts.GridMode));

if gridMode ~= "intersection_casea"
    error("Only GridMode='intersection_caseA' is currently implemented.");
end

gridA = datasetA.grid;
gridB = datasetB.grid;

[xInt, excludedA_x, excludedB_x] = intersection_axis(gridA.x, gridB.x);
[yInt, excludedA_y, excludedB_y] = intersection_axis(gridA.y, gridB.y);
[zInt, excludedA_z, excludedB_z] = intersection_axis(gridA.z, gridB.z);

commonGrid = struct();
commonGrid.x = xInt;
commonGrid.y = yInt;
commonGrid.z = zInt;

if numel(commonGrid.x) < 2 || numel(commonGrid.y) < 2 || numel(commonGrid.z) < 2
    error("Intersection grid is too small for field comparison. Need at least two points along x, y, and z.");
end

BA = total_B_on_own_grid(datasetA, opA);
BB = total_B_on_own_grid(datasetB, opB);

Bdiff = NaN(numel(commonGrid.y), numel(commonGrid.x), numel(commonGrid.z), 3, 1);

[Xc, Yc, Zc] = meshgrid(commonGrid.x, commonGrid.y, commonGrid.z);

for componentIndex = 1:3
    FA = build_scalar_grid_interpolant(gridA, BA(:,:,:,componentIndex), "cubic", "none");
    FB = build_scalar_grid_interpolant(gridB, BB(:,:,:,componentIndex), "cubic", "none");

    AonCommon = FA(Yc, Xc, Zc);
    BonCommon = FB(Yc, Xc, Zc);

    Bdiff(:,:,:,componentIndex,1) = AonCommon - BonCommon;
end

VA = bounding_box_volume(gridA);
VB = bounding_box_volume(gridB);
VI = bounding_box_volume(commonGrid);

excludedA = 100 * (1 - VI / VA);
excludedB = 100 * (1 - VI / VB);

report = struct();
report.gridMode = gridMode;
report.caseNameA = string(opts.CaseNameA);
report.caseNameB = string(opts.CaseNameB);
report.datasetFileA = string(opts.DatasetFileA);
report.datasetFileB = string(opts.DatasetFileB);
report.excludedVolumePercentA = excludedA;
report.excludedVolumePercentB = excludedB;
report.excludedAxisPercentA = [excludedA_x excludedA_y excludedA_z];
report.excludedAxisPercentB = [excludedB_x excludedB_y excludedB_z];

% Keep a fallback geometry for older plotting code, but do not rely on this
% for synthetic coil overlays. New plotting code uses the source geometry
% list saved below.
geometry = choose_geometry_for_difference(datasetA, datasetB);
coilGeometrySources = build_source_geometry_list(datasetA, datasetB, opts);

diffDataset = struct();
diffDataset.source = "synthetic_difference";
diffDataset.createdOn = string(datetime("now", "Format", "yyyy-MM-dd HH:mm:ss"));
diffDataset.datasetFile = "synthetic_difference";
diffDataset.supportsSuperposition = false;
diffDataset.supportsCurrentSolve = false;
diffDataset.geometry = geometry;
diffDataset.grid = commonGrid;
diffDataset.B = Bdiff;

diffDataset.synthetic = struct();
diffDataset.synthetic.type = "difference";
diffDataset.synthetic.operation = "caseA_minus_caseB";
diffDataset.synthetic.caseNameA = report.caseNameA;
diffDataset.synthetic.caseNameB = report.caseNameB;
diffDataset.synthetic.datasetFileA = report.datasetFileA;
diffDataset.synthetic.datasetFileB = report.datasetFileB;
diffDataset.synthetic.gridMode = report.gridMode;
diffDataset.synthetic.excludedVolumePercentA = report.excludedVolumePercentA;
diffDataset.synthetic.excludedVolumePercentB = report.excludedVolumePercentB;

% Source geometry used only for coil overlay plotting. Each source is kept
% separate so differences such as 70 cm vs 90 cm coil offsets can be shown
% as two coil overlays rather than silently using only case A geometry.
diffDataset.synthetic.coilGeometrySources = coilGeometrySources;

if logical(opts.Verbose)
    fprintf("Synthetic difference '%s - %s': intersection excludes %.3g%% of case A bounding-box volume and %.3g%% of case B bounding-box volume.\n", ...
        report.caseNameA, report.caseNameB, excludedA, excludedB);
end
end

function [axisCommon, excludedA, excludedB] = intersection_axis(axisA, axisB)
axisA = axisA(:).';
axisB = axisB(:).';

lo = max(min(axisA), min(axisB));
hi = min(max(axisA), max(axisB));

if hi <= lo
    error("Input grids do not overlap along one axis.");
end

axisCommon = axisA(axisA >= lo & axisA <= hi);

if numel(axisCommon) < 2
    error("Case A grid has fewer than two points inside the intersection along one axis.");
end

lenA = max(axisA) - min(axisA);
lenB = max(axisB) - min(axisB);
lenI = max(axisCommon) - min(axisCommon);

excludedA = 100 * (1 - lenI / lenA);
excludedB = 100 * (1 - lenI / lenB);
end

function V = bounding_box_volume(grid)
V = (max(grid.x)-min(grid.x)) * ...
    (max(grid.y)-min(grid.y)) * ...
    (max(grid.z)-min(grid.z));

if V <= 0
    error("Grid bounding-box volume must be positive.");
end
end

function Btotal = total_B_on_own_grid(dataset, op)
if ~isfield(dataset, "B")
    error("Synthetic difference requires both datasets to contain dataset.B.");
end

if dataset.supportsSuperposition
    if ~isfield(op, "currents") || isempty(op.currents)
        error("Superposable dataset requires op.currents to form a total field.");
    end

    currents = reshape(op.currents, 1, 1, 1, 1, []);
    if numel(op.currents) ~= size(dataset.B, 5)
        error("op.currents length must match size(dataset.B,5).");
    end

    Btotal = sum(dataset.B .* currents, 5);
else
    Btotal = dataset.B(:,:,:,:,1);
end
end

function geometry = choose_geometry_for_difference(datasetA, datasetB)
% Use case A geometry as a fallback only. Synthetic coil plotting should use
% synthetic.coilGeometrySources rather than this single fallback geometry.
if isfield(datasetA, "geometry") && ~isempty(datasetA.geometry)
    geometry = datasetA.geometry;
elseif isfield(datasetB, "geometry") && ~isempty(datasetB.geometry)
    geometry = datasetB.geometry;
else
    geometry = empty_geometry();
end
end

function sources = build_source_geometry_list(datasetA, datasetB, opts)
%BUILD_SOURCE_GEOMETRY_LIST Store both source case geometries for plotting.

sources = repmat(struct( ...
    "source", "", ...
    "caseName", "", ...
    "datasetFile", "", ...
    "hasUsableGeometry", false, ...
    "geometry", empty_geometry()), 1, 2);

sources(1).source = "caseA";
sources(1).caseName = string(opts.CaseNameA);
sources(1).datasetFile = string(opts.DatasetFileA);
sources(1).geometry = geometry_or_empty(datasetA);
sources(1).hasUsableGeometry = has_usable_geometry(sources(1).geometry);

sources(2).source = "caseB";
sources(2).caseName = string(opts.CaseNameB);
sources(2).datasetFile = string(opts.DatasetFileB);
sources(2).geometry = geometry_or_empty(datasetB);
sources(2).hasUsableGeometry = has_usable_geometry(sources(2).geometry);
end

function geometry = geometry_or_empty(dataset)
if isfield(dataset, "geometry") && ~isempty(dataset.geometry)
    geometry = dataset.geometry;
else
    geometry = empty_geometry();
end
end

function tf = has_usable_geometry(geometry)
tf = isstruct(geometry) && ...
     isfield(geometry, "coil") && ...
     ~isempty(geometry.coil);
end

function geometry = empty_geometry()
geometry = struct();
geometry.windTunnel = [];
geometry.coilSpec = struct();
geometry.coil = struct([]);
end
