function style = resolve_plot_colour_limits(records,style)
%RESOLVE_PLOT_COLOUR_LIMITS One shared limit per quantity/comparison class.
% Absolute fields never set difference limits. Each gradient class receives
% its own percentile cap. Explicit class-specific limits override defaults.
requested=struct();
if isfield(style,"clim") && ~isempty(style.clim)
    if isnumeric(style.clim)
        requested=struct("field",style.clim,"gradient",style.clim);
    elseif isstruct(style.clim)
        requested=style.clim;
    else
        error("MSBS:ColourLimits","clim must be empty, numeric or a structure.");
    end
end
percentile=99; if isfield(style,"gradientPercentile"), percentile=style.gradientPercentile; end
style.clim=struct(); style.gradientColorLimitReports=struct();
keys=["field","fieldDifference","gradient","gradientDifference"];
classes=cellfun(@plot_colour_scale_class,records,"UniformOutput",false);
classes=string(classes);
planes=cellfun(@(r) ~isfield(r,"s") && isfield(r,"data") && string(r.query.quantity)~="vector",records);
for key=keys
    selected=records(planes & classes==key);
    if isfield(requested,key) && ~isempty(requested.(key))
        limits=requested.(key);
        validateattributes(limits,{'numeric'},{'real','finite','vector','numel',2});
        limits=limits(:).';
        if limits(2)<=limits(1), error("MSBS:ColourLimits","Colour limits must increase."); end
    elseif startsWith(key,"gradient") && ~isempty(selected)
        [limits,report]=gradient_colour_limits(selected,percentile);
        style.gradientColorLimitReports.(key)=report;
        fprintf("%s display cap: +/-%.6g T/m, percentile %g; %.3g%% saturated. Raw data unchanged.\n", ...
            key,report.threshold,report.percentile,100*report.saturatedFraction);
    else
        peak=0;
        for r=selected
            values=abs(r{1}.data); values=values(isfinite(values));
            if ~isempty(values), peak=max(peak,max(values)); end
        end
        if peak<=0, peak=1; end
        limits=[-peak peak];
    end
    style.clim.(key)=limits;
end
end
