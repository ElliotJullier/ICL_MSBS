function clrb = set_clrbar(ax, clim_lims, dataName)
clrb = colorbar(ax);
clrb.Label.Interpreter = 'latex';
clrb.Label.String = field_quantity_label(dataName);
setappdata(clrb,"MSBSBaseFonts",[clrb.FontSize clrb.Label.FontSize]);

clrmap_range = [0 0 1; 0.8 0.8 0.8; 1 0 0];
clrmap = create_colormap_from_colour_stops(clrmap_range);
colormap(ax, clrmap);

clim(ax, clim_lims);
end
