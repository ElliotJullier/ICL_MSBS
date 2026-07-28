function validate_same_coil_geometry_for_group(reqs)
%VALIDATE_SAME_COIL_GEOMETRY_FOR_GROUP Check grouped plane cases share coils.
%
% Grouped plane plots can show one coil geometry overlay only if all grouped
% cases use equivalent coil setups. Coil order and coil names are ignored;
% coil type, pose, and dimensions must match within tolerance.

if numel(reqs) <= 1
    return
end

ref = build_coil_signature(reqs{1}.geometry);

for k = 2:numel(reqs)
    sig = build_coil_signature(reqs{k}.geometry);
    if ~signatures_match(ref, sig)
        error("Grouped plane plot cannot show coils because grouped cases use different coil geometry. Set showCoils=false or plot cases separately.");
    end
end
end

function sig = build_coil_signature(geometry)
n = numel(geometry.coil);
sig = strings(n,1);

for k = 1:n
    coil = geometry.coil(k);
    spec = geometry.coilSpec.(string(coil.coilType));

    vals = [ ...
        spec.outerRadius, spec.innerRadius, spec.height, spec.turns, ...
        coil.pose(:).' ];

    sig(k) = string(coil.coilType) + ":" + join(string(round(vals, 12)), ",");
end

sig = sort(sig);
end

function tf = signatures_match(a, b)
tf = numel(a) == numel(b) && all(a == b);
end
