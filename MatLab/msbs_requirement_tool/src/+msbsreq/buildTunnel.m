function tunnel = buildTunnel(cfg)
%BUILDTUNNEL Resolve tunnel cross-section, air density, and gravity vector.
arguments
    cfg (1,1) struct
end

crossSection = cfg.tunnel.cross_section;
switch crossSection.type
    case "rectangular"
        tunnel.area_m2 = crossSection.width_m * crossSection.height_m;
        tunnel.width_m = crossSection.width_m;
        tunnel.height_m = crossSection.height_m;
        tunnel.diameter_m = [];
    case "circular"
        tunnel.area_m2 = pi * crossSection.diameter_m^2 / 4;
        tunnel.width_m = [];
        tunnel.height_m = [];
        tunnel.diameter_m = crossSection.diameter_m;
end
tunnel.cross_section_type = crossSection.type;

if cfg.tunnel.air.mode == "density"
    tunnel.rho_kgm3 = cfg.tunnel.air.rho_kgm3;
else
    tunnel.rho_kgm3 = cfg.tunnel.air.pressure_Pa / ...
        (cfg.tunnel.air.R_air_JpkgK * cfg.tunnel.air.temperature_K);
end
tunnel.air_mode = cfg.tunnel.air.mode;
tunnel.R_ET = cfg.frames.R_ET;
tunnel.gravity_E_mps2 = [0;0;-9.80665];
tunnel.gravity_T_mps2 = tunnel.R_ET.' * tunnel.gravity_E_mps2;
end
