# Quick start

## 1. Run the tests

Open MATLAB with the Current Folder set to `MatLab/msbs_requirement_tool` and run:

```matlab
results = runAllTests();
```

Do not continue with a release if any test fails.

## 2. Run the minimal example

```matlab
study = runStudy("case_minimal_example");
```

This uses a 0.60 m × 0.60 m horizontal tunnel, a 10% blockage sphere, a maximum inscribed N52 magnet and the three automatic body-axis magnetisation candidates.

## 3. Create a case

Copy `cases/case_template.m`, rename the file and function identically, then edit the `USER INPUT` sections. Run it with:

```matlab
study = runStudy("case_my_experiment");
```

The normal workflow is:

1. Define tunnel orientation, geometry, magnets and mass.
2. Choose `cfg.aero.mode = "coefficients"` or `"direct_wrench"`.
3. Choose `cfg.motion.mode = "none"`, `"specified"` or `"harmonic"`.
4. Put simultaneous operating states in `cfg.scenarios`. One row is one physical state.
5. Run the study and inspect `scenario_results.csv`, `scenario_extrema.csv`, the fixed/independent ranking CSVs, `magnet_set_summary.csv` and `run_summary.md`. Significant coupling also produces `magnetic_cost_sensitivity.csv`, containing separate relative B/G length-scale and reference-volume RMS-field sensitivities.

## 4. Exact operating-point sweeps

For a speed study, use explicit rows rather than ranges:

```matlab
cfg.scenarios = table( ...
    ["U20";"U30";"U40";"U50"], ...
    [20;30;40;50], ...
    [0.70;0.60;0.55;0.52], ...
    'VariableNames',{'scenario_name','speed_mps','CD'});
```

Omitted coefficient columns use the defaults in `cfg.aero`. Rows are never cross-combined.

Changes that alter the physical configuration should normally be separate case files. For example, comparing 0.60 m and 1.00 m tunnels under blockage sizing changes model dimensions, area, magnet fit, mass and inertia, so use two cases.

## 5. Matched aero and motion

For directly specified motion, append the nine kinematic columns to the **same** scenario rows and set:

```matlab
cfg.motion.mode = "specified";
```

For harmonic motion, either leave `cfg.scenarios` empty to generate evenly spaced phases with constant aerodynamic inputs, or provide one row per aerodynamic state with `phase_rad` (or `time_s`). The harmonic motion is evaluated at that same row; no interpolation or independent timestamp synchronization occurs.

## 6. Results interpretation

All final loads, magnetic fields and gradients are reported in the tunnel frame T. The magnetic solver finds a low field/gradient solution for the requested wrench; it does not calculate coil current or prove that a practical coil system can generate it.
