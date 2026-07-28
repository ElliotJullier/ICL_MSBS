# Quick start

This guide takes a new user from the ZIP archive to a completed study.

## 1. Open the project

Extract the ZIP, start MATLAB, and set the Current Folder to the extracted `msbs_requirement_tool` directory. Do not permanently add every subfolder to the MATLAB path; the entry points configure the required paths themselves.

## 2. Run the tests once

```matlab
results = runAllTests();
```

The first delivered version was generated without an available MATLAB executable. Treat a clean local test run as the first acceptance check. See [Troubleshooting](Troubleshooting.md) if any test fails.

## 3. Run the minimal example

```matlab
study = runStudy("case_minimal_example");
```

The example uses:

- a 0.60 m × 0.60 m rectangular test section;
- a sphere sized to 10% nominal blockage;
- an automatic N52 magnet occupying the full supported inscribed cuboid;
- three candidate body-axis magnetisation directions;
- a static 30 m/s load case.

The command returns the full `study` struct and prints the result-folder path.

## 4. Inspect the main outputs

Open the printed result folder under:

```text
results/minimal_example/<timestamp>/
```

Start with:

- `configuration.png`: tunnel, model, magnet, frames, gravity, wind, centre of mass, and aerodynamic reference point;
- `run_summary.md`: plain-language assumptions, envelopes, residual acceptance, and limitations;
- `magnet_set_summary.csv`: one row per magnet set;
- `scenario_results.csv`: one row per physical scenario and magnet set;
- `results_full.mat`: the complete full-precision `study` object.

## 5. Create a new case

In the MATLAB Current Folder browser, copy:

```text
cases/case_template.m
```

to a new file, for example:

```text
cases/case_my_experiment.m
```

Change the first line to:

```matlab
function cfg = case_my_experiment()
```

Then edit only the clearly marked `USER INPUT` sections. At minimum review:

1. tunnel dimensions, speed, and density;
2. geometry type and absolute or blockage sizing;
3. automatic or manual magnet arrangement;
4. mass assumptions or overrides;
5. `CD`, `CL`, and `Cm` ranges;
6. motion mode;
7. scenario strategy;
8. dimensionless residual threshold and any advisory field limits.

Run it with:

```matlab
study = runStudy("case_my_experiment");
```

The file name, function name, and string passed to `runStudy` must match.

## 6. Iterate a parameter

For example, compare 5%, 10%, and 15% blockage by changing:

```matlab
cfg.geometry.sizing.blockage_ratio = 0.10;
```

Save the case and rerun:

```matlab
study = runStudy("case_my_experiment");
```

A new timestamped folder is created by default. Previous results are not overwritten.

## 7. Understand the residual threshold

```matlab
cfg.magnetic.acceptance_relative_residual = 1e-6;
```

This is dimensionless. It compares the norm of the unachieved wrench after fixed force/moment scaling with the norm of the similarly scaled requested wrench. A value of `1e-6` is a strict numerical controllability criterion, not a hardware tolerance and not a statement that the required field can be built.

A magnet set is considered residual-accepted only when **every scenario** is below this threshold. Only accepted sets participate in the “best set” comparison by scaled magnetic requirement.
