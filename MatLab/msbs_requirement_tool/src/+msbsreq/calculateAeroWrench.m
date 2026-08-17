function wrench = calculateAeroWrench(scenario, geometry, massProperties)
%CALCULATEAEROWRENCH Calculate aerodynamic wrench about the centre of mass.
arguments
    scenario (1,1) struct
    geometry (1,1) struct
    massProperties (1,1) struct
end

mode=string(scenario.aero_source_mode);
switch mode
    case "coefficients"
        q=0.5*scenario.rho_kgm3*scenario.speed_mps^2;
        S=geometry.reference_area_m2;
        b=geometry.reference_span_m;
        c=geometry.reference_length_m;
        forceT=q*S*[scenario.CD;scenario.CY;scenario.CL];
        momentAtRefT=q*S*[b*scenario.Cl_roll;c*scenario.Cm;b*scenario.Cn];
        r_CR_T=scenario.R_TB*(geometry.aero_reference_point_B_m- ...
            massProperties.centre_of_mass_B_m);
        wrench=[forceT;momentAtRefT+cross(r_CR_T,forceT)];

    case "direct_wrench"
        frames=struct('R_ET',scenario.R_ET,'R_TB',scenario.R_TB);
        wrench=msbsreq.transformWrench(scenario.aero_force_input,scenario.aero_moment_input, ...
            scenario.aero_input_frame,scenario.aero_reference_point_B_m, ...
            massProperties.centre_of_mass_B_m,frames);

    otherwise
        error('msbsreq:UnsupportedAeroMode','Unsupported aerodynamic source mode %s.',mode);
end
end
