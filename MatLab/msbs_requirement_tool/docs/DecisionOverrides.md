# Confirmed design decisions — v0.4.1

1. The program is a magnetic-requirement tool, not a coil/current, controller, camera-noise or aerodynamic-solver tool.
2. Use E/T/B frames. T is also the wind-aligned frame; no independent W frame is retained.
3. All final force, moment, field and gradient components are reported in T.
4. One `cfg.scenarios` row is one simultaneous physical state. No factorial case generation is performed.
5. Aerodynamics use either six coefficients `[CD CY CL Cl_roll Cm Cn]` or a dimensional six-component wrench.
6. Aerodynamic and motion states are coupled by being in the same row. There is no separate time-history synchronization or interpolation subsystem.
7. Motion is none, explicitly specified kinematics, or a small-angle single-frequency harmonic helper.
8. Operating-point changes such as speed/coefficient values use scenario rows. Configuration changes that alter physical geometry or mass should normally use separate case files.
9. Automatic magnet mode compares user-specified single-magnet direction candidates. Automatic multi-magnet design generation is not implemented.
10. Manual magnet sets may contain multiple spatially separated magnets. They share one first-order external field `B0 + G r` and one constant G.
11. The magnetic map remains `w = A x` with physical `x=[B0; gxx gyy gxy gxz gyz]`. A new map is built for every scenario/magnet-set combination using the current body attitude.
12. `G` is symmetric and trace-free by construction and is re-expressed internally in an orthonormal STF basis so its solver-coordinate norm is exactly `||G||F`.
13. The primary magnetic cost is the RMS affine-field magnitude over a centred isotropic cube whose side is the largest model outer dimension: `J^2=||B0||^2+(Lref^2/12)||G||F^2`.
14. `lsqminnorm` is retained. Wrench residual is minimised first; among equivalent residual solutions the change of variables makes the secondary minimum norm equal to the selected magnetic cost.
15. Gradient-to-moment coupling is classified from the full map. The full 6x8 system is always solved; classification only controls reporting and optional sensitivity solves.
16. Significant-coupling sensitivity solves use two distinct families without recalculating loads or the magnetic map: relative B/G regularisation lengths `ell=[0.01 0.1 1 10] m`, and reference-volume RMS-field metrics using `Lref=Lmodel`, `0.2*sqrt(A_tunnel)` and `0.5*sqrt(A_tunnel)`.
17. Every pointwise scenario/magnet-set solution is retained. Fixed-hardware ranking uses minimax `min_j max_k J_jk`; independent-scenario ranking uses `min_j J_jk` separately for each scenario and orders scenarios hardest-first.
18. Component extrema retain the actual scenario that produced them and are never combined into a fictitious wrench.
19. Permanent-magnet mutual interactions, coil currents, winding geometry, inductance, resistance, voltage, thermal limits and controller design remain outside scope.
20. A future coil model may replace the local field-cost proxy with direct current, stored-energy, copper-loss or voltage-aware optimisation.
