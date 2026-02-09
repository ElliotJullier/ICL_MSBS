function fig_output = Coil_surf_plot(magField_indices, X, Y, Z, mag_field, output_dims, dir)

% Turn the (x; y; z) list of coords into meshgrid format
deshaped_magField_indices = reshape(magField_indices, output_dims);

% Reshaping the X, Y, Z  meshgrids to have right indices and be a matrix
% (not 3D array)
X_masked=X;
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
if dir == "x"
    B_field = reshape(mag_field(1, :), output_dims);
    B_field(~deshaped_magField_indices) = NaN;
    B_field = squeeze(B_field);
elseif dir == "y"
    B_field = reshape(mag_field(2, :), output_dims);
    B_field(~deshaped_magField_indices) = NaN;
    B_field = squeeze(B_field);
elseif dir == "z"
    B_field = reshape(mag_field(3, :), output_dims);
    B_field(~deshaped_magField_indices) = NaN;
    B_field = squeeze(B_field);
else
end

% Plotting

fig_output = surf(X_masked, Y_masked, Z_masked, B_field, 'EdgeColor','none');
clrb = colorbar;
% Define colourmap
%clrm = [repmat([0 0], [10, 1]), linspace(1, 0, 10)'; repmat()]; % can
%define custom colourmaps to match COMSOL or smt
clrb.Label.String = "$B_Z$ [T]";
clrb.Label.Interpreter = 'latex';
clim([-max(abs(B_field), [], "all"), max(abs(B_field), [], "all")]);
