clear
close all;

addpath(genpath("functs"));

% ----------------------------------------------------------------------------
% ------------------------- START OF USER INPUT ------------------------------
% ----------------------------------------------------------------------------

saveFileName = "MorganSetup_FullBS.mat";

% ------------ Coil Parameter specifications ------------
wire_outer_radius = 5/1000;
wire_inner_radius = 0;

coil_outer_radius = (95)/2000;
coil_inner_radius = (36)/2000;
coil_turns = 300;
coil_height = 60/1000;

geometry = struct();
geometry.windTunnel = [ ...
    -75/1000,  75/1000; ...
    -75/1000,  75/1000; ...
   -125/1000, 125/1000];

% ------------ Coil Type Definition ------------

% Different "types" of coils may be used, with each category used multiple
% times. So far types are axial, vert (vertical) and horiz (horizontal).
% Using Tohoku MSBS convention:
%   Axial - Coils 0 and 9
%   Vert  - Coils 1 & 3 (front) and 5 & 7 (rear)
%   Horiz - Coils 2 & 4 (front) and 6 & 8 (rear)
%
% These can have different property values. Only one type of coil is
% currently defined, probably no need for these variables in future.

geometry.coilSpec.benchtop = struct( ...
    "outerRadius", coil_outer_radius, ...
    "innerRadius", coil_inner_radius, ...
    "height", coil_height, ...
    "turns", coil_turns, ...
    "wireOuterRadius", wire_outer_radius, ...
    "wireInnerRadius", wire_inner_radius);

geometry.coilSpec.axial = struct( ...
    "outerRadius", coil_outer_radius, ...
    "innerRadius", coil_inner_radius, ...
    "height", coil_height, ...
    "turns", coil_turns, ...
    "wireOuterRadius", wire_outer_radius, ...
    "wireInnerRadius", wire_inner_radius);

geometry.coilSpec.vert = struct( ...
    "outerRadius", coil_outer_radius, ...
    "innerRadius", coil_inner_radius, ...
    "height", coil_height, ...
    "turns", coil_turns, ...
    "wireOuterRadius", wire_outer_radius, ...
    "wireInnerRadius", wire_inner_radius);

geometry.coilSpec.horiz = struct( ...
    "outerRadius", coil_outer_radius, ...
    "innerRadius", coil_inner_radius, ...
    "height", coil_height, ...
    "turns", coil_turns, ...
    "wireOuterRadius", wire_outer_radius, ...
    "wireInnerRadius", wire_inner_radius);

% ------------------------- Physical coil instances -------------------------
%
% pose = [x y z yaw pitch roll], SI units and radians.
%
% Coil axis convention:
%   Coil_Field defines the coil as an annular cylinder whose local axis is
%   the local z-axis. 
%   
%   Coils are centered around local origin, ie. lifting a coil with 50mm
%   height by 100mm causes the bottom edge to be 75mm from global origin
%   and coil centre 100mm above origin
%
%   For rotations:
%
%       pose rotation [0, 0, 0]        -> coil axis along global +z
%       pose rotation [0, -pi/2, 0]    -> coil axis along global +x
%       pose rotation [0,  pi/2, 0]    -> coil axis along global -x
%       pose rotation [0, 0,  pi/2]    -> coil axis along global +y
%       pose rotation [0, 0, -pi/2]    -> coil axis along global -y
%
% Yaw alone leaves a z-axis coil pointing along z; it only rotates the coil
% about its own axis. For these axis-alignment cases, use one nonzero angle
% and leave the other two as zero for clarity.
%
% The coil positions do not have to be inside the computation domain.

% Total number of coils to use.
num_coils = 2;

% Do not modify following line
geometry.coil = repmat(struct("coilName", "", "coilType", "", "pose", zeros(1,6), "shape", []), num_coils, 1);
% Modify from here

geometry.coil(1).coilName = "Coil 1";
geometry.coil(1).coilType = "benchtop";
geometry.coil(1).pose = [0, 0,  90/1000, 0, 0, 0];

geometry.coil(2).coilName = "Coil 2";
geometry.coil(2).coilType = "benchtop";
geometry.coil(2).pose = [0, 0,  -90/1000, 0, 0, 0];


% ----------------------------------------------------------------------------
% ------------------------- END OF USER INPUT --------------------------------
% ----------------------------------------------------------------------------

% ------------------------- Field grid -------------------------
grid = struct();
grid.x = linspace(geometry.windTunnel(1,1), geometry.windTunnel(1,2), 100);
grid.y = linspace(geometry.windTunnel(2,1), geometry.windTunnel(2,2), 100);
grid.z = linspace(geometry.windTunnel(3,1), geometry.windTunnel(3,2), 200);

[X, Y, Z] = meshgrid(grid.x, grid.y, grid.z);
output_coord_list = [reshape(X, 1, []); reshape(Y, 1, []); reshape(Z, 1, [])];

Ny = numel(grid.y);
Nx = numel(grid.x);
Nz = numel(grid.z);

% B(y,x,z,component,coil), component 1/2/3 = x/y/z.
% For this MATLAB Biot-Savart dataset, B is field per ampere of coil current.
B = zeros(Ny, Nx, Nz, 3, num_coils);

for k = 1:num_coils
    coilType = string(geometry.coil(k).coilType);
    spec = geometry.coilSpec.(coilType);

    % --------- Calculate Magnetic Field ---------
    local_output_field = coord_global2local(output_coord_list, geometry.coil(k).pose);

    local_mag_field = Coil_Field( ...
        spec, local_output_field, ...
        "nRadial", 10, "nAxial", 10, "nTheta", 40, ...
        "progress", true, "progressStepPercent", 5, "blockSize", 50000);

    % Rotate Bx, By and Bz to align with global directions instead of the
    % local coil axes. Do not translate because these are vector components,
    % not coordinates.
    global_mag_field = coord_local2global(local_mag_field, [0, 0, 0, geometry.coil(k).pose(4:6)]);

    % Coil_Field returns a 3xNpoints list. Store each component explicitly
    % on the [y,x,z] grid to avoid hidden transpose/reshape conventions.
    for c = 1:3
        B(:,:,:,c,k) = reshape(global_mag_field(c,:), [Ny, Nx, Nz]);
    end

    fprintf("[%s] Coil %d/%d finished\n", datestr(now,"HH:MM:SS"), k, num_coils);

    % --------- Calculate plotting shape ---------
    geometry.coil(k).shape = extract_coilShape(spec, geometry.coil(k).pose);
end

dataset = pack_field_dataset( ...
    "matlab_full_biotsavart", geometry, grid, B, ...
    "saveFile", saveFileName, ...
    "supportsSuperposition", true, ...
    "supportsCurrentSolve", true);

if ~endsWith(string(saveFileName), ".mat")
    saveFileName = string(saveFileName) + ".mat";
end
dataset.saveFile = string(saveFileName);

save(saveFileName, "dataset", "-v7.3");
fprintf("Saved field dataset: %s\n", saveFileName);
