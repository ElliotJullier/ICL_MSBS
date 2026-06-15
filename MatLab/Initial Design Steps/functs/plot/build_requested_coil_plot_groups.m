function coilGroups = build_requested_coil_plot_groups(records)
%BUILD_REQUESTED_COIL_PLOT_GROUPS Group requested coil overlays by geometry.
%
% Only records whose query requested ShowCoils=true are considered. Records
% without coil geometry are ignored. Records with equivalent coil geometry
% are grouped so the same coil set is plotted only once.
%
% Synthetic difference datasets may contain multiple source coil geometries
% in record.synthetic.coilGeometrySources. These are expanded so a synthetic
% difference between, for example, 70 cm and 90 cm coil offsets can plot both
% coil layouts. Matching source layouts collapse to one overlay.
%
% Output fields:
%   coilGroups(g).geometry
%   coilGroups(g).records
%   coilGroups(g).recordIndices
%   coilGroups(g).caseNames
%   coilGroups(g).legendLabel
%   coilGroups(g).signature
%
% Legend labels:
%   one distinct requested coil set:
%       Coils
%   multiple distinct requested coil sets:
%       Coils: Case (Case A) and (Case B)

coilGroups = struct( ...
    "geometry", {}, ...
    "records", {}, ...
    "recordIndices", {}, ...
    "caseNames", {}, ...
    "legendLabel", {}, ...
    "signature", {});

if isempty(records)
    return
end

for k = 1:numel(records)
    record = records{k};

    if ~record_requests_coils(record)
        continue
    end

    sources = coil_geometry_sources_for_record(record);

    if isempty(sources)
        warning("ShowCoils=true was requested for case '%s', but no usable coil geometry was available. Coil overlay skipped for that record.", ...
            string(record.caseName));
        continue
    end

    for s = 1:numel(sources)
        source = sources(s);

        if ~source.hasUsableGeometry
            if isfield(record, "synthetic")
                warning("ShowCoils=true was requested for synthetic case '%s', but source case '%s' has no usable coil geometry. Coil overlay skipped for that source.", ...
                    string(record.caseName), string(source.caseName));
            else
                warning("ShowCoils=true was requested for case '%s', but no usable coil geometry was available. Coil overlay skipped for that record.", ...
                    string(record.caseName));
            end
            continue
        end

        coilGroups = add_source_to_coil_groups(coilGroups, record, k, source);
    end
end

% Finalise stable, unique case names and legend labels.
for g = 1:numel(coilGroups)
    coilGroups(g).caseNames = unique(coilGroups(g).caseNames, "stable");
end

if numel(coilGroups) == 1
    coilGroups(1).legendLabel = "Coils";
elseif numel(coilGroups) > 1
    for g = 1:numel(coilGroups)
        caseList = "(" + coilGroups(g).caseNames + ")";
        coilGroups(g).legendLabel = "Coils: Case " + join(caseList, " and ");
    end
end
end

function coilGroups = add_source_to_coil_groups(coilGroups, record, recordIndex, source)
sig = build_coil_signature(source.geometry);

matchIdx = 0;
for g = 1:numel(coilGroups)
    if signatures_match(coilGroups(g).signature, sig)
        matchIdx = g;
        break
    end
end

if matchIdx == 0
    matchIdx = numel(coilGroups) + 1;
    coilGroups(matchIdx).geometry = source.geometry;
    coilGroups(matchIdx).records = {record};
    coilGroups(matchIdx).recordIndices = recordIndex;
    coilGroups(matchIdx).caseNames = string(source.caseName);
    coilGroups(matchIdx).legendLabel = "Coils";
    coilGroups(matchIdx).signature = sig;
else
    coilGroups(matchIdx).records{end+1} = record;
    coilGroups(matchIdx).recordIndices(end+1) = recordIndex;
    coilGroups(matchIdx).caseNames(end+1) = string(source.caseName);
end
end

function tf = record_requests_coils(record)
tf = false;

if isfield(record, "query") && ...
   isfield(record.query, "plot") && ...
   isfield(record.query.plot, "showCoils") && ...
   ~isempty(record.query.plot.showCoils)
    tf = logical(record.query.plot.showCoils);
end
end

