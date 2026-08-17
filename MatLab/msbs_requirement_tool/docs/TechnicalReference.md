# Technical reference

## 1. Scope and frames

The program is a magnetic **requirements** tool. It converts a fully defined simultaneous rigid-body load state into a required applied field and first-order field gradient.

Three right-handed frames are used:

- **E** — Earth/inertial frame; gravity is `[0;0;-g]`.
- **T** — tunnel and MSBS reporting frame; `+x_T` is downstream wind direction.
- **B** — body-fixed frame for geometry, magnets and attitude.

Wind and tunnel axes are deliberately identical in v0.3.0, so no independent W frame is maintained. A vertical or inclined tunnel is represented by rotating T relative to E.

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

## 9. Minimum norm and Frobenius gradient objective

The six wrench equations and eight magnetic parameters are generally underdetermined. MATLAB `lsqminnorm` is therefore used, but v0.3.0 no longer minimizes the raw five independent gradient coordinates.

The solver internally maps the five gradient degrees of freedom onto an orthonormal symmetric trace-free basis. If q contains those five coordinates,

\[
\|\mathbf q\|_2=\|\mathbf G\|_F.
\]

The dimensionally scaled objective is therefore

\[
\min\left(
\left\|\frac{\mathbf B_0}{B_s}\right\|_2^2+
\left\|\frac{\mathbf G}{G_s}\right\|_F^2
\right)^{1/2},
\]

subject to reproducing the requested wrench in the scaled least-squares sense. `lsqminnorm` is the numerical solver; the Frobenius construction defines the physically meaningful gradient norm that solver minimizes.

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
