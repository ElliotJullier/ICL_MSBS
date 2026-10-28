function apply_scientific_plot_style(ax,style)
%APPLY_SCIENTIFIC_PLOT_STYLE Idempotent export defaults for axes/colorbars.
if nargin<2, style=struct(); end
scale=1.5; if isfield(style,"fontScale"), scale=style.fontScale; end
validateattributes(scale,{'numeric'},{'scalar','finite','positive'});
if ~isappdata(ax,"MSBSBaseFonts")
    setappdata(ax,"MSBSBaseFonts",[ax.FontSize,ax.XLabel.FontSize,ax.YLabel.FontSize,ax.ZLabel.FontSize]);
end
base=getappdata(ax,"MSBSBaseFonts");
fig=ancestor(ax,"figure");
bars=findall(fig,"Type","colorbar");
legends=findall(fig,"Type","legend");
for lg=legends.'
    if ~isappdata(lg,"MSBSBaseFont"), setappdata(lg,"MSBSBaseFont",lg.FontSize); end
end
for bar=bars.'
    if isequal(bar.Axes,ax) && ~isappdata(bar,"MSBSBaseFonts")
        setappdata(bar,"MSBSBaseFonts",[bar.FontSize bar.Label.FontSize]);
    end
end
ax.FontSize=scale*base(1);
labels=[ax.XLabel ax.YLabel ax.ZLabel];
for j=1:3, labels(j).FontSize=scale*base(j+1); end
% Both rulers in a yyaxis plot need the same enlarged label/tick fonts.
for j=1:numel(ax.YAxis)
    ax.YAxis(j).FontSize=scale*base(1);
    ax.YAxis(j).Label.FontSize=scale*base(3);
end
title(ax,""); % Figure Name carries provenance; exported axes have no title.
ax.Layer="top"; ax.TickDir="out"; ax.TickLength=[.015 .025]; ax.LineWidth=1;
ax.XMinorTick="on"; ax.YMinorTick="on"; ax.ZMinorTick="on";
fig.NumberTitle="off";
% The requested 50% increase applies to axes/colorbars, not legend text.
for lg=legends.', lg.FontSize=getappdata(lg,"MSBSBaseFont"); end
for bar=bars.'
    if ~isequal(bar.Axes,ax), continue; end
    if ~isappdata(bar,"MSBSBaseFonts")
        setappdata(bar,"MSBSBaseFonts",[bar.FontSize bar.Label.FontSize]);
    end
    b=getappdata(bar,"MSBSBaseFonts");
    bar.FontSize=scale*b(1); bar.Label.FontSize=scale*b(2);
    bar.TickDirection="out"; bar.LineWidth=1;
end
end