function sources = coil_geometry_sources_for_record(record)
%COIL_GEOMETRY_SOURCES_FOR_RECORD Return one or more source geometries.
%
% Normal record:
%   one source, labelled with record.caseName.
%
% Synthetic difference record with record.synthetic.coilGeometrySources:
%   one source per input case, labelled with source.caseName.

sources = struct( ...
    "caseName", {}, ...
    "hasUsableGeometry", {}, ...
    "geometry", {});

if isfield(record, "synthetic") && ...
   isstruct(record.synthetic) && ...
   isfield(record.synthetic, "coilGeometrySources") && ...
   ~isempty(record.synthetic.coilGeometrySources)

    rawSources = record.synthetic.coilGeometrySources;

    for k = 1:numel(rawSources)
        source = struct();

        if isfield(rawSources(k), "caseName") && strlength(string(rawSources(k).caseName)) > 0
            source.caseName = string(rawSources(k).caseName);
        else
            source.caseName = string(record.caseName) + " source " + string(k);
        end

        if isfield(rawSources(k), "geometry") && ~isempty(rawSources(k).geometry)
            source.geometry = rawSources(k).geometry;
        else
            source.geometry = empty_geometry();
        end

        if isfield(rawSources(k), "hasUsableGeometry") && ~isempty(rawSources(k).hasUsableGeometry)
            source.hasUsableGeometry = logical(rawSources(k).hasUsableGeometry);
        else
            source.hasUsableGeometry = has_usable_geometry(source.geometry);
        end

        sources(end+1) = source; %#ok<AGROW>
    end

    return
end

source = struct();
source.caseName = string(record.caseName);

if isfield(record, "geometry") && ~isempty(record.geometry)
    source.geometry = record.geometry;
else
    source.geometry = empty_geometry();
end

source.hasUsableGeometry = has_usable_geometry(source.geometry);
sources = source;
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

function sig = build_coil_signature(geometry)
%BUILD_COIL_SIGNATURE Build an order-independent coil-geometry signature.
%
% This mirrors the intent of validate_same_coil_geometry_for_group, but
% returns a signature instead of throwing errors. Coil order and names are
% ignored; coil type, pose, dimensions, and fallback shape bounds are used.

n = numel(geometry.coil);
sig = strings(n, 1);

for k = 1:n
    coil = geometry.coil(k);

    coilType = "";
    if isfield(coil, "coilType") && ~isempty(coil.coilType)
        coilType = string(coil.coilType);
    end

    vals = [];

    if isfield(geometry, "coilSpec") && isstruct(geometry.coilSpec) && ...
       strlength(coilType) > 0 && isfield(geometry.coilSpec, coilType)

        spec = geometry.coilSpec.(coilType);
        vals = [vals, get_numeric_field(spec, "outerRadius")]; %#ok<AGROW>
        vals = [vals, get_numeric_field(spec, "innerRadius")]; %#ok<AGROW>
        vals = [vals, get_numeric_field(spec, "height")]; %#ok<AGROW>
        vals = [vals, get_numeric_field(spec, "turns")]; %#ok<AGROW>
    end

    if isfield(coil, "pose") && ~isempty(coil.pose)
        vals = [vals, double(coil.pose(:).')]; %#ok<AGROW>
    end

    % Fallback for imported or simplified geometries where coilSpec is not
    % available: include approximate shape bounds. This is less semantically
    % rich than coilSpec+pose, but still avoids plotting identical mesh
    % geometry multiple times.
    if isfield(coil, "shape") && isstruct(coil.shape) && ...
       isfield(coil.shape, "Vertices") && ~isempty(coil.shape.Vertices)

        vertices = double(coil.shape.Vertices);
        xyzMin = min(vertices, [], 1);
        xyzMax = max(vertices, [], 1);
        xyzCtr = 0.5*(xyzMin + xyzMax);
        xyzSize = xyzMax - xyzMin;
        vals = [vals, xyzCtr, xyzSize]; %#ok<AGROW>
    end

    vals = round(vals, 12);
    sig(k) = coilType + ":" + join(string(vals), ",");
end

sig = sort(sig);
end

function val = get_numeric_field(s, name)
if isfield(s, name) && ~isempty(s.(name)) && isnumeric(s.(name))
    val = double(s.(name));
else
    val = NaN;
end
end

function tf = signatures_match(a, b)
tf = numel(a) == numel(b) && all(a == b);
end
