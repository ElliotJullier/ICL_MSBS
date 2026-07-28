function vectorT = transformVector(vector, sourceFrame, frames)
%TRANSFORMVECTOR Transform a free vector from E, T, B, or W into tunnel frame.
arguments
    vector (3,1) double {mustBeFinite}
    sourceFrame (1,1) string {mustBeMember(sourceFrame,["E","T","B","W"])}
    frames struct
end
switch sourceFrame
    case "E"
        vectorT = frames.R_ET.' * vector;
    case "T"
        vectorT = vector;
    case "B"
        vectorT = frames.R_TB * vector;
    case "W"
        vectorT = frames.R_TW * vector;
end
end
