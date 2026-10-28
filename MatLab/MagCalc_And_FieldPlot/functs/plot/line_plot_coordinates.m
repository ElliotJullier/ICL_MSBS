function [coordinates,label,mode] = line_plot_coordinates(records,requested)
%LINE_PLOT_COORDINATES Signed physical axis for axis-aligned lines by default.
% Oblique/mixed-axis groups use arclength; explicit x/y/z/distance is allowed.
if nargin<2, requested="auto"; end
mode=lower(string(requested)); names=["x","y","z"]; fields=["X","Y","Z"];
if mode=="auto"
    candidates=strings(1,numel(records));
    for k=1:numel(records)
        r=records{k};
        delta=[r.X(end)-r.X(1),r.Y(end)-r.Y(1),r.Z(end)-r.Z(1)];
        varying=find(abs(delta)>1e-10*max(norm(delta),realmin));
        if numel(varying)==1, candidates(k)=names(varying); end
    end
    if all(strlength(candidates)>0) && all(candidates==candidates(1))
        mode=candidates(1);
    else
        mode="distance";
    end
end
index=find(names==mode,1); coordinates=cell(size(records));
if mode=="distance"
    label="Distance along line [m]";
    for k=1:numel(records), coordinates{k}=records{k}.s; end
elseif ~isempty(index)
    label="$"+mode+"$ [m]";
    for k=1:numel(records), coordinates{k}=records{k}.(fields(index)); end
else
    error("MSBS:LineAxis","lineAxis must be auto, x, y, z or distance.");
end
end
