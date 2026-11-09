function B_O_T = fieldAtTunnelOrigin(B_C_T,G_Tpm,r_C_T_m)
%FIELDATTUNNELORIGIN Intercept of the same affine field at fixed tunnel origin.
arguments
    B_C_T (3,1) double {mustBeFinite}
    G_Tpm (3,3) double {mustBeFinite}
    r_C_T_m (3,1) double {mustBeFinite}
end
B_O_T=B_C_T-G_Tpm*r_C_T_m;
end
