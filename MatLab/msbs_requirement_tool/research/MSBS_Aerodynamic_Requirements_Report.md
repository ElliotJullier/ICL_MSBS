MSBS aerodynamic loads and magnetic requirements

Source audit, coordinate working, software changes and 168-study screening comparison

6 November 2026 | Square tunnels: 0.6 m and 1.0 m | Horizontal and upward flow

## Calculated targets and their scope

The study solves 96,096 simultaneous scenario/magnet combinations. All 168 requested configurations have a residual-accepted fixed arrangement. The envelope below uses the best immutable arrangement for each physical model and operating envelope; it does not switch magnets between phase or speed rows.

| Envelope | Max |B_C| (T) | Max local |B_i| (T) | Max ||G||F (T/m) | Max tensor entry (T/m) |
|---|---|---|---|---|
| All conditional screens | 0.55652 | 0.55652 | 35.809 | 28.732 |
| Source-anchored subset | 0.072815 | 0.099583 | 3.6998 | 3.0209 |

These are provisional applied-field targets under a local affine-field model. The large all-case gradient is controlled by the small SC(2)-0714 magnet and the transfer of Re=2 million section data to much lower-Re models. It is a conditional sizing screen, not a validated tunnel aerodynamic envelope or a coil-current specification.

The source-anchored subset contains sphere, cuboid, Ahmed and crossflow-cylinder cases. It still includes explicit transfer assumptions, approximate graph readings and assumed cylinder mean drag. The narrower label describes provenance, not validation at 20% blockage.

## Decisions incorporated

The small magnet has 10% of the corresponding large magnet volume: each dimension is multiplied by 0.464159. Blockage is the maximum projected area over the selected attitudes, with one fixed model throughout each sweep. Vertical flow is upward. At 20% blockage, shorter spans are used where the original aspect ratios cannot fit. Each model retains the same residual non-magnet mass when magnet volume changes.

A single permanent dipole cannot provide arbitrary six-axis control. Five auxiliary placement concepts are compared for each six-component cuboid/Ahmed model, with three automatic main-magnet axes per concept. Only arrangements accepted for every scenario enter the design envelope.


---

# 1. Coverage and literature audit

The portfolio is broad enough for an initial load-mechanism screen: drag crisis, sharp-edge separated 3D loading, yaw/ground-effect wake changes, lifting sections, and phase-dependent forced translation. It does not establish a universal six-axis dynamic envelope: angular-motion bounds, gust spectra, peak six-component Ahmed switching histories, finite-wing loads and actuator dynamics remain outside the established evidence.

| Source supplied | Role and selected points | Audit outcome |
|---|---|---|
| Achenbach 1972 [1] | Sphere; six Re/CD points spanning subcritical and post-crisis flow | Fig4, PDF p4 / printed p568. Approximate readings; added Re=300k before crisis. |
| Jann & Geisbauer 2013 [2] | Body A 11:9:5; (alpha,beta)=(0,0),(0,-45),(25,-45),(45,-45),(90,-45) | Tables2/8, PDF pp11/17, recomputed Fourier sums. Six simultaneous coefficients. |
| Meile 2011 [3]; 2016 [4] | 35-deg Ahmed body, beta=0 and +15 deg | 2016 Figs18/20 give approximate means. 12.5-deg switching lacks a paired six-component history. |
| Carberry et al. 2001 [5] | A/D=.5, f/f0=.806,.869,1.04; before/after wake transition | Fig2a amplitude/phase and Eq2 used together. Mean drag is an explicit assumption. |
| Morse & Williamson 2009, two papers [6,7]; Williamson & Roshko 1988 [8] | Wake/regime diversity and controlled-motion interpretation | Regime maps support selection, not an interchangeable six-channel load database. |
| McAlister et al. 1978 [9] | NACA0012 dynamic-stall context | Re=2.5e6; most motion 15+10 sin(wt) deg, reduced frequency up to .25. Not a steady low-Re polar. |
| Jenkins 1989 [10] | SC(2)-0714 identity and transonic data | M=.60-.76, alpha=-2..6 deg; cannot substantiate low-speed alpha=16 deg. |
| Carberry et al. 2005, named in handover | Additional wake/force validation | Absent from Papers.zip. Ten PDFs supplied for eleven listed aerodynamic references. |
| Sawada et al. 2004 [11] | Auxiliary-magnet / roll-control reference | Fig4, PDF p2, and pp2-3 establish main magnet plus pair-magnet roll control. |

Additional primary manuscripts were retrieved for the airfoil audit: NASA TM-81912 [12], Vaddi et al. [13], and Oruganti & Narsipur [14]. The supplied archive does not contain the Nishihara inline-force paper cited by the current cases. Its numerical rows remain unverified legacy screens. Source file hashes and page counts are retained locally; the research scripts recreate the inventory from the supplied archive.


---

# 2. Common coordinates and governing balance

All output forces, moments, fields and gradients use one right-handed tunnel frame T: +x downstream, +z upward in the horizontal installation, and y completing the triad. Earth gravity is [0,0,-9.80665] m/s2. R_ET maps tunnel vectors to Earth. For upward flow R_ET=Ry(-90 deg), so gravity_T=[-9.80665,0,0] m/s2. Rotating the installation changes gravity; it does not change aerodynamic coefficient signs.

q = rho U^2 / 2;  Re = rho U L_Re / mu
w_mag = [m a_C; I_T alpha + omega x (I_T omega)] - w_aero - w_gravity - w_other
M_C = M_P + (r_P - r_C) x F   (all vectors in the same frame)

Air uses rho=1.225 kg/m3 and mu=1.81e-5 Pa s; nu=1.477551e-5 m2/s. All speed/Re calculations use this same nu, replacing legacy metadata that sometimes used 1.5e-5. Reynolds number is computed from actual dimensions and speed; it is not a solver speed input.

| Family | Source-to-tool conversion | Reference convention |
|---|---|---|
| Sphere | F_T=[D,0,0]; moments zero by symmetry assumption | S=pi D^2/4; L_Re=D; reference at geometric centre. |
| DLR cuboid | Retain paper body Bp: x upstream, z downward. Q=diag(-1,1,-1). R_TBp=Q Rz(-beta) Ry(alpha). F_T=qS[CD,CY,CL]; M_T=R_TBp qSl[Cl,Cm,Cn]. | S=l*w, all moments use l; moments about geometric centre. Q is a proper rotation. |
| Ahmed | Body x downstream, z upward. Source positive beta points nose toward +y: R_TB=Rz(-beta). Rotate both body forces and body moments. | Aref=.112s^2; roll length=.327s; pitch/yaw length=.470s. Source floor datum retained and shifted to resolved CoM. |
| Airfoils | Body x from leading to trailing edge; z upward. Positive AoA raises leading edge: R_TB=Ry(+AoA). Lift/drag already in T. | S=c*b; Cm about quarter chord at [-c/4,0,0]_B. Positive tool My is nose-up. |
| Cylinder | Paper transverse y becomes +z_T; source lift sign and displacement phase both map together. | S=D*L; L_Re=D. Rigid-body inertia is separate from measured fluid force. |

The cuboid, Ahmed yaw and airfoil pitch conversions differ from legacy case assumptions. New constructors contain the corrected transformations; legacy files are preserved. The explicit attitude_R_TB input avoids Euler-angle ambiguities. NACA moment signs are treated as an uncertainty branch because the Vaddi text calls negative source Cm nose-up.


---

# 3. Sphere: extraction and complete worked example

Achenbach Fig4 (PDF p4, printed p568) plots measured total drag coefficient against log Reynolds number. Read the smooth-sphere circle symbols against the linear CD axis and logarithmic Re axis. Values below are approximate visual samples, not high-precision digitisation. Indicative reading tolerances are about 0.01-0.02 in CD away from the crisis, with much larger Re-location uncertainty through the steep drop; no statistical confidence interval is inferred.

| Re | CD used | Interpretation |
|---|---|---|
| 150000 | 0.51 | Subcritical |
| 250000 | 0.5 | Subcritical |
| 300000 | 0.48 | Added pre-crisis high-drag point |
| 370000 | 0.07 | Near drag minimum |
| 500000 | 0.08 | Post-crisis |
| 600000 | 0.085 | Post-crisis |

Source evidence: Achenbach [1], Fig4, printed p568. Original graph; values are approximate.

![Source evidence: Achenbach [1], Fig4, printed p568. Original graph; values are approximate.](qa/experiments-on-the_p4_crop.png)

A_T=.6^2=.36 m2; S=.10 A_T=.036 m2; D=sqrt(4S/pi)=0.214094894 m
U=Re mu/(rho D)=17.2534594 m/s; q=182.330139 Pa
D_force=q S CD=3.2819425 N
F_mag,req=[-3.2819, 0, 154.82] N
B_C=[0, 0, 0] T; ||G||F=0.1029378 T/m

For C005, selected Automatic +z_B, total mass is 15.78747 kg. Magnet moment uses Br=1.43 T and m_d=Br V/mu0, with mu0=4 pi 1e-7 and V=0.001619227 m3. A centred z magnet has Gxz=Fx/m_d and Gzz=Fz/m_d; minimum Frobenius norm gives Gxx=Gyy=-Gzz/2 and other free entries zero. Thus a zero torque case needs no CoM field, while its gravity force still needs a gradient.

At fixed Re and blockage, U is inversely proportional to model diameter and aerodynamic drag is identical in the two geometrically similar tunnels. Magnet volume and weight are not identical. Points requiring U>50 m/s are omitted with their absent Re visible in the exported rows. The entire crisis is not bounded by these six discrete samples.


---

# 4. Cuboid: tabulated coefficients, axes and processing

Use Body A, not Body B or the hemispherical shell. Source dimensions are 110 x 90 x 50 mm; S=9900 mm2 and l=110 mm (PDF p3). Source computations used approximately Re_l=165000, U=18 m/s (p5). The paper symmetrises rotating-URANS results to approximate steady zero-rate behaviour (pp9-10); it does not supply a measured six-axis history. Reynolds/Mach dependence is omitted by the source model. Repeating its coefficients over U=10,25,40,50 m/s is an explicit transfer assumption.

