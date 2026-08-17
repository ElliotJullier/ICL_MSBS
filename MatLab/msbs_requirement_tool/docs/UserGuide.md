# User guide — MSBS requirement tool v0.3.0

## 1. Purpose

The tool answers one question:

> For a specified wind-tunnel model, permanent-magnet arrangement and simultaneous external/inertial load state, what applied magnetic field `B0` and source-free first-order gradient `G` are required to produce the balancing magnetic wrench?

It is intentionally not a coil-design, current-allocation, controller, sensor-noise or aerodynamic-prediction package.

## 2. Normal workflow

Create a case from `cases/case_template.m`, define the fixed physical configuration, then define one or more simultaneous operating states in `cfg.scenarios`. Run:

```matlab
study = runStudy("case_my_experiment");
```

The calculation sequence is:

1. Resolve and validate inputs.
2. Build tunnel orientation, geometry, magnets and mass properties.
3. Resolve each exact scenario row into aerodynamic wrench, body attitude and kinematics.
4. Transform all loads to T and reference them to the model centre of mass.
5. Form the required magnetic wrench.
6. Build one magnetic influence matrix `A` for each magnet set and scenario attitude.
7. Solve for the minimum scaled field/Frobenius-gradient requirement.
8. Export component-level results and set-level envelopes.

## 3. Frames and signs

Three frames are retained:

- E: Earth/inertial. `+z_E` is upward and gravity is negative z.
- T: tunnel/MSBS reporting frame. `+x_T` is downstream wind, `+y_T` lateral and `+z_T` completes the right-handed set.
- B: body-fixed model frame.

`cfg.frames.tunnel_to_earth.yaw_pitch_roll_deg` rotates T into E. This is how horizontal, vertical and inclined tunnels are represented. `cfg.frames.body_to_tunnel.yaw_pitch_roll_deg` sets the nominal model attitude.

All reported aerodynamic, gravity, inertial, required magnetic, field and gradient components are in T.

## 4. Aerodynamic input

Set `cfg.aero.mode` to one of:

- `"coefficients"`
- `"direct_wrench"`

### 4.1 Coefficients

The defaults are `cfg.aero.CD`, `cfg.aero.CY`, `cfg.aero.CL`, `cfg.aero.Cl_roll`, `cfg.aero.Cm`, and `cfg.aero.Cn`. Scenario rows may override any of them.

`CL` is lift coefficient. `Cl_roll` is the rolling-moment coefficient normally written mathematically as C_l; the longer MATLAB name avoids confusing lowercase l with uppercase L.

The dimensional loads are

```text
F_T = q S [CD; CY; CL]
M_T = q S [b Cl_roll; c Cm; b Cn]
```

where `q=0.5*rho*U^2`, `S` is reference area, `b` is reference span and `c` is reference length. If a force or moment channel is not being modelled, leave its coefficient at zero.

### 4.2 Direct wrench

With `cfg.aero.mode="direct_wrench"`, every scenario row supplies:

```text
Fx_aero_N Fy_aero_N Fz_aero_N
Mx_aero_Nm My_aero_Nm Mz_aero_Nm
```

Optional `aero_frame` is E, T or B and defaults to `cfg.aero.direct_wrench_frame`. Optional `aero_reference_point_B_m` is a cell column of body-frame 3-vectors. If omitted, `cfg.geometry.aero_reference_point_B_m` is used.

Direct wrench is usually the cleanest input for CFD, load-cell data or literature that already provides dimensional loads.

## 5. Scenario table: exact states only

`cfg.scenarios` is a MATLAB table. Every row is one simultaneous physical state. Rows are not cross-multiplied and separate time histories are not synchronized or interpolated.

If the table is empty:

- `motion.mode="none"` or `"specified"` gives one nominal static row;
- `motion.mode="harmonic"` generates `samples_per_cycle` phase rows.

Useful optional columns in coefficient mode are:

```text
scenario_name speed_mps CD CY CL Cl_roll Cm Cn
```

Additional unrecognized scalar/string columns such as `Re`, `St`, `reduced_frequency`, `roughness` or `source_id` are metadata and pass through to the result table without changing the equations.

