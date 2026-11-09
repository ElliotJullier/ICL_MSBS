# MSBS aerodynamic requirements - complete work log and agent handoff

Date: 6 November 2026 (Europe/London). This log accompanies the 24-page report and the complete generated study bundle. Read the report first for scientific findings; use this file to resume implementation/research.

## Request and accepted scope

The user requested a source-audited aerodynamic portfolio, field/gradient requirements for each simultaneous force case, per-component envelope maxima, a single document showing extraction and coordinate working, a review/update of the existing MATLAB tool, tests, runnable studies and interpreted results. The comparison includes 0.6x0.6m and 1x1m square tunnels, horizontal and vertical installations, maximum wind speed 50m/s, several speeds/Re, 3/10/20% blockage, near-fill and small magnets, automatic magnetisation comparisons, and up to five auxiliary placement concepts for six-component cases. Sawada's NAL/JAXA paper is the first auxiliary-magnet reference.

Explicit user clarifications:

- Small magnet means **10% of volume**, not 10% of each dimension. Linear factor is 0.1^(1/3)=0.4641588834.
- Blockage means **maximum projected area over tested attitudes**, with one fixed article per sweep.
- Vertical means **upward flow only**.
- Original AR=8 cylinders / AR=3 wings cannot fit at 20% blockage. The user approved **shorter-span variants** for that comparison.
- The user subsequently authorised committing and pushing code changes to GitHub and placing a complete handover in the COMSOL OneDrive folder named **Temp Matlab Forces** for use from another computer.

The uploaded handover was treated as reference material, not as authority overriding these user decisions. Its claimed source verifications were independently checked where possible. No subagents were used.

## Workspace / baseline

- Repository: `C:/Bulk Data - No backup/ICL_MSBS_GitHub`.
- Tool: `MatLab/msbs_requirement_tool`.
- Baseline: `f4012c9060cb1cc6afe49fd9ccb42b80e7ac1a4d`, branch `master`, remote `https://github.com/ElliotJullier/ICL_MSBS`.
- Working tree was clean at the start. No AGENTS.md was found in the applicable repository tree/ancestors searched.
- Installed MATLAB: `C:/Program Files/MATLAB/R2025b/bin/matlab.exe`.
- Tool VERSION remains v0.4.1; changes are documented as **Unreleased research extensions**, not a new official release.
- Publishing branch: `codex/msbs-aerodynamic-requirements`. The final push hash is recorded in the OneDrive delivery manifest and can also be obtained from Git history. No force-push, master rewrite or merge is needed.

## Source acquisition / inspection

User files:

1. `C:/Users/'ej221'/Downloads/MSBS_Aerodynamic_Cases_and_Requirement_Tool_Handover.md`.
2. `C:/Users/'ej221'/Downloads/Papers.zip`.
3. `C:/Users/'ej221'/OneDrive - Imperial College London/PhD/11 Literature/Read/Sawada_NAL 60CM MAGNETIC SUSPENSION AND BALANCE SYSTEM.PDF`.

`research/scripts/inspect_sources.py` safely selects only PDFs from the ZIP, flattens names into `research/local_sources`, extracts page-indexed text and records SHA256/page counts in inventory.json. It does not trust archive paths. Local source PDFs and QA renders are ignored by Git. User-supplied papers are included privately in the OneDrive handover, not committed to GitHub.

Papers.zip contains ten PDFs covering Achenbach1972, Jann2013, Meile2011/2016, Carberry2001, Morse/Williamson2009 (two), Williamson/Roshko1988, NASA TP1100 and NASA TP2890. **Carberry2005 is absent** although named in the handover. **Nishihara2005 is also absent**, although cited by existing inline-cylinder cases.

Three additional primary author/government manuscripts were downloaded for the existing airfoil inputs:

