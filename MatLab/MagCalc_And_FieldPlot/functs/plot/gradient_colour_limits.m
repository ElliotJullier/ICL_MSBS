function [limits,report] = gradient_colour_limits(records,percentile)
%GRADIENT_COLOUR_LIMITS Robust symmetric display cap; never modifies samples.
% Pool finite plane magnitudes for one shared scale. The caller filters the
% ordinary/difference class first; explicit user clim takes priority.
validateattributes(percentile,{'numeric'},{'scalar','real','finite','>',0,'<=',100});
values=[];
for r=records
    r=r{1};
    if isfield(r,"s") || ~isfield(r,"data") || lower(string(r.query.quantity))~="gradient", continue; end
    data=abs(r.data(isfinite(r.data))); values=[values;data(:)]; %#ok<AGROW>
end
values=sort(values);
report=struct("percentile",percentile,"threshold",NaN,"saturatedFraction",0,"sampleCount",numel(values));
if isempty(values), limits=[-1 1]; return; end
rank=1+(numel(values)-1)*percentile/100; lo=floor(rank); hi=ceil(rank);
cap=values(lo)+(rank-lo)*(values(hi)-values(lo));
if cap<=0
    positive=values(values>0);
    if isempty(positive), cap=1; else, cap=positive(ceil(percentile/100*numel(positive))); end
end
limits=[-cap cap]; report.threshold=cap;
report.saturatedFraction=nnz(values>cap)/numel(values);
end
