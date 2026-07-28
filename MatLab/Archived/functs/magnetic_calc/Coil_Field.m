function mag_field = Coil_Field(coilSpec, outputField, varargin)
% Simple volume integration of the Biot-Savart law, for constant current
% (density) the field shape is dependant only only coil geometry
%
% Coil geometry assumed to be an annular cylinder with its axis along local z.
%
%  ----- INPUTS -----
% CoilSpec: A struct containing at least the following fields
%   outerRadius [m]: Outer radius of the overall coil
%   innerRadius [m]: Radius of the hole in the coil
%   height [m]: Height of the coil
%   turns [-]: Number of turns of wire in the coil
%
% outputField 3*[m]: a 3xN matrix containing the coordinates (x, y, z)
% relative to the coil CoG in metres.
%
% ----- OPTIONAL INPUTS (name-value) -----
% "progress" [logical]: print progress messages (default false)
% "progressStepPercent" [numeric]: percentage step for messages (default 5, must be between 0 and 100)
% "blockSize" [numeric]: number of output points per block (default 50000, must be a positive integer)
% "nRadial" [numeric]: radial integration cells (default 10, must be a positive integer)
% "nAxial" [numeric]: axial integration cells (default 10, must be a positive integer)
% "nTheta" [numeric]: azimuthal integration cells (default 40, must be a positive integer)
%
% ----- OUPUT(S) -----
% mag_field 3*[T]: A 3xK matrix containing (Bx, By, Bz) in Tesla, where K is the number of grid points, for a cuboid this is x_gridresolution * y_gridres * z_gridres.

% ------------------ Parse Coil Spec Input ------------------
R = coilSpec.outerRadius;
r = coilSpec.innerRadius;
h = coilSpec.height;
N = coilSpec.turns;

% ------------------------- Options -------------------------
p = inputParser;
addParameter(p, "progress", false, @(x)islogical(x) || isnumeric(x));
addParameter(p, "progressStepPercent", 5, @(x)isnumeric(x) && x>0 && x<=100);
addParameter(p, "blockSize", 50000, @(x)isnumeric(x) && x>0);
addParameter(p, "nRadial", 10, @(x)isnumeric(x) && isscalar(x) && x>0);
addParameter(p, "nAxial", 10, @(x)isnumeric(x) && isscalar(x) && x>0);
addParameter(p, "nTheta", 40, @(x)isnumeric(x) && isscalar(x) && x>0);
parse(p, varargin{:});

doProg  = logical(p.Results.progress);
stepPct = p.Results.progressStepPercent;
blkN    = round(p.Results.blockSize);
nRadial = round(p.Results.nRadial);
nAxial  = round(p.Results.nAxial);
nTheta  = round(p.Results.nTheta);

t_total = tic;


% ------------------------- Discretising coil -------------------------
theta_sweep_edge   = linspace(0, 2*pi, nTheta+1);
theta_sweep_centre = theta_sweep_edge(1:end-1) + (theta_sweep_edge(2:end)-theta_sweep_edge(1:end-1))/2;
dtheta = theta_sweep_edge(2) - theta_sweep_edge(1);

R_sweep_edge   = linspace(r, R, nRadial+1);
R_sweep_centre = R_sweep_edge(1:end-1) + (R_sweep_edge(2:end)-R_sweep_edge(1:end-1))/2;
dR = R_sweep_edge(2) - R_sweep_edge(1);

z_sweep_edge   = linspace(-h/2, h/2, nAxial+1);
z_sweep_centre = z_sweep_edge(1:end-1) + (z_sweep_edge(2:end)-z_sweep_edge(1:end-1))/2;
dz = z_sweep_edge(2) - z_sweep_edge(1);

[R_grid, theta_grid, z_grid] = meshgrid(R_sweep_centre, theta_sweep_centre, z_sweep_centre);

theta_grid = reshape(theta_grid, 1, []);
R_grid     = reshape(R_grid, 1, []);
z_grid     = reshape(z_grid, 1, []);

dV = R_grid .* dtheta .* dz .* dR;  % 1 x Nelems

coil_pos = [R_grid.*cos(theta_grid); R_grid.*sin(theta_grid); z_grid]; % 3 x Nelems

current_dir_ang = mod(theta_grid + pi/2, 2*pi);
ax = cos(current_dir_ang);   % 1 x Nelems
ay = sin(current_dir_ang);   % 1 x Nelems

% ------------------------- Output allocation -------------------------
Npts = size(outputField, 2); % Npts is how many outputs points
mag_field = zeros(3, Npts);

% ------------------------- Progress counters -------------------------
Nelems = numel(dV); % Nelems is how many elements are there in the coil discretisation
nextPrint = 0;

if doProg
    fprintf("[%s] Coil_Field: Npts=%d, Nelems=%d, blockSize=%d\n", ...
        datestr(now,"HH:MM:SS"), Npts, Nelems, blkN);
end

% ------------------------- Main integration -------------------------
% Loop over coil elements (small), update points in blocks (vectorised)
for j = 1:Nelems

    % Progress heartbeat (based on coil discretisation)
    if doProg
        pct = floor(100*j/Nelems);
        if pct >= nextPrint
            fprintf("[%s] Coil_Field: %3d%% (elem %d/%d) elapsed %.1f s\n", ...
                datestr(now,"HH:MM:SS"), pct, j, Nelems, toc(t_total));
            nextPrint = nextPrint + stepPct;
        end
    end

    % Coil element position + direction scalars
    cx = coil_pos(1,j); cy = coil_pos(2,j); cz = coil_pos(3,j);
    a_x = ax(j); a_y = ay(j);
    w = dV(j);

    % Block over output points
    for s = 1:blkN:Npts % Splits the calc into chunks of blockSize to avoid huge temporary variables (a 200x100x100 grid gives a 2MB var)
        e = min(s + blkN - 1, Npts);

        dx = outputField(1, s:e) - cx;
        dy = outputField(2, s:e) - cy;
        dzp = outputField(3, s:e) - cz;

        r2 = dx.*dx + dy.*dy + dzp.*dzp;

        % Avoid division by zero if a point is exactly on an element
        r2(r2 == 0) = eps;

        inv_r3 = 1 ./ (r2 .* sqrt(r2));

        % cross([a_x;a_y;0], [dx;dy;dz]) simplified:
        % Bx contrib:  a_y * dz
        % By contrib: -a_x * dz
        % Bz contrib:  a_x*dy - a_y*dx
        mag_field(1, s:e) = mag_field(1, s:e) + (a_y .* dzp) .* (w .* inv_r3);
        mag_field(2, s:e) = mag_field(2, s:e) + (-a_x .* dzp) .* (w .* inv_r3);
        mag_field(3, s:e) = mag_field(3, s:e) + (a_x .* dy - a_y .* dx) .* (w .* inv_r3);
    end
end

% ------------------------- Scaling -------------------------
mag_field = (4*pi*1e-7)/(4*pi)*N/(h*(R-r))*mag_field;

if doProg
    fprintf("[%s] Coil_Field finished in %.1f s\n", datestr(now,"HH:MM:SS"), toc(t_total));
end

end
