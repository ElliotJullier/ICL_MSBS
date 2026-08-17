function cfg = case_minimal_example()
%CASE_MINIMAL_EXAMPLE Minimal static sphere requirement study.
cfg.meta.case_id = "minimal_example";
cfg.meta.description = "10% blockage sphere in a 0.60 m square wind tunnel";

cfg.tunnel.cross_section.width_m = 0.60;
cfg.tunnel.cross_section.height_m = 0.60;
cfg.tunnel.speed_mps = 30;
cfg.tunnel.air.rho_kgm3 = 1.225;

cfg.geometry.type = "sphere";
cfg.geometry.sizing.mode = "blockage";
cfg.geometry.sizing.blockage_ratio = 0.10;

cfg.magnets.mode = "automatic";
cfg.magnets.remanence_selection = "minimum";
cfg.magnets.automatic.grade = "N52";
cfg.magnets.automatic.linear_shrink_fraction = 0;
cfg.magnets.automatic.direction_candidates_B = eye(3);

cfg.mass.shell_mass_factor = 1.30;

cfg.aero.mode = "coefficients";
cfg.aero.CD = 0.50;
cfg.aero.CY = 0;
cfg.aero.CL = 0;
cfg.aero.Cl_roll = 0;
cfg.aero.Cm = 0;
cfg.aero.Cn = 0;

cfg.motion.mode = "none";
% cfg.scenarios is omitted: one nominal simultaneous state is generated.
end
