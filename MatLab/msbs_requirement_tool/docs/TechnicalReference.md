# Technical reference

## 1. Scope and frames

The program is a magnetic **requirements** tool. It converts a fully defined simultaneous rigid-body load state into a required applied field and first-order field gradient.

Three right-handed frames are used:

- **E** — Earth/inertial frame; gravity is `[0;0;-g]`.
- **T** — tunnel and MSBS reporting frame; `+x_T` is downstream wind direction.
- **B** — body-fixed frame for geometry, magnets and attitude.

Wind and tunnel axes are deliberately identical in v0.4.0, so no independent W frame is maintained. A vertical or inclined tunnel is represented by rotating T relative to E.

For a vector fixed in B,

\[
\mathbf v_T=\mathbf R_{TB}\mathbf v_B.
\]

For an Earth-frame free vector,

\[
\mathbf v_T=\mathbf R_{ET}^{T}\mathbf v_E.
\]

A wrench shifted from reference point P to centre of mass C uses

\[
\mathbf M_C=\mathbf M_P+\mathbf r_{CP}\times\mathbf F.
\]

## 2. One row is one physical state

`cfg.scenarios` is not an uncertainty-factor list. Each row is one simultaneous physical state. Speed, aerodynamic values, attitude and motion in a row therefore belong together physically.

The program performs no Cartesian product and no interpolation. This prevents a low-Reynolds-number drag coefficient from being silently combined with an unrelated high-speed state and removes phase-matching ambiguity for unsteady motion.

If `cfg.scenarios` is empty, one nominal static state is generated. In harmonic mode, evenly spaced phase rows are generated instead.

## 3. Aerodynamic inputs

### 3.1 Coefficients

The six supported channels are

\[
[C_D,C_Y,C_L,C_l,C_m,C_n].
\]

In MATLAB the rolling coefficient is named `Cl_roll` to avoid visual confusion with lift `CL`.

With dynamic pressure

\[
q=\frac12\rho U^2,
\]

reference area S, reference span b and reference length c,

\[
\mathbf F_{a,T}=qS
\begin{bmatrix}C_D\\C_Y\\C_L\end{bmatrix},
\]

\[
\mathbf M_{a,R,T}=qS
\begin{bmatrix}bC_l\\cC_m\\bC_n\end{bmatrix}.
\]

Unknown or irrelevant channels are simply zero. `Cl_roll`, `Cm` and `Cn` are therefore not mandatory physical inputs when moments are not being modelled.

The `[b,c,b]` convention must match the aerodynamic data source. If dimensional forces and moments are already available, direct-wrench mode avoids coefficient-normalisation ambiguity.

### 3.2 Direct aerodynamic wrench

`aero.mode="direct_wrench"` reads the six aerodynamic components directly from each scenario row. The wrench may be supplied in E, T or B components and is transformed to T and shifted from its body-fixed reference point to the model centre of mass.

## 4. Motion and inertial demand

For `motion.mode="specified"`, scenario acceleration, angular velocity and angular acceleration are transformed to T. If no kinematic columns are present, they are zero.

The translational inertial demand is

\[
\mathbf F_I=m\mathbf a_C.
\]

The rotational demand is the full Euler expression

\[
\mathbf M_I=\mathbf I_T\boldsymbol\alpha+
\boldsymbol\omega\times(\mathbf I_T\boldsymbol\omega),
\]

where

\[
\mathbf I_T=\mathbf R_{TB}\mathbf I_B\mathbf R_{TB}^{T}.
\]

The harmonic helper generates acceleration, angular velocity, angular acceleration and small-angle body attitude at the same phase used by the aerodynamic row. It is a convenience for prescribed single-frequency motion, not an aerodynamic model.

## 5. Complete required magnetic wrench

All contributions are first expressed in T and referenced to the centre of mass. The required magnetic wrench is then

\[
\boxed{\mathbf w_{mag,req}=\mathbf w_I-\mathbf w_a-\mathbf w_g-\mathbf w_{other}}.
\]

