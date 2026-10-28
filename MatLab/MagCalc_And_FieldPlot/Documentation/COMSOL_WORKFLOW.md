# COMSOL to MATLAB: export checklist and chat handoff

This workflow reads COMSOL exports directly. There is no mandatory conversion/cache step.
`query_main.m` describes cases and queries; `run_query_batch` executes them and saves small Q outputs.
`plot_main.m` loads Q without reopening the numerical export or COMSOL.

**For the script-writing chat, sections 4–7 are the primary handoff contract.**
Read the query API, dataset operations and plotting standards as well as the request form in section 7.

## 1. One-time setup on each computer

Open `MatLab/MagCalc_And_FieldPlot` in MATLAB and run:

```matlab
paths = setup_msbs_project();
paths = set_msbs_data_root("C:/Users/'ej221'/OneDrive - Imperial College London/PhD/21 Design and Procurement/21-2 EM Coils/COMSOL");
```

Use the home PC's actual local synced path on that PC. The preference is stored by MATLAB outside Git.
Your current PC's Imperial OneDrive root is detected automatically, so no additional access/path is needed here.
An environment variable `MSBS_DATA_ROOT`, if set, takes priority over the preference.
The root is a local synced folder, not a web sharing URL or a Windows shortcut.

Expected layout:

```text
COMSOL/
  COMSOL Files/
    2Coil_andYoke.mph
  Datasets/
    2Coil_andYoke_OneCoilExcitation.txt
  Java COMSOL/
    2Coil_andYoke.java
  STL/
    2Coil_andYoke/
      coil_left.stl
      coil_right.stl
      yoke_with_attached_cores.stl
      core_separate.stl                 (only when actually separate)
```

The STL folder matches the model name, including spaces/capitalisation. Both the basename
(as shown) and the complete filename including .mph are accepted.
Each component filename starts with `coil_`, `yoke_` or `core_`.
The default convention is coil=green, yoke=grey, separate core=purple, 50% opacity.
An attached core exported as part of the yoke is grey. Export it separately if it needs separate colour/identity.
Components may also be supplied explicitly when filenames do not follow this convention.

Keep required files available offline in OneDrive. Finish saving/exporting and syncing before switching PCs.
Do not edit the same .mph simultaneously on both PCs. The code does not move existing files automatically.
Existing .lnk files may remain navigation aids but are not used by the loaders.

Q outputs stay in the repository's local `Q outputs` folder; the existing Git ignore excludes .mat files.
Re-run the small query stage on the other PC, or transfer a Q file if you want to reuse that exact batch.

## 2. Checklist after solving in COMSOL

- [ ] Save the solved model, including the solution you want to reuse, under `COMSOL Files`.
- [ ] Export a Model file for Java to `Java COMSOL` with the corresponding model name.
      This gives the script-writing chat context. It is not required for MATLAB field evaluation.
- [ ] Choose the solution and current/parameter case explicitly.
- [ ] Export Data in **Spreadsheet**, comma-separated, non-transposed format.
- [ ] Export only `mf.Bx`, `mf.By`, `mf.Bz`, in that order and in **tesla**.
      Retain the x,y,z coordinates, COMSOL header and parameter descriptions.
- [ ] Choose the required sampling domain. A plane is valid for queries within that plane.
      For arbitrary 3D cuts or derivatives out of that plane, export a volume instead.
- [ ] Use a complete rectilinear coordinate grid. Uniform grids support cubic interpolation;
      shorter/nonuniform active axes use linear interpolation.
- [ ] Keep invalid field entries as NaN at their original coordinates. Do not delete those rows.
- [ ] Save the numerical file under `Datasets` with a meaningful name.
- [ ] For a sweep, vary **one parameter only**. Supply its name and ordered values when missing
      from the header. Do not combine a geometry sweep and current sweep in one export.
- [ ] Export component STLs directly from COMSOL into `STL/<model basename>/`.
      Use the SAME assembly coordinate frame and origin for every component and the field data.
- [ ] Record STL length units. Use InputScale=1 for metres or 1e-3 for millimetres.
      Do not centre each mesh separately.
- [ ] For parameter-dependent geometry, provide matching STLs for each case, for example
      `STL/<model basename>/gap_10mm/` and `.../gap_20mm/`; select the correct relative folder per case.
- [ ] Give the next chat this guide, the Java file/path, dataset filename/header, geometry folder,
      units and the requested queries/comparisons.

