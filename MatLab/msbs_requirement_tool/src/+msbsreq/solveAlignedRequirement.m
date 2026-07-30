function result = solveAlignedRequirement(requiredWrench, mx)
%SOLVEALIGNEDREQUIREMENT Educational single centred +x-aligned solution.
arguments
    requiredWrench (6,1) double {mustBeFinite}
    mx (1,1) double {mustBeFinite}
end
if mx==0
    error('msbsreq:ZeroDipole','mx must be nonzero.');
end
result=struct();
result.dBx_dx_Tpm=requiredWrench(1)/mx;
result.dBy_dx_Tpm=requiredWrench(2)/mx;
result.dBz_dx_Tpm=requiredWrench(3)/mx;
result.By_T=requiredWrench(6)/mx;
result.Bz_T=-requiredWrench(5)/mx;
result.uncontrollable_Tx_Nm=requiredWrench(4);
end
