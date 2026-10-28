function display = vector_display_data(record,style)
%VECTOR_DISPLAY_DATA Replot-safe vector projection/appearance and validity.
opts=record.query.vector;
if isfield(style,"vector") && ~isempty(style.vector)
    overrides=style.vector; allowed=["Mode","MaxArrows","Seeding","UniformFraction", ...
        "LengthMode","ColorBy","ColorMagnitude","ColorScale","ColorLimits", ...
        "MinMagnitude","ArrowFraction","ExcludeMaterials","LineWidth","ShowGeometry"];
    for name=string(fieldnames(overrides)).'
        if ~any(name==allowed), error("MSBS:VectorRequery","%s changes sampling; set it in the vector query and rerun.",name); end
        opts.(name)=overrides.(name);
    end
end
domain="plane"; if record.query.type=="vector_volume", domain="volume"; end
args=reshape([fieldnames(opts).';struct2cell(opts).'],1,[]);
opts=vector_query_options(domain,args{:});
projected=domain=="plane" && string(opts.Mode)=="2d";
if projected
    positions=[record.U,record.V,zeros(size(record.U))];
    vectors=[record.basisComponents(:,1:2),zeros(size(record.U))];
else
    positions=record.points; vectors=record.B;
end
magnitude=vecnorm(vectors,2,2);
cutoff=max(opts.MinMagnitude,1e-12*max(record.magnitude,[],"omitnan"));
eligible=record.valid & magnitude>cutoff;
if opts.ExcludeMaterials, eligible=eligible & ~record.inMaterial; end
colour=magnitude; colourLabel="$|B|$ [T]"; metric="Full";
if projected && string(opts.ColorMagnitude)=="display"
    colourLabel="$|B_{\parallel}|$ [T]"; metric="Projected";
else
    colour=record.magnitude;
end
if string(opts.ColorScale)=="log", eligible=eligible & colour>0; end
key="vector"+metric;
baseClass=plot_colour_scale_class(record);
if endsWith(baseClass,"Difference"), key=key+"Difference"; end
if endsWith(baseClass,"Difference")
    colourLabel=replace(colourLabel,"B",string(char(92))+"Delta B");
end
display=struct("positions",positions,"vectors",vectors,"magnitude",magnitude, ...
    "colour",colour,"colourLabel",colourLabel,"eligible",eligible,"projected",projected, ...
    "key",key,"options",opts);
display.variation=record.variation;
if projected, display.variation=record.projectedVariation; end
end
