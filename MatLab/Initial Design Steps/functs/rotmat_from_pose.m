function [R_gl2loc, R_loc2gl] = rotmat_from_pose(pose)
% Returns rotation matrices based on the project's yaw-pitch-roll convention.
%
% ----- INPUTS -----
% pose: 1x6 vector [x, y, z, yaw, pitch, roll]
%
% ----- OUTPUTS -----
% R_gl2loc: rotation from global frame to local frame
% R_loc2gl: rotation from local frame to global frame

yaw   = pose(4);
pitch = pose(5);
roll  = pose(6);

R_gl2loc = [cos(pitch)*cos(yaw), -cos(roll)*sin(yaw)+sin(roll)*sin(pitch)*cos(yaw),  sin(roll)*sin(yaw)+cos(roll)*sin(pitch)*cos(yaw);
            cos(pitch)*sin(yaw),  cos(roll)*cos(yaw)+sin(roll)*sin(pitch)*sin(yaw), -sin(roll)*cos(yaw)+cos(roll)*sin(pitch)*sin(yaw);
            -sin(pitch),          sin(roll)*cos(pitch),                               cos(roll)*cos(pitch)];

R_loc2gl = R_gl2loc.'; % orthonormal rotation

end
