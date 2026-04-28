function output_grid = coord_global2local(input_grid, relative_position)
% Elliot Jullier, 27/04/2026
% This function applies a 3D translation of coordinate system then a
% aerospace standard pitch-roll-yaw Euler rotations from a basis frame of reference (FoR) (see Wikipedia
% Davenport chained rotations - section Tait-Bryan chained rotations, see
% also Wikipedia Rotation formalisms in three dimensions - section Euler
% angles (z-y'-x'' intrinsic) -> rotation matrix. See also https://codesignal.com/learn/courses/3d-worlds-and-matrix-transformations/lessons/translation-and-rotation-matrices
%
% ----- INPUTS -----
% input_grid: An 3xN array of 3D coordinates that need translate + rotating
% relative_position a 1x6 array containing the following (in order):
% x_trans [m]: x-direction in m by which the new coordinate system in
% translated compared to the 'global' FoR
% y_trans [m]: ident, in y dir
% z_trans [m]: ident, in z dir
%
% (Rotation assumes going from ground FoR to plane FoR)
% rotations in radians
% yaw [rad]: intrinsic rotation around original FoR z-axis
% pitch [rad]: intrinsic rotation around new y-axis (after yaw rotation)
% roll [rad]: instrinsic rotation around new x-axis (after yaw and pitch
% rotations)

x_trans = -relative_position(1);
y_trans = -relative_position(2);
z_trans = -relative_position(3);
yaw     = -relative_position(4);
pitch   = -relative_position(5);
roll    = -relative_position(6);

% negative of translations taken since FoR translation as input
% Eg. a coord of (1, 1) in global
% New FoR is translated by (0.25, 0.25) relative to global
% Output coord should (obviously) be (0.75, 0.75)
translation_matrix = [x_trans; y_trans; z_trans];
rotation_matrix = [cos(pitch)*cos(yaw), -cos(roll)*sin(yaw)+sin(roll)*sin(pitch)*cos(yaw), sin(roll)*sin(yaw)+cos(roll)*sin(pitch)*cos(yaw);
    cos(pitch)*sin(yaw), cos(roll)*cos(yaw)+sin(roll)*sin(pitch)*sin(yaw), -sin(roll)*cos(yaw)+cos(roll)*sin(pitch)*sin(yaw);
    -sin(pitch), sin(roll)*cos(pitch), cos(roll)*cos(pitch)];
output_grid = zeros(3, length(input_grid));
for i = 1:length(input_grid)
    % Rotation+ Transformation matrix is 4x4, whereas the input is 3x1, we
    % add a 1 at the botton of the input to allow the translations to take
    % effect
    output_grid(:, i) = rotation_matrix*(input_grid(:, i)+translation_matrix); 
end