STL meshes used for material entry/exit intervals must resolve to a closed manifold surface, with holes represented.
COMSOL can export internal partition faces as well as the external skin. The importer and plot-time
geometry adapter now remove verifiable flat internal partitions: only meshes without missing boundary
edges are considered, external-visible patches are retained, and a candidate repair is accepted only
when every remaining edge belongs to exactly two triangles. It never adds caps, takes a convex hull,
moves vertices or modifies the source STL. Separate closed cavities are retained. Unsupported
non-manifold arrangements and genuinely open meshes remain unchanged and warn rather than guess.
This also works when replotting older Q geometry. The previous blanket diagnosis that these saved
COMSOL meshes were incomplete was too broad: the tested coils/yoke contained internal partitions.
An unrepaired open mesh can be displayed and sectioned, but its line material shading is skipped.
Geometry intersections use the tessellated mesh: their accuracy is limited by the STL surface resolution.

COMSOL export reference:
https://doc.comsol.com/6.4/doc/com.comsol.help.comsol/comsol_ref_results.37.224.html
STL selection export reference:
https://doc.comsol.com/6.4/doc/com.comsol.help.comsol/comsol_api_geom.48.053.html

## 3. How exported parameter cases become layers

Standard COMSOL spreadsheet format shares coordinates:

```text
x,y,z,Bx(case1),By(case1),Bz(case1),Bx(case2),By(case2),Bz(case2),...
```

It has **3 + 3*N columns**, not 6*N. Repeated coordinate blocks are also supported:

```text
x,y,z,Bx1,By1,Bz1,x,y,z,Bx2,By2,Bz2,...
```

The importer stores both as `dataset.B(y,x,z,component,layer)`.
It detects identical repeated coordinate blocks; use `"Layout","blocks6"` to be explicit.
For the shared format use `"Layout","shared_xyz"`.

```matlab
caseDefs(1).datasetOptions = {"ParameterName","I", "ParameterValues",[1 5 10]};
caseDefs(1).opRequest = struct("mode","precomputed","layerIndex",2);
```

Where the COMSOL header contains complete `@ I=...` labels, the importer reads them automatically.
Headerless multi-case exports require the manual name/ordered values. It never silently discards extra cases.
The numeric layer index must be selected explicitly; a sweep layer is not automatically a superposition basis.
The query case name should include the parameter value so plots are easy to interpret.
If two parameters were varied in a headerless export, the code cannot discover that from numbers alone;
the supplied name/values must honestly describe a single-parameter export.

## 4. Script contract for the other chat

Start each main script independently of the current folder:

```matlab
projectDir = fileparts(mfilename("fullpath"));
addpath(genpath(fullfile(projectDir,"functs")));
paths = msbs_paths();
```

Define source cases first:

```matlab
caseDefs = struct([]);
caseDefs(1).caseName = "One coil excited, I=5 A";
caseDefs(1).model = "comsol_precomputed";
caseDefs(1).datasetFile = "2Coil_andYoke_OneCoilExcitation.txt";
caseDefs(1).opRequest = struct("mode","precomputed","layerIndex",1);
caseDefs(1).geometryModel = "2Coil_andYoke";
caseDefs(1).geometryOptions = {"InputScale",1}; % STL units -> metres

caseDefs(1).queries = {
    create_plane_field_query("xz",0,"z", ...
        "Group",1,"Overview",true,"ShowGeometry",true), ...
    create_line_field_query([0 0 -0.2],[0 0 0.2],[1 0 1], ...
        "NPoints",300,"Group",2,"ShowGeometry",true), ...
    create_line_gradient_query([0 0 -0.2],[0 0 0.2],"z", ...
        "GradientDirection","z","NPoints",300,"Group",3,"ShowGeometry",true)
};
[Q,queryFile] = run_query_batch(caseDefs,"MyStudy");
```

Available query builders:

| Builder | Required inputs after function name |
| --- | --- |
| create_plane_field_query | plane ("xy"/"xz"/"yz"), offset, field direction |
| create_plane_gradient_query | plane, offset, field direction, derivative direction |
| create_custom_plane_field_query | point, normal, field direction |
| create_custom_plane_gradient_query | point, normal, field direction, derivative direction |
| create_line_field_query | start point, end point, field direction |
| create_line_gradient_query | start point, end point, field direction; optional GradientDirection |

Directions accept "x", "y", "z" or finite nonzero 3-vectors. Vectors are normalised.
Field direction means projection onto that unit vector, not magnitude of B.
Plane normal, field direction and derivative direction are independent.
For line gradients, omitted GradientDirection means the direction from start to end.

