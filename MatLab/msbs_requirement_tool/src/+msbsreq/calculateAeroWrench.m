function wrench = calculateAeroWrench(scenario, geometry, massProperties)
%CALCULATEAEROWRENCH Calculate aerodynamic wrench about the centre of mass.
arguments
    scenario (1,1) struct
    geometry (1,1) struct
    massProperties (1,1) struct
end

if isfield(scenario,'aero_source_mode'),mode=string(scenario.aero_source_mode);else,mode="legacy_3coeff";end

switch mode
    case "legacy_3coeff"
        q=0.5*scenario.rho_kgm3*scenario.speed_mps^2;
        forceW=q*geometry.reference_area_m2*[scenario.CD;0;scenario.CL];
        momentW=q*geometry.reference_area_m2*[0;geometry.reference_length_m*scenario.Cm;0];
        forceT=scenario.R_TW*forceW;
        momentAtRefT=scenario.R_TW*momentW;
        r_CR_T=scenario.R_TB*(geometry.aero_reference_point_B_m- ...
            massProperties.centre_of_mass_B_m);
        wrench=[forceT;momentAtRefT+cross(r_CR_T,forceT)];

    case "coefficients_6dof"
        q=0.5*scenario.rho_kgm3*scenario.speed_mps^2;
        S=geometry.reference_area_m2;c=geometry.reference_length_m;b=geometry.reference_span_m;
        forceW=q*S*[scenario.CD;scenario.CY;scenario.CL];
        momentW=q*S*[b*scenario.Cl;c*scenario.Cm;b*scenario.Cn];
        forceT=scenario.R_TW*forceW;
        momentAtRefT=scenario.R_TW*momentW;
        r_CR_T=scenario.R_TB*(geometry.aero_reference_point_B_m- ...
            massProperties.centre_of_mass_B_m);
        wrench=[forceT;momentAtRefT+cross(r_CR_T,forceT)];

    case {"direct_wrench_cases","wrench_time_history"}
        frames=struct('R_ET',scenario.R_ET,'R_TB',scenario.R_TB,'R_TW',scenario.R_TW);
        wrench=msbsreq.transformWrench(scenario.aero_force_input,scenario.aero_moment_input, ...
            scenario.aero_input_frame,scenario.aero_reference_point_B_m, ...
            massProperties.centre_of_mass_B_m,frames);

    otherwise
        error('msbsreq:UnsupportedAeroMode','Unsupported aerodynamic source mode %s.',mode);
end
end
