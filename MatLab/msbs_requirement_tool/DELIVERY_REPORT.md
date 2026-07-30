# Delivery report

## Included

- Complete MATLAB project structure and relocatable root entry points
- Primitive geometry and exact nominal-orientation blockage sizing
- Automatic and explicit multi-magnet arrangements
- Editable generic N35–N52 magnet-grade CSV for later supplier-specific replacement
- Hybrid explicit-magnet plus distributed-shell mass and inertia properties
- Aerodynamic, gravity, additional-static, and Newton–Euler inertial loads
- Harmonic phase-updated attitude and full `I*alpha + omega x (I*omega)` demand
- Direct-kinematics, time-history, and direct-required-wrench motion modes
- Full-factorial and correlated user-defined scenario generation
- Source-free first-order multi-magnet mapping and dimensionally scaled solver
- Dimensionless residual-based acceptance and residual-first rejected-set ranking
- PNG/PDF figures and MAT/JSON/CSV/Markdown result exports
- Unit, regression, interface-equivalence, output-package, and documentation tests
- Quick start, complete user field reference, technical reference, troubleshooting guide, and per-run summary

## Git handling

No Git repository, commits, or tags were created. `.gitignore`, `VERSION`, and `CHANGELOG.md` are included. Runtime metadata records a Git commit hash after the project is integrated into a repository.

## Static validation performed

The delivery environment was used to verify:

- all required project files are present;
- all 45 MATLAB source/test/case files have matching primary class or function names;
- all 31 `msbsreq.*` package references resolve to delivered package functions;
- delimiters are structurally balanced under a MATLAB-aware static scan;
- all local Markdown links resolve;
- all 94 fields in `defaultConfig.m` are documented in `docs/UserGuide.md`;
- all mandatory scenario-result columns are implemented;
- N35, N42, N48, and N52 data rows and required CSV fields are present;
- no unresolved `TODO`/`FIXME` markers, generated result artifacts, or machine-specific absolute paths are present.

These checks are not a substitute for MATLAB execution.

## MATLAB test status

MATLAB and GNU Octave were not available in the delivery environment. The MATLAB tests and example studies were therefore **not executed**, and no runtime-pass claim is made. The project owner should run from the extracted project root:

```matlab
results = runAllTests();
```

Provide the complete command-window output if any test fails or is incomplete.

## Material-data status

The N35–N52 values are configurable generic room-temperature placeholders. Magnet Store UK is recorded as the anticipated supplier, but exact product data must replace or confirm these values before procurement or conservative final sizing.

## Known modelling limits

The software reports requirements under a point-dipole, source-free, common first-order applied-field model. It does not design coils, calculate current or power, integrate finite magnet volumes, model self-field or magnet interaction, assess saturation/demagnetisation, predict aerodynamic coefficients, or design a controller.
