# Updating from version 0.1.0

Version 0.1.1 is a corrective runtime release based on the first MATLAB test log.

## Recommended Git workflow

From the repository containing this project:

```bash
git switch -c fix/msbs-requirement-tool-0.1.1
```

Copy the contents of the corrected `msbs_requirement_tool/` folder over the existing folder, preserving the same relative paths. Do not delete your own case files or generated results if they live inside that folder; move or back them up first.

Review the update:

```bash
git status
git diff -- msbs_requirement_tool
```

Run MATLAB from the corrected project root:

```matlab
clear functions
rehash path
results = runAllTests();
```

After the tests pass:

```bash
git add msbs_requirement_tool
git commit -m "Fix MSBS requirement tool MATLAB runtime failures"
```

Merge the fix branch using the normal workflow for the parent repository.

## Changed implementation files

- `runAllTests.m`
- `src/+msbsreq/buildMagnetSets.m`
- `src/+msbsreq/loadMagnetGradeTable.m` (new)
- `src/+msbsreq/run.m`
- `src/+msbsreq/summariseResults.m`
- `src/+msbsreq/validateConfig.m`
- `tests/TestLoads.m`
- `tests/TestMagnetSizing.m`

Documentation and release metadata were also updated.

## Why a full replacement is supplied

The initial release had several interacting startup and runtime defects. A complete corrected folder gives one authoritative state and avoids missed files. A patch-only bundle and unified diff are also supplied for review, but manual line-by-line editing is not recommended.
