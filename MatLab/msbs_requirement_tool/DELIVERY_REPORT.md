# Corrective delivery report — version 0.1.2

## Basis

This release responds to the second local MATLAB test run. Version 0.1.1 reduced the suite to 38 passing tests and four incomplete failures.

## Corrections

1. Warning arrays are now maintained as column string arrays and normalised before vertical concatenation.
2. The hybrid centre-of-mass test now applies a 10% automatic magnet shrink before a 10 mm centre offset, so the test magnet remains inside the spherical geometry proxy.
3. Documentation now clarifies that the unified `.patch` file is sufficient and that helper patch artifacts may be deleted after a successful commit.

## Runtime status

MATLAB and GNU Octave are unavailable in the packaging environment. Version 0.1.2 has therefore been statically audited but not runtime-certified here. Run `runAllTests` locally and provide the complete output if any failure remains.
