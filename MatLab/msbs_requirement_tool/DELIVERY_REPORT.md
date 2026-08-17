# Feature delivery report — version 0.3.0

## Basis

This release simplifies the v0.2.0 aerodynamic/motion extension after review of the intended MSBS requirements workflow.

## Implemented

1. One coefficient aerodynamic mode with `[CD CY CL Cl_roll Cm Cn]`; all unused channels may be zero.
2. Direct dimensional aerodynamic wrench mode integrated with the same motion state.
3. One explicit scenario table: one row equals one simultaneous physical state.
4. Removal of factorial coefficient combinations and separate aero/motion synchronization machinery.
5. Motion modes reduced to `none`, `specified`, and a small-angle harmonic helper.
6. Frames reduced to E/T/B, with T also serving as the wind-aligned reporting frame.
7. Removal of incremental resolution, direct inertial-wrench, camera/jitter, aerodynamic-Jacobian and callback concepts from the core interface.
8. Manual multiple magnets remain spatially resolved under one common first-order external field.
9. Magnetic minimum norm corrected so the gradient objective is the physical Frobenius norm using an orthonormal symmetric trace-free basis.
10. Documentation and automated tests updated for the streamlined interface.

## Runtime status

MATLAB is unavailable in the packaging environment. The patch is generated against master commit `6d29e4c3b7629191d980eb50f0ceb744ab9061b4`; the project owner's local `runAllTests()` remains the authoritative runtime validation.
