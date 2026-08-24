# MSBS Aerodynamic-Load-to-Magnetic-Requirement Tool

A compact MATLAB framework for converting simultaneous wind-tunnel load states into required applied magnetic field and first-order field-gradient requirements for one or more permanent magnets.

The tool combines aerodynamic, gravity, prescribed rigid-body inertial and optional static external loads in the tunnel frame. Aerodynamics are supplied either as six conventional coefficients or as a dimensional six-component aerodynamic wrench. One scenario row is one simultaneous physical state: there is no factorial combination logic and no time-history interpolation.

It does **not** design coils, calculate coil currents or power, simulate a finite magnet volume, model sensors/controllers, or generate aerodynamic data.

## Requirements

- MATLAB R2022b or later
- Base MATLAB
- MATLAB Unit Test Framework
- No additional toolbox required

## First run

```matlab
results = runAllTests();
study = runStudy("case_minimal_example");
```

Version 0.4.1 retains the model-scale RMS-field primary cost and separates two significant-coupling sensitivity families: explicit relative field/gradient length scales and physically interpreted reference-volume RMS-field metrics. It also reports gradient-to-moment coupling and exports both fixed-configuration and independent-scenario rankings.

## Documentation

- [Quick start](docs/QuickStart.md)
- [User guide](docs/UserGuide.md)
- [Technical reference](docs/TechnicalReference.md)
- [Troubleshooting](docs/Troubleshooting.md)
- [Confirmed design decisions](docs/DecisionOverrides.md)

## Project structure

- `runStudy.m`: top-level study command
- `runAllTests.m`: top-level test command
- `cases/`: editable experiment definitions
- `data/`: configurable magnet-grade data
- `src/+msbsreq/`: calculation package
- `tests/`: automated tests
- `docs/`: user and technical documentation
- `results/`: generated run folders

The version is stored in `VERSION`. No standalone licence is added by this subproject.
