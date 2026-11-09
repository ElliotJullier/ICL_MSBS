# MSBS study decisions and handoff

This portfolio estimates local magnetic field and gradient requirements for a stingless wind-tunnel balance. The PDF is the entry point. Its Useful Results section gives the targets, followed by installation and hardware choices, mass sensitivity and the working from the literature. The data archive includes the exact MATLAB inputs and CAD figures.

## Aerodynamic scope

- Size models for square 0.6 m and 1 m test sections with horizontal or upward flow. Blockage is the maximum projected area over the tested attitudes, divided by tunnel area. Use 3%, 10% and 20% as geometric sizing targets. Hold each geometry fixed across its attitude sweep and omit wall corrections in this sizing study.
- Preserve the source reference geometry, coefficients and Reynolds numbers. Find the model size from geometry and blockage, then solve for speed at the source Reynolds number. Keep states from 5 to 50 m/s. A larger tunnel can admit more cases at matched Re. A lower speed or shorter span needs a new applicability check before borrowing aerodynamic coefficients.
- The steady portfolio covers sphere drag, a six-axis cuboid, a six-axis yawed Ahmed body, a NACA 0012 wing and parked-cylinder drag. The report's source working records the data locations, reference lengths, coordinate transformations and moment shifts. The parked cylinder uses Ajmal et al. Table 2 mean drag at the measured Reynolds numbers and retains span/diameter 3.2.
- The prescribed transverse air-cylinder study uses Blackburn and Melbourne Fig. 7 signed RMS lift components at Re 160,000 and span/diameter 4.5. Recover the phase-dependent lift with the velocity and acceleration terms, scaled by sqrt(2). Apply it coherently over the span and add the article inertia separately. Screen peak acceleration at a provisional 50 m/s². Preserve the amplitude ratio and reduced velocity when scaling. Use this result for the specified transverse load. Residual lift and drag need simultaneous measurements before they can enter a full wrench.

## Frames, hardware and target selection

- The tunnel frame uses +x downstream and +z upward in the horizontal installation. Gravity acts along −z in the horizontal tunnel and −x in the upward tunnel. Resolve target fields and gradients in tunnel axes. Shift applied moments to the assembly centre of mass C.
- In steady states, C coincides with the fixed tunnel origin O. The steady targets show one field vector there. The local field metric is the greatest field magnitude among the installed magnet centres. The constant affine gradient uses `G_ij = dB_i/dx_j` everywhere in the modelled region. In a moving history, `B(O) = B(C) − G r_C` for displacement `r_C` from O to C. Retain both fields in the raw data for motion and coil-interface work.
- The driven cylinder gradient delivers `m a − F_aero − m g`. The selected driven arrangements use a centred dipole with zero torque demand. Their solved field at the magnet is zero, so the driven target export contains gradients. The raw histories retain the nonzero fixed-origin field where applicable, and keep the original internal operating-group IDs for joins.
- Cap the whole installed magnet assembly, including spacing, at 0.30 times the tunnel side on each evaluated axis. V100 is the capped fit of the layout. V10 uses 10% of that layout's V100 volume at the same auxiliary centre positions. Oblique blocks rotate inside the true model envelope. Smaller auxiliary dipoles use opposed polarities to let gradients supply roll in either direction or zero roll. Cuboid and Ahmed candidates must span all six wrench directions. The wing includes body +x, a 30° chordwise tilt and alignment with tunnel +x at the last attitude among its tested candidates.
- Choose fixed hardware for the primary results. For each feasible set, evaluate its worst RMS-field score over the campaign, then choose the set with the lowest such peak. One campaign means family, tunnel, orientation, blockage and volume policy, including the full speed and attitude grid or all phases of all retained histories. Use the independent selection only when the test plan actually permits a hardware swap between trials.
- Use the longest model dimension as the RMS score's cube side. The sensitivity study varies it and measures the cost of keeping the original winner when rankings change. The score combines field and gradient with a shared tesla scale for comparing local solutions. Coil geometry determines which modes are available and how much current each mode takes.
- Report maxima and observed nearest-rank P90 independently for each metric, installation and volume, with controlling case and state. Weight each steady state equally. For driven histories use one peak per metric and history. The signed value in the target CSV links to the simultaneous wrench in the raw selection. Different component maxima can come from different states.

## Mass assumptions

- Use 540 kg/m³ as the effective density of solid foamed LW-PLA. Remove the oriented cavities, add the N52 magnets at 7,500 kg/m³ and recompute mass, centre of mass and inertia about the assembly centre of mass. The geometry is a solid density proxy for sizing. A printable shell and support structure require their own mass properties.
- Run the 25 kg study separately with the same outer dimensions, aerodynamic loads, material density, auxiliary centre positions and magnet directions. Reduce the magnet volume and treat the vacated cavity volume as LW-PLA. The floor is 10% of the largest capped V100 candidate volume for that geometry. It differs from baseline V10, which is layout-relative. Flag the body-only failures and cases below the magnet-volume floor.

## Reproduce and verify

From `MatLab/msbs_requirement_tool` in MATLAB R2025b:

```matlab
runAllTests
addpath('research')
run_standalone_portfolio
```

From the same directory in a shell with Python, NumPy, pandas, Pillow and ReportLab:

```text
python research/scripts/build_standalone_report.py
```

The MATLAB run writes `research/outputs/standalone`. The archived run contains 120 campaigns, 23,396 candidate rows, 3,348 fixed-hardware state rows and 51 MATLAB figures. `standalone_run.log` records 83 passing MATLAB tests and the solver run. The report builder reads the exports and regenerates the PDF, figure SVGs and derived target CSVs. The presentation pass verified the steady field equality, the driven local field and the published target values against the archived numerical results.

- Start from `coverage.csv` for admissibility, `inputs/*.mat` for run configs and `selected_primary.csv` for signed solved states. `useful_results_max_p90.csv` and `driven_history_max_p90.csv` carry the per-metric targets.
- Use `candidate_hardware_peaks.csv`, `hardware_rankings.csv` and `reference_length_layout_changes.csv` to trace candidate and score decisions. The CAD archive contains MATLAB FIGs and PNG previews.
- Use `mass_cap_campaigns.csv` for the separate pass/fail results, and the candidate and selected CSVs for the floor, cap and re-solved state checks.
- For the next extension, obtain matched-Re six-axis loads for any added Ahmed operating range, and phase-synchronised air loads with a still-air inertial tare for a complete cylinder wrench. For coil design, map the field and gradient modes per ampere in the working region, then evaluate the simultaneous state requirements against the real current and thermal limits.
