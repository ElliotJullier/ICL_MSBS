# User guide

## 1. What the program calculates

The program follows this sequence:

1. Resolve every input and default in SI units.
2. Build the tunnel, Earth/tunnel/body/wind frames, and model geometry.
3. Fit the supported inscribed cuboid and create automatic or manual magnet sets.
4. Calculate hybrid magnet-plus-shell mass, centre of mass, and inertia.
5. Generate simultaneous physical scenarios from speed, coefficients, attitudes, wind directions, and motion cases.
6. Calculate aerodynamic, gravity, additional, and rigid-body inertial demands about the model centre of mass.
7. Form the required magnetic wrench from Newton–Euler balance.
8. Build the first-order magnetic influence matrix for each magnet set and attitude.
9. Solve for applied field and source-free field gradient using a dimensionally scaled minimum-norm calculation.
10. Report residuals, controllability, envelopes, figures, and reproducible files.

The program calculates requirements. It does not calculate a coil geometry, current, voltage, temperature, control law, or finite-element field.

## 2. Coordinate frames and signs

All reported force, moment, field, and gradient components are in the tunnel frame unless a name states otherwise.

- **Earth E:** `+z_E` upward; gravity is `[0;0;-g]`.
- **Tunnel T:** `+x_T` nominally downstream, `+y_T` lateral, `+z_T` completes a right-handed frame.
- **Body B:** fixed to the model.
- **Wind W:** `+x_W` downstream, `+z_W` positive lift, `+y_W` completes the right-handed frame.

`R_AB` maps components from B into A. Body attitude is intrinsic Z-Y-X yaw-pitch-roll:

```text
R_TB = Rz(yaw) Ry(pitch) Rx(roll)
```

For a body-fixed point, translation and rotation are both applied. Free vectors are rotated but never translated. Wrenches are shifted by adding `r × F` to the moment.

## 3. Core configuration reference

The table below covers every user-facing field in `defaultConfig.m`. Fields can be omitted when the default is appropriate; the resolved configuration saved after each run shows the final value used.

### 3.1 Identity, tunnel, and air

| Field | Type / units | Required | Default | Meaning |
|---|---|---:|---|---|
| `meta.case_id` | string | No | `unnamed_case` | Folder-safe study identifier. |
| `meta.description` | string | No | generic | Human-readable description. |
| `tunnel.cross_section.type` | `rectangular` or `circular` | Yes | rectangular | Test-section shape. |
| `tunnel.cross_section.width_m` | m | rectangular | 0.60 | Tunnel width. |
| `tunnel.cross_section.height_m` | m | rectangular | 0.60 | Tunnel height. |
| `tunnel.cross_section.diameter_m` | m | circular | empty | Circular diameter. |
| `tunnel.speed` | range struct, m/s | Yes | 0 | Nominal and optional range. |
| `tunnel.air.mode` | `density` or `ideal_gas` | No | density | Air-property method. |
| `tunnel.air.rho_kgm3` | kg/m³ | density | 1.225 | Direct density. |
| `tunnel.air.pressure_Pa` | Pa | ideal gas | 101325 | Absolute pressure. |
| `tunnel.air.temperature_K` | K | ideal gas | 288.15 | Absolute temperature. |
| `tunnel.air.R_air_JpkgK` | J/(kg K) | No | 287.05 | Ideal-gas helper constant. |

### 3.2 Frames

| Field | Type / units | Default | Meaning |
|---|---|---|---|
| `frames.tunnel_to_earth.yaw_pitch_roll_deg` | 1×3 deg | `[0 0 0]` | Orientation of T in E. |
| `frames.body_to_tunnel.yaw_pitch_roll_deg` | 1×3 deg | `[0 0 0]` | Nominal orientation of B in T. |
| `frames.body_origin_T_m` | 3×1 m | zero | Body-origin position in T. |
| `frames.wind_to_tunnel.R_TW` | 3×3 | identity | Wind axes in tunnel components. |
| `frames.body_attitude_cases(i).name` | string | nominal | Named attitude factor. |
| `frames.body_attitude_cases(i).yaw_pitch_roll_deg` | 1×3 deg | nominal | Named attitude using Euler angles. |
| `frames.body_attitude_cases(i).R_TB` | 3×3 | optional | Explicit named attitude. |
| `frames.wind_orientation_cases(i).name` | string | nominal | Named wind factor. |
| `frames.wind_orientation_cases(i).R_TW` | 3×3 | identity | Named wind orientation. |

