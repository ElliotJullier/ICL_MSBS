# User guide — MSBS requirement tool v0.4.1

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
7. Diagnose field/gradient coupling and solve the minimum primary RMS-field magnetic requirement for every scenario/magnet-set combination.
8. Build scenario extrema plus fixed-configuration and independent-scenario rankings, then export all pointwise and summary results.

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

## 9. Magnetic solve, coupling and ranking

The physical magnetic map is

```text
x = [Bx By Bz gxx gyy gxy gxz gyz]'
w = A x
```

with a symmetric trace-free gradient. `A` is 6x8. Each column is the six-component wrench created by one unit physical field/gradient parameter for the current magnet geometry and attitude. A new map is built for every scenario/magnet-set combination because the current `R_TB` rotates magnet offsets and dipole moment vectors into T.

### Force/torque coupling diagnostic

Partition the map into field and gradient columns and force and moment rows. A uniform field cannot produce point-dipole force, so the force/field block is identically zero. The gradient/moment block is also zero for a centred magnet but becomes nonzero for offset or separated magnets because gradient-generated force acts through a moment arm and because the local field varies as `G*r`.

The program compares the gradient-generated moment block with the direct field-generated moment block after both are normalised to the same primary RMS-field cost. It records one of three classes per solved record:

- `zero`: coupling is below `magnetic.coupling.zero_ratio_tolerance`;
- `insignificant`: nonzero but no more than `magnetic.coupling.insignificant_ratio` (default 1/50) of direct field moment authority;
- `significant`: larger than that threshold.

This classification is a diagnostic, not a second physical model. The full 6x8 map is always solved. When the gradient/moment block is exactly zero, changing only the relative scalar field-versus-gradient weighting cannot change the physical least-squares solution because the force/gradient and moment/field subproblems are independent.

### Magnetic cost passed to `lsqminnorm`

The five independent gradient degrees of freedom are re-expressed in an orthonormal symmetric trace-free (STF) basis. If `q` contains those coordinates,

\[
\|q\|_2=\|G\|_F.
\]

The primary cost is the RMS affine-field magnitude over a centred isotropic reference cube whose side is the largest resolved model outer dimension, `Lref`. For `B(r)=B0+G r`, symmetry of the centred cube gives

\[
J^2 = \frac{1}{V}\int_V \|B_0+G r\|_2^2\,dV
     = \|B_0\|_2^2 + \frac{L_{ref}^2}{12}\|G\|_F^2.
\]

`J` has units tesla and is stored as `magnetic_cost_rms_T`. The corresponding mean vacuum magnetic-energy-density proxy is

\[
\bar u = \frac{J^2}{2\mu_0}.
\]

This is a local field-cost proxy, not actual coil stored energy or electrical power. A future coil model may instead optimise current, `0.5*I'*L*I`, copper loss, voltage, or related hardware quantities.

`lsqminnorm` itself still minimises the Euclidean norm of its solver unknown. The code changes variables so that the solver unknown is `[B0; (Lref/sqrt(12))*q]`; consequently its Euclidean norm is exactly `J`. Force and moment equations are separately nondimensionalised by the study-wide characteristic force and moment magnitudes before the least-squares solve.

### Significant-coupling sensitivity solves

If coupling is classified `significant` and sensitivity is enabled, the program repeats only the magnetic solve using two deliberately separate metric families. The physical loads and magnetic map are not recalculated.

**Relative B/G weighting family.** A single length `ell` sets the field/gradient trade-off:

\[
C_{rel}^2=\|B_0\|_2^2+ell^2\|G\|_F^2.
\]

The default `ell` values are `0.01, 0.1, 1 and 10 m`. This is a regularisation sensitivity only; it does not claim an energy or control-volume interpretation. Equivalently, dividing by `ell^2` gives `||B0||^2/ell^2+||G||F^2`, which selects the same physical solution for a fixed `ell`. The former tesla-valued form is stored because it uses the same solver-coordinate convention as the RMS-field metrics. The previous `B*=0.1 T`, `G*=1 T/m` weighting corresponds exactly to the single ratio `ell=B*/G*=0.1 m`; separate reference magnitudes are therefore unnecessary for this sensitivity family.

**Reference-volume family.** For a centred isotropic cube of side `Lref`,

\[
B_{rms}^2=\|B_0\|_2^2+\frac{L_{ref}^2}{12}\|G\|_F^2,
\]

with the default volumes `Lref=Lmodel`, `0.2*sqrt(tunnel area)` and `0.5*sqrt(tunnel area)`. Only these rows have the physical RMS-field / mean-vacuum-energy-density interpretation `ubar=B_rms^2/(2*mu0)`.

All seven alternatives are stored in `magnetic_cost_sensitivity.csv` for significantly coupled records, with `metric_type` identifying `relative_length` or `reference_volume_rms`. The primary `scenario_results.csv` remains one row per scenario/magnet set and continues to use `Lref=Lmodel`.

### Two ranking interpretations

Every scenario/magnet-set combination is solved pointwise first. No synthetic wrench is created from separate component extrema. The results then support two equally valid interpretations depending on the experiment:

