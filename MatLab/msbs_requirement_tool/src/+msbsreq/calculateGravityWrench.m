function wrench = calculateGravityWrench(tunnel, massProperties)
%CALCULATEGRAVITYWRENCH Calculate gravity wrench about the centre of mass.
arguments
    tunnel (1,1) struct
    massProperties (1,1) struct
end
wrench=[massProperties.total_mass_kg*tunnel.gravity_T_mps2;zeros(3,1)];
end
