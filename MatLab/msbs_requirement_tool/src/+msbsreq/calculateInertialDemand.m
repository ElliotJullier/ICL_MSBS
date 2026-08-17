function demand = calculateInertialDemand(scenario, massProperties)
%CALCULATEINERTIALDEMAND Calculate Newton-Euler force and angular-momentum demand.
arguments
    scenario (1,1) struct
    massProperties (1,1) struct
end
I_T=scenario.R_TB*massProperties.inertia_B_kgm2*scenario.R_TB.';
force=massProperties.total_mass_kg*scenario.a_C_T_mps2;
angularMomentum=I_T*scenario.omega_T_radps;
moment=I_T*scenario.alpha_T_radps2+cross(scenario.omega_T_radps,angularMomentum);
demand=[force;moment];
end