C(alpha) = a0 + sum_i [a_i cos(i alpha) + b_i sin(i alpha)]
At beta=0 use Table2 (p11); at beta=-45 deg use Table8 (p17).
Angles enter trig functions in radians; retain all eight tabulated harmonics.

| alpha,beta deg | CD | CY | CL | Cl_Bp | Cm_Bp | Cn_Bp |
|---|---|---|---|---|---|---|
| 0,0 | .375300 | 0 | 0 | 0 | 0 | 0 |
| 0,-45 | .554500 | .108900 | 0 | 0 | 0 | .014200 |
| 25,-45 | .743947 | -.032449 | .402542 | .025319 | .046606 | .015231 |
| 45,-45 | .894500 | -.182400 | .300200 | .021991 | .037300 | .019104 |
| 90,-45 | 1.000900 | -.374500 | 0 | .043100 | 0 | .000100 |

Source evidence: Jann & Geisbauer [2], Table8 and Table9, PDF p17. Table8 is transcribed in jannCoefficients.m.

![Source evidence: Jann & Geisbauer [2], Table8 and Table9, PDF p17. Table8 is transcribed in jannCoefficients.m.](qa/jann-geisbauer-201_p17_crop.png)

Example alpha=25, beta=-45 deg:
R_TBp = [-.640856  .707107 -.298836;
          .640856  .707107  .298836;
          .422618  0       -.906308]

For C029 at U=25 m/s, dimensionalise force with q*l*w and moment with q*l*w*l, then rotate the source-body moment with the matrix above. The resulting aerodynamic force is [9.1531, -0.39924, 4.9527] N and moment about the resolved CoM is [0.029696, 0.13103, -0.0075689] N m. Required magnetic force is [-9.1531, 0.39924, 153.41] N and moment is [-0.029696, -0.13103, 0.0075689] N m. All six remain paired in this one state.

The largest selected cuboid projection sets model scale: Aproj=|nx|wh+|ny|lh+|nz|lw, n=R_TBp^T e_x. Scale all lengths by sqrt(beta*A_T/max(Aproj_unit)). Moments are not multiplied by planform span: all three source moment coefficients use l.


---

# 5. Ahmed body: yaw, datum and missing switching wrench

Meile 2016 Fig1 (PDF p2, printed p35) supplies the 1044 x 389 x 288 mm outer dimensions, 50 mm ground clearance and support/datum dimensions. Section2.3 and Figs5-6 (PDF p4) distinguish wind-fixed and model-fixed measurements. Figs18 and20 (PDF pp9-10) are read at the same beta and U=30 m/s, giving paired mean body-axis coefficients. Approximate tolerance for these manual reads is 0.02-0.04 per component; zero lateral symmetry values are assumptions.

| beta deg | CD | CS | CL | CMR | CMP | CMY |
|---|---|---|---|---|---|---|
| 0 | 0.29 | 0 | 0 | 0 | 0.08 | 0 |
| 15 | 0.43 | 0.81 | 0.57 | 0.53 | -0.17 | 0.26 |

Source evidence: Meile [4], Fig5, PDF p4. Positive beta rotates downstream body x toward -y_T.

![Source evidence: Meile [4], Fig5, PDF p4. Positive beta rotates downstream body x toward -y_T.](qa/1-s2.0-S0142727X15_p4_crop.png)

s = model_length/1.044
F_B = q (.112 s^2) [CD,CS,CL]
M_P,B = q (.112 s^2) [.327s CMR, .470s CMP, .470s CMY]
P_B = s [(.182+.202)-.522, 0, -(.050+.144)]
    = s [-.138,0,-.194] m; R_TB=Rz(-beta)
M_C,T = R_TB M_P,B + R_TB(P_B-r_C,B) x R_TB F_B

The new body origin is the outer bounding-box centre. This gives P_x=-0.138s m from Fig1, rather than the legacy -0.085s m. The inscribed constant-section prism is x=100..822 mm from the nose, centred 61 mm forward of bounding-box centre. This declared proxy and datum choice are retained explicitly; a CAD-defined CoM would require a fresh reference conversion.

Example C053, U=25 m/s, beta=15 deg: after rotation and the CoM shift the aerodynamic wrench is F=[5.1855, 5.5681, 4.7292] N, M=[1.0635, -0.6908, 0.15599] N m. The selected fixed arrangement is layout2_main_axis3. The reference point is a measurement datum on the floor, not a centre of pressure.

Source means are reused at U=10,25,40 m/s as load-transfer screens, not measurements at those model Reynolds numbers. A comparable floor at 50s mm clearance is assumed. Rotating the tunnel vertically also rotates this floor/model arrangement conceptually; an isolated suspended body without the floor would need different aerodynamic data. The paper identifies switching near 12.5 deg and Re-dependent changes. It shows lift histories, but not a full synchronised six-component history suitable for a six-axis peak case. No invented six-component switching row is used.


---

# 6. Airfoils: what can and cannot be taken from the sources

## SC(2)-0714

The supplied Jenkins report is transonic. NASA TM-81912 was therefore obtained separately. Its Fig11, printed pp61,63,65 (PDF pp63,65,67), gives low-speed section lift, quarter-chord moment and drag polar at M=.15, fixed transition. The lowest source Re is 2 million. Approximate curve reads retained below are taken from the same Re curve; drag is read at the corresponding lift. They are transferred unchanged to the model Re and are not demonstrated conservative bounds.

| AoA deg | CD | CL | Cm quarter chord | Status |
|---|---|---|---|---|
| 0 | 0.012 | 0.5 | -0.115 | Graph-read section screen |
| 7 | 0.0165 | 1.2 | -0.11 | Graph-read section screen |
| 16 | 0.043 | 1.84 | -0.067 | Near source high-lift/stall region; model stall not established |

NASA TM-81912 [12], Fig11a, printed p61 / PDF p63. Circles are Re=2e6.

![NASA TM-81912 [12], Fig11a, printed p61 / PDF p63. Circles are Re=2e6.](qa/NASA_TM81912_p63_crop.png)

## NACA 0012

Vaddi plasma-OFF Fig5 (PDF p8) gives approximately CL(.0)=0, CL(6)=.70, CL(8)=.90; CD(0)=.0122, CD(6)=.0140 and CD(8)=.0198 at Re=201k. Linear interpolation to 7 deg gives CL=.80 and CD=.0169. Source Cm(6) is about -.0052 and Cm(8) about -.0032, giving -.0042 at 7 deg. The paper calls negative moment nose-up. The constructor maps that prose to tool +My, and includes the opposite sign as a labelled convention-uncertainty branch.

For 12 deg, lift is retained from legacy approximate reference-curve reads/interpolation associated with Oruganti & Narsipur. The obtained author manuscript places NACA0012 in Fig10, PDF p8 (the legacy file cites Fig17, a version-dependent locator). CD=.053 and Cm=0 at 12 deg remain engineering assumptions. Legacy Re-dependent CL rows are held during geometry scaling; they are not freshly validated polars at each new Re. This family remains a conditional screen.

All section forces use planform c*b, not frontal blockage area. At 20% blockage, NACA AR is 1.25 and SC AR is 1.5, versus AR=3 at 3%/10%. Section coefficients applied to these short finite wings omit a validated induced-drag/tip-flow correction. The 20% variants quantify the stated proxy, not an experimentally verified finite-wing comparison.


---

# 7. Forced cylinders: phase-consistent fluid and inertia loads

Carberry 2001 [5], PDF pp2-4 (printed pp524-526): water-channel U=.090 m/s, D=.0254 m, L=.3175 m, AR=12.5, Re=2300, stationary shedding frequency f0=.748 Hz. A/D=.5 and y=A sin(2 pi f t). Fig2a supplies simultaneous lift amplitude and phase. Choose three operating states around the transition; the source identifies .806 as low-frequency/2P and .869 as high-frequency/2S. The higher-frequency point extends force severity within the measured curve.

| f/f0 | CL amplitude | Phase deg | Approximate reading / interpretation |
|---|---|---|---|
| 0.806 | 0.26 | 160 | Small lift, nearly opposite displacement |
| 0.869 | 1.55 | -20 | After abrupt wake/phase transition |
| 1.04 | 2.25 | -40 | High-frequency larger lift |

Carberry [5], Fig2a, printed p526 / PDF p4: black dots are CL amplitude, diamonds are phase. Both are read at the same frequency.

![Carberry [5], Fig2a, printed p526 / PDF p4: black dots are CL amplitude, diamonds are phase. Both are read at the same frequency.](qa/1-s2.0-S0889974600_p4_crop.png)

St0 = f0 D_source / U_source = .2111022
D = H sqrt(beta/AR); L=AR D; U=Re mu/(rho D)
f = (f/f0) St0 U/D; A=.5 D; theta=2 pi f t
z=A sin(theta); vz=2 pi f A cos(theta); az=-(2 pi f)^2 z
CL(theta)=CL_amp sin(theta+phi_lift); CD(theta)=1.2 (assumed)
Fz_mag = m az - qDL CL(theta) + m g    (horizontal tunnel)

The controlling source-anchored gradient state is C122, Re5000_state3_phase54: U=2.01069 m/s, f=12.0145 Hz, Re=5000, CL=-1.7236, a_z=104.69 m/s2. Required force is [-0.032092, 0, 58.478] N. Its ||G||F=3.69979 T/m occurs at one actual phase, not at independently selected aerodynamic/inertial extrema.

The paper subtracts the structural inertial tare before reporting lift. Its fluid lift includes fluid acceleration effects. Accordingly no generic added-mass term is added; the actual MSBS model inertia is added separately in Newton-Euler balance. Graph readings are approximately +/-0.05 in CL at low amplitude, +/-0.1 at high amplitude, and +/-5-10 deg phase. These are reading estimates, not experimental uncertainty statistics.

