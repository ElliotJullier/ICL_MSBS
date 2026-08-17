function cfg = case_sphere_example()
%CASE_SPHERE_EXAMPLE Sphere with matched harmonic rigid-body motion.
cfg=case_minimal_example();
cfg.meta.case_id="sphere_harmonic_example";
cfg.meta.description="Sphere with 2 Hz heave/pitch motion and matched aerodynamic states";

cfg.aero.CD=0.50;
cfg.aero.CL=0.05;
cfg.aero.Cm=0.01;

cfg.motion.mode="harmonic";
cfg.motion.harmonic.frequency_Hz=2;
cfg.motion.harmonic.translation_amplitude_m=[0;0;0.002];
cfg.motion.harmonic.translation_phase_rad=[0;0;0];
cfg.motion.harmonic.angular_amplitude_rad=deg2rad([0;2;0]); % [roll; pitch; yaw]
cfg.motion.harmonic.angular_phase_rad=[0;0;0];
cfg.motion.harmonic.samples_per_cycle=24;

% With cfg.scenarios empty, 24 phase rows are generated and the constant
% coefficients above are evaluated at each matched motion phase. To supply
% phase-varying aerodynamic data, provide explicit cfg.scenarios rows with
% phase_rad (or time_s) plus the matching coefficient or wrench values.
end