### 3.3 Geometry

| Field | Type / units | Default | Meaning |
|---|---|---|---|
| `geometry.type` | primitive name | sphere | `cuboid`, `sphere`, `ellipsoid`, `cylinder`, `flat_plate`, or `custom`. |
| `geometry.sizing.mode` | `blockage` or `absolute` | blockage | Sizing method. |
| `geometry.sizing.blockage_ratio` | fraction | 0.10 | Target nominal projected-area ratio. |
| `geometry.sizing.nominal_dimensions_m` | 3×1 relative or m | `[1;1;1]` | Cuboid dimensions; ellipsoid relative diameters in blockage mode. |
| `geometry.sizing.diameter_m` | m | empty | Absolute sphere diameter. |
| `geometry.sizing.radius_m` | m | empty | Alternative sphere radius. |
| `geometry.sizing.ellipsoid_diameters_m` | 3×1 m | empty | Absolute ellipsoid diameters. |
| `geometry.sizing.cylinder_diameter_m` | m | empty | Absolute cylinder diameter. |
| `geometry.sizing.cylinder_length_m` | m | empty | Absolute cylinder length. |
| `geometry.sizing.cylinder_axis` | x/y/z | x | Cylinder axis in B. |
| `geometry.sizing.cylinder_length_to_diameter` | ratio | 2 | Blockage-mode cylinder aspect ratio. |
| `geometry.sizing.plate_dimensions_m` | 3×1 m | empty | Absolute finite-thickness plate. |
| `geometry.sizing.plate_normalised_dimensions` | 3×1 | `[1;1;0.05]` | Blockage-mode plate ratios. |
| `geometry.sizing.custom` | struct | empty | Custom proxy data described below. |
| `geometry.aero_reference_area.mode` | projected/manual | projected | Coefficient reference area. |
| `geometry.aero_reference_area.value_m2` | m² | empty | Manual area. |
| `geometry.aero_reference_length.mode` | default/manual | default | Moment reference length. |
| `geometry.aero_reference_length.value_m` | m | empty | Manual length. |
| `geometry.aero_reference_point_B_m` | 3×1 m | zero | Point about which coefficient moment is defined. |

A custom proxy must provide outer dimensions, nominal projected area, volume, and inscribed-cuboid dimensions. It can optionally provide plot vertices/faces. No mesh optimisation is performed.

### 3.4 Magnets

| Field | Type / units | Default | Meaning |
|---|---|---|---|
| `magnets.mode` | automatic/manual_sets | automatic | Magnet input method. |
| `magnets.remanence_selection` | nominal/minimum/maximum/manual | nominal | Which CSV remanence value to use. |
| `magnets.manual_Br_T` | T | empty | Used only for manual remanence. |
| `magnets.check_containment` | logical | true | Validate magnet cuboid against geometry proxy. |
| `magnets.automatic.grade` | string | N52 | CSV grade. |
| `magnets.automatic.linear_shrink_fraction` | fraction | 0 | Fraction removed from every fitted length. |
| `magnets.automatic.centre_offset_B_m` | 3×1 m | zero | Offset from fitted-cuboid centre. |
| `magnets.automatic.effective_magnetisation_factor` | dimensionless | 1 | Engineering reduction factor. |
| `magnets.automatic.direction_candidates_B` | 3×N | identity | Candidate unit directions as columns. |
| `magnets.automatic.dipole_moment_override_Am2` | A m² | empty | Direct magnitude override. |
| `magnets.sets` | struct array | empty | Explicit manual arrangements. |

Each manual magnet contains dimensions, body-frame centre, `R_BM`, grade, local magnetisation direction, effective factor, and optional dipole/density overrides.

