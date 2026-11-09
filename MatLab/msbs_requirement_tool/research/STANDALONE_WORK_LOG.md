# Standalone MSBS aerodynamic requirements handoff

## Scope and decisions

- Use the six papers uploaded on 9 November 2026 as technical evidence. Their content supplies experimental facts, coefficient data and caveats. The user instructions determine the study scope.
- Exclude the Re = 4,000 water cylinder and its high-acceleration screens from the active configuration grid, targets and distributions. Inline water data from Nishihara are cited for comparison only. The active flow window is 5–50 m/s, with a provisional 50 m/s² acceleration ceiling on the driven air comparison. The ceiling is a sizing assumption rather than a verified rig limit.
- Use 540 kg/m³ for the uniform solid LW-PLA proxy, from the foamed density in [eSUN's product data](https://www.esun3d.com/epla-lw-product). Subtract oriented cavities, add explicit NdFeB magnets and combine their CoM and inertia. The outer shape, projected area, effective density, magnet offsets and aerodynamic inputs are held fixed in the separate 25 kg calculation. The vacated magnet volume is treated as material in a resized cavity design.
- Use one fixed installed magnet set per campaign as the primary choice. A campaign is family, tunnel side, maximum blockage, gravity orientation and magnet-volume policy. Speed and attitude changes remain in the same campaign. A motion history is one operating group and all its phases use one arrangement. Swappable hardware is a planning comparison for independently mounted tests.
- For the separate mass limit, the minimum is 10% of the largest **capped** V100 candidate volume for each geometry. V10 in the baseline still means 10% of that particular layout's V100. Retain both ratios in the mass audit. Keep auxiliary centres and magnet directions when resizing. Reject cases where the solid body fills the allowance or every viable magnet falls below the minimum.

## Supplied papers and treatment

| Local source alias | DOI and verified evidence | Use |
|---|---|---|
| `ajmal.pdf` | [10.1016/j.jfluidstructs.2026.104658](https://doi.org/10.1016/j.jfluidstructs.2026.104658), PDF pp. 3–4, 7 and 13. AR 3.2, ten measured stationary Re/CD rows, forced sweep and uncertain absolute lift phase. | Use Table 2 mean drag at matched Re. Context for lock-in, hysteresis and spectra. |
| `blackburn.pdf` | [10.1006/jfls.1997.0086](https://doi.org/10.1006/jfls.1997.0086), printed pp. 416–418 and Fig. 7, p. 422. AR 4.5, Re 160k, signed acceleration/velocity-correlated RMS lift. | Digitise four drive states. Convert signed RMS to peak with sqrt(2). Simulate the retained coherent lift and body inertia. Residual lift and drag are outside this supplement. |
| `matsuda.pdf` | [10.1016/S0167-6105(02)00336-7](https://doi.org/10.1016/S0167-6105(02)00336-7), Table 1 and Figs. 3 and 5–9. Air, free inline response and end plates. | Motion and wake context. The paper does not give a phase-resolved drag history. |
| `nishihara.pdf` | [10.1016/j.jfluidstructs.2005.02.003](https://doi.org/10.1016/j.jfluidstructs.2005.02.003), Table 1, Eq. 9 and Fig. 8. Forced inline water at Re 17k and 34k, A/D 0.05. | Approximate frequency and phase reads as inline context. No water-force transfer to active cases. |
| `azadeh.pdf` | [10.1063/1.5042774](https://doi.org/10.1063/1.5042774), Table II. Air, two free ends and support-dependent response, resonance Re 844–2,946. | Short-span wake and lock-in context. |
| `li.pdf` | [10.1016/j.expthermflusci.2025.111488](https://doi.org/10.1016/j.expthermflusci.2025.111488), §2.2 and Fig. 10. Measured 35° Ahmed force comparison at Re 640k, with three published force components. | Compare force magnitudes at yaw 0° and 15°. Keep the Meile six-axis data in the sizing portfolio because the Li moments are missing. |

The remaining steady sources and coordinate transformations are in Section 09 of the report. The air-cylinder inputs are embedded in `airCylinderInputs.m`, with source figure and equation locations. The attachment audit explicitly distinguishes measured and omitted load components.

## Numerical results and verification

- 120 campaigns, 23,396 candidate rows, 3,348 fixed-hardware state rows, 51 MATLAB figures. The 0.6 m tunnel has 56 campaigns and the 1 m tunnel has 64. The difference comes from the larger models reaching the Meile Reynolds number under 50 m/s and the larger driven cylinders meeting the acceleration screen.
- Combined steady V100 max/P90 is 0.02526/0.004466 T local field and 0.3224/0.2198 T/m Frobenius gradient. Steady V10 max/P90 is 0.1845/0.02503 T and 2.055/0.7992 T/m. The driven transverse supplement reaches 2.186 T/m. The small wing controls the steady gradient and the small yaw-capable Ahmed controls the local field. The largest solid model is the 1 m/20% V100 sphere at 183.9066 kg.
- The independently swappable choice changes layouts within 56 campaigns. A fixed installation raises the peak RMS score in 19 of 120. The median increase is zero and the maximum is 13.68%. Layout changes with reference length are tabulated with the regret from keeping the original winner. The largest example is 27.17% for the 0.6 m upward 3% V10 cuboid at half model length.
- The 25 kg study passes 52 of 60 V100 geometry/installation combinations. All passing campaigns retain the same physical layout as the baseline. Of the eight failures, four are body-only failures and four are below the 10% magnet-volume floor. The 1 m/20% sphere and Ahmed fail on body-only mass. The 1 m/10% Ahmed and 1 m/20% parked cylinder fail the magnet-volume floor, in both orientations.
- MATLAB R2025b reports 83 passed, zero failed and zero incomplete. Verified candidate U and Re, the absence of Re 4,000 and water-force rows, 0.30H assembly limits, ≤50 m/s² in the driven comparison, and the cap/floor of every selected mass-limited design. The report was rendered and visually reviewed with PDFium, including table of contents, component pages, coil figure, statistical labels and source working.

## Reproduction and data

From `MatLab/msbs_requirement_tool` in MATLAB:

```matlab
runAllTests
addpath('research')
run_standalone_portfolio
```

From the same directory in a shell with Python, NumPy, pandas, Pillow and ReportLab:

```text
python research/scripts/build_standalone_report.py
```

The MATLAB function writes `research/outputs/standalone`. The report builder reads those CSVs and produces the single PDF, chart SVGs, observed nearest-rank component percentiles and case summaries. See the report's case index for file roles. `inputs/*.mat` holds exact baseline configs. The mass code scales each candidate inside the solved runner and exports candidate-level and selected per-state outputs. `standalone_run.log` records the final test and solver runs.

The OneDrive delivery includes the report, complete data and MATLAB FIG archive, code snapshot, the six supplied PDFs, and SHA-256 manifest. The PDF archive is kept in the user's workspace. Git carries the code, report and handoff.
