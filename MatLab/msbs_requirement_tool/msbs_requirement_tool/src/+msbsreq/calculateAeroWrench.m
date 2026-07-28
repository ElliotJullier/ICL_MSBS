function wrench = calculateAeroWrench(scenario, geometry, massProperties)
%CALCULATEAEROWRENCH Calculate aerodynamic wrench about the centre of mass.
arguments
    scenario (1,1) struct
    geometry (1,1) struct
    massProperties (1,1) struct
end
q = 0.5*scenario.rho_kgm3*scenario.speed_mps^2;
forceW = [q*geometry.reference_area_m2*scenario.CD; 0; ...
    q*geometry.reference_area_m2*scenario.CL];
momentW = [0; q*geometry.reference_area_m2*geometry.reference_length_m*scenario.Cm; 0];
forceT = scenario.R_TW*forceW;
momentAtRefT = scenario.R_TW*momentW;
r_CR_T = scenario.R_TB*(geometry.aero_reference_point_B_m- ...
    massProperties.centre_of_mass_B_m);
momentAtCoMT = momentAtRefT+cross(r_CR_T,forceT);
wrench = [forceT;momentAtCoMT];
end
