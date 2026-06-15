function clrb = set_clrbar(ax, clim_lims, dataName)
clrb = colorbar(ax);
clrb.Label.String = latex_data_label(dataName);
clrb.Label.Interpreter = 'latex';

clrmap_range = [0 0 1; 0.8 0.8 0.8; 1 0 0];
clrmap = create_colormap_from_colour_stops(clrmap_range);
colormap(ax, clrmap);

clim(ax, clim_lims);
end

function lbl = latex_data_label(dataName)
dataName = string(dataName);
if startsWith(dataName, "B") && strlength(dataName) == 2
    comp = extractAfter(dataName, 1);
    lbl = "$B_" + comp + "$ [T]";
elseif startsWith(dataName, "dB")
    lbl = "$" + dataName + "$ [T/m]";
else
    lbl = dataName;
end
end