Air studies use Re=2300 and5000, with U<=7 m/s, AR=8 at 3%/10% and AR=4 at20%. Re=5000, changed aspect ratio/end conditions and confinement require transfer assumptions. The inline cases retain A/D=.05 and lambda*=1.7,2.2,2.7,3.5,5 with legacy mean/harmonic drag and phase; those exact coefficients cannot be verified from the supplied PDFs. Their labels are screening coordinates, not confirmed wake identities.


---

# 7a. Conditional input ledger and phase resolution

The following inputs are exposed because a repeatable numerical result is not the same as a checked source extraction. The inline rows below are retained engineering screens from the existing case files. Their cited Nishihara Fig8/9 source is absent from the supplied archive. No claim is made that the numbers have been newly extracted from that paper.

| lambda*=U/(fD) | Mean CD | Harmonic CD amplitude | Phase wrt displacement (deg) |
|---|---|---|---|
| 1.7 | 0.95 | 1.05 | 5 |
| 2.2 | 1.27 | 0.5 | 20 |
| 2.7 | 1.45 | 0.25 | 0 |
| 3.5 | 1.2 | 0.12 | 35 |
| 5 | 1.03 | 0.1 | -90 |

Inline: x=.05D sin(theta); ax=-(2 pi f)^2 x
CD=CD_mean+CD_amp sin(theta+phi); f=U/(lambda*D)
Fx_mag=m ax-qDL CD-Fx_gravity; other aero components assumed zero

The NACA12-deg legacy rows use CD=.053 and Cm=0 for all three speeds. The baseline0.6m/10% geometry uses CL=.8200,.8587746649,1.010157855 at U=10,25,40 m/s, respectively. They are associated with approximate low-Re reference-curve values, then held when the physical model is rescaled. Their many decimal places reflect arithmetic/interpolation, not source reading precision. Re is recalculated from the resized chord; coefficients are not represented as newly measured at that Re.

The mean-drag-only crossflow assumption CD=1.2 omits drag harmonics and unsteady moments. Its three lift states use the paired amplitude/phase entries on the previous page. Inline and crossflow rigid-body inertia use the resolved model mass in each arrangement, not the source water-channel cylinder mass. Angular rates/accelerations are zero in these studies.

| Family | Samples/cycle | Max ||G||F (T/m) | Max entry (T/m) | Relative shortfall vs288 |
|---|---|---|---|---|
| crossflow | 72 | 3.69979 | 3.020866 | 0 |
| crossflow | 144 | 3.69979 | 3.020866 | 0 |
| crossflow | 288 | 3.69979 | 3.020866 | 0 |
| inline | 72 | 2.457323 | 1.984062 | 0 |
| inline | 144 | 2.457323 | 1.984062 | 0 |
| inline | 288 | 2.457323 | 1.984062 | 0 |

Resolution check: the0.6m/3% horizontal,10%-volume cylinder screens are rerun at72,144 and288 phase samples for each speed/state group. Their controlling gradient maxima agree at displayed precision. This verifies those sampled harmonic envelopes; it does not bound neglected source harmonics or coefficient uncertainty. The six extra runs are validation runs, additional to the168-study comparison.


---

# 8. Geometry, magnet size and five auxiliary concepts

For square tunnel side H, A_T=H^2. The blockage parameter controls geometrically similar model size, never a force multiplier. At every selected attitude the orthographic projection and conservative wall envelope are checked. This is geometric blockage only; solid/wake blockage corrections to the aerodynamic coefficients are not invented.

| Geometry | At 3% and10% | At20% / consequence |
|---|---|---|
| Sphere and cuboid | One uniformly scaled article per blockage/tunnel | Same shape; all selected attitudes fit. |
| Ahmed | Bounded silhouette proxy at maximum yaw15 deg | Same aspect ratio and scaled source floor gap; mesh projection not integrated. |
| Transverse cylinder | AR=8; L/H=sqrt(8 beta) | AR=8 would give L/H=1.265 and cannot fit. Approved AR=4 gives .8944. |
| NACA0012 wing | AR=3; common geometry across0,7,12 deg | Approved AR=1.25. Span shortened, chord increased to restore20%. |
| SC(2)-0714 wing | AR=3; common geometry across0,7,16 deg | Approved AR=1.5. Changes finite-wing applicability. |

Large single magnets occupy 95% of each dimension of the valid inscribed cuboid (85.7375% of its volume), allowing a geometric margin. They are large cuboid proxies, not a CAD-optimised magnet of arbitrary shape. The 10%-volume alternative scales all dimensions by .464159. The earlier 15%-of-tunnel magnet cap is not applied: the current request compares containment-limited magnets. Automatic +x_B,+y_B,+z_B magnetisations are alternative immutable builds, not three magnets installed together or a magnet turning independently inside a pitched model.

For six-component cuboid/Ahmed loads, auxiliaries reserve space by using smaller separated components. d=[dx,dy,dz] is the valid inscribed cuboid; centres below are fractions of d relative to its centre. Dimensions are normalised fractions before equal-volume scaling. Auxiliary plus/minus dipoles cancel their uniform-field net moment and supply gradient-mediated torque. Main magnet axes are tested automatically. Some axis/layout combinations remain rank deficient and are rejected.

| Layout | Centres and magnetisations | Dimensions / reason |
|---|---|---|
| L1 | Main at0; pair at +/- .37dy e_y, dipoles +/-e_z | Main [.9,.4,.9]; pair each [.9,.22,.9]. Lateral lever plus transverse dipoles for roll authority. |
| L2 | Same lateral centres, dipoles +/-e_y | Same dimensions. Radial pair tests a different independent gradient-to-roll channel. |
| L3 | Main at0; pair at +/- .37dz e_z, dipoles +/-e_y | Main [.9,.9,.4]; pair [.9,.9,.22]. Vertical separation trades lateral room for height. |
| L4 | Same vertical centres, dipoles +/-e_z | Same dimensions. Radial vertical alternative. |
| L5 | Main at0; four auxiliaries at +/- .34dy e_y and +/- .34dz e_z. y pair +/-e_z; z pair +/-e_y | All five [.95,.32,.32]. Two moment arms distribute authority; cancellation can also worsen conditioning. |

All five layouts have equal total magnet volume .4864*V_envelope before the small-volume factor. L1-L4 dimensions are scaled by (.4864/.6804)^(1/3); L5 already has .4864. Volumes are matched across these five concepts, although they are smaller than the near-fill single magnet. Magnets remain disjoint and contained. Shrinking preserves centre separations. Sawada Fig4 motivates a main magnet plus pairs, but these dimensions, locations, N52 material and polarities are new engineering choices, not an asserted reconstruction of JAXA hardware.


---

# 8a. Physical dimensions and aerodynamic references

Dimensions below are for the0.6m tunnel. All lengths, magnet dimensions and offsets scale by5/3 for the1.0m tunnel at the same blockage; areas scale by25/9 and volumes by125/27. H/up flow has identical body/magnet geometry. The force reference area S is listed separately from projected blockage area. Body dimensions are in the family-specific body axes declared in Section2.

| Family | beta% | Body extents (mm) | Inscribed cuboid (mm) | S (m2) |
|---|---|---|---|---|
| Sphere | 3 | 117.3 x 117.3 x 117.3 | 67.7 x 67.7 x 67.7 | 0.0108 |
| Sphere | 10 | 214.1 x 214.1 x 214.1 | 123.6 x 123.6 x 123.6 | 0.036 |
| Sphere | 20 | 302.8 x 302.8 x 302.8 | 174.8 x 174.8 x 174.8 | 0.072 |
| DLR cuboid | 3 | 108.6 x 88.82 x 49.34 | 108.6 x 88.82 x 49.34 | 0.00964191 |
| DLR cuboid | 10 | 198.2 x 162.2 x 90.09 | 198.2 x 162.2 x 90.09 | 0.0321397 |
| DLR cuboid | 20 | 280.3 x 229.3 x 127.4 | 280.3 x 229.3 x 127.4 | 0.0642794 |
| Ahmed 35 deg | 3 | 251.5 x 93.73 x 69.39 | 174 x 93.73 x 69.39 | 0.00650203 |
| Ahmed 35 deg | 10 | 459.3 x 171.1 x 126.7 | 317.6 x 171.1 x 126.7 | 0.0216734 |
| Ahmed 35 deg | 20 | 649.5 x 242 x 179.2 | 449.2 x 242 x 179.2 | 0.0433469 |
| NACA 0012 | 3 | 105.2 x 315.6 x 12.62 | 52.6 x 47.34 x 8.206 | 0.0332012 |
| NACA 0012 | 10 | 192.1 x 576.2 x 23.05 | 96.03 x 86.43 x 14.98 | 0.110671 |
| NACA 0012 | 20 | 420.8 x 526 x 50.5 | 210.4 x 189.4 x 32.82 | 0.221341 |
| SC(2)-0714 | 3 | 93.68 x 281 x 13.12 | 46.84 x 42.16 x 8.525 | 0.0263277 |
| SC(2)-0714 | 10 | 171 x 513.1 x 23.94 | 85.52 x 76.97 x 15.56 | 0.0877591 |
| SC(2)-0714 | 20 | 342.1 x 513.1 x 47.89 | 171 x 153.9 x 31.13 | 0.175518 |
| Crossflow cylinder | 3 | 36.74 x 293.9 x 36.74 | 25.98 x 293.9 x 25.98 | 0.0108 |
| Crossflow cylinder | 10 | 67.08 x 536.7 x 67.08 | 47.43 x 536.7 x 47.43 | 0.036 |
| Crossflow cylinder | 20 | 134.2 x 536.7 x 134.2 | 94.87 x 536.7 x 94.87 | 0.072 |
| Inline cylinder | 3 | 36.74 x 293.9 x 36.74 | 25.98 x 293.9 x 25.98 | 0.0108 |
| Inline cylinder | 10 | 67.08 x 536.7 x 67.08 | 47.43 x 536.7 x 47.43 | 0.036 |
| Inline cylinder | 20 | 134.2 x 536.7 x 134.2 | 94.87 x 536.7 x 94.87 | 0.072 |