1. **Fixed configuration / minimax:** when one magnet arrangement must cover all scenarios, each set is characterised by its maximum `J`; accepted sets are ranked by the smallest of those maxima.
2. **Independent scenarios:** when each unrelated scenario may use its own magnet arrangement, the lowest-cost acceptable set is selected separately for every scenario and scenarios are then ranked hardest-first by that best achievable `J`.

## 10. Outputs

`scenario_results.csv` contains one primary row per scenario and magnet set, including separate aerodynamic, gravity, other and inertial contributions; the required magnetic wrench; `B0`; all six unique physical gradient components; local-field and Frobenius-gradient metrics; coupling class/ratio; primary RMS-field cost; mean vacuum energy-density proxy; residuals; map rank and condition number; plus scenario metadata.

`scenario_extrema.csv` identifies the actual scenario producing each absolute force/moment-component extreme and each force/moment, field, gradient, cost and residual maximum. Component maxima are never combined into a fictitious load case.

`magnet_set_summary.csv` contains per-set envelopes. `fixed_configuration_ranking.csv` contains the minimax fixed-hardware ranking. `independent_scenario_ranking.csv` contains the hardest-first independent-scenario ranking. If significant coupling triggered alternate solves, `magnetic_cost_sensitivity.csv` stores those compact pointwise alternatives. `results_full.mat` retains all full-precision matrices, local magnet fields and intermediate records.

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
| `magnetic.cost.primary_mode` | `model_characteristic_cube_rms` | Primary RMS-field cost using a centred cube with side equal to the largest model dimension. |
| `magnetic.cost.sensitivity_when_significant` | true | Run alternate relative-length and reference-volume solves only for significantly coupled maps. |
| `magnetic.cost.sensitivity_relative_length_scales_m` | `[0.01 0.10 1 10]` m | Relative B/G regularisation lengths `ell` for significant-coupling sensitivity. |
| `magnetic.cost.sensitivity_tunnel_length_fractions` | `[0.20 0.50]` | Alternate cube sides as fractions of `sqrt(tunnel area)`. |
| `magnetic.coupling.zero_ratio_tolerance` | 1e-10 | Dimensionless threshold for effectively zero gradient-to-moment coupling. |
| `magnetic.coupling.insignificant_ratio` | 1/50 | Dimensionless threshold below which nonzero coupling is labelled insignificant. |
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

## Research study extensions (6 November 2026)

| Field | Default | Meaning |
|---|---|---|
| `mass.non_magnet_mass_kg` | empty | Optional fixed residual model mass. Total mass is this plus the resolved magnet mass; mutually exclusive with total-mass override. Empty preserves the legacy shell-factor calculation. |
| `mass.solid_abs_density_kgm3` | empty | Optional bulk density in kg/m³. The tool subtracts each checked, disjoint magnet cavity from the solid body, adds its magnet, and computes the centre of mass and inertia. Requires containment checking and excludes mass property overrides. Custom shapes supply `solid_centroid_B_m` and `solid_unit_density_inertia_B_m5` about the solid centroid. |
| `scenario_set.relationship` | `fixed_envelope` | `independent`, `fixed_envelope`, or `time_history`. Both rankings remain exported; use the fixed ranking for immutable hardware. Histories require finite, strictly increasing time within optional `scenario_group_id`. |
| `position.mode` | `nominal` | `nominal`, `specified`, or `harmonic_analytic`. No implicit integration. |
| `position.reference_C_T_m` | `[0;0;0]` m | Absolute reference CoM in tunnel axes, independent of plotting body origin and magnet-set CoM in B. |

For `specified` position, supply scenario columns `x_C_T_m`, `y_C_T_m`, `z_C_T_m` in metres; optional `vx_C_T_mps`, `vy_C_T_mps`, `vz_C_T_mps` must be supplied together. Position columns denote absolute CoM, not body origin. `harmonic_analytic` is restricted to pure translational harmonic motion and follows the existing helper's fixed B translation axes; it rejects simultaneous angular oscillations. Known harmonic position and velocity are calculated analytically. Numerical acceleration integration is deferred.

Scenario attitude may alternatively use the cell column `attitude_R_TB`, with one proper 3-by-3 rotation per row. It cannot be combined with Euler-angle columns or generated harmonic attitude. This permits explicit source-frame conversion without Euler sign ambiguity or gimbal singularities.

The local field remains `Bx_T,By_T,Bz_T` at the instantaneous CoM. The new `BOx_T,BOy_T,BOz_T` columns are the fixed-tunnel-origin intercept, `B_O=B_C-G*r_C`, of the same affine field. One common tensor G is exported. This is an affine reference conversion, not a measured global coil field. Results now include total mass, fixed residual mass, magnet volume, absolute CoM and scenario relationship.

The constructors and reproducible batch runner in `research` implement the literature study without replacing legacy cases. See the research report for evidence tiers, source transcriptions, geometry rejections and the assumptions behind coefficient transfer across Reynolds numbers/blockages.
