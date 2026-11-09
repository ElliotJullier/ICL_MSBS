# Aerodynamic requirements research - 6 November 2026

Read `MSBS_Aerodynamic_Requirements_Report.pdf` for the complete working, assumptions, per-component targets and every study comparison. The matching Markdown is editable source text. Results are conditional engineering screens; see the evidence tiers in the report.

## Reproduce

From the requirement-tool folder in MATLAB:

```matlab
runAllTests
addpath('src','cases','research')
run_portfolio
audit_geometry_and_resolution
```

The constructor is `msbsstudy.makeCase(family,H,blockage,orientation,volumeFraction)`. Families are `sphere`, `cuboid`, `ahmed`, `naca0012`, `sc20714`, `cylinder_crossflow`, `cylinder_inline`; H is 0.6 or 1 m, orientation is `h` or `up`, and volumeFraction is 1 or 0.1. The sixth optional argument sets cylinder phase samples (default 72).

Each `outputs/<case_id>/study_input.mat` contains `cfg`. Run one saved study with:

```matlab
input = load('research/outputs/<case_id>/study_input.mat','cfg');
study = runStudy(input.cfg);
```

Then run `scripts/analyse_results.py`, `scripts/build_report.py`, and `scripts/verify_report.py` using Python with NumPy, pypdf/pypdfium2, pdfplumber, Pillow and ReportLab available. The report builder uses the source-page renders created by `scripts/inspect_sources.py`; see its recorded source filenames in `local_sources/inventory.json`. Original papers are not redistributed through Git.

## Key outputs

- `study_manifest.csv`: all 168 requested configurations and fixed hardware selection.
- `case_comparison.csv`: one summary per study, including speed/Re ranges, volume and mass.
- `component_extrema_full_states.csv`: signed minima/maxima and largest absolute components, with the entire simultaneous state.
- `selected_fixed_configuration_results.csv`: only the selected immutable configuration for each study.
- `all_scenario_results.csv`: all candidates, including rejected configurations; use the acceptance flag.
- `selected_geometry_and_magnets.json`: physical geometry and selected magnet dimensions, centres, directions, CoM and inertia.
- `geometry_comparison.csv`: reference areas/lengths, inscribed envelopes and actual CoM-dependent wall clearance.
- `phase_resolution.csv`: 72/144/288-sample cylinder comparisons.
- `verification_summary.json`: independent CSV-level force balance, trace-free gradient, origin-conversion and speed-limit checks.

The outputs folder and locally extracted PDFs are ignored by Git because they are generated data. Constructors, tests, report scripts, the report and the agent handoff are published on the research branch. The final commit is recorded in the OneDrive delivery manifest. The official tool release version is unchanged.