For any row, large single-magnet dimensions are .95 times the inscribed-cuboid dimensions, while the10%-volume alternative is another factor .464159 smaller. Multi-magnet dimensions follow Section8 and the equal-volume factor. Exact selected magnet dimensions, centres, magnetisation vectors, CoM and inertia are exported in selected_geometry_and_magnets.json; no rounding from this table enters the solver.

The final clearance audit reconstructs body origin as r_origin,T=r_C,T-R_TB*r_C,B for the selected fixed arrangement. It then tests the complete bounding envelope plus prescribed displacement at every scenario. The largest cross-section wall fraction is 0.960341, below1 for all168 selected arrangements. This includes the actual off-centre CoM, rather than equating CoM and body origin.


---

# 9. Magnetic solution, fixed mass and field origin

B(rho) = B_C + G rho; G=G^T; trace(G)=0
F_i=G m_i
M_i=rho_i x (G m_i) + m_i x (B_C+G rho_i)
x=[B_Cx,B_Cy,B_Cz,gxx,gyy,gxy,gxz,gyz]; A x=w_mag
B_O = B_C - G r_C,T; one common G in both reference systems

Local offsets rho_i are measured from each arrangement's resolved CoM. Translation changes the fixed-origin intercept B_O, not the local A or the common gradient. Cylinder positions and velocities are analytic and explicitly specified; no acceleration is integrated across independent rows. Absolute CoM is distinct from body-origin plotting placement. For pure harmonic helper motion, analytic position is supported only without angular oscillation.

The source-free symmetric trace-free gradient has five independent degrees of freedom. Its orthonormal basis makes the norm equal to ||G||F. Force and moment residual equations have separate whole-study scales. The solver first minimises scaled wrench residual and then the configured magnetic norm. Passing residual does not establish coil or control-system feasibility.

J^2 = |B_C|^2 + (L_ref^2/12) ||G||F^2
L_ref = max(model outer dimensions); u_proxy=J^2/(2 mu0)
Chosen fixed set = arg min_j max_k J_jk, accepted for every scenario k

J is the analytic RMS affine field in a CoM-centred reference cube, and u_proxy is a vacuum-equivalent applied-field energy-density proxy. Neither is coil stored energy, power, current or voltage. Each physical case retains its own reference length. Cross-model J rankings therefore compare case-dependent regularisation; B and G targets are also reported separately. Significant-coupling sensitivity solves use alternate lengths already present in v0.4.1; they are exported separately.

Magnet assumptions: generic N52 minimum Br=1.43 T, density7500 kg/m3, uniform magnetisation factor1. m_d=Br*V/mu0. For each physical body, residual mass=.30 times the near-fill large single magnet mass. This residual mass is then held fixed for all candidate layouts and both volume fractions. Total mass=magnet mass+residual mass. The residual is a uniform outer-primitive proxy about body origin; cavities are not subtracted. Per-magnet cuboid inertia and parallel-axis shifts are included. No CAD-derived shell or measured mass is claimed.

Large near-fill magnets can make physically heavy test articles: selected total masses span 0.0433 to 503 kg. These are consequences of the stated containment-limited solid-NdFeB comparison. Hardware mass, grade, packaging, demagnetisation and coil limits need independent design choices before procurement.


---

# 10. Tool audit, implemented changes and verification

| Capability | Baseline v0.4.1 | Action for this study |
|---|---|---|
| Paired 6-component states; frame rotation; moment shift; per-set mass/inertia | Available | Retained; corrected source case transformations in new constructors. |
| STF field/gradient solve, residual acceptance, extrema, minimax/maximin | Available | Retained; design targets use only an accepted fixed set. |
| Automatic magnetisation axes; manual auxiliaries | Available | Three main axes plus five engineered equal-volume layouts. |
| Scenario relationship and ordered history semantics | Missing | Added independent/fixed_envelope/time_history; validate monotonic grouped timestamps. |
| Absolute CoM / tunnel-origin field | Missing | Added nominal, specified and pure translational harmonic positions; export B_O=B_C-G r_C. |
| Mass independent of magnet shrink | Only manual total overrides | Added mass.non_magnet_mass_kg; legacy factor remains backward-compatible. |
| Source attitude without Euler ambiguity | Euler rows | Added attitude_R_TB proper-rotation cell input. |
| Maximum attitude blockage, shorter-span models, batch comparison | Case-specific/manual | New reproducible research constructors and run manifest; added wall/sweep and layout-disjointness checks. |
| Numerical acceleration integration, CAD projection, coil currents/dynamics | Missing | Deferred: not required for explicit analytic current motion; requires further physical data. |

Baseline repository commit: f4012c9060cb1cc6afe49fd9ccb42b80e7ac1a4d. All65 original tests passed before changes. Final suite:76 passed,0 failed,0 incomplete. New tests cover affine-origin field invariance, translation leaving local solve unchanged, harmonic position/acceleration consistency, grouped timestamp ordering, fixed residual mass under10%-volume shrink, source Fourier values, source rotations, auxiliary rank/equal volumes/no overlap, approved shorter-span clearance and upward gravity. Existing tests cover Newton-Euler gyroscopic demand, gradient constraints, moment shifts, load equivalence, ranking and exports.

The first updated run exposed missing documentation entries, which were added before the passing final run. Scientific batches were recomputed after source sign and datum corrections. The batch does not substitute old saved results. Source files are hashed in the report build record. Code and report are published on the research branch; the final commit and delivery status are recorded in the OneDrive handover manifest.

## Reproduce

MATLAB: cd('<repository>/MatLab/msbs_requirement_tool')
runAllTests
addpath('src','cases','research'); run_portfolio
Python: research/scripts/analyse_results.py
        research/scripts/build_report.py

Every study folder retains its exact study_input.mat, primary scenario CSV, per-set summary, extrema, both ranking tables, warnings and significant-coupling sensitivity results. The MAT input is directly runnable through runStudy. The global component-extrema CSV retains the complete simultaneous source/result row. The report is generated from current per-case files, with no mixing of independent component extrema into a new wrench.


---

# 11. Comparative results and interpretation

| Family | Max local B (T) | Max ||G||F (T/m) | Controlling study / meaning |
|---|---|---|---|
| Sphere | 0 | 0.38101 | C002 |
| DLR cuboid | 0.099583 | 2.0728 | C026 |
| Ahmed 35 deg | 0.08041 | 1.0543 | C072 |
| NACA 0012 | 0.42887 | 20.305 | C076 |
| SC(2)-0714 | 0.55652 | 35.809 | C100 |
| Crossflow cylinder | 0 | 3.6998 | C122 |
| Inline cylinder | 0 | 2.7434 | C148 |

Each line takes the harder of horizontal/upward for that family, tunnel size and magnet volume. The20% cylinder/airfoil points change aspect ratio and therefore are not a pure blockage-only continuation.

Small magnets increase aerodynamic force per dipole and retain the same shell mass. For pure gravity, the near-fill versus10%-volume gradient ratio is approximately (0.4/0.1)/(1.3/1)=3.077 when both use the same direction and no torque coupling. Aerodynamic contributions can increase this further. At fixed U under uniform geometric scaling, aerodynamic G scales approximately1/model length, while aerodynamic torque/dipole field is approximately size-invariant; gravity-related field and coupling can have different scaling.

The crossflow gradient maximum comes from prescribed acceleration and lift sharing the same phase. Frequency/acceleration are not controller-feasible merely because speeds are low. Horizontal and upward gravity can either add to or oppose a given aerodynamic demand. A larger speed is not always the controlling field state, especially for offset/auxiliary configurations where gradient torque and field torque trade off.


---

# 12. Per-component target maxima with original states

The following are largest absolute signed entries over the selected immutable arrangements, including conditional airfoil/inline screens. Each row names the actual state that produces it. These entries define a component capacity envelope; using all their magnitudes simultaneously would create an untested field/gradient combination. CoM field B_C and fixed-origin intercept B_O are different quantities.

| Quantity | Signed value at |max| | Study | Scenario | Selected arrangement |
|---|---|---|---|---|
| B_Cx (T) | -0.5349642 | C098 | U40_a16 | Automatic +z_B |
| B_Cy (T) | -0.03129402 | C030 | U10_a0_b0 | layout3_main_axis1 |
| B_Cz (T) | 0.1533985 | C098 | U40_a16 | Automatic +z_B |
| Gxx (T/m) | 14.78096 | C100 | U40_a16 | Automatic +z_B |
| Gyy (T/m) | 13.95091 | C100 | U40_a16 | Automatic +z_B |
| Gzz (T/m) | -28.73188 | C100 | U40_a16 | Automatic +z_B |
| Gxy (T/m) | -0.4580289 | C026 | U50_a45_b-45 | layout3_main_axis1 |
| Gxz (T/m) | -4.872921 | C098 | U40_a16 | Automatic +z_B |
| Gyz (T/m) | 0.6035017 | C034 | U40_a0_b-45 | layout2_main_axis1 |
| B_Ox (T) | -0.5349642 | C098 | U40_a16 | Automatic +z_B |
| B_Oy (T) | -0.03129402 | C030 | U10_a0_b0 | layout3_main_axis1 |
| B_Oz (T) | 0.1533985 | C098 | U40_a16 | Automatic +z_B |

## Controlling gradient: complete simultaneous state

C100 = sc20714_T060_b03_up_v10; S00009 / U40_a16; Automatic +z_B. U=40 m/s, model Re=253608.3, blockage3%, upward flow,10% magnet volume. The following values coexist in this state:

F_aero=[1.1095, 0, 47.474] N
M_aero,C=[0, 0.91399, 0] N m
F_gravity=[-0.42459, 0, -2.5999e-17] N
F_mag,req=[-0.68486, 0, -47.474] N
M_mag,req=[0, -0.91399, 0] N m
B_C=[-0.53496, 0, 0.1534] T
G=[[14.781, 0, -4.6722];
   [0, 13.951, 0];
   [-4.6722, 0, -28.732]] T/m

Maximum residual across all selected rows is 1.78e-14; acceptance threshold is1e-6. Rejected arrangements are retained in the candidate CSV but excluded from this envelope. component_extrema_full_states.csv also provides signed minima/maxima, source-anchored maxima and the wider envelope of every accepted fixed candidate.