### 5.1 Parametric studies

Use scenario rows for operating-point changes that do not alter the physical model, for example speed, aerodynamic coefficients, attitude or motion phase.

Use separate case files when the configuration itself changes. In particular, changing tunnel dimensions while using blockage sizing changes model dimensions, reference area, magnet fit, mass and inertia, so a 0.60 m tunnel and a 1.00 m tunnel should normally be separate cases.

## 6. Motion

`cfg.motion.mode` is one of:

- `"none"`: zero acceleration, angular velocity and angular acceleration;
- `"specified"`: read matched kinematics from the same scenario row;
- `"harmonic"`: generate prescribed small-angle single-frequency kinematics at each row's phase/time.

For specified motion, if any kinematic column is supplied, all nine are required:

```text
a_x a_y a_z
omega_x omega_y omega_z
alpha_x alpha_y alpha_z
```

Their common frame is `cfg.motion.frame` (E, T or B). If no kinematic columns are present, the motion demand is zero. Optional `yaw_deg`, `pitch_deg`, `roll_deg` set an absolute body attitude for the row.

For harmonic motion, amplitudes are body-axis quantities. If `cfg.scenarios` is explicit, each row must provide `phase_rad` or `time_s`; aerodynamic values in that row are therefore automatically matched to the same motion state. For large angular motion, supply explicit kinematics instead of relying on the small-angle harmonic helper.

## 7. Additional static external wrench

`cfg.additional_wrenches` is optional. Each row requires:

```text
name Fx_N Fy_N Fz_N Mx_Nm My_Nm Mz_Nm components_frame reference_point_B_m
```

`components_frame` is E, T or B. These wrenches are applied to every scenario; time-varying aerodynamic loads belong in `cfg.scenarios` instead.

## 8. Permanent magnets

`cfg.magnets.mode="automatic"` fits one magnet into the supported inscribed cuboid and creates one candidate set for each column of `cfg.magnets.automatic.direction_candidates_B`. With the default `eye(3)`, +x_B, +y_B and +z_B are compared independently.

`cfg.magnets.mode="manual_sets"` accepts explicitly defined magnet sets. Each magnet has its own dimensions, body-frame centre, local-to-body orientation, grade and magnetisation direction. Multiple magnets do not occupy one point.

All magnets in one rigid set share the same external first-order field

```text
B(r) = B0 + G r
```

so separated magnets see different local B but the same constant G. The solver simultaneously sums the force and torque from every magnet; it does not solve a gradient for a main magnet and then add secondary magnets afterwards.

## 9. Magnetic solve and ranking

The physical map uses

```text
x = [Bx By Bz gxx gyy gxy gxz gyz]'
w = A x
```

with a symmetric trace-free gradient. `A` is 6×8. Each column is the six-component wrench created by one unit physical field/gradient parameter for the current magnet geometry and attitude.

Because there are generally more magnetic unknowns than wrench equations, `lsqminnorm` is used. Internally the five gradient degrees of freedom are transformed into an orthonormal symmetric trace-free basis, so the minimized gradient norm is exactly `norm(G,'fro')` rather than the coordinate-dependent norm used before v0.3.0.

The objective is dimensionally scaled using `cfg.magnetic.field_scale_T` and `cfg.magnetic.gradient_scale_Tpm`. These are requirement-ranking scales, not hardware limits. A future coil model may map the required field/gradient to current, but that is outside this tool.

## 10. Outputs

`scenario_results.csv` contains one row per scenario and magnet set, including separate aerodynamic, gravity, other and inertial contributions; the required magnetic wrench; `B0`; all six unique physical gradient components; Frobenius gradient norm; residuals; map rank and condition number; plus scenario metadata.

`magnet_set_summary.csv` contains per-set worst-case envelopes. `results_full.mat` retains full matrices, local magnet fields and intermediate records.

## 11. Complete default configuration reference

### Identity and tunnel

