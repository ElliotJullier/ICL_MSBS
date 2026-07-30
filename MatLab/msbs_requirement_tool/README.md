# MSBS Aerodynamic-Load-to-Magnetic-Requirement Tool

A modular MATLAB framework for converting wind-tunnel experiment definitions into required applied magnetic field and first-order field-gradient requirements for one or more permanent magnets.

The tool combines aerodynamic, gravity, prescribed rigid-body inertial, and optional user-defined loads in a common tunnel frame. It evaluates simultaneous physical scenarios, solves the source-free first-order magnetic requirement, reports uncontrollable residuals, compares magnet arrangements, and exports reproducible result packages.

It does **not** design coils, calculate coil currents or power, simulate a finite magnet volume, or design a controller.

## Requirements

- MATLAB R2022b or later
- Base MATLAB
- MATLAB Unit Test Framework
- No additional toolbox is required

## First run

Open MATLAB in this project root and run:

```matlab
results = runAllTests();
study = runStudy("case_minimal_example");
```

Version 0.1.2 incorporates corrections from the first two MATLAB runtime logs. MATLAB is still unavailable in the packaging environment, so run the complete test suite locally before relying on results.

## Documentation

- [Quick start](docs/QuickStart.md)
- [User guide](docs/UserGuide.md)
- [Technical reference](docs/TechnicalReference.md)
- [Troubleshooting](docs/Troubleshooting.md)
- [Confirmed decision overrides](docs/DecisionOverrides.md)
- [Updating from version 0.1.0](UPDATING_FROM_0.1.0.md)
- [Updating from version 0.1.1](UPDATING_FROM_0.1.1.md)

## Project structure

- `runStudy.m`: top-level study command
- `runAllTests.m`: top-level test command
- `cases/`: editable experiment definitions
- `data/`: configurable magnet-grade data
- `src/+msbsreq/`: calculation package
- `tests/`: automated tests
- `docs/`: user and technical documentation
- `results/`: generated run folders, excluded from version control except `.gitkeep`

## Version and Git integration

The project version is stored in `VERSION`. The tool records a Git commit hash when it is later run inside a Git repository; otherwise the metadata records `unavailable`. This delivery does not initialise or modify Git.

## Licence

No standalone open-source licence is included. Licensing should be defined by the larger repository into which this project is integrated.
