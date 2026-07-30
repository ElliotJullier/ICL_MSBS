# Updating from version 0.1.1

Version 0.1.2 is a small corrective release based on the second MATLAB test log.

The unified patch file is sufficient by itself. A `replacement_files` directory is not required; it was only an alternative manual fallback in the previous delivery.

From the repository root used in the project owner's current layout:

```bat
git apply --check --directory=MatLab "MatLab/msbs_requirement_tool_v0.1.1_to_v0.1.2.patch"
git apply --directory=MatLab "MatLab/msbs_requirement_tool_v0.1.1_to_v0.1.2.patch"
```

Confirm the update:

```bat
type "MatLab\msbs_requirement_tool\VERSION"
git apply --reverse --check --directory=MatLab "MatLab/msbs_requirement_tool_v0.1.1_to_v0.1.2.patch"
git --no-pager diff --name-status -- "MatLab/msbs_requirement_tool"
```

The version should be `0.1.2`, and the reverse check should produce no output.

After the patch has been applied, tested, and committed, the patch file may be deleted or moved outside the repository. It should not normally be committed as part of the source project.

Run locally from the project root:

```matlab
clear functions
restoredefaultpath
rehash toolboxcache
results = runAllTests();
```
