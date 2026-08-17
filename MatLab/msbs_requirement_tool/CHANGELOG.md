# Changelog

## 0.3.0 — Streamlined simultaneous-state interface and Frobenius magnetic objective

- Replaced legacy/factorial aerodynamic interfaces with one six-channel coefficient mode and one direct dimensional-wrench mode.
- Renamed rolling coefficient input to `Cl_roll` to distinguish it from lift `CL`.
- Replaced separate aerodynamic/motion case matching with one exact `cfg.scenarios` table: one row is one simultaneous physical state.
- Reduced motion modes to none, specified kinematics, and a small-angle harmonic helper.
- Removed independent W-frame orientation; T is the wind-aligned tunnel/reporting frame while E retains gravity and B retains body-fixed geometry.
- Removed the incremental resolution subsystem, direct inertial-wrench shortcut, factorial combination machinery, and time-history interpolation/synchronization options.
- Retained explicit multi-magnet geometry with one common first-order external field and constant gradient.
- Corrected the minimum-norm magnetic objective by solving in an orthonormal symmetric trace-free gradient basis, making the gradient contribution exactly the Frobenius norm.
- Clarified operating-point sweeps versus physical-configuration changes and the boundary to future coil-current optimization.

## 0.2.0 — Six-DOF aerodynamic wrench and incremental requirement extension

- Added explicit aerodynamic source modes: backward-compatible three-coefficient, six-coefficient, direct dimensional wrench cases, and aerodynamic wrench time histories.
- Added `CY`, `Cl`, and `Cn` with separate roll/yaw reference span `b` and pitch reference length `c`.
- Added correlated six-DOF user scenarios with scalar metadata passthrough.
- Prevented accidental six-coefficient Cartesian products unless explicitly enabled.
- Added exact timestamp synchronization for simultaneous aerodynamic and kinematic time histories; no hidden interpolation is performed.
- Added baseline-plus-perturbation magnetic requirement studies and `resolution_results.csv`.
- Preserved the numerical-scaling meaning of `minimum_force_scale_N` and `minimum_moment_scale_Nm`.
- Added regression/unit tests for the new aerodynamic interfaces and incremental linearity.
- Position/attitude aerodynamic sensitivity matrices remain deliberately deferred until the perturbation/reference-state semantics are defined.

## 0.1.2 — Warning-array and containment-test corrections

- Normalised all warning collections as column string arrays before concatenation.
- Changed warning appends to explicit row-and-column indexing so MATLAB does not change array orientation during growth.
- Corrected the hybrid centre-of-mass test to shrink the automatic inscribed magnet before applying a centre offset, preserving physical containment.
- Runtime verification remains pending the project owner's rerun because MATLAB is unavailable in the packaging environment.

## 0.1.1 — MATLAB runtime corrections

- Added the project root and test folder to the temporary test path so `runStudy` is available inside test methods.
- Added a central, schema-validating magnet-grade CSV loader with preserved variable names.
- Corrected heterogeneous structure-array initialisation for mass properties and result envelopes.
- Corrected the harmonic-motion test to verify acceleration magnitude after phase-specific body rotation.
- Added a magnet-database regression test and update instructions for Git integration.
- Runtime verification remains pending the project owner's rerun because MATLAB is unavailable in the packaging environment.

## 0.1.0 — Initial delivery

- Initial modular MATLAB implementation of the MSBS aerodynamic-load-to-magnetic-requirement framework.
- Primitive geometry and blockage sizing, automatic and manual magnet sets, hybrid mass properties, load-case generation, magnetic mapping, scaled requirement solver, visualisation, exports, tests, and user documentation.
- MATLAB test execution is pending the project owner's local MATLAB run.