This is a simultaneous six-component balance. The program does not calculate independent scalar "drag gradient", "gravity gradient" and "inertial gradient" maxima and add them.

## 6. First-order magnetic field

The applied external field around the model centre of mass is

\[
\mathbf B(\mathbf r)=\mathbf B_0+\mathbf G\mathbf r.
\]

The model region is assumed current-free, so

\[
\nabla\times\mathbf B=0,\qquad \nabla\cdot\mathbf B=0,
\]

which makes G symmetric and trace-free:

\[
\mathbf G=
\begin{bmatrix}
g_{xx}&g_{xy}&g_{xz}\\
g_{xy}&g_{yy}&g_{yz}\\
g_{xz}&g_{yz}&-g_{xx}-g_{yy}
\end{bmatrix}.
\]

The physical parameter vector retained by the magnetic map is

\[
\mathbf x=[B_x,B_y,B_z,g_{xx},g_{yy},g_{xy},g_{xz},g_{yz}]^T.
\]

## 7. One or multiple permanent magnets

For magnet i, its body-fixed centre and dipole are rotated to T:

\[
\mathbf r_i=\mathbf R_{TB}(\mathbf r_{i,B}-\mathbf r_{C,B}),
\qquad
\mathbf m_i=\mathbf R_{TB}\mathbf m_{i,B}.
\]

Every magnet experiences the same constant gradient G but a position-dependent local field

\[
\mathbf B_i=\mathbf B_0+\mathbf G\mathbf r_i.
\]

The force and torque are

\[
\mathbf F_i=\mathbf G\mathbf m_i,
\]

\[
\mathbf T_i=\mathbf r_i\times\mathbf F_i+\mathbf m_i\times\mathbf B_i.
\]

The rigid-body magnetic wrench is the sum over all magnets. There is no special "main magnet" in the solver and no independent gradient assigned to each magnet. A poor multi-magnet geometry can therefore require a larger field/gradient or make a wrench direction uncontrollable.

Permanent-magnet mutual fields are not included because they are internal to the rigid assembly for net external-wrench purposes; structural and demagnetisation effects remain outside this tool.

## 8. The 6×8 magnetic influence matrix A

For a fixed magnet arrangement and attitude, magnetic wrench is linear in x:

\[
\boxed{\mathbf w_{mag}=\mathbf A\mathbf x},\qquad \mathbf A\in\mathbb R^{6\times8}.
\]

`buildMagneticMap` constructs A by basis evaluation. Column j is the six-component wrench produced by setting physical magnetic parameter `x(j)=1` and every other parameter to zero. Thus A maps **field/gradient to wrench**; the requirement solve uses it in the inverse direction to find x for a requested wrench.

For one centred +x dipole of magnitude m,

\[
\mathbf F=m[g_{xx},g_{xy},g_{xz}]^T,
\qquad
\mathbf T=[0,-mB_z,mB_y]^T.
\]

Therefore torque about x is uncontrollable for that single centred dipole. A +z dipole analogously cannot generate torque about z. Multiple separated/nonparallel magnets change A through their different dipoles and moment arms.

## 9. Magnetic cost, coupling and minimum-norm solve

The six wrench equations and eight magnetic parameters are generally underdetermined. The code therefore retains MATLAB `lsqminnorm`, but the physical cost is supplied by a change of variables rather than by minimising the raw physical coordinate vector.

### 9.1 STF gradient coordinates

The source-free first-order model constructs

\[
G=G^T,\qquad \mathrm{tr}(G)=0,
\]

leaving five independent gradient degrees of freedom. They are re-expressed in an orthonormal symmetric trace-free basis,

\[
G=\sum_{a=1}^5 q_a E_a,\qquad E_a:E_b=\delta_{ab},
\]

so that

\[
\|q\|_2=\|G\|_F.
\]

The symmetry/trace constraints are enforced by construction; the orthonormal basis is then used to give the solver a coordinate-independent Frobenius gradient magnitude.