Custom planes also accept:
- `"Resolution",[Nu Nv]`
- `"UpVector","z"`: direction projected into the plane for increasing V
- `"ULimits",[-.2 .2]` and `"VLimits",[-.2 .2]`: metres measured relative to the plane point

Plane sections are filled with separate hole contours preserved. Full surfaces appear in 3D overviews.
Line shading uses geometric entry/exit intervals, independent of NPoints. Native xregion bands
span the entire vertical axes range and remain full-height after zooming/changing ylim.
ShowGeometry is the preferred spelling; ShowCoils remains a compatible alias.

Interpolation always returns NaN outside the dataset domain. A singleton axis has one coordinate:
e.g. grid.y=0 defines only that plane, not an extruded volume.
A gradient with a component along an unsampled axis warns and returns NaN.
A sampled but thin axis warns below `max(2,ceil(5*abs(direction cosine)))` samples;
this is a practical threshold, not an accuracy guarantee. It does not create extra samples.
Increasing query Resolution/NPoints cannot recover information absent from the COMSOL export.

Cross-gradient symmetry is a local physical condition, not a general property of magnetic plots.
In smooth, current-free air (constant isotropic permeability), dBx/dz = dBz/dx because
the y component of curl(B) is zero. For differentiable scalar permeability,
curl(B) = grad(mu) cross H + mu*J_free. At material interfaces, normal B and
(without free surface current) tangential H are continuous; tangential B can jump.
Ordinary cross-derivatives need not be equal at the interface.

The MATLAB method takes finite differences of the exported Cartesian grid, then interpolates
the derivative grid. It has no material-domain labels and does not choose one-sided stencils
at interfaces. Stencils crossing an air/Mu-metal jump can produce large, unequal bands;
cubic interpolation can spread/overshoot them. They are not reliable point derivatives at
the interface. Compare raw data within current-free air with all stencil/interpolation support
on the air side, and check FEM mesh/export-grid convergence. Do not symmetrise the Jacobian
or smooth curves to force equality. Domain-aware one-sided derivatives or appropriate COMSOL
gradient recovery/export are future alternatives. Direct COMSOL differentiation of B is
formulation-dependent (curl elements need special treatment):
https://www.comsol.com/blogs/plotting-spatial-derivatives-magnetic-field
Boundary conditions:
https://doc.comsol.com/6.4/doc/com.comsol.help.comsol/comsol_ref_acdc.26.69.html

Do not modify the simple Biot-Savart evaluator or expand its capabilities.
It retains its x/y/z line queries and along-line derivative limitations.

## 5. Dataset arithmetic and transformations

Append a virtual case after its source cases:

```matlab
caseDefs(3).caseName = "A/10 - B";
caseDefs(3).model = "virtual_field";
caseDefs(3).combination = struct("cases",[1 2],"weights",[0.1 -1], ...
    "poses",zeros(2,6));
caseDefs(3).queries = caseDefs(1).queries;
```

More than two terms, repeated source indices and nested virtual cases are supported.
For A plus a transformed copy of A:

```matlab
caseDefs(2).caseName = "A plus rotated A";
caseDefs(2).model = "virtual_field";
caseDefs(2).combination = struct("cases",[1 1],"weights",[1 1], ...
    "poses",[0 0 0 0 0 0; 0 0 0 pi 0 0]);
caseDefs(2).queries = caseDefs(1).queries;
```

Poses reuse the existing coord_local2global convention:
[x y z yaw pitch roll], metres/radians. Rotation is about the source frame origin,
then translation is applied. To rotate about c, choose translation `c-R*c`.
R is obtained by applying coord_local2global to eye(3) with zero translation;
field vectors and gradient directions rotate consistently with coordinates.
The existing global2local helper is not used as an assumed general inverse.

Each nonzero source is sampled at the requested points. No new combined volume is stored.
Missing data from any nonzero term makes the combined sample NaN; zero-weight sources are ignored.
Default sampling bounds come from the first nonzero transformed source. For custom sampling axes:
`caseDefs(k).combination.referenceGrid = struct("x",...,"y",...,"z",...)`.
This changes sampling coordinates, not data coverage, and does not allow extrapolation.
Use line/custom-plane queries for rotated planar datasets; oblique planes remain oblique.

Existing synthetic_difference definitions are accepted by run_query_batch as weights [1 -1].
The older create_synthetic_difference_dataset function remains for scripts needing a materialised grid.