The delivered N52 data are generic placeholders with Magnet Store as the anticipated supplier. Edit `data/magnet_grades.csv` when the exact part and datasheet are known.

### 3.5 Mass

| Field | Units | Default | Meaning |
|---|---|---|---|
| `mass.shell_mass_factor` | dimensionless | 1.30 | Default total mass divided by summed magnet mass. |
| `mass.total_mass_override_kg` | kg | empty | Measured or designed total mass. |
| `mass.centre_of_mass_override_B_m` | m | empty | Direct CoM. |
| `mass.inertia_override_B_kgm2` | kg m² | empty | Symmetric positive-definite tensor. |

The default hybrid model calculates each magnet cuboid explicitly. The remaining total mass is distributed uniformly through the outer primitive. The combined CoM and inertia include parallel-axis shifts. This is still an approximation because the distributed shell overlaps the magnet volume mathematically.

### 3.6 Aerodynamics and motion

| Field | Type / units | Default | Meaning |
|---|---|---|---|
| `aero.CD`, `aero.CL`, `aero.Cm` | range structs | zero | Drag, lift, and pitch-moment coefficients. |
| `motion.mode` | named mode | none | Motion input method. |
| `motion.direct_kinematics_cases` | table | empty | Acceleration, omega, alpha, frame. |
| `motion.harmonic.frequency_Hz` | Hz | 1 | Common harmonic frequency. |
| `motion.harmonic.translation_amplitude_m` | 3×1 m | zero | Translational displacement amplitude. |
| `motion.harmonic.translation_phase_rad` | scalar/3×1 rad | zero | Translation phases. |
| `motion.harmonic.angular_amplitude_rad` | 3×1 rad | zero | `[roll; pitch; yaw]` small-angle amplitude. |
| `motion.harmonic.angular_phase_rad` | scalar/3×1 rad | zero | Angular phases. |
| `motion.harmonic.samples_per_cycle` | integer | 72 | Phase samples. |
| `motion.time_history` | table | empty | Time-resolved kinematics and optional attitude. |
| `motion.direct_required_wrench` | table | empty | Direct rigid-body inertial demand. |

Harmonic angular displacement updates the body attitude at every phase. Angular velocity and acceleration are transformed into T and the moment demand includes both `I alpha` and `omega × (I omega)`.

Time-history rows may include absolute `yaw_deg`, `pitch_deg`, `roll_deg` or a cell containing `R_TB`. When omitted, the selected body-attitude case is retained.

### 3.7 Scenarios, magnetic solve, and output

| Field | Default | Meaning |
|---|---|---|
| `combinations.strategy` | full_factorial | Endpoint Cartesian product or explicit correlated rows. |
| `combinations.include_nominal_case` | true | Add one scalar-nominal case. |
| `combinations.max_cases` | 4096 | Hard stop before expansion. |
| `combinations.user_scenarios` | empty table | Explicit correlated scenarios. |
| `magnetic.field_scale_T` | 0.10 T | Field scale in the minimum-norm metric. |
| `magnetic.gradient_scale_Tpm` | 1 T/m | Gradient scale in the metric. |
| `magnetic.acceptance_relative_residual` | 1e-6 | Dimensionless controllability threshold. |
| `magnetic.condition_warning_threshold` | 1e10 | Map-conditioning warning. |
| `magnetic.advisory_B_max_T` | empty | Optional flag only. |
| `magnetic.advisory_G_max_Tpm` | empty | Optional flag only. |
| `validation.blockage_advisory_limit` | 0.15 | Warning threshold. |
| `visualisation.enable` | true | Generate figures. |
| `visualisation.plot_worst_case` | true | Save worst-effort figures. |
| `output.enable` | true | Save result package. |
| `output.root_folder` | results | Output root. |
| `output.save_fig` | false | Also save MATLAB `.fig`. |
| `output.overwrite_existing` | false | Preserve earlier runs. |

## 3.8 Table input schemas

