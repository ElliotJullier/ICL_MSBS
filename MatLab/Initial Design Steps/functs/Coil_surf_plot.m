function hSurf = Coil_surf_plot(ax, magField_indices, X, Y, Z, mag_field, output_dims, dir)
% This function takes a full 3D field + mask and plots the chosen component
% on a masked plane using a surface plot.
%
% ----- INPUTS -----
% ax: axes handle to plot into
% magField_indices: logical mask indices (vector) for valid points
% X, Y, Z: meshgrids corresponding to the plane (may be 3D before squeeze)
% mag_field: 3xN array of magnetic field components
% output_dims: dimensions used to reshape indices/field back to grid form
% dir: "x", "y", or "z" selecting the B-field component to plot
%
% ----- OUTPUTS -----
% hSurf: handle to the plotted surface object

% Turn the (x; y; z) list of coords into meshgrid format
deshaped_magField_indices = reshape(magField_indices, output_dims);

% Reshaping the X, Y, Z meshgrids to have right indices and be a matrix
% (not 3D array)
X_masked = X;
X_masked(~deshaped_magField_indices) = NaN;
X_masked = squeeze(X_masked);

Y_masked = Y;
Y_masked(~deshaped_magField_indices) = NaN;
Y_masked = squeeze(Y_masked);

Z_masked = Z;
Z_masked(~deshaped_magField_indices) = NaN;
Z_masked = squeeze(Z_masked);

% Extract required component of B field that corresponds to the correct
% masking indices
dir = string(dir);
idx = find(dir == ["x","y","z"], 1);

if isempty(idx)
    error('dir must be "x", "y", or "z".');
end

B_field = reshape(mag_field(idx, :), output_dims);
B_field(~deshaped_magField_indices) = NaN;
B_field = squeeze(B_field);

% Plotting (direct the plot into the provided axes)
hold(ax, 'on');
hSurf = surf(ax, X_masked, Y_masked, Z_masked, B_field, 'EdgeColor','none');

% Colorbar + label
clrb = colorbar(ax);
clrb.Label.String = append("$B_", dir, "$ [T]");
clrb.Label.Interpreter = 'latex';

% Symmetric color limits (robust to all-NaN)
Bmax = max(abs(B_field), [], "all", "omitnan");
if isempty(Bmax) || isnan(Bmax)
    Bmax = 0;
end
clim(ax, [-Bmax, Bmax]);

end

