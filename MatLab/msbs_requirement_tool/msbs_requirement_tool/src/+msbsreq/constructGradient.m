function G = constructGradient(x)
%CONSTRUCTGRADIENT Construct the symmetric trace-free gradient from 8 unknowns.
%   x = [Bx By Bz gxx gyy gxy gxz gyz].
arguments
    x (8,1) double {mustBeFinite}
end
gxx=x(4); gyy=x(5); gxy=x(6); gxz=x(7); gyz=x(8);
G=[gxx,gxy,gxz;gxy,gyy,gyz;gxz,gyz,-gxx-gyy];
end
