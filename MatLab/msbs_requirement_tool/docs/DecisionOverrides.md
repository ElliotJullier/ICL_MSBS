# Confirmed implementation decisions

These decisions supersede conflicting or ambiguous wording in the original implementation brief.

1. The delivery does not initialise Git, create commits, or create tags. Git metadata is detected later when available.
2. MATLAB tests are supplied but were not executed in the delivery environment. The project owner will run the first suite locally and provide output for correction.
3. Harmonic angular displacement updates body attitude phase by phase. The inertial moment includes `I alpha + omega × (I omega)`.
4. Time histories may provide absolute Euler attitude or `R_TB` per row.
5. Primitive blockage uses the exact supported orthographic projection at nominal body/wind orientation.
6. Default mass properties use the hybrid explicit-magnet plus uniformly distributed shell model.
7. Magnet-set ranking first applies a dimensionless relative-residual threshold, then compares worst-case scaled requirement only among accepted sets.
8. Supplied examples use a 0.60 m × 0.60 m wind tunnel and 10% blockage.
9. Automatic magnet shrink remains an explicit user option and is zero in the supplied examples.
10. N52 magnets from Magnet Store UK are anticipated. Delivered grade values are approximate, editable placeholders pending an exact part datasheet.
11. No standalone software licence is imposed; the parent repository should define licensing.
