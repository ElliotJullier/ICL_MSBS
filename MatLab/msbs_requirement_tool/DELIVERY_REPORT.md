# Feature delivery report — version 0.4.1

## Basis

This release retains the v0.4.0 simultaneous-state and ranking interface, while separating relative field/gradient weighting sensitivity from reference-volume RMS-field sensitivity.

## Implemented

1. Primary magnetic cost changed from arbitrary field/gradient scales to RMS affine-field magnitude over a centred model-scale reference cube.
2. Mean vacuum magnetic-energy-density proxy reported for the primary solution.
3. Full magnetic map retained while gradient-to-moment coupling is classified as zero, insignificant or significant using cost-normalised map blocks.
4. Significantly coupled records receive two compact sensitivity families: relative B/G length scales `ell=[0.01 0.1 1 10] m` and reference-volume RMS metrics at `Lmodel`, `0.2*sqrt(A_tunnel)` and `0.5*sqrt(A_tunnel)`; primary pointwise results remain one row per scenario/magnet set.
5. Component-wise absolute force/moment extrema retain the actual scenario that generated each extreme.
6. Fixed-configuration minimax and independent-scenario best-set rankings are both exported.
7. New CSV outputs provide scenario extrema, both ranking views and significant-coupling sensitivity solutions.
8. Sensitivity output explicitly identifies metric type and only assigns mean vacuum energy density to reference-volume metrics.
9. Documentation and automated tests updated for the corrected sensitivity semantics.

## Runtime status

MATLAB is unavailable in the packaging environment. The patch was generated from the locally reconstructed, previously tested v0.3.0 tree; the project owner's local `runAllTests()` remains the authoritative runtime validation.
