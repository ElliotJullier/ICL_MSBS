# Changelog

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