### 9.2 Primary RMS-field cost

Let `Lref=max(geometry.outer_dimensions_B_m)`. Define a centred isotropic cube of side `Lref` about the instantaneous model CoM. Because its first spatial moment is zero and its second moment is `(Lref^2/12)I`, the mean-square affine field is

\[
J^2=\frac1V\int_V \|B_0+Gr\|^2dV
=\|B_0\|^2+\frac{L_{ref}^2}{12}\|G\|_F^2.
\]

The equivalent mean vacuum energy-density proxy is

\[
\bar u=\frac{J^2}{2\mu_0}.
\]

The reference cube is a regularisation region chosen from the model scale. It is not a claim that the whole real magnetic field or actual coil energy is described by a first-order field over that volume.

Define `ell=Lref/sqrt(12)` and the solver coordinate

\[
y=[B_0;\;ell\,q].
\]

Then `||y||2=J`. If `P` maps STF coordinates `q` to the five physical gradient parameters and `Tbasis=blkdiag(I3,P)`, the physical magnetic vector is

\[
x=T_{basis}\,\mathrm{diag}(I_3,ell^{-1}I_5)y.
\]

The wrench equations are scaled separately by the study-wide force and moment magnitudes using `Dw`. The solved system is therefore

\[
D_w A T_{basis}T_{cost}y \approx D_w w_{req}.
\]

`lsqminnorm` first minimises the scaled wrench residual and, among equivalent least-squares solutions, minimises `||y||2=J`.

### 9.3 Force/torque coupling diagnostic

In STF coordinates partition the map as

\[
\begin{bmatrix}F\\M\end{bmatrix}=
\begin{bmatrix}A_{FB}&A_{FG}\\A_{MB}&A_{MG}\end{bmatrix}
\begin{bmatrix}B_0\\q\end{bmatrix}.
\]

The point-dipole equations guarantee `A_FB=0`. `A_MG=0` for a centred magnet but is generally nonzero for offset/separated magnets. To compare `A_MG` with `A_MB` without mixing field and gradient units, the gradient columns are divided by the primary `ell`; both moment blocks then correspond to moment authority per unit RMS-field cost. The dimensionless coupling ratio is

\[
\rho_c=\frac{\|A_{MG}/ell\|_F}{\|A_{MB}\|_F}.
\]

The configured thresholds classify the map as zero, insignificant or significant. The full coupled map is always solved; classification only controls reporting and whether alternate cost sensitivities are run. If `A_MG=0`, the force/gradient and moment/field subproblems are independent, so changing only the scalar relative B/G weighting cannot change the physical minimum-residual solution.

### 9.4 Significant-coupling sensitivity suite

For significant maps the default alternate reference lengths are model multipliers 0.01, 0.1 and 10 around the primary factor 1, plus cube sides 0.2 and 0.5 times `sqrt(tunnel area)`. Each alternate solution is another `lsqminnorm` solve using the same `A`, `w_req` and wrench scaling; only `ell` changes. These compact alternatives are stored separately from the primary pointwise result.

### 9.5 Ranking

For primary cost `J_jk`, fixed-hardware ranking uses

\[
\arg\min_j\max_k J_{jk},
\]

subject to all scenarios meeting the residual threshold for set `j`. Independent-scenario ranking instead uses `min_j J_jk` separately for each scenario and then orders those best-achievable scenario costs from largest to smallest. Both rankings retain the actual scenario IDs and never combine component extrema into a synthetic wrench.

## 10. Boundary to future coil design

If a later coil model provides

\[
\mathbf x=\mathbf C\mathbf I,
\]

where each column of C is field/gradient per ampere for one coil, then

\[
\mathbf w=\mathbf A\mathbf C\mathbf I.
\]

This project stops before that step. Its output is a coil-independent magnetic requirement. A future coil tool may solve `C I = x` or, preferably when optimizing the real actuator, solve `A C I = w_req` directly for current or copper-loss objectives.
