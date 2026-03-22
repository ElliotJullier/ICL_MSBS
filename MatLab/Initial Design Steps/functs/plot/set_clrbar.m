function clrb = set_clrbar(ax, clim_lims, refComponent)
clrb = colorbar(ax);
clrb.Label.String = append("$B_", string(refComponent), "$ [T]");
clrb.Label.Interpreter = 'latex';

clrmap_range = [0 0 1; 0.8 0.8 0.8; 1 0 0];
clrmap = def_clrmap(clrmap_range);
colormap(ax, clrmap);

clim(ax, clim_lims);
end
