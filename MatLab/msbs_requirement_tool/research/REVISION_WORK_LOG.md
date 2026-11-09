# MSBS aerodynamic requirements revision handoff

9 November 2026. The previous report, input archive and code are the baseline at `ba17ce9d282a50691794a68188b526036ff1c53e`. The design summary for this revision is in `MSBS_Aerodynamic_Requirements_Revision.pdf`. The earlier report explains the original portfolio and preserves the original digitisation and results.

## Request and decisions

- The user confirmed upward-only vertical flow, 10% of large magnet **volume**, and maximum projected blockage over the tested attitudes.
- The revised user instruction caps the entire installed magnet assembly at 30% of the square test-section side. The implementation measures the axis-wise extent of the union of all magnet corners in body axes and at all tested tunnel attitudes. Maximum measured ratio is 0.30. A block diagonal is a different dimension.
- The nominal large magnet starts from 95% of an inscribed certified-fit prism, capped and rotated as applicable. The 10% version scales each dimension by 0.464159. Auxiliary centres retain the lever arms of the capped large arrangement. Physical rotation and a discrete direction library are implemented. Alternate layouts can have different large reference volumes.
- The user initially requested shorter span variants where needed, then asked for supported aspect-ratio transfer or exclusion. The NACA 0012 portfolio uses directly applicable AR 1 experiment data at all three blockages. The transverse cylinder retains source AR 10 at 3% and 8%, with 10% and 20% explicitly excluded from the design envelope. The model uses geometric blockage with no blockage correction.
- Per-source Re is used to solve model U. No coefficients are carried to 50 m/s unless the resized model reaches that speed at source Re. Retained speeds range from 0.661 to 46.62 m/s. The 50 m/s cap excludes undersized Ahmed and some high-Re sphere points. Aircraft-section SC data and unverified legacy inline values are outside the selected portfolio.
- Full six-axis wrench rank is required for cuboid and Ahmed. The specified symmetry-plane wing and force-only sphere/cylinder rows can be balanced at rank five. Static hardware can be exchanged between points, and the primary cylinder ranking uses one set across all histories and phases.
- The mass revision is an opt-in solid ABS volume calculation with magnet cavities. It replaces the 30%-of-magnet-mass assumption only for the new portfolio. Model density is 1,050 kg/m³. Magnet density and minimum remanence come from the existing grade table. The affine field formulation and coil-related interfaces have the prior behavior.

## Chronology and source evidence