Current scaling/superposition assumes a suitable linear static response and correctly matched geometry.
The code records combinations; it does not certify their physical validity.
This implementation targets real static fields, not complex/transient exports.

## 6. Plotting and outputs

```matlab
Q_file = "Q_MyStudy_batch1_QueryBatch.mat"; % actual returned name
Q = load_Q_case(Q_file);                  % resolves Q outputs automatically
style = plotStyle();
style.Q_file = Q_file;
style.geometryAlpha = 0.5;
style.metadataOutputDir = paths.metadata;
plot_field(Q,style);
```

Use the actual queryFile returned by run_query_batch; batch numbers are chosen automatically.
The shipped plot_main uses the newest Q output when its Q_file is empty.
Set a specific filename for repeatable plotting.
Figure export filenames must be stable across Q batches. Use
`stable_plot_basename(figure.Name,Q_file)` for the export basename, then write
to that same path on every run; `exportgraphics` overwrites a matching PNG.
For example, batches 4 and 5 both export
`Line_group_line_Bz_-_Q_TwoCoil_yoke_study_QueryBatch.png`.
Keep the study and plot/group identifiers; omit the `_batchN` token. Do not
append timestamps, counters or automatic version suffixes. Manually rename
an exported file when an old version should be retained. Metadata files use
the same stable basename and are overwritten too; their contents retain the
full source Q filename/batch for provenance. Q files themselves retain their
batch numbering, and figure/tab names can still show the source batch.
Q includes sampled values, directions, source identifiers, parameter selection and display geometry.
It excludes source field volumes. Detailed STLs can still make Q large; export a suitable display mesh.
Replotting does not reopen the original data/STLs. To change mesh geometry, regenerate Q.
Use different groups for different planes/quantities, except line groups can pair field and gradient axes.

**Colour-scale selection: separate ordinary fields from field differences.**
Within one plot_field(Q,style) run, all field-difference planes share one symmetric
scale computed from those differences only. Ordinary field planes use their own
shared scale. Do not use ordinary-field amplitudes to set a difference colourbar.
The same separation applies to gradients versus gradient differences, using an
independently calculated 99th-percentile cap for each class. Field scales (T) and
gradient scales (T/m) also remain separate. The selected classes are:

| Class / explicit override | Shared across | Automatic limits |
| --- | --- | --- |
| style.clim.field | Ordinary field planes | Symmetric maximum absolute value |
| style.clim.fieldDifference | All field-difference planes in this run | Symmetric maximum absolute difference |
| style.clim.gradient | Ordinary gradient planes | Symmetric 99th percentile |
| style.clim.gradientDifference | All gradient-difference planes in this run | Independent symmetric 99th percentile |

Only finite planar samples in the corresponding class determine its limits.
No scale is pooled between ordinary and difference plots. A plot group cannot
mix those classes on one coloured axes. Different calls/runs recalculate their
own limits unless explicit limits are supplied. The palette remains the same;
its numerical colour limits differ between the classes.

Legacy synthetic_difference cases and virtual combinations with positive and
negative weights are recognised automatically. A pure scale, rotation or sum
is an ordinary field, not automatically a difference merely because it is virtual.
A transformed/scaled difference retains its difference classification. For an
ambiguous imported or nested case, set caseDefs(k).isDifference=true (or false)
explicitly; this flag is saved in Q metadata. A per-query q.plot.isDifference flag
can override it. Classification uses metadata/operations, not case-name wording.
Existing saved Q differences are recognised without rerunning queries.

To fix a difference scale, use a separate override, for example:

```matlab
style.clim = struct("fieldDifference",[-1 1]*1e-6);
% Optional independent gradient-difference override, in T/m:
style.clim.gradientDifference = [-2 2]*1e-4;
```

An explicit field or gradient limit controls ordinary plots only; it does not
silently tie the corresponding difference plots to that scale. The legacy
numeric [min max] override applies to ordinary field/gradient plots; use the
named difference fields for differences. Plot metadata records the selected
class/limits, and gradient captions use that class's own clipping report.

### Scientific plotting standards (apply to every generated plot script)

- Keep figure/tab Name for provenance. Do not draw a title within exported axes.
- Export using stable_plot_basename and overwrite matching files. Batch numbers
  belong in Q provenance, not in exported figure/metadata filenames; preserve
  old exported figures only when the user manually chooses another name.
- Draw each disconnected boundary separately. Open contours must use open polylines;
  never use patch for an outline because it closes endpoints automatically.