The vector-valued table inputs use separate numeric columns so they remain readable in MATLAB and CSV-style workflows.

### Direct kinematics and time history

Required columns are `a_x`, `a_y`, `a_z` (m/s²), `omega_x`, `omega_y`, `omega_z` (rad/s), and `alpha_x`, `alpha_y`, `alpha_z` (rad/s²). Optional columns are:

- `case_name`: readable row name;
- `frame`: `E`, `T`, `B`, or `W`, default `T`;
- `time_s`: time-history timestamp;
- `yaw_deg`, `pitch_deg`, `roll_deg`: absolute row attitude; or
- `R_TB`: a cell-column containing absolute 3×3 rotation matrices.

The attitude columns are used only in `time_history` mode. When omitted, the selected named body-attitude case is retained.

### Direct inertial demand

Required columns are `F_x`, `F_y`, `F_z` (N) and `M_x`, `M_y`, `M_z` (N m). Optional columns are `case_name` and `frame`. The wrench is interpreted about the model centre of mass.

### Additional static wrenches

Required columns are `name`, `Fx_N`, `Fy_N`, `Fz_N`, `Mx_Nm`, `My_Nm`, `Mz_Nm`, `components_frame`, and `reference_point_B_m`. Each reference point is a 3-vector stored in a table cell. Forces and moments are rotated from `components_frame`, then shifted from the stated body-fixed point to the centre of mass.

### User-defined correlated scenarios

`scenario_name` is required. Optional columns are `speed_mps`, `CD`, `CL`, `Cm`, `body_attitude_case`, `wind_orientation_case`, and `motion_case`; omitted values use the corresponding nominal or first named case. An additional-wrench row named `cable load` is scaled with a scenario column named `scale_cableLoad` after MATLAB identifier sanitisation.

## 3.9 Residual threshold guidance

`acceptance_relative_residual` is a dimensionless numerical controllability criterion:

```text
||scaled unachieved wrench|| / ||scaled requested wrench||
```

The study uses one force scale and one moment scale across every scenario and magnet set, so residuals can be compared consistently. Typical interpretation:

| Threshold | Interpretation |
|---:|---|
| `1e-6` | Strict numerical reproduction; recommended default. |
| `1e-4` | Looser numerical screening where conditioning is difficult. |
| `1e-3` | Approximately a 0.1% scaled-wrench mismatch; use only deliberately. |

This is not a component-by-component percentage, sensor accuracy, mechanical safety factor, or hardware feasibility limit. A set is called **residual-accepted**, not feasible, only when every scenario passes.

## 3.10 Authoritative complete field matrix

This matrix lists every field in `defaultConfig.m`. “Conditional” means the field is required only for the selected mode.

