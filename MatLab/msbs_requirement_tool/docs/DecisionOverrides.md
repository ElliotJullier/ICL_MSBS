# Confirmed design decisions — v0.3.0

1. The program is a magnetic-requirement tool, not a coil/current, controller, camera-noise or aerodynamic-solver tool.
2. Use E/T/B frames. T is also the wind-aligned frame; no independent W frame is retained.
3. All final force, moment, field and gradient components are reported in T.
4. One `cfg.scenarios` row is one simultaneous physical state. No factorial case generation is performed.
5. Aerodynamics use either six coefficients `[CD CY CL Cl_roll Cm Cn]` or a dimensional six-component wrench.
6. Moment coefficients may simply be zero; direct wrench mode is preferred when dimensional moments are already known.
7. Aerodynamic and motion states are coupled by being in the same row. There is no separate time-history synchronization or interpolation subsystem.
8. Motion is none, explicitly specified kinematics, or a small-angle single-frequency harmonic helper.
9. Actual physical motion contributes inertial demand. Sensor jitter, camera noise and controller errors are outside scope.
10. Operating-point changes such as speed/coefficient values use scenario rows. Configuration changes that alter model geometry or mass should normally use separate case files.
11. Automatic magnet mode compares user-specified single-magnet direction candidates. Automatic multi-magnet design generation is not implemented.
12. Manual magnet sets may contain multiple spatially separated magnets. They share one first-order external field `B0 + G r` and one constant G.
13. Permanent-magnet mutual interactions are not included in the net external-wrench calculation.
14. The magnetic map remains `w = A x` with physical `x=[B0; gxx gyy gxy gxz gyz]`.
15. `lsqminnorm` is retained, but its gradient coordinates are transformed internally to an orthonormal symmetric trace-free basis so the minimized gradient magnitude is exactly the Frobenius norm.
16. Incremental resolution studies, aerodynamic Jacobians and user aerodynamic callback functions are not part of v0.3.0.