- NASA TM81912: `https://ntrs.nasa.gov/api/citations/19830013896/downloads/19830013896_Redacted.pdf` -> `NASA_TM81912.pdf`. The unredacted URL returned404; use the redacted URL above.
- Oruganti/Narsipur: `https://arxiv.org/pdf/2006.09560` -> `Oruganti_Narsipur_2006.09560.pdf`.
- Vaddi et al.: `https://arxiv.org/pdf/2106.11453` -> `Vaddi_2106.11453.pdf`.

The Nishihara publication identity/DOI was found (10.1016/j.jfluidstructs.2005.02.003), but its full numerical figures were not inspected. Do not upgrade its inputs to verified status without the primary paper.

Relevant page inspections / renders (1-based PDF pages):

- Achenbach: pp2,3,4; Fig4 at PDFp4 / printed568.
- Jann: pp3,4,9,10,11,16,17,18,19,20; Table2 p11 and Table8 p17; source axes Fig9 p9.
- Meile2016: pp2,3,4,5,9,10,11; geometryFig1 p2; source yaw Figs5/6 p4; forceFig18 p9 and momentFig20 p10.
- Sawada: PDFp2 Fig4 (main magnet plus auxiliary pairs), and source text pp1-10.
- Carberry2001: pp2,3,4,5; Fig2a amplitude/phase and Eq2 p4 / printed526.
- Morse JFS2009: p3 contextual controlled/free-motion and wake transition discussion.
- NASA TP1100: pp11/12; TP2890 p2.
- NASA TM81912: pp61-67; relevant Fig11 lift/moment/drag are pp63,65,67 (printed61,63,65).
- Vaddi: pp3,6,8 and text search for moments; passive Fig5 p8.
- Oruganti: pp6,7,8; NACA curves are Fig10 p8 in the author manuscript, not the legacy Fig17 locator.

Run the inspector as `python research/scripts/inspect_sources.py <filename-prefix> 4,17` to extract/render specific pages. `find:<text>` gives page hits. PDF source snippets used in the report are embedded, so the delivered PDF is self-contained. Figure-reading tolerances are engineering reading estimates, not published statistical confidence intervals.

## Source and coordinate findings

Common T is right-handed, x downstream. Horizontal T z is upward. Earth gravity=[0,0,-9.80665]. Upward installation uses R_ET=Ry(-90deg), hence gravity_T=[-g,0,0]. rho=1.225kg/m3, mu=1.81e-5Pa.s, nu=mu/rho=1.477551e-5m2/s consistently.

### Sphere

Six approximate Fig4 samples: (Re,CD)=(150k,.510),(250k,.500),(300k,.480),(370k,.070),(500k,.080),(600k,.085). The300k point was added because the five legacy points omit a potentially important pre-crisis drag state. S=piD^2/4=beta H^2; U=Re*nu/D. Rows with U>50 are omitted. Zero non-drag aero force and zero moments are symmetry assumptions. The points do not certify a continuous crisis envelope.

### DLR cuboid

Body A is11:9:5, S=l*w, all moment lengths=l; reference at geometric centre. Recompute full Fourier sums from Tables2/8 in `jannCoefficients.m`, not rounded handover arrays. Five source states are (alpha,beta)=(0,0),(0,-45),(25,-45),(45,-45),(90,-45). Speeds10,25,40,50m/s. Source computations Re~165k omit Re/Mach dependence; transfer across model Re is assumed.

Retain paper body Bp (x upstream, z downward). Set Q=diag(-1,1,-1), R_TBp=Q*Rz(-beta)*Ry(alpha). Source forces are qS[CD,CY,CL] in T; source moments are qSl[Cl,Cm,Cn] in Bp then rotated. This fixes the legacy direct reuse of source Euler signs in an incompatible nominal body frame. Q is a proper rotation. Coefficients remain simultaneous.

### Ahmed

35-degree slant; beta0 and+15, approximate source means at30m/s: C0=[.29,0,0,0,.08,0], C15=[.43,.81,.57,.53,-.17,.26] in [CD,CS,CL,CMR,CMP,CMY] order. Reused at10/25/40m/s as screens; not measured polars at every model Re.

