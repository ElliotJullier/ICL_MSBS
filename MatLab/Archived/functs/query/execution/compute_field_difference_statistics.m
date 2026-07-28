function stats = compute_field_difference_statistics(diffDataset, varargin)
%COMPUTE_FIELD_DIFFERENCE_STATISTICS Compute summary statistics for a difference dataset.
%
% stats = compute_field_difference_statistics(diffDataset)
%
% diffDataset should be a precomputed field-difference dataset with:
%   diffDataset.B(y,x,z,component,1)
%
% Optional name-value inputs:
%   "Mask"       logical [Ny,Nx,Nz] mask selecting points to include.
%   "Region"     struct with optional xLim, yLim, zLim fields.
%
% Reported values include max absolute error and RMS error for each
% component and for the vector norm.

p = inputParser;
addParameter(p, "Mask", [], @(x)islogical(x) || isempty(x));
addParameter(p, "Region", struct(), @(x)isstruct(x));
parse(p, varargin{:});
opts = p.Results;

if ~isfield(diffDataset, "B")
    error("diffDataset must contain diffDataset.B.");
end

B = diffDataset.B(:,:,:,:,1);
grid = diffDataset.grid;

validMask = all(isfinite(B), 4);

if ~isempty(opts.Mask)
    if ~isequal(size(opts.Mask), size(validMask))
        error("Mask must have size [Ny,Nx,Nz].");
    end
    validMask = validMask & opts.Mask;
end

if ~isempty(fieldnames(opts.Region))
    validMask = validMask & region_mask(grid, opts.Region);
end

Bx = B(:,:,:,1);
By = B(:,:,:,2);
Bz = B(:,:,:,3);
Bnorm = sqrt(Bx.^2 + By.^2 + Bz.^2);

stats = struct();
stats.createdOn = string(datetime("now", "Format", "yyyy-MM-dd HH:mm:ss"));
stats.nValidPoints = nnz(validMask);
stats.totalGridPoints = numel(validMask);
stats.validFraction = stats.nValidPoints / max(1, stats.totalGridPoints);

stats.maxAbsBx = max(abs(Bx(validMask)), [], "omitnan");
stats.maxAbsBy = max(abs(By(validMask)), [], "omitnan");
stats.maxAbsBz = max(abs(Bz(validMask)), [], "omitnan");

stats.rmsBx = rms_no_toolbox(Bx(validMask));
stats.rmsBy = rms_no_toolbox(By(validMask));
stats.rmsBz = rms_no_toolbox(Bz(validMask));

stats.maxBnorm = max(Bnorm(validMask), [], "omitnan");
stats.meanBnorm = mean(Bnorm(validMask), "omitnan");
stats.rmsBnorm = rms_no_toolbox(Bnorm(validMask));

if isfield(diffDataset, "synthetic")
    stats.synthetic = diffDataset.synthetic;
end
end

function m = region_mask(grid, region)
[X, Y, Z] = meshgrid(grid.x, grid.y, grid.z);
m = true(size(X));

if isfield(region, "xLim") && ~isempty(region.xLim)
    m = m & X >= min(region.xLim) & X <= max(region.xLim);
end
if isfield(region, "yLim") && ~isempty(region.yLim)
    m = m & Y >= min(region.yLim) & Y <= max(region.yLim);
end
if isfield(region, "zLim") && ~isempty(region.zLim)
    m = m & Z >= min(region.zLim) & Z <= max(region.zLim);
end
end

function y = rms_no_toolbox(x)
x = x(isfinite(x));
if isempty(x)
    y = NaN;
else
    y = sqrt(mean(x.^2));
end
end
