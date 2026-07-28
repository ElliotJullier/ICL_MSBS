function cfg = case_sphere_example()
%CASE_SPHERE_EXAMPLE Worked sphere case with aerodynamic and harmonic ranges.

cfg.meta.case_id = "sphere_example";
cfg.meta.description = "Worked 10% blockage sphere with phase-resolved heave and pitch motion";

cfg.tunnel.cross_section.type = "rectangular";
cfg.tunnel.cross_section.width_m = 0.60;
cfg.tunnel.cross_section.height_m = 0.60;
cfg.tunnel.speed = msbsreq.rangeSpec(30, 5, "absolute");
cfg.tunnel.air.mode = "density";
cfg.tunnel.air.rho_kgm3 = 1.225;

cfg.frames.tunnel_to_earth.yaw_pitch_roll_deg = [0 0 0];
cfg.frames.body_to_tunnel.yaw_pitch_roll_deg = [0 0 0];
cfg.frames.wind_to_tunnel.R_TW = eye(3);

cfg.geometry.type = "sphere";
cfg.geometry.sizing.mode = "blockage";
cfg.geometry.sizing.blockage_ratio = 0.10;
cfg.geometry.aero_reference_area.mode = "projected_nominal";
cfg.geometry.aero_reference_length.mode = "characteristic_default";

cfg.magnets.mode = "automatic";
cfg.magnets.remanence_selection = "minimum";
cfg.magnets.automatic.grade = "N52";
cfg.magnets.automatic.linear_shrink_fraction = 0.0;
cfg.magnets.automatic.direction_candidates_B = eye(3);

cfg.mass.shell_mass_factor = 1.30;

cfg.aero.CD = msbsreq.rangeSpec(0.50, 0.05, "absolute");
cfg.aero.CL = msbsreq.rangeSpec(0.05, 0.05, "absolute");
cfg.aero.Cm = msbsreq.rangeSpec(0.01, 0.01, "absolute");

cfg.motion.mode = "harmonic_single_frequency";
cfg.motion.harmonic.frequency_Hz = 2;
cfg.motion.harmonic.translation_amplitude_m = [0;0;0.002];
cfg.motion.harmonic.angular_amplitude_rad = deg2rad([0;2;0]); % roll, pitch, yaw
cfg.motion.harmonic.samples_per_cycle = 24;

cfg.combinations.max_cases = 4096;
cfg.magnetic.acceptance_relative_residual = 1e-6;
end
