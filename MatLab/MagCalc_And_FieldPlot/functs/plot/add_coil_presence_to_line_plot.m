function h = add_coil_presence_to_line_plot(ax,lineReq,geometry,unusedColor,alpha,showBores)
%ADD_COIL_PRESENCE_TO_LINE_PLOT Full-height material bands, hatched coil bores.
% Native xregion stays full height after zoom/ylim changes and behind traces.
if nargin<5, alpha=[]; end
if nargin<6, showBores=true; end
h=gobjects(0);
if ~isfield(lineReq,"s") || numel(lineReq.s)<2, return; end
p0=[lineReq.X(1),lineReq.Y(1),lineReq.Z(1)];
p1=[lineReq.X(end),lineReq.Y(end),lineReq.Z(end)]; L=norm(p1-p0);
for c=geometry_components(geometry)
    if ~c.closed
        warning("MSBS:OpenMesh","Cannot determine material intervals for '%s'; cleanup did not yield a closed surface.",c.name); continue
    end
    spans=mesh_line_intervals(c.shape,p0,p1);
    opacity=c.alpha; if ~isempty(alpha), opacity=alpha; end
    [color,~]=component_plot_style(c);
    for j=1:size(spans,1)
        x=plot_interval(spans(j,:));
        if existing_band("MSBSMaterialBand",x,c.role), continue; end
        h(end+1)=xregion(ax,x(1),x(2),"FaceColor",color,"FaceAlpha",opacity, ...
            "EdgeColor","none","Layer","bottom","HandleVisibility","off", ...
            "Tag","MSBSMaterialBand","UserData",struct("role",c.role,"material",true)); %#ok<AGROW>
        draw_material_boundaries(ax,x,color);
    end
    if ~isempty(spans), register_geometry_legend(ax,c,opacity); end
    if showBores && string(c.role)=="coil"
        bore=coil_bore_geometry(c.shape);
        if ~isempty(bore)
            boreSpans=mesh_line_intervals(bore,p0,p1);
            for j=1:size(boreSpans,1)
                x=sort(plot_interval(boreSpans(j,:)));
                if existing_band("MSBSBoreBand",x,"coil"), continue; end
                xregion(ax,x(1),x(2),"FaceColor",color,"FaceAlpha",.08, ...
                    "EdgeColor","none","Layer","bottom","HandleVisibility","off", ...
                    "Tag","MSBSBoreBand","UserData",struct("material",false,"role","coil"));
                draw_bore_hatching(ax,x,color);
                draw_material_boundaries(ax,x,color);
            end
            if ~isempty(boreSpans)
                tag="MSBSGeometryLegend_bore";
                if isempty(findobj(ax,"Tag",tag))
                    patch(ax,NaN,NaN,color,"FaceAlpha",.08,"EdgeColor",color, ...
                        "LineStyle",":","DisplayName","Coil bore (not winding)", ...
                        "Tag",tag,"HitTest","off");
                end
            end
        end
    end
end
    function found=existing_band(tag,span,role)
        found=false;
        for region=findall(ax,"Tag",tag).'
            info=region.UserData;
            if isstruct(info) && isfield(info,"role") && string(info.role)==string(role) && ...
                    max(abs(sort(region.Value(:))-sort(span(:))))<1e-10*max(1,max(abs(span)))
                found=true; return
            end
        end
    end
    function x=plot_interval(span)
        if isfield(lineReq,"plotCoordinates")
            values=lineReq.plotCoordinates;
            x=values(1)+span/L*(values(end)-values(1));
        else
            x=span+lineReq.s(1);
        end
    end
end
