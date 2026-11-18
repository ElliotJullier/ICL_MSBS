# MSBS sizing at 15 and 35 m/s

The 17 November Rev6 FR7120 archive supplies the 30 original steady MATLAB configurations, the motion comparison and the published Sawada benchmark. The 1 m steady portfolio now runs at 15 and 35 m/s. For cylinder motion, the new speeds replace the original 50 m/s rows, with other speeds preserved for mass-compliant assemblies. The 60 cm Sawada benchmark uses the published conditions. Its equivalent speed inferred from the 2011 paper is 35.95 m/s.

## Decisions and interpretation

- Preserve the Rev6 geometry, blockage, attitudes, V100 and V25 policies and aerodynamic reference quantities. Apply the 25 kg limit to the entire installed assembly. Model the solid foam as FR-7120 at 320 kg/m³, subtract its magnet cavities and add the N52 magnets at 7,500 kg/m³. Screen each original candidate before the fixed-layout selection. Use the original candidate dimensions in both volume policies.
- Retain the Rev6 separation between the aerodynamic solution and each of the two gravity support biases. Rank mass-compliant layouts by the worst aerodynamic RMS score across both speeds and every attitude, requiring feasible gravity support in each installation. Cuboid and Ahmed additionally need rank six.
- Calculate Re at each speed. Use the archived Achenbach curve reads with log-Re interpolation for the sphere. Evaluate the other steady cases using the Rev6 source coefficients. The square-prism 3% and 10% cases at 15 m/s are below the measured Re range, and the applicable Reynolds flags mark coefficient transfers beyond the Rev6 factor-of-two comparison for the wing, Ahmed and cuboid.
- Keep the prescribed motion amplitude ratio and reduced velocity at the new speeds. The phase trace gives kinematics and body inertia. The transverse trace also gives the inertia-only axial gradient for the Rev6 dipole assumption. The available force sources lack the matching phase-resolved loads for these new drive points. Original source-based motion traces survive the mass screen.
- The Clark Y 17° orientation comparison has only tabulated inputs in Rev6. Apply the exact dynamic-pressure scaling of the feasible fixed-coefficient affine solutions for the two candidate orientations. Gravity support stays tied to the same pose and assembly mass.
- The magnetic maxima use the archived body-axis exterior dimensions `model_dimensions_B_m` to give bounding boxes in millimetres. The full envelope selects each signed field or Jacobian component by absolute magnitude. The results CSV also gives per-speed and per-volume maxima. The report lists aerodynamic field and gravity support separately, so combined requirements for a particular state use their signed simultaneous solutions from the case export.

## Reproduction

Unpack `2026-11-17_MSBS_50mps_Sizing_Rev6_FR7120.zip` and set `rev6Folder` to the directory containing the original PDF, tables and `inputs`. In MATLAB R2025b, from `MatLab/msbs_requirement_tool`:

```matlab
addpath('research')
run_rev6_speed_update(rev6Folder, outputFolder)
```

From the same directory in a shell with Python, NumPy, pandas, ReportLab and pypdf:

```text
python research/scripts/update_rev6_exports.py REV6_FOLDER OUTPUT_FOLDER
python research/scripts/build_rev7_sizing_report.py REV6_FOLDER OUTPUT_FOLDER
```

The MATLAB runner uses the existing requirement-tool solver and exports a 50 m/s reproduction alongside the requested speed solves for validation. The case export filters the active speeds to 15 and 35 m/s. The baseline check compares total mass, magnet volume, aerodynamic loads and the feasible magnetic solutions against the archive. Read `coverage.csv` for the 23 retained and seven excluded steady campaigns, `mass_screen.csv` for layout-level decisions, and `oscillating_cylinder_mass_exclusions.csv` for the motion mass screen. In the case CSV, `selected_fixed` identifies the single hardware layout retained across a campaign and `sizing_eligible` identifies individual candidate states that pass the mass and wrench checks. The mass screen and full results retain rejected candidates for traceability.