1. Inspected the baseline study, scripts, earlier §7a, and the supplied source PDFs. The earlier transverse histories used Carberry Fig. 2a. Morse and Williamson was context only. Replaced this with the 2009 Morse and Williamson Fig. 3(a) wake map and figure-linked loads at Re 4,000. Fig. 7 provides 2S and 2P points around the transition. Fig. 10 supplies two coexisting branches at A/D 0.78 and wavelength/D 6. Fig. 8 P+S needs higher harmonics and a drive phase reference. It has a distinct phase-independent sensitivity with vortex trace allowance 13 plus the Eq. 3 potential term. See the PDF for plotted evidence and phase convention. [Morse and Williamson](https://doi.org/10.1016/j.jfluidstructs.2008.12.003).
2. Kept Achenbach Fig. 4 curve reads at their selected source Re. Retained Body A six-component Jann Fourier coefficients at the reported Re 165,000 and documented the source U/length discrepancy. Mapped the source body axes with the previous verified rotation. Meile Figs. 18 and 20 now run at Re approximately 2.0475 million based on §2.5, with the source ground datum and yaw sign retained. The faceted Ahmed prism explicitly omits nose radii and support hardware. [Achenbach](https://doi.org/10.1017/S0022112072000874), [Jann and Geisbauer](https://doi.org/10.2514/6.2013-1282), [Meile et al.](https://doi.org/10.1016/j.ijheatfluidflow.2015.11.002).
3. Searched for compatible finite-wing load data. Retrieved the publisher’s Fig. 6 raster for the isolated AR 1 wing. The publisher PDF download returned HTTP 403 from the shell while the figure URL succeeded. Transcribed paired KU series at Re 129k, 215k and 300k for 0, 10, 25 and 45 deg. Read positive moment as nose-up from the plotted annotation. Both force and moment data are present. The original NACA section data and higher-Re NASA supercritical loads were not transferred. SC geometry uses measured NASA TP-2890 Table I coordinates as a geometry-only preview. [Chinwicharnam and Thipyopas](https://doi.org/10.1177/1756829316638206), [NASA TP-2890](https://ntrs.nasa.gov/citations/19890008197), [NASA TM-81912](https://ntrs.nasa.gov/citations/19830013896).
4. Reviewed inline candidates. The legacy Nishihara Fig. 8/9 values remain unverified. Cagney and Balabani’s free-vibration experiment has inferred forcing and is not a direct replacement for controlled inline tests. These references are candidates for a new evidence pass. [Nishihara et al.](https://doi.org/10.1016/j.jfluidstructs.2005.02.003), [Cagney and Balabani](https://discovery.ucl.ac.uk/id/eprint/1477168/).
5. Kept the five opposed-magnet layout concepts based on the NAL roll-control example. Re-expressed magnets in their own +x axes and checked the envelope over the full assembly. The report derives both local-field and force-lever contributions to pair torque. [Sawada et al.](https://www.icas.org/icas_archive/ICAS2004/PAPERS/182.PDF).
6. Added a separate research entry point and a small mass-model option in the core. The first run caught a row/column broadcasting mistake in the wall check and a toolbox dependency in `range`. Both were corrected. The first full unit run caught the documentation coverage check for the new config field, which was added to the user guide. Re-ran 81 tests successfully, followed by the full six-axis-rank-filtered portfolio.
7. Built the report and verified the PDF by rendering every page with PDFium. Tightened appendix columns and replaced wrap-prone hardware names with short labels. Generated SVG charts and MATLAB FIG and PNG previews. Numeric data come from the CSV outputs.

## Reproduction from the repository

MATLAB R2025b was used. From `MatLab/msbs_requirement_tool`, run

```matlab
runAllTests
addpath('research')
run_requirements_revision
export_revision_cad
audit_revision
```

The default output is `research/outputs/revision`, which is ignored by Git. Copy the packaged results into that path or regenerate them. The report build requires Python with NumPy, pandas, ReportLab and Pillow. PDFium and Pillow were used for render verification.

```text
python research/scripts/build_revision_report.py
```

Load any exact input MAT file and run `plot_revision_cad(cfg,setIndex,scenarioIndex)` from the tool directory with `research` on the MATLAB path. The figure shows the opaque exterior and the assembly separately at the same attitude. The renderer uses the shared section geometry, and each magnet arrow follows the installed magnet’s local +x axis. The time-varying translation is in the study rows. CAD previews show attitude about the nominal model location.

## Output index

| File | Contents |
|---|---|
| `coverage.csv` | Requested grid, source or speed exclusion reason and exact case ID. The 8% cylinder row is an explicit alternate grid point. |
| `inputs/*.mat` | All 100 runnable configs including source rows and all candidate magnets. |
| `candidates.csv` | All 32,792 solved candidate rows. `sizing_eligible` includes the residual and relevant rank filters. Unselected adverse hardware can have much higher demands. |
| `selected_primary.csv` | Both hardware policies at the primary RMS reference length, with all phases retained. |
| `component_targets.csv` | Component and norm maxima by installation and combined, using the family-preferred policy. Signed values and the controlling state remain paired. |
| `preferred_case_extrema.csv` | Per-case maxima for the preferred policy. Each metric has its own controlling state. |
| `operating_group_peaks.csv`, `distribution_statistics.csv`, `*_histogram_counts.csv` | Counted observations and numeric histogram bins. Dynamic groups enter once via their peak. Mass uses one occurrence per distinct selected set within each case. |
| `selection_sensitivity.csv`, `hardware_rankings.csv` | Re-solved J for L, L/2, 2L and 0.30H. Full fixed candidate ranks and independent operating-group winners. |
| `installed_magnets_and_mass.csv` | Magnet centres, dimensions, directions, volume, mass, cap checks, calculated CoM and inertia tensor for every set. |
| `morse_figure_reads.csv`, `PplusS_trace_sensitivity.csv`, `phase_resolution_check.csv` | Figure-linked inputs, conditional alternate wake screen and convergence check. |
| `cad/`, `charts/` | MATLAB figure/PNG previews and editable SVG report charts. |
| `logs/` in the results archive | MATLAB final suite/portfolio output, CAD/initial run output and P+S audit. |
| `evidence/` in the results archive | The published isolated-wing figure used for the new approximate numeric reads. The earlier OneDrive delivery contains the supplied source archive. |

## Verification and limits

- MATLAB R2025b reported 81 passed, zero failed and zero incomplete.
- All candidate CSV Re values agree with U L / nu within 9e−9 absolute Reynolds units after export. All cap ratios are ≤ 0.30. Each small-to-large volume ratio agrees with 0.10 within 8e−14. Largest nominal wall envelope ratio is 0.8944.
- Preferred peak local B is 0.338438 T for 1 m horizontal Ahmed, 20% blockage, 10% magnet volume, yaw 0, layout 3 with +x main. Preferred peak gradient is 4.028572 T/m Frobenius and 3.289314 T/m largest absolute component for the 0.6 m horizontal transverse cylinder at 3% blockage, 10% magnet volume, 2Po branch and 270 deg phase. The gradient is unchanged at 72, 144 and 288 samples per cycle. The heaviest selected article is 214.9076 kg.
- The P+S screen peaks at about 12.0 T/m in the same 0.6 m geometry. It is kept separate from the reconstructed phase-history limit and illustrates the hardware implication of larger prescribed accelerations.
- Model effects such as free cylinder tips, high blockage interference, Ahmed ground-plane transfer, source figure precision and real magnet availability still limit the interpretation. Structural supports and manufacturable hollow shell mass require CAD inputs. The report includes concrete next decisions.
