function clrmap = def_clrmap(clrmap_range)
if and(or(size(clrmap_range, 1)~=3, size(clrmap_range, 2)~=3), size(clrmap_range, 3)~=1)
    error('clrmap_range does not have the correct dimensions should be a 3xN or Nx3');
end
if max(abs(clrmap_range), [], "all")>1
    error('clrmap_range requires values between 0 and 1')
end

num_colours = size(clrmap_range, 1);
n = 100;

clrmap = zeros(n*(num_colours-1)+1, 3);

for k = 2:num_colours
    clrend = clrmap_range(k, :);
    clrstart = clrmap_range(k-1, :);
    
    R = linspace(clrstart(1), clrend(1), n+1);
    G = linspace(clrstart(2), clrend(2), n+1);
    B = linspace(clrstart(3), clrend(3), n+1);
    clrmap((k-2)*n+1:(k-1)*n, :) = [R(1:end-1)', G(1:end-1)', B(1:end-1)'];
end
clrmap(end, :) = clrmap_range(end, :);

end