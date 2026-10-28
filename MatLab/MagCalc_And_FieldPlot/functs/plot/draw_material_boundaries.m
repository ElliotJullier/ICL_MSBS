function draw_material_boundaries(ax,span,color)
%DRAW_MATERIAL_BOUNDARIES Solid full-height edges, without duplicate strokes.
% Native constant lines follow ylim/zoom independently of the band fills.
for value=span(:).'
    existing=findall(ax,"Tag","MSBSMaterialBoundary");
    duplicate=false;
    for h=existing.'
        if abs(h.Value-value)<=1e-10*max(1,abs(value))
            duplicate=true; break
        end
    end
    if duplicate, continue; end
    xline(ax,value,"-","Color",.55*color,"Alpha",1,"LineWidth",1.25, ...
        "HandleVisibility","off","Tag","MSBSMaterialBoundary", ...
        "HitTest","off");
end
end
