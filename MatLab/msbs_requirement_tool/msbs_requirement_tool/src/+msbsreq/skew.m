function S = skew(v)
%SKEW Return the 3-by-3 cross-product matrix for a 3-vector.
arguments
    v (3,1) double {mustBeFinite}
end
S = [0, -v(3), v(2); v(3), 0, -v(1); -v(2), v(1), 0];
end
