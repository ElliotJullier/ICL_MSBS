function result = query_line(field, F, I, q)
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

for k = 1:numel(I)
    switch string(q.component)
        case "x"
            Bk = F.Bx{k}(Y, X, Z);
        case "y"
            Bk = F.By{k}(Y, X, Z);
        case "z"
            Bk = F.Bz{k}(Y, X, Z);
        otherwise
            error('q.component must be "x", "y", or "z".');
    end
    B = B + I(k)*Bk;
end

inside = query_in_domain(field, X, Y, Z);
B(~inside) = NaN;

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
result.inside = inside;

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
end
