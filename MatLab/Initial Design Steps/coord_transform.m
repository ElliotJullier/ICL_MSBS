function output_grid = coord_transform(input_grid, x_trans, y_trans, z_trans, yaw, pitch, roll)
% This function applies a 3D translation of coordinate system then a
% aerospace standard pitch-roll-yaw Euler rotations from a basis frame of reference (FoR) (see Wikipedia
% Davenport chained rotations - section Tait-Bryan chained rotations, see
% also Wikipedia Rotation formalisms in three dimensions - section Euler
% angles (z-y'-x'' intrinsic) -> rotation matrix. See also https://codesignal.com/learn/courses/3d-worlds-and-matrix-transformations/lessons/translation-and-rotation-matrices
%
% ----- INPUTS -----
% input_grid: An 3xN array of 3D coordinates that need translate + rotating
% x_trans [m]: x- direction in m along the original FoR
% y_trans [m]: ident, in y dir
% z_trans [m]: ident, in z dir
%
% (Rotation assumes going from ground FoR to plane FoR)
% yaw [rad]: intrinsic rotation around original FoR z-axis
% pitch [rad]: intrinsic rotation around new y-axis (after yaw rotation)
% roll [rad]: instrinsic rotation around new x-axis (after yaw and pitch
% rotations)

transform_matrix = [cos(pitch)*cos(yaw), -cos(roll)*sin(yaw)+sin(roll)*sin(pitch)*cos(yaw), sin(roll)*sin(yaw)+cos(roll)*sin(pitch)*cos(yaw), x_trans;
    cos(pitch)*sin(yaw), cos(roll)*cos(yaw)+sin(roll)*sin(pitch)*sin(yaw), -sin(roll)*cos(yaw)+cos(roll)*sin(pitch)*sin(yaw), y_trans;
    -sin(pitch), sin(roll)*cos(pitch), cos(roll)*cos(pitch), z_trans;
    0, 0, 0, 1];
output_grid = zeros(3, length(input_grid));
for i = 1:length(input_grid)
    output_grid(:, i) = input_grid(:, i)*transform_matrix;
end
