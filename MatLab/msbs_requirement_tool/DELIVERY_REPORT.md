# Feature delivery report — version 0.2.0

## Basis

This release implements the supplied aerodynamic-wrench extension specification, with conservative choices where the proposed interface was ambiguous.

## Implemented

1. Backward-compatible `legacy_3coeff` aerodynamic mode.
2. Six-DOF `[CD CY CL Cl Cm Cn]` coefficient mode using reference dimensions `[b c b]`.
3. Correlated user-defined six-DOF scenarios and metadata passthrough.
4. Direct dimensional aerodynamic wrench cases in W/T/B frames with reference-point shifting.
5. Aerodynamic wrench time histories that coexist with motion time histories using exact timestamp matching.
6. Baseline-plus-perturbation force/moment requirement studies with independent linear-increment consistency checks.
7. Updated template, user guide, technical reference, changelog, exports, and automated tests.

## Deliberate decisions

- Six-coefficient extrema are not expanded into a Cartesian product unless `combinations.allow_full_factorial_6dof=true`.
- Time histories are not silently interpolated; v0.2.0 requires exact timestamps within a configurable tolerance.
- Position/attitude aerodynamic sensitivity matrices are deferred because the supplied proposal does not yet define the perturbation vector/reference state to which the matrices should be applied.
- The optional user-supplied aerodynamic model function remains a later extension, as proposed.

## Runtime status

MATLAB and GNU Octave are unavailable in the packaging environment. Static checks and source-level audits were performed, but the project owner's local `runAllTests()` remains the authoritative runtime validation.
