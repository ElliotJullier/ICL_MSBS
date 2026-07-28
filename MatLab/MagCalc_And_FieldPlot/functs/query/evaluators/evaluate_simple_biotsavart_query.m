function result = evaluate_simple_biotsavart_query(dataset, op, q, queryIndex)
%EVALUATE_SIMPLE_BIOTSAVART_QUERY Evaluate an on-axis circular-loop model.
%
% This simple model supports line queries only. For q.quantity="gradient",
% the returned data is d(selected component)/ds along the sampled line.
% Arbitrary gradient directions are intentionally not supported.

if q.type ~= "line"
    error("simple_biotsavart supports only line queries.");
end

if q.quantity == "gradient" && isfield(q, "gradientDirection") && ~isempty(q.gradientDirection)
    warning("simple_biotsavart ignores GradientDirection and returns derivative along the queried line.");
end

geometry = dataset.geometry;
coils = geometry.coil;

component = q.component;

currents = op.currents(:).';
if isscalar(currents)
    currents = repmat(currents, 1, numel(coils));
end
if numel(currents) ~= numel(coils)
    error("Number of currents must match number of coils.");
end

mu0 = 4*pi*1e-7;

p0 = q.start(:).';
p1 = q.end(:).';
t = linspace(0, 1, q.nPoints).';
X = p0(1) + t*(p1(1)-p0(1));
Y = p0(2) + t*(p1(2)-p0(2));
Z = p0(3) + t*(p1(3)-p0(3));

B = zeros(size(X));
pts_global = [X.'; Y.'; Z.'];

for k = 1:numel(coils)
    coilType = string(coils(k).coilType);
spec = geometry.coilSpec.(coilType);

pts_local = coord_global2local(pts_global, coils(k).pose);
radial = hypot(pts_local(1,:), pts_local(2,:));
if any(radial > 1e-9)
    error("Query line must lie on the axis of coil %d for the simple on-axis model.", k);
end

axial = pts_local(3,:).';

% Approximate a finite winding pack by spreading the turns uniformly over
% radius and axial height. Each sampled circular loop carries an equal
% fraction of the total turns.
%
% This is still an on-axis model, but no longer concentrates all turns at
% one radius and one axial position.
nRadialSamples = 7;
nAxialSamples = 11;

if isfield(spec, "nRadialSamples") && ~isempty(spec.nRadialSamples)
    nRadialSamples = max(1, round(spec.nRadialSamples));
end

if isfield(spec, "nAxialSamples") && ~isempty(spec.nAxialSamples)
    nAxialSamples = max(1, round(spec.nAxialSamples));
end

rSamples = linspace(spec.innerRadius, spec.outerRadius, nRadialSamples);

if isfield(spec, "height") && ~isempty(spec.height) && spec.height > 0
    zSamples = linspace(-spec.height/2, spec.height/2, nAxialSamples);
else
    zSamples = 0;
    nAxialSamples = 1;
end

turnsPerLoop = spec.turns / (numel(rSamples) * numel(zSamples));

B_local_z = zeros(size(axial));

for ir = 1:numel(rSamples)
    rLoop = rSamples(ir);

    for iz = 1:numel(zSamples)
        zLoop = zSamples(iz);

        dz = axial - zLoop;

        B_local_z = B_local_z + ...
            turnsPerLoop * mu0 * currents(k) * rLoop^2 ./ ...
            (2 * (dz.^2 + rLoop^2).^(3/2));
    end
end

    N = numel(B_local_z);
    B_local = [zeros(1,N); zeros(1,N); B_local_z.'];
    B_global = coord_local2global(B_local, [0, 0, 0, coils(k).pose(4:6)]);

    switch component
        case "x"
            B = B + B_global(1,:).';
        case "y"
            B = B + B_global(2,:).';
        case "z"
            B = B + B_global(3,:).';
    end
end

dxyz = [X - X(1), Y - Y(1), Z - Z(1)];
s = sqrt(sum(dxyz.^2, 2));

data = B;
dataName = "B" + component;

if q.quantity == "gradient"
    data = gradient(B, s);
    dataName = "dB" + component + "/ds";
end

result = struct();
result.queryIndex = queryIndex;
result.X = X;
result.Y = Y;
result.Z = Z;
result.s = s;
result.data = data;
result.dataName = dataName;
result.inside = true(size(data));
result.plot = q.plot;
end
