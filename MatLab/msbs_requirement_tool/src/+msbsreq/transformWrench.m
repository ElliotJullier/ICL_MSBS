function wrenchTAtC = transformWrench(force, momentAtP, sourceFrame, referencePointB, centreOfMassB, frames)
%TRANSFORMWRENCH Transform a wrench into tunnel components and shift it to CoM.
arguments
    force (3,1) double {mustBeFinite}
    momentAtP (3,1) double {mustBeFinite}
    sourceFrame (1,1) string {mustBeMember(sourceFrame,["E","T","B"])}
    referencePointB (3,1) double {mustBeFinite}
    centreOfMassB (3,1) double {mustBeFinite}
    frames struct
end
forceT = msbsreq.transformVector(force, sourceFrame, frames);
momentT = msbsreq.transformVector(momentAtP, sourceFrame, frames);
r_CP_T = frames.R_TB * (referencePointB - centreOfMassB);
momentAtC_T = momentT + cross(r_CP_T, forceT);
wrenchTAtC = [forceT; momentAtC_T];
end