---

# 13. Limits, assumptions and the next decisions

The requested comparisons are computationally complete for the stated proxies. The report cannot turn unsupported inputs into validated aerodynamic evidence. In particular, the SC short-wing lower-Re transfer controls the largest targets; the inline harmonic coefficients lack a checked primary PDF; NACA12-deg drag/moment and its scaled-Re lift remain assumptions. The source-anchored subset should be used as a separate provisional engineering reference.

| Assumption / limitation | Consequence and action |
|---|---|
| 20% geometric blockage; no source-specific correction | Treat as confinement sensitivity. Obtain confined-model data/validated CFD before calling it a tunnel load prediction. |
| Shorter span at20% | AR changes to4 /1.25 /1.5 for cylinder/NACA/SC. Hold aspect ratio fixed only when comparing3% versus10%. |
| Approximate figure reads | Rounding is intentionally limited. Re-extract digital data for precision; repeat coupled amplitude/phase uncertainty studies before design margins. |
| Constant coefficient transfer across speed/Re | Multiple speeds are tested, but this does not constitute multiple measured polars. Especially important for stall, drag crisis and Ahmed switching. |
| Steady6D cases and prescribed cylinder translation | No quantified rotational dynamic envelope or closed-loop gust specification. Define angular amplitude/rate/acceleration demands separately. |
| Only three automatic single-magnet axes | Best means best among enumerated candidates, not a global continuous orientation optimum. Positive and negative axes are equivalent for unconstrained symmetric field capacity; oblique axes remain a possible extension. |
| Generic magnet properties / large solid magnets | Specify real magnet grade/part data and buildable shell mass. The thin airfoil magnet fit is a legacy proxy, not a fresh CAD containment proof. |
| Common affine field and point-dipole abstraction | No coil maps, current/voltage/thermal limits, slew, field higher derivatives or control stability. Auxiliary centre fields differ from B_C. |
| Model-dependent RMS objective | Selected configuration can change with reference length; significant-coupling sensitivity tables enable a separate robustness review. No universal coil-power optimum is claimed. |

Recommended next evidence step: obtain the Nishihara2005 full paper and a low-Re finite-wing SC(2)-0714 force/moment dataset (or validated CFD) for the actual short-span geometries. Then replace the conditional rows and rerun the same matrix. For Ahmed transition sizing, obtain synchronized six-axis data or specify a physically justified uncertainty model rather than combine unrelated mean and peak components.

No numerical coil ratings or safety factor are assigned here. Any design margin must be chosen after separating aerodynamic uncertainty, magnet material uncertainty, trajectory bandwidth and actuator field-map limitations. A single “maximum field” without its tensor, position, fixed arrangement and original load state would conceal those distinctions.


---

# 14. References and source locations

[1] Achenbach (1972), Experiments on the flow past spheres at very high Reynolds numbers, JFM54,565-575. Fig4 p568; apparatus p566. <link href="https://doi.org/10.1017/S0022112072000874" color="#176b8a">Primary source</link>.

[2] Jann &amp; Geisbauer (2013), Approximated Steady Aerodynamic Coefficients for Two Cuboids and a Hemispherical Shell Used in Airdrop Simulation, AIAA2013-1282. Geometry p3; axes Fig9 p9; Tables2/8 pp11/17. <link href="https://doi.org/10.2514/6.2013-1282" color="#176b8a">Primary source</link>.

[3] Meile et al. (2011 issue), Experiments and Numerical Simulations on the Aerodynamics of the Ahmed Body, CFD Letters3(1),32-39. Context/validation. <link href="https://akademiabaru.com/submit/index.php/cfdl/article/view/3333" color="#176b8a">Primary source</link>.

[4] Meile et al. (2016), Non-symmetric bi-stable flow around the Ahmed body, IJHFF57,34-47. Figs1,5,6,18,20; Section2.3; Section5.3. <link href="https://doi.org/10.1016/j.ijheatfluidflow.2015.11.002" color="#176b8a">Primary source</link>.

[5] Carberry, Sheridan &amp; Rockwell (2001), Forces and wake modes of an oscillating cylinder, JFS15,523-532. Fig2a and Eq2 on p526; method pp524-525. <link href="https://doi.org/10.1006/jfls.2000.0363" color="#176b8a">Primary source</link>.

[6] Morse &amp; Williamson (2009), Fluid forcing, wake modes, and transitions for a cylinder undergoing controlled oscillations, JFS25,697-712. Regime-map context. <link href="https://doi.org/10.1016/j.jfluidstructs.2008.12.003" color="#176b8a">Primary source</link>.

[7] Morse &amp; Williamson (2009), Prediction of vortex-induced vibration response by employing controlled motion, JFM634,5-39. Controlled/free-motion interpretation. <link href="https://www.cambridge.org/core/journals/journal-of-fluid-mechanics/article/abs/prediction-of-vortex-induced-vibration-response-by-employing-controlled-motion/5895EE0EFCECDC64607C687FE34F3C62" color="#176b8a">Primary source</link>.

[8] Williamson &amp; Roshko (1988), Vortex formation in the wake of an oscillating cylinder, JFS2,355-381. Wake topology context. <link href="https://doi.org/10.1016/S0889-9746(88)90058-8" color="#176b8a">Primary source</link>.

[9] McAlister, Carr &amp; McCroskey (1978), Dynamic Stall Experiments on the NACA0012 Airfoil, NASA TP-1100. Experiment PDF p12. <link href="https://ntrs.nasa.gov/citations/19780009057" color="#176b8a">Primary source</link>.

[10] Jenkins (1989), NASA SC(2)-0714 Airfoil Data Corrected for Sidewall Boundary-Layer Effects, NASA TP-2890. Summary PDF p2. <link href="https://ntrs.nasa.gov/citations/19890008197" color="#176b8a">Primary source</link>.

[11] Sawada, Suda &amp; Kunimasu (2004), NAL60cm Magnetic Suspension and Balance System, ICAS2004-3.1.2. Fig4 p2; roll discussion and Table1 p3. <link href="https://www.icas.org/icas_archive/ICAS2004/PAPERS/182.PDF" color="#176b8a">Primary source</link>.

[12] Harris, McGhee &amp; Allison (1980), Low-Speed Aerodynamic Characteristics of a14-Percent-Thick NASA Phase2 Supercritical Airfoil Designed for a Lift Coefficient of0.7, NASA TM-81912. Fig11a/b/c printed pp61/63/65; PDF pp63/65/67. <link href="https://ntrs.nasa.gov/api/citations/19830013896/downloads/19830013896_Redacted.pdf" color="#176b8a">Primary source</link>.

[13] Vaddi et al., Active Flow Control of NACA0012 airfoil using Sawtooth Direct Current Augmented Dielectric Barrier Discharge Plasma Actuator, author manuscript. Fig5 PDF p8; passive curves only. <link href="https://arxiv.org/abs/2106.11453" color="#176b8a">Primary source</link>.

[14] Oruganti &amp; Narsipur, Airfoil Lift Calculation Using Wind Tunnel Wall Pressures, author manuscript2006.09560. NACA reference curves Fig10 PDF p8. <link href="https://arxiv.org/abs/2006.09560" color="#176b8a">Primary source</link>.

Unverified inline attribution: Nishihara, Kaneko & Watanabe (2005), JFS20,505-518, DOI10.1016/j.jfluidstructs.2005.02.003. Publication identity was located; the numerical Fig8/9 readings in the legacy cases were not checked against full text. The Carberry2005 reference from the handover is also not present in the supplied archive.

Reproducibility paths (relative to tool root): research/outputs/study_manifest.csv; case_comparison.csv; selected_fixed_configuration_results.csv; all_scenario_results.csv; component_extrema_full_states.csv. Input MAT files and candidate/sensitivity outputs are in each case_id subfolder. Appendix study IDs below map directly to the full case names in the manifest.


---

# Appendix: Sphere - every study

H=horizontal, U=upward flow. V%=magnet volume relative to the corresponding large version. B=max local magnet-centre norm; G=max tensor Frobenius norm over the fixed arrangement. An arrangement is chosen once for all speeds/attitudes/phases in that study. Model-dependent RMS field cost determines that choice.

| ID | H(m) | beta% | Flow | V% | Selected set | B(T) | G(T/m) | Mass(kg) |
|---|---|---|---|---|---|---|---|---|
| C001 | 0.6 | 3 | H | 100 | +z_B | 0 | 0.1051 | 2.594 |
| C002 | 0.6 | 3 | H | 10 | +z_B | 0 | 0.381 | 0.7982 |
| C003 | 0.6 | 3 | U | 100 | +x_B | 0 | 0.09884 | 2.594 |
| C004 | 0.6 | 3 | U | 10 | +x_B | 0 | 0.2759 | 0.7982 |
| C005 | 0.6 | 10 | H | 100 | +z_B | 0 | 0.103 | 15.79 |
| C006 | 0.6 | 10 | H | 10 | +z_B | 0 | 0.3185 | 4.858 |
| C007 | 0.6 | 10 | U | 100 | +x_B | 0 | 0.1022 | 15.79 |
| C008 | 0.6 | 10 | U | 10 | +x_B | 0 | 0.3099 | 4.858 |
| C009 | 0.6 | 20 | H | 100 | +z_B | 0 | 0.1029 | 44.65 |
| C010 | 0.6 | 20 | H | 10 | +z_B | 0 | 0.3169 | 13.74 |
| C011 | 0.6 | 20 | U | 100 | +x_B | 0 | 0.1027 | 44.65 |
| C012 | 0.6 | 20 | U | 10 | +x_B | 0 | 0.3143 | 13.74 |
| C013 | 1 | 3 | H | 100 | +z_B | 0 | 0.103 | 12.01 |
| C014 | 1 | 3 | H | 10 | +z_B | 0 | 0.3199 | 3.695 |
| C015 | 1 | 3 | U | 100 | +x_B | 0 | 0.102 | 12.01 |
| C016 | 1 | 3 | U | 10 | +x_B | 0 | 0.3078 | 3.695 |
| C017 | 1 | 10 | H | 100 | +z_B | 0 | 0.1029 | 73.09 |
| C018 | 1 | 10 | H | 10 | +z_B | 0 | 0.3167 | 22.49 |
| C019 | 1 | 10 | U | 100 | +x_B | 0 | 0.1028 | 73.09 |
| C020 | 1 | 10 | U | 10 | +x_B | 0 | 0.3152 | 22.49 |
| C021 | 1 | 20 | H | 100 | +z_B | 0 | 0.1029 | 206.7 |
| C022 | 1 | 20 | H | 10 | +z_B | 0 | 0.3166 | 63.61 |
| C023 | 1 | 20 | U | 100 | +x_B | 0 | 0.1029 | 206.7 |
| C024 | 1 | 20 | U | 10 | +x_B | 0 | 0.3161 | 63.61 |

