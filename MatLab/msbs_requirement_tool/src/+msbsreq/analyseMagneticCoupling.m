function coupling = analyseMagneticCoupling(map, primaryMetric, cfg)
%ANALYSEMAGNETICCOUPLING Quantify gradient-to-moment coupling in the map.
% The raw A_MG and A_MB blocks have different magnetic-input units. They are
% compared after converting gradient coordinates to orthonormal STF form and
% normalising them by the primary RMS-field reference length. This makes the
% ratio dimensionless: both blocks then represent moment per unit RMS-field cost.
arguments
    map (1,1) struct
    primaryMetric (1,1) struct
    cfg (1,1) struct
end
P=msbsreq.gradientCoordinateTransform();
Aq=map.A*blkdiag(eye(3),P);
ell=primaryMetric.gradient_equivalent_length_m;
AMB=Aq(4:6,1:3);
AMGcost=Aq(4:6,4:8)/ell;
AFB=Aq(1:3,1:3);
AFGcost=Aq(1:3,4:8)/ell;

mbNorm=norm(AMB,'fro');
mgNorm=norm(AMGcost,'fro');
if mgNorm==0
    ratio=0;
elseif mbNorm==0
    ratio=Inf;
else
    ratio=mgNorm/mbNorm;
end
zeroTol=cfg.magnetic.coupling.zero_ratio_tolerance;
smallTol=cfg.magnetic.coupling.insignificant_ratio;
if ratio<=zeroTol
    classification="zero";
elseif ratio<=smallTol
    classification="insignificant";
else
    classification="significant";
end

coupling=struct();
coupling.classification=classification;
coupling.ratio=ratio;
coupling.zero_ratio_tolerance=zeroTol;
coupling.insignificant_ratio=smallTol;
coupling.A_FB_frobenius=norm(AFB,'fro');
coupling.A_FG_cost_normalised_frobenius=norm(AFGcost,'fro');
coupling.A_MB_frobenius=mbNorm;
coupling.A_MG_cost_normalised_frobenius=mgNorm;
coupling.reference_cube_side_m=primaryMetric.reference_cube_side_m;
coupling.note="Ratio compares gradient-generated moment authority with uniform-field-generated moment authority for equal primary RMS-field cost.";
end