| Field | Default | Meaning |
|---|---:|---|
| `meta.case_id` | `unnamed_case` | Case identifier. |
| `meta.description` | text | Human description. |
| `tunnel.cross_section.type` | `rectangular` | Rectangular or circular. |
| `tunnel.cross_section.width_m` | 0.60 | Rectangular width. |
| `tunnel.cross_section.height_m` | 0.60 | Rectangular height. |
| `tunnel.cross_section.diameter_m` | empty | Circular diameter. |
| `tunnel.speed_mps` | 0 | Nominal speed used when a scenario omits speed. |
| `tunnel.air.mode` | `density` | Density or ideal-gas calculation. |
| `tunnel.air.rho_kgm3` | 1.225 | Air density. |
| `tunnel.air.pressure_Pa` | 101325 | Ideal-gas pressure. |
| `tunnel.air.temperature_K` | 288.15 | Ideal-gas temperature. |
| `tunnel.air.R_air_JpkgK` | 287.05 | Gas constant. |

### Frames

| Field | Default | Meaning |
|---|---:|---|
| `frames.tunnel_to_earth.sequence` | `ZYX` | Required Euler sequence. |
| `frames.tunnel_to_earth.yaw_pitch_roll_deg` | `[0 0 0]` | Tunnel orientation in Earth. |
| `frames.body_to_tunnel.sequence` | `ZYX` | Required Euler sequence. |
| `frames.body_to_tunnel.yaw_pitch_roll_deg` | `[0 0 0]` | Nominal body attitude. |
| `frames.body_origin_T_m` | zero | Body origin location for plotting. |

### Geometry

| Field | Default | Meaning |
|---|---:|---|
| `geometry.type` | `sphere` | Supported primitive/custom proxy. |
| `geometry.sizing.mode` | `blockage` | Blockage or absolute sizing. |
| `geometry.sizing.blockage_ratio` | 0.10 | Nominal projected blockage fraction. |
| `geometry.sizing.nominal_dimensions_m` | `[1;1;1]` | Cuboid/ellipsoid normalized or absolute dimensions as applicable. |
| `geometry.sizing.diameter_m` | empty | Sphere diameter. |
| `geometry.sizing.radius_m` | empty | Sphere radius alternative. |
| `geometry.sizing.ellipsoid_diameters_m` | empty | Absolute ellipsoid diameters. |
| `geometry.sizing.cylinder_diameter_m` | empty | Absolute cylinder diameter. |
| `geometry.sizing.cylinder_length_m` | empty | Absolute cylinder length. |
| `geometry.sizing.cylinder_axis` | `x` | Cylinder body axis. |
| `geometry.sizing.cylinder_length_to_diameter` | 2 | Blockage-mode aspect ratio. |
| `geometry.sizing.plate_dimensions_m` | empty | Absolute plate dimensions. |
| `geometry.sizing.plate_normalised_dimensions` | `[1;1;0.05]` | Blockage-mode plate proportions. |
| `geometry.sizing.custom` | struct | Custom proxy data. |
| `geometry.aero_reference_area.mode` | `projected_nominal` | Projected or manual S. |
| `geometry.aero_reference_area.value_m2` | empty | Manual S. |
| `geometry.aero_reference_length.mode` | `characteristic_default` | Default or manual c. |
| `geometry.aero_reference_length.value_m` | empty | Manual c. |
| `geometry.aero_reference_span.mode` | `characteristic_default` | Default or manual b. |
| `geometry.aero_reference_span.value_m` | empty | Manual b. |
| `geometry.aero_reference_point_B_m` | zero | Aero wrench reference point in B. |
| `geometry.custom_plot_vertices_B_m` | empty | Optional custom plot vertices. |
| `geometry.custom_plot_faces` | empty | Optional custom plot faces. |

### Magnets and mass

