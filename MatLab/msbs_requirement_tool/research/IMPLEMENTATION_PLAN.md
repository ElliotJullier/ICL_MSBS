# Study implementation record - 6 November 2026

Baseline: commit f4012c9060cb1cc6afe49fd9ccb42b80e7ac1a4d, tool v0.4.1; 65/65 tests passed before edits.

1. Audit every literature family against the supplied PDFs and current case comments. Keep verified numerical fits, approximate figure readings and unverified engineering screens distinguishable.
2. Preserve the eight-coordinate STF affine-field solver and existing magnetic objective. Add explicit scenario relationships, CoM positions (nominal, specified and analytic pure translation) and fixed-origin field intercept export. Numerical acceleration integration is unnecessary for these studies and remains deferred.
3. Add a fixed non-magnet mass option. Hold it fixed within each same-model magnet comparison, retaining magnet mass changes and their effects on CoM/inertia.
4. Build new reproducible study constructors rather than overwrite legacy case files. Parameterise tunnel dimension, maximum tested projected blockage, H/up/down gravity, speeds/Re, magnet size and five auxiliary placement concepts. Reject geometries or swept envelopes that cross tunnel walls.
5. Add regression tests for origin transformation, trajectory semantics, fixed residual mass, source-coordinate conversion, source Fourier evaluation, layout rank and impossible geometry. Run the original suite and new tests before scientific batches.
6. Export actual per-state B/G and component extrema with their originating state and fixed hardware configuration. Exclude residual-rejected configurations from design maxima. Keep 20% blockage results labelled uncorrected load-transfer sensitivity rather than a validated aerodynamic prediction.

Deferred: coil field maps/current limits, numerical acceleration integration, automatic CAD fitting, and validated low-Re airfoil/inline-cylinder databases. These cannot be established by software changes alone.
