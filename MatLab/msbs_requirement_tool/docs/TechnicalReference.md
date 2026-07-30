# Technical reference

## Frames and wrench convention

Vectors use `v_A = R_AB v_B`. Body attitude is intrinsic Z-Y-X yaw-pitch-roll. A wrench about point O is `[F; M_O]`. Shifting from P to O uses:

```text
M_O = M_P + r_OP × F
```

All balance equations are formed about the model centre of mass in tunnel components.

## Aerodynamics

Dynamic pressure is `q = 0.5 rho V^2`. In W:

```text
F_a,W = [q S CD; 0; q S CL]
M_a,R,W = [0; q S c Cm; 0]
```

Both are rotated by `R_TW`; the moment is then shifted from aerodynamic reference point R to CoM C.

## Newton–Euler requirement

```text
F_mag,req = m a_C - F_a - F_g - F_other
M_mag,req = I_T alpha + omega × (I_T omega) - M_a - M_g - M_other
I_T = R_TB I_B R_TB^T
```

The gyroscopic term is retained. Harmonic attitude changes update `R_TB` phase by phase before inertia and magnet vectors are transformed.

## Hybrid mass properties

Each magnet is an explicit rotated cuboid. Remaining mass is uniformly distributed through the outer primitive. CoM and inertia are combined using parallel-axis shifts. Direct total-mass, CoM, and inertia overrides take precedence.

## Dipole approximation

For selected remanence `Br` and effective factor `eta`:

```text
M = eta Br / mu0
m = M V d_hat
```

A direct dipole-moment override takes precedence. CSV data are configurable and supplier/temperature dependent.

## Applied field and source-free gradient

```text
B(r) = B0 + G r
```

In a source-free magnetostatic region, `G` is symmetric and trace-free. The implementation verifies both properties after each solve against `cfg.validation.gradient_tolerance`. The unknown vector is:

```text
x = [B0x B0y B0z gxx gyy gxy gxz gyz]^T
```

with:

```text
G = [gxx  gxy  gxz
     gxy  gyy  gyz
     gxz  gyz -gxx-gyy]
```

## Multi-magnet wrench

For magnet i relative to CoM:

```text
B_i = B0 + G r_i
F_i = G m_i
T_i = r_i × F_i + m_i × B_i
```

The total wrench is the sum over magnets. One common first-order field is used for every magnet.

## Influence matrix

The program builds `w = A x` by evaluating each unit basis vector of x through the direct multi-magnet wrench function. It records rank, singular values, a nonzero-singular-value condition number, and the left null space.

## Scaled solve

Field and gradient units cannot be minimised in one raw Euclidean norm. Define:

```text
x = Dx y
Dx = diag(Bs,Bs,Bs,Gs,Gs,Gs,Gs,Gs)
```

Force and moment are scaled by fixed study-wide maxima with safe lower bounds:

```text
Dw = diag(1/Fs,1/Fs,1/Fs,1/Ts,1/Ts,1/Ts)
```

The code solves:

```text
y = lsqminnorm(Dw A Dx, Dw w_req)
x = Dx y
```

`scaled_solution_norm = ||y||2` compares magnet sets under the chosen B/G scales. It is not energy, coil power, current, or a feasibility probability.

## Residual and acceptance

Physical residual:

```text
r = A x - w_req
```

Dimensionless relative residual:

```text
relative = ||Dw r||2 / ||Dw w_req||2
```

For zero requested wrench the numerator itself is used. A scenario is accepted when this value is below `cfg.magnetic.acceptance_relative_residual`. Set-level acceptance requires every scenario to pass.

## Single aligned check

For one centred `m = [mx,0,0]`:

```text
Fx = mx dBx/dx
Fy = mx dBy/dx
Fz = mx dBz/dx
Ty = -mx Bz
Tz =  mx By
```

`Tx` is directly uncontrollable and appears in the residual.

## Numerical checks

The tests and runtime validation cover proper rotations, symmetric positive inertia, exact supported geometry fits, force/moment signs and reference shifts, harmonic peak acceleration, gyroscopic demand, source-free gradient symmetry/trace, direct-versus-basis magnetic wrench equality, rank/residual behaviour, scenario counts, and fixed regression values.

## Known first-version limitations

- point dipoles rather than finite-volume magnets;
- first spatial derivative only;
- no self-field or magnet–magnet interaction;
- no coil/current model;
- nominal-orientation blockage diagnostic only;
- primitive/custom-proxy geometry only;
- small-angle engineering interpretation for harmonic angular motion;
- generic initial magnet-grade data.
