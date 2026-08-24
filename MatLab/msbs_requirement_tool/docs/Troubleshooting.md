# Troubleshooting

## MATLAB is running the wrong copy

Check:

```matlab
pwd
strtrim(fileread("VERSION"))
which runStudy -all
which msbsreq.buildScenarioTable -all
```

All paths should point to the same `msbs_requirement_tool` folder and `VERSION` should report `0.4.1`.

## Invalid rotation

Only proper orthonormal rotations are accepted. User-facing tunnel/body attitudes use intrinsic Z-Y-X `[yaw pitch roll]` degrees.

## Direct aerodynamic wrench rejected

`aero.mode="direct_wrench"` requires all six columns in `cfg.scenarios`:

`Fx_aero_N`, `Fy_aero_N`, `Fz_aero_N`, `Mx_aero_Nm`, `My_aero_Nm`, `Mz_aero_Nm`.

Optional `aero_frame` is E, T or B. Optional `aero_reference_point_B_m` must be a cell column of finite 3-vectors.

## Specified motion rejected

If any kinematic column is supplied, all nine must be present:

`a_x`, `a_y`, `a_z`, `omega_x`, `omega_y`, `omega_z`, `alpha_x`, `alpha_y`, `alpha_z`.

Set `cfg.motion.mode="specified"`. If motion is unknown or irrelevant, omit all nine columns and the motion demand is zero.

## Harmonic motion has no phase

When `cfg.scenarios` is explicitly supplied in harmonic mode, every row must have `phase_rad` or `time_s`. If `cfg.scenarios` is empty, the program generates `samples_per_cycle` evenly spaced phases automatically.

## Too many scenarios

There is no factorial expansion. `max_scenarios` is only a safety cap on explicit rows (or the harmonic rows generated from `samples_per_cycle`). Reduce the table size or increase the cap deliberately.

## Residual is large

A large relative residual generally means the selected magnet arrangement cannot reproduce that six-component wrench within the point-dipole/first-order model. Inspect `map_rank`, `map_condition_number`, the required component values and the magnet directions/positions; do not interpret the solver residual as a coil-current limitation.

## Custom geometry moment coefficients

The default roll/yaw reference span is the body-y outer extent. If the source defining `Cl_roll` or `Cn` uses another b, set `geometry.aero_reference_span.mode="manual"` and provide `value_m`.