Study ID mapping: C001=sphere_T060_b03_h_v100; C002=sphere_T060_b03_h_v10; C003=sphere_T060_b03_up_v100; C004=sphere_T060_b03_up_v10; C005=sphere_T060_b10_h_v100; C006=sphere_T060_b10_h_v10; C007=sphere_T060_b10_up_v100; C008=sphere_T060_b10_up_v10; C009=sphere_T060_b20_h_v100; C010=sphere_T060_b20_h_v10; C011=sphere_T060_b20_up_v100; C012=sphere_T060_b20_up_v10; C013=sphere_T100_b03_h_v100; C014=sphere_T100_b03_h_v10; C015=sphere_T100_b03_up_v100; C016=sphere_T100_b03_up_v10; C017=sphere_T100_b10_h_v100; C018=sphere_T100_b10_h_v10; C019=sphere_T100_b10_up_v100; C020=sphere_T100_b10_up_v10; C021=sphere_T100_b20_h_v100; C022=sphere_T100_b20_h_v10; C023=sphere_T100_b20_up_v100; C024=sphere_T100_b20_up_v10

Each reported maximum belongs to an actual result row. Component maxima and their complete six-component load/field states are in component_extrema_full_states.csv. For all candidates rather than the selected fixed set, inspect the per-case scenario and sensitivity CSVs.


---

# Appendix: DLR cuboid - every study

H=horizontal, U=upward flow. V%=magnet volume relative to the corresponding large version. B=max local magnet-centre norm; G=max tensor Frobenius norm over the fixed arrangement. An arrangement is chosen once for all speeds/attitudes/phases in that study. Model-dependent RMS field cost determines that choice.

| ID | H(m) | beta% | Flow | V% | Selected set | B(T) | G(T/m) | Mass(kg) |
|---|---|---|---|---|---|---|---|---|
| C025 | 0.6 | 3 | H | 100 | L2/axis1 | 0.007827 | 0.3104 | 2.653 |
| C026 | 0.6 | 3 | H | 10 | L3/axis1 | 0.03737 | 2.073 | 1.091 |
| C027 | 0.6 | 3 | U | 100 | L3/axis1 | 0.004835 | 0.2868 | 2.653 |
| C028 | 0.6 | 3 | U | 10 | L3/axis1 | 0.01919 | 1.141 | 1.091 |
| C029 | 0.6 | 10 | H | 100 | L2/axis1 | 0.01015 | 0.2976 | 16.15 |
| C030 | 0.6 | 10 | H | 10 | L3/axis1 | 0.04599 | 1.433 | 6.642 |
| C031 | 0.6 | 10 | U | 100 | L3/axis1 | 0.008926 | 0.2898 | 16.15 |
| C032 | 0.6 | 10 | U | 10 | L3/axis1 | 0.03602 | 1.171 | 6.642 |
| C033 | 0.6 | 20 | H | 100 | L2/axis1 | 0.01269 | 0.2955 | 45.67 |
| C034 | 0.6 | 20 | H | 10 | L2/axis1 | 0.07971 | 1.257 | 18.79 |
| C035 | 0.6 | 20 | U | 100 | L3/axis1 | 0.01267 | 0.2909 | 45.67 |
| C036 | 0.6 | 20 | U | 10 | L3/axis1 | 0.05143 | 1.181 | 18.79 |
| C037 | 1 | 3 | H | 100 | L2/axis1 | 0.009612 | 0.2984 | 12.28 |
| C038 | 1 | 3 | H | 10 | L3/axis1 | 0.04251 | 1.499 | 5.053 |
| C039 | 1 | 3 | U | 100 | L3/axis1 | 0.008138 | 0.2895 | 12.28 |
| C040 | 1 | 3 | U | 10 | L3/axis1 | 0.03278 | 1.167 | 5.053 |
| C041 | 1 | 10 | H | 100 | L2/axis1 | 0.01425 | 0.295 | 74.76 |
| C042 | 1 | 10 | H | 10 | L2/axis1 | 0.08415 | 1.243 | 30.75 |
| C043 | 1 | 10 | U | 100 | L3/axis1 | 0.01496 | 0.2913 | 74.76 |
| C044 | 1 | 10 | U | 10 | L3/axis1 | 0.06082 | 1.185 | 30.75 |
| C045 | 1 | 20 | H | 100 | L2/axis1 | 0.01853 | 0.2942 | 211.5 |
| C046 | 1 | 20 | H | 10 | L2/axis1 | 0.09958 | 1.225 | 86.97 |
| C047 | 1 | 20 | U | 100 | L3/axis1 | 0.0212 | 0.2919 | 211.5 |
| C048 | 1 | 20 | U | 10 | L3/axis1 | 0.0865 | 1.192 | 86.97 |

Study ID mapping: C025=cuboid_T060_b03_h_v100; C026=cuboid_T060_b03_h_v10; C027=cuboid_T060_b03_up_v100; C028=cuboid_T060_b03_up_v10; C029=cuboid_T060_b10_h_v100; C030=cuboid_T060_b10_h_v10; C031=cuboid_T060_b10_up_v100; C032=cuboid_T060_b10_up_v10; C033=cuboid_T060_b20_h_v100; C034=cuboid_T060_b20_h_v10; C035=cuboid_T060_b20_up_v100; C036=cuboid_T060_b20_up_v10; C037=cuboid_T100_b03_h_v100; C038=cuboid_T100_b03_h_v10; C039=cuboid_T100_b03_up_v100; C040=cuboid_T100_b03_up_v10; C041=cuboid_T100_b10_h_v100; C042=cuboid_T100_b10_h_v10; C043=cuboid_T100_b10_up_v100; C044=cuboid_T100_b10_up_v10; C045=cuboid_T100_b20_h_v100; C046=cuboid_T100_b20_h_v10; C047=cuboid_T100_b20_up_v100; C048=cuboid_T100_b20_up_v10

Each reported maximum belongs to an actual result row. Component maxima and their complete six-component load/field states are in component_extrema_full_states.csv. For all candidates rather than the selected fixed set, inspect the per-case scenario and sensitivity CSVs.


---

# Appendix: Ahmed 35 deg - every study

H=horizontal, U=upward flow. V%=magnet volume relative to the corresponding large version. B=max local magnet-centre norm; G=max tensor Frobenius norm over the fixed arrangement. An arrangement is chosen once for all speeds/attitudes/phases in that study. Model-dependent RMS field cost determines that choice.

| ID | H(m) | beta% | Flow | V% | Selected set | B(T) | G(T/m) | Mass(kg) |
|---|---|---|---|---|---|---|---|---|
| C049 | 0.6 | 3 | H | 100 | L2/axis3 | 0.003882 | 0.2543 | 6.31 |
| C050 | 0.6 | 3 | H | 10 | L2/axis3 | 0.0192 | 1.049 | 2.595 |
| C051 | 0.6 | 3 | U | 100 | L4/axis1 | 0.00404 | 0.2559 | 6.31 |
| C052 | 0.6 | 3 | U | 10 | L4/axis1 | 0.02657 | 1.046 | 2.595 |
| C053 | 0.6 | 10 | H | 100 | L2/axis3 | 0.00696 | 0.2542 | 38.4 |
| C054 | 0.6 | 10 | H | 10 | L2/axis3 | 0.03409 | 1.047 | 15.79 |
| C055 | 0.6 | 10 | U | 100 | L4/axis1 | 0.006329 | 0.2564 | 38.4 |
| C056 | 0.6 | 10 | U | 10 | L4/axis1 | 0.03858 | 1.051 | 15.79 |
| C057 | 0.6 | 20 | H | 100 | L2/axis3 | 0.009801 | 0.2542 | 108.6 |
| C058 | 0.6 | 20 | H | 10 | L2/axis3 | 0.04823 | 1.046 | 44.67 |
| C059 | 0.6 | 20 | U | 100 | L4/axis1 | 0.008429 | 0.2565 | 108.6 |
| C060 | 0.6 | 20 | U | 10 | L4/axis1 | 0.04972 | 1.053 | 44.67 |
| C061 | 1 | 3 | H | 100 | L2/axis3 | 0.006364 | 0.2542 | 29.21 |
| C062 | 1 | 3 | H | 10 | L2/axis3 | 0.03112 | 1.047 | 12.02 |
| C063 | 1 | 3 | U | 100 | L4/axis1 | 0.005887 | 0.2563 | 29.21 |
| C064 | 1 | 3 | U | 10 | L4/axis1 | 0.03625 | 1.05 | 12.02 |
| C065 | 1 | 10 | H | 100 | L2/axis3 | 0.01154 | 0.2542 | 177.8 |
| C066 | 1 | 10 | H | 10 | L2/axis3 | 0.05685 | 1.046 | 73.12 |
| C067 | 1 | 10 | U | 100 | L4/axis1 | 0.00971 | 0.2566 | 177.8 |
| C068 | 1 | 10 | U | 10 | L4/axis1 | 0.05655 | 1.053 | 73.12 |
| C069 | 1 | 20 | H | 100 | L2/axis3 | 0.01628 | 0.2542 | 502.9 |
| C070 | 1 | 20 | H | 10 | L2/axis3 | 0.08041 | 1.046 | 206.8 |
| C071 | 1 | 20 | U | 100 | L4/axis1 | 0.01321 | 0.2567 | 502.9 |
| C072 | 1 | 20 | U | 10 | L4/axis1 | 0.07526 | 1.054 | 206.8 |