Body x downstream,z up; source Fig5 positive beta points nose toward+y, so R_TB=Rz(-beta), correcting legacy yaw=+beta. Reference area=.112s^2; roll length=.327s; pitch/yaw=.470s. B origin explicitly defined at outer bounding-box centre. Floor datum from Fig1 is P_B=s[-.138,0,-.194], using x=(.182+.202)-.522, z=-(.050+.144). This differs from legacy Px=-.085s. The inscribed constant-section prism spans source x100..822mm, centred61mm forward of bbox centre. Moments are shifted from floor datum to each resolved CoM once, in consistent frames. A scaled floor/ground clearance is assumed. Do not apply these coefficients to an isolated body without acknowledging that change. No fabricated12.5-degree six-axis switching history is added.

### Airfoils

Body x from leading to trailing edge,z up. Positive AoA raises the leading edge, requiring **Ry(+AoA)**, correcting legacy negative pitch. Conventional coefficient force reference is planform c*b; quarter-chord point is[-c/4,0,0].

SC values from NASA TM81912 Re2e6,M.15,fixed transition are approximately [CD,CL,Cm]=[.012,.5,-.115] at0deg, [.0165,1.2,-.11] at7deg, [.043,1.84,-.067] at16deg. Their low-Re finite-wing transfer is explicitly conditional and not proved conservative. Supplied TP2890 is transonic and cannot validate them.

NACA0/7deg passive values are linked to Vaddi Fig5. At7deg interpolate6/8deg to CL=.8,CD=.0169, sourceCm=-.0042. The source calls negative moment nose-up; map prose to tool+My and ALSO retain opposite sign as a labelled uncertainty branch. At12deg, legacy CL values [.82,.8587746649,1.010157855] for10/25/40m/s are held through geometry scaling. CD=.053,Cm=0 remain assumptions. Version-specific Oruganti figure number and Re transfer remain caveats; this is not a verified complete low-Re polar.

AR=3 at3%/10%; at20%, approved shorter-span NACA AR1.25 and SC AR1.5, increasing chord to restore projected blockage. No validated finite-wing correction is claimed.

### Cylinders

New crossflow source states use Carberry2001 A/D=.5, pairs (f/f0,CLamp,phase_deg)=(.806,.26,160),(.869,1.55,-20),(1.04,2.25,-40). Source St0=.748*.0254/.090=.2111022. z=A*sin(theta), az=-omega^2*z, CL=CLamp*sin(theta+phase). CD=1.2 is assumed mean-only. Structural inertia was removed in the source measured lift; do not add generic fluid added mass again. Add the MSBS article's actual rigid-body inertia separately.

Air Re=2300/5000; U=Re*nu/D<=7m/s. Source AR12.5 transfers to AR8 (3%/10%) and approved AR4 (20%). Inline A/D=.05, lambda*=1.7/2.2/2.7/3.5/5 and existing mean/harmonic coefficients/phase are retained but explicitly unverified. Exact ledger is in report Section7a.

Both cylinder families use72 phase samples per cycle and explicit grouped timestamps, analytic position/velocity/acceleration. Six extra72/144/288-sample runs verify the controlling gradients for0.6m/3% horizontal/small magnet; maxima agree. This does not bound omitted harmonics or source uncertainty.

## Magnet / mass / geometry decisions

