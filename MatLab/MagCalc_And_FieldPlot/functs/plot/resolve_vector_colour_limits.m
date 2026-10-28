function limits = resolve_vector_colour_limits(records,style)
%RESOLVE_VECTOR_COLOUR_LIMITS Independent nonnegative vector magnitude scales.
% Full/projected and ordinary/difference quantities never pool with scalars.
limits=struct(); data=struct(); manual=struct(); scales=struct();
for record=records
    d=vector_display_data(record{1},style); opts=d.options; key=d.key;
    if string(opts.ColorBy)=="none", continue; end
    if isfield(scales,key) && scales.(key)~=string(opts.ColorScale)
        error("MSBS:VectorColourScale","Use the same linear/log mapping for comparable vector quantities within one run.");
    end
    scales.(key)=string(opts.ColorScale);
    if ~isfield(data,key), data.(key)=[]; end
    values=d.colour(d.eligible); data.(key)=[data.(key);values(:)];
    if ~isempty(opts.ColorLimits)
        if isfield(manual,key) && ~isequal(manual.(key),opts.ColorLimits)
            error("MSBS:VectorColourScale","Conflicting ColorLimits for vector class %s.",key);
        end
        manual.(key)=opts.ColorLimits;
    end
end
for key=string(fieldnames(data)).'
    values=data.(key); values=values(isfinite(values));
    if isfield(manual,key)
        range=manual.(key);
    elseif isempty(values)
        range=[0 1]; if scales.(key)=="log", range=[1e-12 1]; end
    elseif scales.(key)=="log"
        positive=values(values>0);
        range=[min(positive),max(positive)];
        if range(2)<=range(1), range=range(1)*[.5 2]; end
    else
        peak=max(values); if peak<=0, peak=1; end
        range=[0 peak];
    end
    if range(1)<0 || (scales.(key)=="log" && range(1)<=0)
        error("MSBS:VectorColourScale","Vector magnitudes need nonnegative limits, strictly positive for a log scale.");
    end
    limits.(key)=range;
end
end