Study ID mapping: C049=ahmed_T060_b03_h_v100; C050=ahmed_T060_b03_h_v10; C051=ahmed_T060_b03_up_v100; C052=ahmed_T060_b03_up_v10; C053=ahmed_T060_b10_h_v100; C054=ahmed_T060_b10_h_v10; C055=ahmed_T060_b10_up_v100; C056=ahmed_T060_b10_up_v10; C057=ahmed_T060_b20_h_v100; C058=ahmed_T060_b20_h_v10; C059=ahmed_T060_b20_up_v100; C060=ahmed_T060_b20_up_v10; C061=ahmed_T100_b03_h_v100; C062=ahmed_T100_b03_h_v10; C063=ahmed_T100_b03_up_v100; C064=ahmed_T100_b03_up_v10; C065=ahmed_T100_b10_h_v100; C066=ahmed_T100_b10_h_v10; C067=ahmed_T100_b10_up_v100; C068=ahmed_T100_b10_up_v10; C069=ahmed_T100_b20_h_v100; C070=ahmed_T100_b20_h_v10; C071=ahmed_T100_b20_up_v100; C072=ahmed_T100_b20_up_v10

Each reported maximum belongs to an actual result row. Component maxima and their complete six-component load/field states are in component_extrema_full_states.csv. For all candidates rather than the selected fixed set, inspect the per-case scenario and sensitivity CSVs.


---

# Appendix: NACA 0012 - every study

H=horizontal, U=upward flow. V%=magnet volume relative to the corresponding large version. B=max local magnet-centre norm; G=max tensor Frobenius norm over the fixed arrangement. An arrangement is chosen once for all speeds/attitudes/phases in that study. Model-dependent RMS field cost determines that choice.

| ID | H(m) | beta% | Flow | V% | Selected set | B(T) | G(T/m) | Mass(kg) |
|---|---|---|---|---|---|---|---|---|
| C073 | 0.6 | 3 | H | 100 | +z_B | 0.04289 | 1.927 | 0.1708 |
| C074 | 0.6 | 3 | H | 10 | +z_B | 0.4289 | 19.98 | 0.05256 |
| C075 | 0.6 | 3 | U | 100 | +z_B | 0.04289 | 2.034 | 0.1708 |
| C076 | 0.6 | 3 | U | 10 | +z_B | 0.4289 | 20.31 | 0.05256 |
| C077 | 0.6 | 10 | H | 100 | +z_B | 0.04289 | 1.009 | 1.039 |
| C078 | 0.6 | 10 | H | 10 | +z_B | 0.4289 | 10.8 | 0.3198 |
| C079 | 0.6 | 10 | U | 100 | +z_B | 0.04289 | 1.118 | 1.039 |
| C080 | 0.6 | 10 | U | 10 | +z_B | 0.4289 | 11.13 | 0.3198 |
| C081 | 0.6 | 20 | H | 100 | +z_B | 0.01787 | 0.1082 | 10.93 |
| C082 | 0.6 | 20 | H | 10 | +z_B | 0.1787 | 1.797 | 3.364 |
| C083 | 0.6 | 20 | U | 100 | +z_B | 0.01787 | 0.2421 | 10.93 |
| C084 | 0.6 | 20 | U | 10 | +z_B | 0.1787 | 2.145 | 3.364 |
| C085 | 1 | 3 | H | 100 | +z_B | 0.04289 | 1.115 | 0.7908 |
| C086 | 1 | 3 | H | 10 | +z_B | 0.4289 | 11.86 | 0.2433 |
| C087 | 1 | 3 | U | 100 | +z_B | 0.04289 | 1.224 | 0.7908 |
| C088 | 1 | 3 | U | 10 | +z_B | 0.4289 | 12.19 | 0.2433 |
| C089 | 1 | 10 | H | 100 | +z_B | 0.04289 | 0.5638 | 4.812 |
| C090 | 1 | 10 | H | 10 | +z_B | 0.4289 | 6.354 | 1.481 |
| C091 | 1 | 10 | U | 100 | +z_B | 0.04289 | 0.6775 | 4.812 |
| C092 | 1 | 10 | U | 10 | +z_B | 0.4289 | 6.682 | 1.481 |
| C093 | 1 | 20 | H | 100 | +z_B | 0.01787 | 0.1029 | 50.61 |
| C094 | 1 | 20 | H | 10 | +z_B | 0.1787 | 0.9508 | 15.57 |
| C095 | 1 | 20 | U | 100 | +x_B | 0.01787 | 0.1696 | 50.61 |
| C096 | 1 | 20 | U | 10 | +z_B | 0.1787 | 1.32 | 15.57 |

Study ID mapping: C073=naca0012_T060_b03_h_v100; C074=naca0012_T060_b03_h_v10; C075=naca0012_T060_b03_up_v100; C076=naca0012_T060_b03_up_v10; C077=naca0012_T060_b10_h_v100; C078=naca0012_T060_b10_h_v10; C079=naca0012_T060_b10_up_v100; C080=naca0012_T060_b10_up_v10; C081=naca0012_T060_b20_h_v100; C082=naca0012_T060_b20_h_v10; C083=naca0012_T060_b20_up_v100; C084=naca0012_T060_b20_up_v10; C085=naca0012_T100_b03_h_v100; C086=naca0012_T100_b03_h_v10; C087=naca0012_T100_b03_up_v100; C088=naca0012_T100_b03_up_v10; C089=naca0012_T100_b10_h_v100; C090=naca0012_T100_b10_h_v10; C091=naca0012_T100_b10_up_v100; C092=naca0012_T100_b10_up_v10; C093=naca0012_T100_b20_h_v100; C094=naca0012_T100_b20_h_v10; C095=naca0012_T100_b20_up_v100; C096=naca0012_T100_b20_up_v10

Each reported maximum belongs to an actual result row. Component maxima and their complete six-component load/field states are in component_extrema_full_states.csv. For all candidates rather than the selected fixed set, inspect the per-case scenario and sensitivity CSVs.


---

# Appendix: SC(2)-0714 - every study

H=horizontal, U=upward flow. V%=magnet volume relative to the corresponding large version. B=max local magnet-centre norm; G=max tensor Frobenius norm over the fixed arrangement. An arrangement is chosen once for all speeds/attitudes/phases in that study. Model-dependent RMS field cost determines that choice.

| ID | H(m) | beta% | Flow | V% | Selected set | B(T) | G(T/m) | Mass(kg) |
|---|---|---|---|---|---|---|---|---|
| C097 | 0.6 | 3 | H | 100 | +z_B | 0.05565 | 3.475 | 0.1407 |
| C098 | 0.6 | 3 | H | 10 | +z_B | 0.5565 | 35.47 | 0.0433 |
| C099 | 0.6 | 3 | U | 100 | +z_B | 0.05565 | 3.587 | 0.1407 |
| C100 | 0.6 | 3 | U | 10 | +z_B | 0.5565 | 35.81 | 0.0433 |
| C101 | 0.6 | 10 | H | 100 | +z_B | 0.05565 | 1.856 | 0.8564 |
| C102 | 0.6 | 10 | H | 10 | +z_B | 0.5565 | 19.28 | 0.2635 |
| C103 | 0.6 | 10 | U | 100 | +z_B | 0.05565 | 1.97 | 0.8564 |
| C104 | 0.6 | 10 | U | 10 | +z_B | 0.5565 | 19.62 | 0.2635 |
| C105 | 0.6 | 20 | H | 100 | +z_B | 0.02783 | 0.3859 | 6.851 |
| C106 | 0.6 | 20 | H | 10 | +z_B | 0.2783 | 4.58 | 2.108 |
| C107 | 0.6 | 20 | U | 100 | +z_B | 0.02783 | 0.5097 | 6.851 |
| C108 | 0.6 | 20 | U | 10 | +z_B | 0.2783 | 4.932 | 2.108 |
| C109 | 1 | 3 | H | 100 | +z_B | 0.05565 | 2.043 | 0.6515 |
| C110 | 1 | 3 | H | 10 | +z_B | 0.5565 | 21.15 | 0.2004 |
| C111 | 1 | 3 | U | 100 | +z_B | 0.05565 | 2.156 | 0.6515 |
| C112 | 1 | 3 | U | 10 | +z_B | 0.5565 | 21.49 | 0.2004 |
| C113 | 1 | 10 | H | 100 | +z_B | 0.05565 | 1.072 | 3.965 |
| C114 | 1 | 10 | H | 10 | +z_B | 0.5565 | 11.44 | 1.22 |
| C115 | 1 | 10 | U | 100 | +z_B | 0.05565 | 1.188 | 3.965 |
| C116 | 1 | 10 | U | 10 | +z_B | 0.5565 | 11.79 | 1.22 |
| C117 | 1 | 20 | H | 100 | +z_B | 0.02783 | 0.1899 | 31.72 |
| C118 | 1 | 20 | H | 10 | +z_B | 0.2783 | 2.62 | 9.759 |
| C119 | 1 | 20 | U | 100 | +z_B | 0.02783 | 0.3221 | 31.72 |
| C120 | 1 | 20 | U | 10 | +z_B | 0.2783 | 2.98 | 9.759 |

Study ID mapping: C097=sc20714_T060_b03_h_v100; C098=sc20714_T060_b03_h_v10; C099=sc20714_T060_b03_up_v100; C100=sc20714_T060_b03_up_v10; C101=sc20714_T060_b10_h_v100; C102=sc20714_T060_b10_h_v10; C103=sc20714_T060_b10_up_v100; C104=sc20714_T060_b10_up_v10; C105=sc20714_T060_b20_h_v100; C106=sc20714_T060_b20_h_v10; C107=sc20714_T060_b20_up_v100; C108=sc20714_T060_b20_up_v10; C109=sc20714_T100_b03_h_v100; C110=sc20714_T100_b03_h_v10; C111=sc20714_T100_b03_up_v100; C112=sc20714_T100_b03_up_v10; C113=sc20714_T100_b10_h_v100; C114=sc20714_T100_b10_h_v10; C115=sc20714_T100_b10_up_v100; C116=sc20714_T100_b10_up_v10; C117=sc20714_T100_b20_h_v100; C118=sc20714_T100_b20_h_v10; C119=sc20714_T100_b20_up_v100; C120=sc20714_T100_b20_up_v10