| Field | Type / units | Required | Default | Meaning |
|---|---|---|---|---|
| `meta.case_id` | string | No | `unnamed_case` | Study and output-folder identifier. |
| `meta.description` | string | No | `MSBS requirement study` | Readable study description. |
| `tunnel.cross_section.type` | enum | Yes | `rectangular` | `rectangular` or `circular`. |
| `tunnel.cross_section.width_m` | m | Rectangular | `0.60` | Rectangular test-section width. |
| `tunnel.cross_section.height_m` | m | Rectangular | `0.60` | Rectangular test-section height. |
| `tunnel.cross_section.diameter_m` | m | Circular | empty | Circular test-section diameter. |
| `tunnel.speed` | range struct, m/s | Yes | 0 nominal | Tunnel-speed range. |
| `tunnel.air.mode` | enum | No | `density` | Direct density or ideal-gas helper. |
| `tunnel.air.rho_kgm3` | kg/m³ | Density mode | `1.225` | Direct air density. |
| `tunnel.air.pressure_Pa` | Pa absolute | Ideal-gas mode | `101325` | Air pressure. |
| `tunnel.air.temperature_K` | K | Ideal-gas mode | `288.15` | Air temperature. |
| `tunnel.air.R_air_JpkgK` | J/(kg K) | Ideal-gas mode | `287.05` | Specific gas constant. |
| `frames.tunnel_to_earth.sequence` | string | No | `ZYX` | Fixed supported Euler sequence. |
| `frames.tunnel_to_earth.yaw_pitch_roll_deg` | 1×3 deg | No | `[0 0 0]` | Orientation of T in E. |
| `frames.body_to_tunnel.sequence` | string | No | `ZYX` | Fixed supported Euler sequence. |
| `frames.body_to_tunnel.yaw_pitch_roll_deg` | 1×3 deg | No | `[0 0 0]` | Nominal orientation of B in T. |
| `frames.body_origin_T_m` | 3×1 m | No | zero | Body-origin translation in T. |
| `frames.wind_to_tunnel.R_TW` | 3×3 rotation | No | identity | Nominal wind axes in T. |
| `frames.body_attitude_cases` | struct array | No | one nominal case | Named body attitudes. |
| `frames.wind_orientation_cases` | struct array | No | one nominal case | Named wind orientations. |
| `geometry.type` | enum | Yes | `sphere` | Supported primitive or custom proxy. |
| `geometry.sizing.mode` | enum | Yes | `blockage` | `blockage` or `absolute`. |
| `geometry.sizing.blockage_ratio` | fraction | Blockage mode | `0.10` | Nominal projected-area ratio. |
| `geometry.sizing.nominal_dimensions_m` | 3-vector | Cuboid/ellipsoid | `[1;1;1]` | Absolute cuboid dimensions or blockage-mode shape ratios. |
| `geometry.sizing.diameter_m` | m | Absolute sphere | empty | Sphere diameter. |
| `geometry.sizing.radius_m` | m | Absolute sphere | empty | Alternative sphere radius. |
| `geometry.sizing.ellipsoid_diameters_m` | 3×1 m | Absolute ellipsoid | empty | Full ellipsoid diameters. |
| `geometry.sizing.cylinder_diameter_m` | m | Absolute cylinder | empty | Cylinder diameter. |
| `geometry.sizing.cylinder_length_m` | m | Absolute cylinder | empty | Cylinder length. |
| `geometry.sizing.cylinder_axis` | enum | Cylinder | `x` | Cylinder body axis. |
| `geometry.sizing.cylinder_length_to_diameter` | ratio | Blockage cylinder | `2.0` | Cylinder aspect ratio. |
| `geometry.sizing.plate_dimensions_m` | 3×1 m | Absolute plate | empty | Finite-thickness plate dimensions. |
| `geometry.sizing.plate_normalised_dimensions` | 3-vector | Blockage plate | `[1;1;0.05]` | Plate shape ratios. |
| `geometry.sizing.custom` | struct | Custom | empty | Custom proxy quantities. |
| `geometry.aero_reference_area.mode` | enum | No | `projected_nominal` | Default or manual coefficient area. |
| `geometry.aero_reference_area.value_m2` | m² | Manual area | empty | Manual coefficient reference area. |
| `geometry.aero_reference_length.mode` | enum | No | `characteristic_default` | Default or manual moment length. |
| `geometry.aero_reference_length.value_m` | m | Manual length | empty | Manual coefficient reference length. |
| `geometry.aero_reference_point_B_m` | 3×1 m | No | zero | Point for aerodynamic coefficient wrench. |
| `geometry.custom_plot_vertices_B_m` | N×3 m | No | empty | Optional absolute custom-proxy vertices. |
| `geometry.custom_plot_faces` | face index array | No | empty | Faces matching custom plot vertices. |
| `magnets.mode` | enum | Yes | `automatic` | Automatic or explicit set definitions. |
| `magnets.remanence_selection` | enum | No | `nominal` | Nominal/minimum/maximum/manual Br. |
| `magnets.manual_Br_T` | T | Manual Br | empty | Explicit remanence. |
| `magnets.check_containment` | logical | No | `true` | Enable primitive/proxy containment checks. |
| `magnets.automatic.grade` | string | Automatic | `N52` | Grade lookup key. |
| `magnets.automatic.linear_shrink_fraction` | fraction | Automatic | `0` | Reduction applied independently to every fitted length. |
| `magnets.automatic.centre_offset_B_m` | 3×1 m | Automatic | zero | Offset from fitted-cuboid centre. |
| `magnets.automatic.effective_magnetisation_factor` | dimensionless | Automatic | `1` | Engineering magnetisation factor. |
| `magnets.automatic.direction_candidates_B` | 3×N | Automatic | identity | Candidate magnetisation directions as columns. |
| `magnets.automatic.dipole_moment_override_Am2` | A m² | No | empty | Direct automatic-magnet dipole magnitude. |
| `magnets.sets` | struct array | Manual sets | empty | Explicit arrangements and magnets. |
| `mass.shell_mass_factor` | dimensionless | No | `1.30` | Default total mass divided by magnet mass. |
| `mass.total_mass_override_kg` | kg | No | empty | Direct total model mass. |
| `mass.centre_of_mass_override_B_m` | 3×1 m | No | empty | Direct body-frame CoM. |
| `mass.inertia_override_B_kgm2` | 3×3 kg m² | No | empty | Direct body-frame inertia tensor. |
| `aero.CD` | range struct | Yes | zero | Drag coefficient. |
| `aero.CL` | range struct | Yes | zero | Lift coefficient. |
| `aero.Cm` | range struct | Yes | zero | Pitch-moment coefficient. |
| `motion.mode` | enum | No | `none` | Motion/inertial input method. |
| `motion.direct_kinematics_cases` | table | Direct kinematics | empty | Acceleration, angular velocity, and angular acceleration cases. |
| `motion.harmonic.frequency_Hz` | Hz | Harmonic | `1` | Common oscillation frequency. |
| `motion.harmonic.translation_amplitude_m` | 3×1 m | Harmonic | zero | Displacement amplitudes. |
| `motion.harmonic.translation_phase_rad` | scalar/3×1 rad | Harmonic | zero | Translation phases. |
| `motion.harmonic.angular_amplitude_rad` | 3×1 rad | Harmonic | zero | `[roll; pitch; yaw]` angle amplitudes. |
| `motion.harmonic.angular_phase_rad` | scalar/3×1 rad | Harmonic | zero | Angular phases. |
| `motion.harmonic.samples_per_cycle` | integer | Harmonic | `72` | Phase resolution. |
| `motion.time_history` | table | Time history | empty | Kinematics and optional absolute attitude. |
| `motion.direct_required_wrench` | table | Direct demand | empty | Inertial force/moment demand about CoM. |
| `additional_wrenches` | table | No | empty | Additional body-fixed-point external wrenches. |
| `combinations.strategy` | enum | No | `full_factorial` | Factorial corners or correlated rows. |
| `combinations.include_nominal_case` | logical | Factorial | `true` | Retain all-nominal scalar case once. |
| `combinations.max_cases` | integer | No | `4096` | Expansion safety limit. |
| `combinations.user_scenarios` | table | User-defined | empty | Correlated scenario rows. |
| `magnetic.model` | enum | No | `source_free_first_order` | Fixed first-version magnetic model. |
| `magnetic.field_scale_T` | T | Yes | `0.10` | Field scale in solution metric. |
| `magnetic.gradient_scale_Tpm` | T/m | Yes | `1.0` | Gradient scale in solution metric. |
| `magnetic.acceptance_relative_residual` | dimensionless | Yes | `1e-6` | Residual-acceptance threshold. |
| `magnetic.condition_warning_threshold` | dimensionless | No | `1e10` | Condition-number warning level. |
| `magnetic.advisory_B_max_T` | T | No | empty | Optional field flag; not an optimiser constraint. |
| `magnetic.advisory_G_max_Tpm` | T/m | No | empty | Optional gradient flag; not an optimiser constraint. |
| `magnetic.minimum_force_scale_N` | N | No | `1e-9` | Safe lower bound for study force scale. |
| `magnetic.minimum_moment_scale_Nm` | N m | No | `1e-9` | Safe lower bound for study moment scale. |
| `validation.rotation_tolerance` | dimensionless | No | `1e-10` | Rotation orthogonality/determinant tolerance. |
| `validation.gradient_tolerance` | T/m numerical | No | `1e-10` | Source-free gradient validation tolerance. |
| `validation.blockage_advisory_limit` | fraction | No | `0.15` | High-blockage warning level. |
| `visualisation.enable` | logical | No | `true` | Generate figures. |
| `visualisation.plot_worst_case` | logical | No | `true` | Generate worst-effort scenario figures. |
| `visualisation.vector_scale_mode` | enum | No | `normalised` | Current vector display mode. |
| `visualisation.save_magnetic_field_plot` | logical | No | `true` | Save field/dipole direction figure. |
| `output.enable` | logical | No | `true` | Write a result package. |
| `output.root_folder` | path | Output enabled | `results` | Project-relative or absolute output root. |
| `output.save_fig` | logical | No | `false` | Also save MATLAB FIG files. |
| `output.overwrite_existing` | logical | No | `false` | Permit replacement of an identical timestamp folder. |

