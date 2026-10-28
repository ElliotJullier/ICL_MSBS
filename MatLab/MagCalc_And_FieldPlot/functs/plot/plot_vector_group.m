function plot_vector_group(group,style)
%PLOT_VECTOR_GROUP Uncluttered projected/full-vector plots from cached Q.
if numel(group.requests)~=1
    error("MSBS:VectorOverlay","Use separate vector groups for different cases/planes; overlapping arrow sets are ambiguous. Plot a virtual difference to compare vector changes.");
end
r=group.requests{1}; d=vector_display_data(r,style); opts=d.options;
indices=select_vector_seeds(r,d);
[~,qbase]=fileparts(string(style.Q_file)); if strlength(qbase)==0, qbase="Q output"; end
label="Vector "+string(opts.Mode)+": "+string(r.caseName);
if strlength(string(r.queryName))>0, label=label+" - "+r.queryName; end
fig=figure("Name",char(label+" - "+qbase),"NumberTitle","off");
layout=tiledlayout(fig,1,1,"TileSpacing","compact","Padding","compact");
ax=nexttile(layout); hold(ax,"on"); axis(ax,"equal"); box(ax,"on"); grid(ax,"on");
if opts.ShowGeometry
    if isfield(r,"synthetic") && isfield(r.synthetic,"coilGeometrySources")
        sources=r.synthetic.coilGeometrySources; geometries={sources.geometry};
    else
        geometries={r.geometry};
    end
    seen={};
    for geometry=geometries
        components=geometry_components(geometry{1});
        if any(cellfun(@(a)isequaln(a,components),seen)), continue; end
        seen{end+1}=components; %#ok<AGROW>
        g=struct("components",components);
        if d.projected
            for j=1:numel(components)
                components(j).shape.Vertices=(components(j).shape.Vertices-r.planePoint)*r.basis;
            end
            g.components=components;
            section=struct("type","fundamental_plane","plane","xy","planeOffset",0);
            plot_geometry_sections(ax,g,section,style.geometryAlpha);
        else
            plot_component_geometry(ax,g,style.geometryAlpha);
        end
    end
end
if isempty(indices)
    warning("MSBS:VectorEmpty","No valid nonzero vector arrows in '%s' after coverage/material/projection filtering.",r.queryName);
    referenceLength=0; lengthReference=NaN;
else
    P=d.positions(indices,:); V=d.vectors(indices,:); mag=d.magnitude(indices);
    if numel(indices)>1
        distance=Inf(numel(indices),1);
        for j=1:numel(indices)
            delta=sum((P-P(j,:)).^2,2); delta(j)=Inf; distance(j)=sqrt(min(delta));
        end
        spacing=min(distance);
    else
        span=max(d.positions)-min(d.positions); spacing=max(span)/5;
    end
    referenceLength=opts.ArrowFraction*spacing;
    sorted=sort(mag); lengthReference=sorted(max(1,ceil(.99*numel(sorted))));
    factor=ones(size(mag));
    if string(opts.LengthMode)=="linear", factor=min(mag/lengthReference,1); end
    if string(opts.LengthMode)=="sqrt", factor=sqrt(min(mag/lengthReference,1)); end
    arrows=V./mag.*(referenceLength*factor);
    if string(opts.ColorBy)=="magnitude"
        range=style.vectorColourLimits.(d.key); colors=vector_magnitude_colormap(32);
        value=d.colour(indices);
        if string(opts.ColorScale)=="log"
            fraction=(log10(value)-log10(range(1)))/diff(log10(range));
        else
            fraction=(value-range(1))/diff(range);
        end
        bins=1+floor(31*max(0,min(1,fraction)));
    else
        colors=[.055 .12 .26]; bins=ones(size(mag));
    end
    for bin=unique(bins).'
        select=bins==bin;
        if d.projected
            quiver(ax,P(select,1),P(select,2),arrows(select,1),arrows(select,2),0, ...
                "Color",colors(bin,:),"LineWidth",opts.LineWidth,"MaxHeadSize",.55, ...
                "HandleVisibility","off","Tag","MSBSVectorArrows");
        else
            quiver3(ax,P(select,1),P(select,2),P(select,3),arrows(select,1),arrows(select,2),arrows(select,3),0, ...
                "Color",colors(bin,:),"LineWidth",opts.LineWidth,"MaxHeadSize",.55, ...
                "HandleVisibility","off","Tag","MSBSVectorArrows");
        end
    end
end
if string(opts.ColorBy)=="magnitude"
    colormap(ax,vector_magnitude_colormap(32)); clim(ax,style.vectorColourLimits.(d.key));
    ax.ColorScale=string(opts.ColorScale);
    bar=colorbar(ax); bar.Label.Interpreter="latex"; bar.Label.String=d.colourLabel;
    setappdata(bar,"MSBSBaseFonts",[bar.FontSize,bar.Label.FontSize]);