- Near-fill single cuboid dimensions=.95*valid inscribed cuboid dimensions. This is85.7375% of envelope volume, not a CAD-global optimum.
- Small magnet volume fraction=.1 relative to the corresponding large design. No15%-of-tunnel dimension cap was applied; the current request is containment-limited comparison.
- Generic N52 minimumBr1.43T,density7500kg/m3, effective factor1; m_d=Br*V/mu0. Supplier-specific part data remain required.
- Residual non-magnet mass=.3 times the large near-fill single-magnet mass, fixed for all candidates and both size variants of that body. Total mass changes with actual magnet mass. This avoids shrinking the shell with the magnet.
- Existing hybrid outer-body residual inertia remains; cavities are not subtracted. CoM/inertia are computed per candidate set. No measured/CAD mass is claimed.
- Some near-fill articles reach503kg; this is a physically consequential assumption, not a realistic hardware mass specification.
- Five auxiliary placement concepts are in `auxiliaryLayouts.m`: lateral opposed pair with +/-z; lateral radial pair with +/-y; vertical opposed pair with +/-y; vertical radial pair with +/-z; four auxiliaries at lateral/vertical offsets. Three main-magnet axes each, plus three single-magnet controls, give18 candidates for cuboid/Ahmed.
- All five auxiliary concepts have equal total magnet volume .4864*envelope volume before the small-size factor. Centres remain fixed when dimensions shrink. Magnets are disjoint and contained; some direction/layout combinations remain rank deficient and are rejected.
- Sawada motivates pair magnets for roll authority; the present coordinates/dimensions/polarities are new engineering layouts, not a reconstruction of JAXA hardware.
- Final geometry audit uses actual resolved CoM to compute body origin=r_C,T-R_TB*r_C,B and checks the swept bounding envelope. No selected arrangement crosses a wall. See geometry_comparison.csv and selected_geometry_and_magnets.json.

## Software work

Core modified files: defaultConfig, resolveConfig, validateConfig, buildScenarioTable, calculateMassProperties, calculateRequiredMagneticWrench, buildResultTable. Added resolvePosition and fieldAtTunnelOrigin.

- `scenario_set.relationship`: independent / fixed_envelope / time_history. Both ranking tables remain available. Histories require finite increasing timestamps per optional scenario_group_id.
- `position.mode`: nominal / specified / harmonic_analytic; explicit CoM reference. Specified columns x_C_T_m,y_C_T_m,z_C_T_m; optional three velocity columns together. Harmonic analytic position is restricted to pure translation, matching the existing helper's fixed B translation semantics. No implicit acceleration integration.
- `attitude_R_TB`: optional proper-rotation cell column, mutually exclusive with Euler/harmonic attitude.
- `mass.non_magnet_mass_kg`: fixed residual mass, mutually exclusive with total-mass override. Empty preserves legacy behaviour.
- Added primary CSV columns for B_O=B_C-G*r_C, absolute CoM, relationship, magnet volume and masses. Legacy Bx/By/Bz denote B_C.
- Preserved STF solver, scaling, primary RMS reference-cube cost, residual acceptance and alternate sensitivity families.

Research files: makeCase, jannCoefficients, auxiliaryLayouts, checkClearance, run_portfolio, rerun_families, audit_geometry_and_resolution; scripts inspect_sources/analyse_results/build_report/verify_report. Updated UserGuide/CHANGELOG and added TestResearchExtensions. Legacy case files remain unchanged.

Deferred as unnecessary/unsupported for current explicit inputs: numerical acceleration integration, CAD/mesh projection, coil currents/R/L/power/voltage/slew, control stability, continuous orientation optimisation, validated angular dynamic envelope, complete low-Re finite-wing database, complete Ahmed switching wrench.

## Execution and verification log

1. Read handover, skills, repository/current cases, solver/load/frame/mass/export code. Inventory sources and current dependencies.
2. MATLAB initially failed in sandbox with a filesystem startup inconsistency, even using local preferences. Running the installed MATLAB through the normal reviewed escalation succeeded. No user system preferences were changed manually.
3. Baseline `runAllTests`:65 passed,0 failed,0 incomplete (baseline_tests_20261106.log).
4. Implemented extensions and new source constructors/tests. First updated run was74/75 passing because documentation-default-field coverage caught missing new settings. Added documentation and reran successfully.
5. Ran initial full matrix; after user approved shorter spans, reran with20% variants and added sphere300k point.
6. Corrected source attitude/datum mappings and recomputed Ahmed/NACA/SC families. A shell-quoting error in one batch invocation was corrected before actual recomputation; no partial result was used as final.
7. Added NACA moment-sign uncertainty branch and recomputed NACA. All168 matrix configurations now ran successfully.
8. Final suite:76 passed,0 failed,0 incomplete, including all65 original tests. Logs retained.
9. Independent CSV audit of28,912 selected rows: force-balance error<=8.87e-12N; gradient trace<=4.98e-14T/m; fixed-origin field error<=2.23e-16T; maxspeed50m/s.
10. Geometry/phase audit initially lacked src on MATLAB path after runAllTests restored it. Added explicit project/src/cases/research paths, reran successfully. Actual selected CoM/swept wall checks pass;72/144/288 phase gradients agree.
11. Built a24-page PDF with ReportLab and editable Markdown; rendered every page and checked figures/tables/boundaries. No automated text-boundary issues. Source hashes and report hash recorded in report_build_record.json.
12. Prepared full private OneDrive bundle and publishing branch per the user's follow-up. Delivery-specific final commit/push/sync status is recorded with that bundle.

