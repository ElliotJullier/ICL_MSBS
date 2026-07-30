# Troubleshooting

## MATLAB cannot find `runStudy`

Set MATLAB's Current Folder to the project root containing `runStudy.m`. Do not start in `cases/` or `src/`. Version 0.1.1 and later add the project root explicitly while `runAllTests` is running. After replacing an older project copy, run `clear functions` and `rehash path` once before rerunning the tests.

## The case function is not found

The case file must be in `cases/` or on the MATLAB path, and these three names must match:

- file: `case_my_experiment.m`;
- first line: `function cfg = case_my_experiment()`;
- call: `runStudy("case_my_experiment")`.

## Invalid rotation matrix

Explicit `R_TB` or `R_TW` matrices must satisfy `R.'*R = eye(3)` and `det(R) = +1` within tolerance. Prefer documented yaw-pitch-roll inputs when possible.

## Excessive or impossible blockage

Blockage is a fraction: use `0.10` for 10%, not `10`. The target projected area must be smaller than the tunnel cross-section. For a high blockage warning, reduce the target or deliberately change `cfg.validation.blockage_advisory_limit` after assessing tunnel corrections.

## Invalid range

A range must have finite `lower <= nominal <= upper`. Use:

```matlab
msbsreq.rangeSpec(30, 5, "absolute")
msbsreq.rangeSpec(0.5, 10, "percent")
msbsreq.rangeSpec(0.5, [], "absolute")
```

Speed and density cannot have negative lower bounds. Aerodynamic coefficients can be signed.

## Unknown magnet grade

Edit or add the grade in `data/magnet_grades.csv`. The delivered N35–N52 rows are configurable generic placeholders intended for later replacement with exact Magnet Store product data.


## Magnet database headers are renamed or `grade` is unrecognised

Use version 0.1.1 or later. Magnet data are loaded through `msbsreq.loadMagnetGradeTable`, which fixes the CSV delimiter, preserves the documented column names, and validates the complete schema before calculations begin.

## Magnet lies outside the model

Correct the magnet dimensions, centre, or `R_BM`. For a custom geometry, the first version checks against the supplied bounding proxy. Containment checking can be deliberately disabled with:

```matlab
cfg.magnets.check_containment = false;
```

Disabling the check does not make an invalid geometry physically valid.

## Too many factorial cases

The tool stops rather than silently discarding combinations. Reduce independent ranges or frame/motion cases, increase `max_cases` deliberately, or use `cfg.combinations.strategy = "user_defined"` for correlated physical scenarios.

## Poorly conditioned magnetic map

A high condition number means small wrench changes can require large changes in the solved field/gradient. Inspect magnet geometry and orientation, compare singular values, and consider separated or nonparallel magnets. The scaled solution remains a requirement calculation, not a robust coil design.

## Uncontrollable torque or residual

A centred single dipole cannot directly generate torque parallel to its own dipole direction. The tool reports rather than hides the residual. Change the magnetisation direction or define an explicit multi-magnet arrangement.

## Relative residual threshold is confusing

The threshold is dimensionless and uses fixed study-wide force and moment scales. `1e-6` means the remaining scaled wrench is at most one millionth of the requested scaled wrench norm. It is used for controllability/ranking, not for specifying sensor accuracy or mechanical load tolerance.

## PDF or PNG export fails on a headless installation

Run MATLAB with graphics support and verify that `exportgraphics` can create files. Set:

```matlab
cfg.visualisation.enable = false;
```

for calculation-only runs while diagnosing graphics configuration.

## The result appears physically unrealistic

Check the warnings and assumptions in `run_summary.md`. Common causes are generic remanence, a magnet too large for a point-dipole approximation, widely separated magnets under one first-order gradient, approximate shell inertia, unrealistic simultaneous factorial corners, or aerodynamic coefficients defined using a different reference area or moment point.

## `MATLAB:catenate:dimensionMismatch` while collecting warnings

Use version 0.1.2 or later. Earlier versions could allow a dynamically grown string array to become a row vector and then attempt to vertically concatenate it with a column vector. Version 0.1.2 fixes the orientation explicitly and normalises warning arrays before concatenation.
