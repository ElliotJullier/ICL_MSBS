function [fraction,status] = massCapFractions(bodyMass,fullMass,volume,referenceVolume,cap)
%MASSCAPFRACTIONS Maximum permitted retained volume for each layout.
% With fixed outer volume, net magnet mass replaces body material.
fraction=min(1,max(0,(cap-bodyMass)./(fullMass-bodyMass)));
status=repmat("pass_unmodified",size(fullMass));
status(fraction<1-1e-12)="pass_resized";
status(volume.*fraction<.1*referenceVolume-1e-12*referenceVolume)="fail_below_10pct_reference";
if bodyMass>=cap,status(:)="fail_body_alone_at_or_over_limit";end
end