## Final numerical state

-168 requested configurations, all ran with an accepted immutable magnet arrangement.
-96,096 primary scenario/candidate combinations;28,912 rows for selected fixed arrangements.
-Maximum selected scaled residual1.781512662e-14, versus acceptance1e-6.
-All conditional screens: maximum CoM/local field norm0.55652291T (SC,0.6m,3%,horizontal,10%-volume,U40,a16). Maximum gradient Frobenius norm35.80899712T/m and maximum tensor entry28.73187792T/m (same SC geometry/volume,U40,a16,upward).
-Source-anchored transfer subset (sphere,cuboid,Ahmed,crossflow): max CoM field0.07281527T; max local magnet field0.09958346T; max gradient norm3.69979029T/m; max tensor entry3.02086552T/m. These come from different actual states, listed in the report/CSV.
-Do not combine these component maxima into a synthetic simultaneous load or field state. They are a component capacity envelope for the enumerated selected builds, not a global optimum or coil specification.

## Reproduction / next-agent entry points

From the tool root in MATLAB:

```matlab
runAllTests
addpath('src','cases','research')
run_portfolio
audit_geometry_and_resolution
```

To run one delivered MAT input:

```matlab
input=load('research/outputs/<case_id>/study_input.mat','cfg');
study=runStudy(input.cfg);
```

Then Python scripts: analyse_results.py, build_report.py, verify_report.py. Bundled runtime used here was Codex primary26.1105.12137; Python had pypdf,pdfplumber,pypdfium2,Pillow,ReportLab,NumPy. Plotting uses ReportLab vector graphics. The user need not have Codex to run the MATLAB studies or view the PDF/CSVs.

Generated data are under research/outputs and ignored by Git. The OneDrive snapshot includes them. Important tables: study_manifest.csv, case_comparison.csv, all_scenario_results.csv, selected_fixed_configuration_results.csv, component_extrema_full_states.csv, geometry_comparison.csv, phase_resolution.csv, verification_summary.json and selected_geometry_and_magnets.json. Every per-case folder contains exact input, results, rankings, extrema, warnings and applicable sensitivity CSV.

For ongoing scientific work, priorities are:

1. Verify the Nishihara inline coefficient/phase extraction against its full PDF.
2. Replace SC low-Re finite-wing transfer with appropriate measured/validated CFD data. It controls the largest conditional targets. Do not call the current high-Re transfer conservative without evidence.
3. Verify NACA stall drag/moment, source moment sign and Re-dependent lift at each actual resized model; retain moment-sign uncertainty until resolved.
4. Define buildable magnet parts and shell masses; containment-limited503kg articles are not hardware specifications.
5. Obtain synchronized6-component Ahmed transition histories if12.5deg peak switching loads are required, plus floor/no-floor conditions matching the intended tunnel.
6. Define angular trajectories/gust bandwidth, then introduce real coil maps/current/voltage/thermal constraints. Current local affine solutions do not certify these.

Preserve physical pairing, reference area/length, source-frame conversion, moment datum and evidence status when replacing any rows. Changing loads, magnet geometry/mass or cost length requires recomputation, not merely reranking saved values.
