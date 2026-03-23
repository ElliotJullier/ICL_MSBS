function Q = simple_biotsavart_query(load_filename, currents, queries, varargin)
% Build plot-ready query output using a simple on-axis Biot-Savart model.
%
% This helper is intended for quick comparisons against the full queried
% field. It currently supports line queries that lie along the local axis of
% a circular coil. The output Q matches the expected plot_main format.
%
% Optional name-value pairs:
%   "caseName"   string stored in Q.meta.case_name
%   "sourceName" string used only as metadata

p = inputParser;
addParameter(p, 'caseName', "", @(x) isstring(x) || ischar(x));
addParameter(p, 'sourceName', "Simple Biot-Savart", @(x) isstring(x) || ischar(x));
parse(p, varargin{:});
opts = p.Results;

[coils, geom, ~] = load_coilfield_mat(load_filename);

if isscalar(currents)
    currents = repmat(currents, 1, numel(coils));
end
currents = currents(:).';

if numel(currents) ~= numel(coils)
    error("Number of currents must match the number of coils.");
end

averageR = (geom.coil_outer_radius + geom.coil_inner_radius) / 2;
mu_0 = 1.2566e-6;

Q = struct();
Q.input = struct();
Q.input.load_filename = load_filename;
Q.input.queries = queries;
Q.input.model = "simple_biotsavart_on_axis";

Q.intermediate = struct();
Q.intermediate.currents = struct();
Q.intermediate.currents.current = currents;
Q.intermediate.currents.isOverridden = true;

Q.meta = struct();
Q.meta.case_name = string(opts.caseName);
Q.meta.source_type = string(opts.sourceName);
Q.meta.created_on = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
Q.meta.notes = "Valid only for line queries aligned with each coil axis.";

Q.plotting = cell(size(queries));

for iq = 1:numel(queries)
    q = queries{iq};
    if lower(string(q.type)) ~= "line"
        error("simple_biotsavart_query currently supports only line queries.");
    end
    if string(q.component) ~= "x"
        error("simple_biotsavart_query currently supports only the on-axis component, q.component = 'x'.");
    end

    if ~isfield(q, 'nPoints')
        q.nPoints = 200;
    end

    p0 = q.start(:).';
    p1 = q.end(:).';
    t = linspace(0, 1, q.nPoints).';

    X = p0(1) + t*(p1(1)-p0(1));
    Y = p0(2) + t*(p1(2)-p0(2));
    Z = p0(3) + t*(p1(3)-p0(3));

    B = zeros(size(X));

    for k = 1:numel(coils)
        pts_global = [X.'; Y.'; Z.'];
        pts_local = coord_global2local(pts_global, coils(k).rel_pos);

        radial = hypot(pts_local(1,:), pts_local(2,:));
        if any(radial > 1e-9)
            error("Query line must lie on the axis of coil %d for the simple on-axis model.", k);
        end

        axial = pts_local(3,:).';
        B_local_z = geom.N * mu_0 * currents(k) * averageR^2 ./ (2 * (axial.^2 + averageR^2).^(3/2));
        % On-axis field is along local z
        N = numel(B_local_z);
        B_local = [zeros(1,N); zeros(1,N); B_local_z.'];
        B_global = coord_local2global(B_local, [0, 0, 0, coils(k).rel_pos(4:6)]);
        B = B + B_global(1,:).';
    end

    dxyz = [X - X(1), Y - Y(1), Z - Z(1)];
    s = sqrt(sum(dxyz.^2, 2));

    result = struct();
    result.type = "line";
    result.component = q.component;
    result.start = q.start;
    result.end = q.end;
    result.X = X;
    result.Y = Y;
    result.Z = Z;
    result.s = s;
    result.B = B;
    result.inside = true(size(B));

    if isfield(q, 'group')
        result.group = q.group;
    end
    if isfield(q, 'inOverview')
        result.inOverview = q.inOverview;
    else
        result.inOverview = false;
    end
    if isfield(q, 'legendName')
        result.legendName = q.legendName;
    end

    Q.plotting{iq} = result;
end

end
