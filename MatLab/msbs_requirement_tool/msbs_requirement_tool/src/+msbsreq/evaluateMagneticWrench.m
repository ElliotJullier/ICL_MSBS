function [wrench, localFields] = evaluateMagneticWrench(x, positionsT, dipolesT)
%EVALUATEMAGNETICWRENCH Evaluate total first-order multi-dipole wrench.
arguments
    x (8,1) double {mustBeFinite}
    positionsT (3,:) double {mustBeFinite}
    dipolesT (3,:) double {mustBeFinite}
end
if size(positionsT,2)~=size(dipolesT,2)
    error('msbsreq:MagnetArraySize','Position and dipole arrays must have equal columns.');
end
B0=x(1:3); G=msbsreq.constructGradient(x);
force=zeros(3,1); torque=zeros(3,1);
localFields=zeros(3,size(positionsT,2));
for i=1:size(positionsT,2)
    r=positionsT(:,i); m=dipolesT(:,i);
    Bi=B0+G*r; Fi=G*m;
    Ti=cross(r,Fi)+cross(m,Bi);
    force=force+Fi; torque=torque+Ti;
    localFields(:,i)=Bi;
end
wrench=[force;torque];
end