- Fill closed regions only, preserving holes. Do not connect, cap or infer missing STL
  surfaces. Verified internal partitions are removed by clean_component_mesh before sectioning.
  If cleanup cannot produce a closed manifold, show open contours with a warning rather than
  manufacture a fill. A re-export may then be necessary; internal COMSOL mesh lines alone
  do not imply a missing surface.
- Use green coils, dark-grey yokes (RGB [0.25 0.25 0.25]), and purple separate cores,
  at 50% opacity. Zero-field/gradient colormap grey stays [0.8 0.8 0.8]. Role colours
  are applied when plotting, including when loading older Q files.
- Use one filled legend swatch per role: Coils, Yokes, Cores. Do not expose component
  names or outline segments. A swatch identifies the role, not proof that an open section
  has been filled. For a single plane, omit the field-surface swatch: the colorbar names
  its quantity. Plane legends sit below the axes to avoid covering colorbar labels.
- On line plots, material intersections are full-height green/dark-grey/purple bands,
  not polygons frozen to the initial ylim. Draw them behind traces at 50% opacity.
  Accompany material and bore bands with solid, fully opaque vertical entry/exit
  lines (1.25 pt, darkened role colour), retaining the existing fills and hatching.
  These lines follow the full axes height and stay out of the legend; deduplicate
  coincident boundaries so repeated cases do not thicken them.
  Deduplicate matching role/position bands across cases to avoid double opacity. Every
  source case requiring material bands must attach its geometry and request ShowGeometry.
  Bands show the union of requested source geometries when comparing configurations;
  they do not imply that every comparison curve has all of those components.
- For a verified straight-extruded coil with a closed hole, show the coil-bore interval
  as a pale green hatched band. It means "not winding", not "air": a core may occupy
  the bore, in which case its solid material band remains visible underneath. Do not
  shade a bore as solid copper. Bore geometry is inferred only after verifying the
  extrusion/caps/section holes; no bounding-box or convex-hull approximation is used.
  Unsupported coil shapes omit bore hatching. style.showCoilBores=false disables it.
- Typeset differential d upright, e.g. $\mathrm{d}B_z/\mathrm{d}z$ [T/m]. B, its
  component subscript and coordinate symbols remain mathematical; units are upright.
  Use field_quantity_label for colorbar and line-axis labels.
- Use style.fontScale=1.5: axes labels, tick numbers, colorbar numbers and label are
  50% larger than original defaults. Apply the shared style idempotently, never multiply
  repeatedly. Legend text keeps its original size.
- Draw axes/ticks above surfaces (Layer=top), with outward major/minor ticks.
- Use signed physical x/y/z for axis-aligned lines. At x=y=0, a line from z=-1.5 to
  +1.5 m must plot that z range with label z [m], not distance 0..3 m. The default
  style.lineAxis="auto" selects this. Use "distance" for oblique/mixed-axis groups or
  when explicitly requested. Explicit "x", "y", "z" modes are available. Geometry
  shading must use the same coordinate transformation as the traces.
- Preserve raw derivative values; use the interface guidance in section 4. Formatting
  does not change the gradient operator or enforce cross-gradient symmetry.
- All planar gradient plots default to a symmetric 99th-percentile colour
  cap on absolute finite plane values, shared within each ordinary/difference
  class in the run, with independent caps between those classes. Extremes saturate at
  the ends of the colormap; numerical values in Q and line traces are unchanged.
  The chosen threshold and saturated fraction are printed and written to plot metadata
  when enabled. State the cap in a scientific figure caption. Percentile scales depend
  on the ROI/grid; use a fixed cap for comparisons between separate studies.
  style.gradientPercentile=100 restores the full range. An explicit style.clim.gradient
  overrides automatic capping, for example struct("gradient",[-.002 .002]) in T/m.
  Use clim.gradientDifference for a separate gradient-difference override.
- Ordinary fields and field differences must never be automatically pooled for
  colour limits. All field differences within the same run must share their own
  scale; apply the same rule separately to gradient differences, as tabulated above.
- Presentation changes work by replotting existing Q. Regenerate Q to change sampling,
  data or geometry, including after correcting an open STL export.

### Gradient-interface choices: benefits and limitations