end
if d.projected
    view(ax,2);
    xlabel(ax,plane_axis_label(r.basis(:,1),r.planePoint,"u"),"Interpreter","latex");
    ylabel(ax,plane_axis_label(r.basis(:,2),r.planePoint,"v"),"Interpreter","latex");
    xlim(ax,[min(r.U),max(r.U)]); ylim(ax,[min(r.V),max(r.V)]);
else
    view(ax,3); axis(ax,"vis3d");
    xlabel(ax,"$x$ [m]","Interpreter","latex"); ylabel(ax,"$y$ [m]","Interpreter","latex");
    zlabel(ax,"$z$ [m]","Interpreter","latex"); camproj(ax,"orthographic");
    for edge=r.roiEdges.'
        vertices=r.roiVertices(edge,:);
        plot3(ax,vertices(:,1),vertices(:,2),vertices(:,3),"Color",[.65 .65 .65], ...
            "LineWidth",.7,"HandleVisibility","off","Tag","MSBSVectorROI");
    end
    low=min(r.roiVertices); high=max(r.roiVertices);
    if r.query.type=="vector_plane" && opts.ShowGeometry
        % A plane is a sampling surface, not an artificial thin 3D solid.
        % Preserve the full assembly context for a 3D plane view.
        for geometry=geometries
            for c=geometry_components(geometry{1})
                low=min(low,min(c.shape.Vertices)); high=max(high,max(c.shape.Vertices));
            end
        end
    end
    pad=max(referenceLength,.03*max(high-low));
    xlim(ax,[low(1)-pad high(1)+pad]); ylim(ax,[low(2)-pad high(2)+pad]);
    zlim(ax,[low(3)-pad high(3)+pad]);
end
proxies=findobj(ax,"-regexp","Tag","^MSBSGeometryLegend_");
if ~isempty(proxies)
    lg=legend(ax,"show","Orientation","horizontal","Interpreter","none");
    lg.Layout.Tile="south"; % Reserve space below 3D axis labels during export.
end
report=struct("mode",string(opts.Mode),"seeding",string(opts.Seeding), ...
    "arrowCount",numel(indices),"candidateCount",size(r.B,1),"lengthMode",string(opts.LengthMode), ...
    "glyphReferenceLength_m",referenceLength,"fieldLengthReference_T",lengthReference, ...
    "colourClass",d.key,"colourMagnitude",string(opts.ColorMagnitude), ...
    "colourMapping",string(opts.ColorScale),"materialSeedsExcluded",logical(opts.ExcludeMaterials));
report.materialMaskComponents=r.materialMaskComponents;
if d.projected
    fractions=abs(r.normalComponent)./r.magnitude;
    fractions=fractions(r.valid & r.magnitude>0 & ~r.inMaterial);
    if isempty(fractions), normalFraction=NaN; else, normalFraction=median(fractions); end
    report.medianNormalComponentFraction=normalFraction;
    report.planePoint=r.planePoint; report.basisU=r.basis(:,1).'; report.basisV=r.basis(:,2).';
    fprintf("2D projection: normal component omitted (median |Bn|/|B|=%.3g); full B and Bn remain in Q.\n",normalFraction);
end
if string(opts.ColorBy)=="magnitude"
    report.colourLimits=style.vectorColourLimits.(d.key);
    style.colourScaleClass=d.key; style.colourScaleLimits=report.colourLimits;
    setappdata(fig,"MSBSColourScaleClass",d.key);
    setappdata(fig,"MSBSColourScaleLimits",report.colourLimits);
end
setappdata(fig,"MSBSVectorDisplay",report); setappdata(fig,"MSBSVectorSeedIndices",indices);
style.vectorDisplayReport=report;
apply_scientific_plot_style(ax,style);
write_plot_metadata_file(string(fig.Name),{r},style);
fprintf("Vector plot '%s': %d/%d arrows; %s seeding; %s lengths; %s mode.\n", ...
    r.queryName,numel(indices),size(r.B,1),string(opts.Seeding),string(opts.LengthMode),string(opts.Mode));
if style.showOrientationReadout && ~d.projected, attach_view_report_callback(ax); end
end

function label=plane_axis_label(direction,origin,fallback)
names=["x","y","z"]; [value,index]=max(abs(direction));
if abs(value-1)<1e-10 && abs(origin(index))<1e-12
    sign=""; if direction(index)<0, sign="-"; end
    label="$"+sign+names(index)+"$ [m]";
else
    label="$"+fallback+"$ [m]";
end
end