## 4. Blockage and reference areas

Blockage is calculated from the exact orthographic projection of the supported primitive at the first configured body/wind orientation. Blockage sizing uniformly scales all dimensions until the requested projection is reached.

The aerodynamic reference area and length are coefficient definitions. They remain fixed through attitude cases and are never replaced by an attitude-varying projected area.

## 5. Automatic magnet example

```matlab
cfg.magnets.mode = "automatic";
cfg.magnets.automatic.grade = "N52";
cfg.magnets.automatic.linear_shrink_fraction = 0.05;
cfg.magnets.automatic.direction_candidates_B = eye(3);
```

A shrink of 0.05 multiplies all three fitted lengths by 0.95. It does not mean a 5% volume reduction.

## 6. Two-magnet example

```matlab
m1.name = "front";
m1.dimensions_local_m = [0.04;0.02;0.02];
m1.centre_B_m = [0.04;0;0];
m1.R_BM = eye(3);
m1.grade = "N52";
m1.magnetisation_direction_M = [1;0;0];
m1.effective_magnetisation_factor = 1;
m1.dipole_moment_override_Am2 = [];
m1.density_override_kgm3 = [];

m2 = m1;
m2.name = "rear";
m2.centre_B_m = [-0.04;0;0];

cfg.magnets.mode = "manual_sets";
cfg.magnets.sets(1).name = "two_parallel";
cfg.magnets.sets(1).magnets = [m1 m2];
```

