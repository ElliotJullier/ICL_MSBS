function R = rotationZYX(yawPitchRoll, units)
%ROTATIONZYX Intrinsic Z-Y-X yaw-pitch-roll rotation matrix.
%   R maps vector components from the rotated frame into the parent frame.

arguments
    yawPitchRoll (1,3) double {mustBeFinite}
    units (1,1) string {mustBeMember(units,["rad","deg"])} = "rad"
end

angles = yawPitchRoll;
if units == "deg"
    angles = deg2rad(angles);
end
psi = angles(1);
theta = angles(2);
phi = angles(3);

Rz = [cos(psi), -sin(psi), 0; sin(psi), cos(psi), 0; 0, 0, 1];
Ry = [cos(theta), 0, sin(theta); 0, 1, 0; -sin(theta), 0, cos(theta)];
Rx = [1, 0, 0; 0, cos(phi), -sin(phi); 0, sin(phi), cos(phi)];
R = Rz * Ry * Rx;
end