| Choice | Advantages | Disadvantages / requirements | Decision |
| --- | --- | --- | --- |
| Mask any derivative stencil crossing a physical material/property interface; return NaN | Removes values that are not valid one-material derivatives; suitable for quantitative air-region comparisons | Requires reliable grid material labels and propagation through interpolation; removes a band of data near interfaces, especially in thin gaps; requires rerunning queries | Recommended next numerical step when boundary-adjacent values are used quantitatively; not yet implemented |
| Fixed symmetric colour cap | Immediate; retains raw data; same scale can be used across studies | Threshold must be selected in T/m; peaks are visually saturated; does not fix interface derivatives | Already supported by explicit clim.gradient |
| Robust percentile colour cap | Immediate and automatic; small interface peaks cannot set the whole scale; no numerical data discarded | Depends on ROI/grid/distribution; can hide real peaks; still not a validity mask | Implemented default: 99th percentile for all planar gradient plots |
| One-sided, same-material derivatives or COMSOL gradient recovery with material identifiers | Can retain more useful points near interfaces and use the FEM representation | More export/implementation work; needs sufficient same-domain samples and convergence checks; direct B differentiation depends on COMSOL formulation | Useful future alternative for accurate near-boundary gradients |

The current decision is robust display capping plus preservation of the raw derivative values.
Colour saturation is explicitly a visual choice, not proof of gradient accuracy. For the masking
option, distinguish real changes in material properties from artificial COMSOL partitions inside
one homogeneous material; the latter do not require masking merely because there is an internal
mesh line. If masks are added later, test the entire finite-difference stencil and subsequent
interpolation support, not just whether the query point itself lies in air. Do not average cross
derivatives or smooth interface spikes to force Maxwell symmetry.

## 7. Copy-and-fill request for the script-writing chat

```text
Please create query_<study>.m and plot_<study>.m in
MatLab/MagCalc_And_FieldPlot using the existing functions and
Documentation/COMSOL_WORKFLOW.md. Read and follow sections 4–7 together,
including the scientific plotting standards in section 6. Do not change the underlying functions
or simple Biot-Savart method.

Model/Java:
- COMSOL model basename:
- Java file: Java COMSOL/<name>.java
- Relevant setup/current winding directions:

Sources:
- Dataset filename(s) under Datasets:
- Export format/header (attach or read the file):
- Sampling domain: plane/volume; bounds; units:
- Swept parameter (one maximum): name and ordered values:
- Layer(s) to compare and readable labels:
- STL folder(s) relative to STL:
- STL length units:
- Component roles if names do not use coil_/yoke_/core_:

Queries:
- Plane(s): xy/xz/yz plus offset, OR point + normal:
- For oblique planes: up direction and U/V bounds:
- Line(s): start and end, in metres:
- Field direction(s): x/y/z or a vector:
- Derivative direction(s), if needed:
- Sampling resolution/NPoints:

Comparisons:
- Weights/divisors/subtractions:
- Poses for transformed source copies (existing convention):
- Which queries share plot groups:
- Required 3D overviews and geometry sections:
- Any colour limits, axis limits or legend labels:

Please use msbs_paths rather than hardcoded PC paths, run_query_batch to
save into Q outputs, explicit layerIndex for parametric data, and the
component colours at geometryAlpha=0.5. Keep the query and plotting
stages separate. Apply the section-6 scientific plotting defaults: no axes
titles, category fill legends, larger fonts, upright differential d, visible
ticks, and physical signed coordinates for aligned lines. Report unavailable
directions/data as NaN. Do not fill open STL contours or force cross-gradient
symmetry across material interfaces.
Use full-height material bands and verified coil-bore hatching for line plots,
attach geometry to every relevant case, and report the gradient display cap.
Use independent ordinary/difference colour-scale classes: all field differences
within the run share their own limits, and all gradient differences share a
separate 99th-percentile cap. Do not reuse the ordinary-field/gradient limits
for differences. Mark ambiguous comparison cases with isDifference explicitly.
```

## 8. Verification

From the project folder:

```matlab
addpath("tests");
test_plot_standards
test_mesh_partitions_and_bands
test_colour_scale_classes
test_comsol_pipeline
```

Checks include planar NaN behaviour, directional gradients, parametric columns,
both STL encodings, bore-preserving sections and line intervals, virtual scaling/
rotation, Q packing and hidden figure rendering. Render previews are local ignored
files under tests/preview. No COMSOL solve is invoked.
The plotting test also checks disconnected/open outlines, category fill legends,
upright differentials, exact/idempotent 1.5x fonts, and signed coordinate shading.
Partition/band tests cover internal-face removal without capping real holes, preservation
of enclosed cavities, inferred bore geometry, zoom-persistent/deduplicated bands and
display clipping that leaves raw data unchanged.
Colour-scale tests verify independent ordinary/difference limits, shared limits for
multiple differences, independent gradient percentile caps and class-specific overrides.
