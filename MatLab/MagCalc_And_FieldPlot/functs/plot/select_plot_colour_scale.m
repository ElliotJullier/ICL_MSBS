function selected = select_plot_colour_scale(style,records)
%SELECT_PLOT_COLOUR_SCALE Resolve one axes/overview from precomputed classes.
keys=string(cellfun(@plot_colour_scale_class,records,"UniformOutput",false));
if isempty(keys), selected=style; return; end
if any(keys~=keys(1))
    error("MSBS:MixedColourScales","Ordinary and difference quantities cannot share one coloured axes. Use separate plot groups.");
end
key=keys(1); selected=style;
selected.colourScaleClass=key;
selected.colourScaleLimits=style.clim.(key);
if startsWith(key,"gradient")
    selected.clim.gradient=style.clim.(key);
else
    selected.clim.field=style.clim.(key);
end
if isfield(selected,"gradientColorLimitReport"), selected=rmfield(selected,"gradientColorLimitReport"); end
if isfield(style,"gradientColorLimitReports") && isfield(style.gradientColorLimitReports,key)
    selected.gradientColorLimitReport=style.gradientColorLimitReports.(key);
end
end
