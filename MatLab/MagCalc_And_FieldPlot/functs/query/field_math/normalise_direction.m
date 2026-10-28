function [direction,label] = normalise_direction(value)
%NORMALISE_DIRECTION x/y/z shorthand or finite nonzero vector -> unit row.
if ischar(value) || (isstring(value) && isscalar(value))
    index=find(["x","y","z"]==lower(string(value)),1);
    if isempty(index), error("MSBS:Direction","Use x, y, z or a finite nonzero 3-vector."); end
    direction=zeros(1,3); direction(index)=1;
else
    validateattributes(value,{'numeric'},{'real','finite','vector','numel',3});
    direction=double(value(:).');
    if norm(direction)==0, error("MSBS:Direction","Direction cannot be zero."); end
    direction=direction/norm(direction);
end
index=find(all(abs(eye(3)-direction)<1e-12,2),1);
if isempty(index)
    label="["+join(compose("%.6g",direction),",")+"]";
else
    names=["x","y","z"]; label=names(index);
end
end