Each reported maximum belongs to an actual result row. Component maxima and their complete six-component load/field states are in component_extrema_full_states.csv. For all candidates rather than the selected fixed set, inspect the per-case scenario and sensitivity CSVs.


---

# Appendix: Crossflow cylinder - every study

H=horizontal, U=upward flow. V%=magnet volume relative to the corresponding large version. B=max local magnet-centre norm; G=max tensor Frobenius norm over the fixed arrangement. An arrangement is chosen once for all speeds/attitudes/phases in that study. Model-dependent RMS field cost determines that choice.

| ID | H(m) | beta% | Flow | V% | Selected set | B(T) | G(T/m) | Mass(kg) |
|---|---|---|---|---|---|---|---|---|
| C121 | 0.6 | 3 | H | 100 | +z_B | 0 | 1.202 | 1.659 |
| C122 | 0.6 | 3 | H | 10 | +z_B | 0 | 3.7 | 0.5103 |
| C123 | 0.6 | 3 | U | 100 | +z_B | 0 | 1.105 | 1.659 |
| C124 | 0.6 | 3 | U | 10 | +z_B | 0 | 3.403 | 0.5103 |
| C125 | 0.6 | 10 | H | 100 | +z_B | 0 | 0.2835 | 10.09 |
| C126 | 0.6 | 10 | H | 10 | +z_B | 0 | 0.8725 | 3.106 |
| C127 | 0.6 | 10 | U | 100 | +z_B | 0 | 0.2161 | 10.09 |
| C128 | 0.6 | 10 | U | 10 | +z_B | 0 | 0.6652 | 3.106 |
| C129 | 0.6 | 20 | H | 100 | +z_B | 0 | 0.1255 | 40.38 |
| C130 | 0.6 | 20 | H | 10 | +z_B | 0 | 0.3861 | 12.42 |
| C131 | 0.6 | 20 | U | 100 | +x_B | 0 | 0.1062 | 40.38 |
| C132 | 0.6 | 20 | U | 10 | +x_B | 0 | 0.3266 | 12.42 |
| C133 | 1 | 3 | H | 100 | +z_B | 0 | 0.3403 | 7.679 |
| C134 | 1 | 3 | H | 10 | +z_B | 0 | 1.047 | 2.363 |
| C135 | 1 | 3 | U | 100 | +z_B | 0 | 0.2654 | 7.679 |
| C136 | 1 | 3 | U | 10 | +z_B | 0 | 0.8169 | 2.363 |
| C137 | 1 | 10 | H | 100 | +z_B | 0 | 0.1419 | 46.73 |
| C138 | 1 | 10 | H | 10 | +z_B | 0 | 0.4367 | 14.38 |
| C139 | 1 | 10 | U | 100 | +x_B | 0 | 0.1123 | 46.73 |
| C140 | 1 | 10 | U | 10 | +x_B | 0 | 0.3456 | 14.38 |
| C141 | 1 | 20 | H | 100 | +z_B | 0 | 0.1078 | 186.9 |
| C142 | 1 | 20 | H | 10 | +z_B | 0 | 0.3316 | 57.51 |
| C143 | 1 | 20 | U | 100 | +x_B | 0 | 0.1031 | 186.9 |
| C144 | 1 | 20 | U | 10 | +x_B | 0 | 0.3171 | 57.51 |

Study ID mapping: C121=cylinder_crossflow_T060_b03_h_v100; C122=cylinder_crossflow_T060_b03_h_v10; C123=cylinder_crossflow_T060_b03_up_v100; C124=cylinder_crossflow_T060_b03_up_v10; C125=cylinder_crossflow_T060_b10_h_v100; C126=cylinder_crossflow_T060_b10_h_v10; C127=cylinder_crossflow_T060_b10_up_v100; C128=cylinder_crossflow_T060_b10_up_v10; C129=cylinder_crossflow_T060_b20_h_v100; C130=cylinder_crossflow_T060_b20_h_v10; C131=cylinder_crossflow_T060_b20_up_v100; C132=cylinder_crossflow_T060_b20_up_v10; C133=cylinder_crossflow_T100_b03_h_v100; C134=cylinder_crossflow_T100_b03_h_v10; C135=cylinder_crossflow_T100_b03_up_v100; C136=cylinder_crossflow_T100_b03_up_v10; C137=cylinder_crossflow_T100_b10_h_v100; C138=cylinder_crossflow_T100_b10_h_v10; C139=cylinder_crossflow_T100_b10_up_v100; C140=cylinder_crossflow_T100_b10_up_v10; C141=cylinder_crossflow_T100_b20_h_v100; C142=cylinder_crossflow_T100_b20_h_v10; C143=cylinder_crossflow_T100_b20_up_v100; C144=cylinder_crossflow_T100_b20_up_v10

Each reported maximum belongs to an actual result row. Component maxima and their complete six-component load/field states are in component_extrema_full_states.csv. For all candidates rather than the selected fixed set, inspect the per-case scenario and sensitivity CSVs.


---

# Appendix: Inline cylinder - every study

H=horizontal, U=upward flow. V%=magnet volume relative to the corresponding large version. B=max local magnet-centre norm; G=max tensor Frobenius norm over the fixed arrangement. An arrangement is chosen once for all speeds/attitudes/phases in that study. Model-dependent RMS field cost determines that choice.

| ID | H(m) | beta% | Flow | V% | Selected set | B(T) | G(T/m) | Mass(kg) |
|---|---|---|---|---|---|---|---|---|
| C145 | 0.6 | 3 | H | 100 | +x_B | 0 | 0.7979 | 1.659 |
| C146 | 0.6 | 3 | H | 10 | +x_B | 0 | 2.457 | 0.5103 |
| C147 | 0.6 | 3 | U | 100 | +x_B | 0 | 0.8916 | 1.659 |
| C148 | 0.6 | 3 | U | 10 | +x_B | 0 | 2.743 | 0.5103 |
| C149 | 0.6 | 10 | H | 100 | +x_B | 0 | 0.1759 | 10.09 |
| C150 | 0.6 | 10 | H | 10 | +x_B | 0 | 0.5414 | 3.106 |
| C151 | 0.6 | 10 | U | 100 | +x_B | 0 | 0.2325 | 10.09 |
| C152 | 0.6 | 10 | U | 10 | +x_B | 0 | 0.7154 | 3.106 |
| C153 | 0.6 | 20 | H | 100 | +z_B | 0 | 0.1046 | 40.38 |
| C154 | 0.6 | 20 | H | 10 | +z_B | 0 | 0.3218 | 12.42 |
| C155 | 0.6 | 20 | U | 100 | +x_B | 0 | 0.1191 | 40.38 |
| C156 | 0.6 | 20 | U | 10 | +x_B | 0 | 0.3665 | 12.42 |
| C157 | 1 | 3 | H | 100 | +x_B | 0 | 0.2078 | 7.679 |
| C158 | 1 | 3 | H | 10 | +x_B | 0 | 0.6397 | 2.363 |
| C159 | 1 | 3 | U | 100 | +x_B | 0 | 0.2733 | 7.679 |
| C160 | 1 | 3 | U | 10 | +x_B | 0 | 0.8408 | 2.363 |
| C161 | 1 | 10 | H | 100 | +z_B | 0 | 0.1079 | 46.73 |
| C162 | 1 | 10 | H | 10 | +z_B | 0 | 0.3319 | 14.38 |
| C163 | 1 | 10 | U | 100 | +x_B | 0 | 0.1309 | 46.73 |
| C164 | 1 | 10 | U | 10 | +x_B | 0 | 0.4028 | 14.38 |
| C165 | 1 | 20 | H | 100 | +z_B | 0 | 0.103 | 186.9 |
| C166 | 1 | 20 | H | 10 | +z_B | 0 | 0.3169 | 57.51 |
| C167 | 1 | 20 | U | 100 | +x_B | 0 | 0.1064 | 186.9 |
| C168 | 1 | 20 | U | 10 | +x_B | 0 | 0.3274 | 57.51 |

Study ID mapping: C145=cylinder_inline_T060_b03_h_v100; C146=cylinder_inline_T060_b03_h_v10; C147=cylinder_inline_T060_b03_up_v100; C148=cylinder_inline_T060_b03_up_v10; C149=cylinder_inline_T060_b10_h_v100; C150=cylinder_inline_T060_b10_h_v10; C151=cylinder_inline_T060_b10_up_v100; C152=cylinder_inline_T060_b10_up_v10; C153=cylinder_inline_T060_b20_h_v100; C154=cylinder_inline_T060_b20_h_v10; C155=cylinder_inline_T060_b20_up_v100; C156=cylinder_inline_T060_b20_up_v10; C157=cylinder_inline_T100_b03_h_v100; C158=cylinder_inline_T100_b03_h_v10; C159=cylinder_inline_T100_b03_up_v100; C160=cylinder_inline_T100_b03_up_v10; C161=cylinder_inline_T100_b10_h_v100; C162=cylinder_inline_T100_b10_h_v10; C163=cylinder_inline_T100_b10_up_v100; C164=cylinder_inline_T100_b10_up_v10; C165=cylinder_inline_T100_b20_h_v100; C166=cylinder_inline_T100_b20_h_v10; C167=cylinder_inline_T100_b20_up_v100; C168=cylinder_inline_T100_b20_up_v10

Each reported maximum belongs to an actual result row. Component maxima and their complete six-component load/field states are in component_extrema_full_states.csv. For all candidates rather than the selected fixed set, inspect the per-case scenario and sensitivity CSVs.