| Field | Default | Meaning |
|---|---:|---|
| `magnets.mode` | `automatic` | Automatic single-magnet candidates or manual sets. |
| `magnets.remanence_selection` | `nominal` | Nominal/minimum/maximum/manual Br. |
| `magnets.manual_Br_T` | empty | Manual Br. |
| `magnets.check_containment` | true | Check magnets lie inside supported volume. |
| `magnets.automatic.grade` | `N52` | Grade lookup. |
| `magnets.automatic.linear_shrink_fraction` | 0 | Uniform shrink from max fit. |
| `magnets.automatic.centre_offset_B_m` | zero | Automatic magnet offset. |
| `magnets.automatic.effective_magnetisation_factor` | 1 | Dipole scaling factor. |
| `magnets.automatic.direction_candidates_B` | `eye(3)` | Candidate magnetisation directions. |
| `magnets.automatic.dipole_moment_override_Am2` | empty | Optional measured/forced dipole. |
| `magnets.sets` | empty | Manual magnet-set array. |
| `mass.shell_mass_factor` | 1.30 | Total/magnet mass factor for default hybrid model. |
| `mass.total_mass_override_kg` | empty | Total mass override. |
| `mass.centre_of_mass_override_B_m` | empty | CoM override. |
| `mass.inertia_override_B_kgm2` | empty | Body-frame inertia override. |

### Aerodynamics, scenarios and motion

| Field | Default | Meaning |
|---|---:|---|
| `aero.mode` | `coefficients` | Coefficients or direct wrench. |
| `aero.CD` | 0 | Default drag coefficient. |
| `aero.CY` | 0 | Default side-force coefficient. |
| `aero.CL` | 0 | Default lift coefficient. |
| `aero.Cl_roll` | 0 | Default rolling-moment coefficient. |
| `aero.Cm` | 0 | Default pitching-moment coefficient. |
| `aero.Cn` | 0 | Default yawing-moment coefficient. |
| `aero.direct_wrench_frame` | `T` | Default E/T/B frame for dimensional aero. |
| `scenarios` | empty table | Exact simultaneous physical states. |
| `max_scenarios` | 4096 | Safety limit on rows. |
| `motion.mode` | `none` | None, specified or harmonic. |
| `motion.frame` | `T` | Frame for specified kinematics. |
| `motion.harmonic.frequency_Hz` | 1 | Harmonic frequency. |
| `motion.harmonic.translation_amplitude_m` | zero | Body-axis translation amplitudes. |
| `motion.harmonic.translation_phase_rad` | zero | Translation phases. |
| `motion.harmonic.angular_amplitude_rad` | zero | `[roll;pitch;yaw]` amplitudes. |
| `motion.harmonic.angular_phase_rad` | zero | Angular phases. |
| `motion.harmonic.samples_per_cycle` | 72 | Auto-generated harmonic rows when scenarios are empty. |
| `additional_wrenches` | empty table | Optional static external wrenches. |

### Magnetic, validation, visualisation and output

| Field | Default | Meaning |
|---|---:|---|
| `magnetic.model` | `source_free_first_order` | Point-dipole/first-order field model. |
| `magnetic.field_scale_T` | 0.10 | Field scale in minimum-norm objective. |
| `magnetic.gradient_scale_Tpm` | 1.0 | Frobenius-gradient scale in objective. |
| `magnetic.acceptance_relative_residual` | 1e-6 | Dimensionless numerical controllability threshold. |
| `magnetic.condition_warning_threshold` | 1e10 | Map-conditioning warning level. |
| `magnetic.advisory_B_max_T` | empty | Optional user advisory field level. |
| `magnetic.advisory_G_max_Tpm` | empty | Optional user advisory gradient level. |
| `magnetic.minimum_force_scale_N` | 1e-9 | Numerical floor for wrench scaling. |
| `magnetic.minimum_moment_scale_Nm` | 1e-9 | Numerical floor for moment scaling. |
| `validation.rotation_tolerance` | 1e-10 | Rotation check tolerance. |
| `validation.gradient_tolerance` | 1e-10 | Maxwell-gradient check tolerance. |
| `validation.blockage_advisory_limit` | 0.15 | Advisory nominal blockage. |
| `visualisation.enable` | true | Save figures. |
| `visualisation.plot_worst_case` | true | Save worst case per set. |
| `visualisation.vector_scale_mode` | `normalised` | Vector display mode. |
| `visualisation.save_magnetic_field_plot` | true | Save local field plot. |
| `output.enable` | true | Enable result folder. |
| `output.root_folder` | `results` | Root output folder. |
| `output.save_fig` | false | Also save MATLAB `.fig`. |
| `output.overwrite_existing` | false | Protect prior run folder. |
