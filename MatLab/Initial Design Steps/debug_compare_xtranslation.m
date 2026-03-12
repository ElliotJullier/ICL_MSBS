clear
close all

addpath("functs")

%% ------------------------- Inputs -------------------------
filename = "coilfield_run13.mat";   % choose one case to inspect
I = 30;                             % overwrite current
dir = "x";                          % "x", "y", or "z"
planeName = "xy";                   % "xy", "xz", or "yz"
planeValue = 0;                     % e.g. y=0 for xz, z=0 for xy, x=0 for yz

%% ------------------------- Load -------------------------
S = load(filename);
field = S.field;

%% ------------------------- Build combined field -------------------------
% Single coil debug
mag_field = field.mag_field_unit(:,:,1) * I;

%% ------------------------- Build interpolants -------------------------
F = build_percoil_interpolants(field);

%% ------------------------- Select component -------------------------
switch dir
    case "x"
        comp = 1;
        Fi = F.Bx{1};
    case "y"
        comp = 2;
        Fi = F.By{1};
    case "z"
        comp = 3;
        Fi = F.Bz{1};
    otherwise
        error('dir must be "x", "y", or "z".')
end

%% ------------------------- Reshape raw field -------------------------
Ny = numel(field.y);
Nx = numel(field.x);
Nz = numel(field.z);

B = reshape(mag_field(comp,:), [Ny, Nx, Nz]);

%% ------------------------- Compare direct slice vs interpolated slice -------------------------
switch planeName

    case "xz"
        % y = planeValue
        [~, iy] = min(abs(field.y - planeValue));

        % Direct slice
        B_direct = squeeze(B(iy,:,:));             % [Nx,Nz] after squeeze
        X_direct = squeeze(field.X(iy,:,:));
        Z_direct = squeeze(field.Z(iy,:,:));

        % Interpolated on exactly the same coordinates
        Yq = planeValue * ones(size(X_direct));
        B_interp = I*Fi(Yq, X_direct, Z_direct);

        xplot = X_direct;
        yplot = Z_direct;
        ylab = 'z [m]';

    case "xy"
        % z = planeValue
        [~, iz] = min(abs(field.z - planeValue));

        % Direct slice
        B_direct = squeeze(B(:,:,iz));             % [Ny,Nx]
        X_direct = squeeze(field.X(:,:,iz));
        Y_direct = squeeze(field.Y(:,:,iz));

        % Interpolated on exactly the same coordinates
        B_interp = I*Fi(Y_direct, X_direct, planeValue * ones(size(X_direct)));

        xplot = X_direct;
        yplot = Y_direct;
        ylab = 'y [m]';

    case "yz"
        % x = planeValue
        [~, ix] = min(abs(field.x - planeValue));

        % Direct slice
        B_direct = squeeze(B(:,ix,:));             % [Ny,Nz]
        Y_direct = squeeze(field.Y(:,ix,:));
        Z_direct = squeeze(field.Z(:,ix,:));

        % Interpolated on exactly the same coordinates
        Xq = planeValue * ones(size(Y_direct));
        B_interp = I*Fi(Y_direct, Xq, Z_direct);

        xplot = Y_direct;
        yplot = Z_direct;
        ylab = 'z [m]';

    otherwise
        error('planeName must be "xy", "xz", or "yz".')
end

%% ------------------------- Common colour limits -------------------------
Bmax = max(abs([B_direct(:); B_interp(:)]), [], "omitnan");
if isempty(Bmax) || ~isfinite(Bmax) || Bmax <= 0
    Bmax = 1;
end

%% ------------------------- Plot -------------------------
figure

subplot(3,1,1)
surf(xplot, yplot, B_direct)
shading interp
view(2)
axis equal tight
title("Direct slice: B" + dir + " on " + planeName + " plane")
xlabel("x [m]")
ylabel(ylab)
clim([-Bmax Bmax])
colorbar

subplot(3,1,2)
surf(xplot, yplot, B_interp)
shading interp
view(2)
axis equal tight
title("Interpolated slice: B" + dir + " on " + planeName + " plane")
xlabel("x [m]")
ylabel(ylab)
clim([-Bmax Bmax])
colorbar

subplot(3,1,3)
surf(xplot, yplot, B_interp - B_direct)
shading interp
view(2)
axis equal tight
title("Difference (interp - direct)")
xlabel("x [m]")
ylabel(ylab)
colorbar