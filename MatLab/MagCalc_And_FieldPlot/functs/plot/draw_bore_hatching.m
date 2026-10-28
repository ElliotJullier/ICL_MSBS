function group = draw_bore_hatching(ax,span,color)
%DRAW_BORE_HATCHING Diagonal bore marks that follow changing y-limits.
group=hggroup("Parent",ax,"HandleVisibility","off","Tag","MSBSBoreHatch");
lines=gobjects(0); offsets=-.8:.2:.8;
for offset=offsets
    a=max(0,-offset); b=min(1,1-offset);
    lines(end+1)=line("XData",NaN,"YData",NaN,"Color",.5*color+.5,"LineWidth",.6, ...
        "Parent",group,"HandleVisibility","off","HitTest","off"); %#ok<AGROW>
    setappdata(lines(end),"unitPoints",[a b;a+offset b+offset]);
end
busy=false;
refresh();
listener=addlistener(ax,"YLim","PostSet",@(~,~)refresh());
setappdata(group,"YLimListener",listener);
    function refresh()
        if busy || ~isgraphics(group) || ~isgraphics(ax), return; end
        busy=true; finish=onCleanup(@release); %#ok<NASGU>
        limits=ax.YLim;
        for h=lines
            uv=getappdata(h,"unitPoints");
            h.XData=span(1)+uv(1,:)*diff(span);
            h.YData=limits(1)+uv(2,:)*diff(limits);
        end
    end
    function release(), busy=false; end
end