Define a second `sets(2)` entry to compare a different arrangement. The program does not silently vary manual magnets.

## 7. Physical scenarios versus envelopes

A scenario is one simultaneous combination. The default factorial strategy is conservative only when all corners can occur together. Use user-defined scenarios when coefficients, attitudes, or motion extrema are correlated.

A component-wise envelope reports independent minima/maxima. `Fx_max` and `My_max` can come from different scenario IDs. Use those IDs rather than treating an envelope vector as one physical case.

## 8. Interpreting magnetic outputs

- `B0_T`: common applied field at the CoM expansion point.
- `B_at_each_magnet_T`: first-order local field.
- `G_Tpm`: symmetric trace-free gradient.
- `scaled_solution_norm`: dimensionless comparison metric based on user scales; not coil power.
- `relative_scaled_residual`: dimensionless unachieved/requested wrench ratio after fixed force/moment scaling.
- `controllable`: true only below the configured threshold for that scenario.
- rank and singular values: available wrench-space diagnostics.

Set ranking first excludes any set whose worst residual exceeds the threshold. Among remaining sets it selects the smallest worst-case scaled solution norm. If none pass, no set is called best or feasible; rejected sets are ordered by residual first and scaled effort second so the least-uncontrollable option appears first without being mislabelled.

## 9. Model-validity limits

The calculation assumes point dipoles in a common externally applied first-order field in a current-free region. It excludes magnet self-field, magnet interactions, higher spatial derivatives, finite-volume force integration, saturation, demagnetisation, coil design, tunnel blockage corrections, CFD, flexible-body dynamics, and controller design.
