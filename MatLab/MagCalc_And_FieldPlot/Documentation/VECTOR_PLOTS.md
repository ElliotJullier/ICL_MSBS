# Magnetic field vector queries

Vector plots use the existing dataset -> query -> compact Q -> plot pipeline.
They do not solve COMSOL or alter scalar/gradient queries.
Start with query_vector_example.m and plot_vector_example.m.

## Selected defaults and rationale

| Choice | Default | Why / alternatives |
| --- | --- | --- |
| Spatial seeding | Uniform lattice | Easy to compare regions without confusing density with field strength |
| Adaptive seeding | Optional magnitude or variation importance, with ~70% uniform baseline before masking/rounding | Emphasises detail while preserving coverage; biased sampling is not a magnetic flux/field-line density |
| Arrow budget | At most 300 for a plane; 400 for a volume | Prevents unreadable fields; uniform lattice and masking may produce fewer arrows |
| Arrow length | Uniform, direction-normalised | Colour encodes magnitude; weak fields remain visible; linear/square-root magnitude length options are available |
| Arrow colour | Sequential navy-blue-gold by magnitude | Separate from signed scalar red/grey/blue and material green/grey/purple |
| Material seeds | Hidden when closed display meshes are available | Avoids arrows inside geometry; this tests origins, not the entire arrow segment |
| Background | No scalar heatmap | Avoids two competing colour meanings; scalar and vector plots get separate groups/figures |
| Geometry | Existing role colours and 50% opacity | Plane sections in 2D; full assembly context for a 3D plane view; clipped to the selected box for a 3D volume |

Zero/near-zero displayed vectors are suppressed, not assigned an arbitrary direction.
Limits and projection modes are explicit; the normal field is never guessed from a 2D export.

## 1. Sampling and display modes

### Projected 2D plane

```matlab
q = create_vector_plane_query("xz",0, ...
    "ULimits",[-.8 .8],"VLimits",[-1.4 1.4], ...
    "Resolution",[41 61],"MaxArrows",300, ...
    "Seeding","uniform","Name","Projected B");
```

"xy", "xz", "yz" use world-coordinate offsets and intuitive increasing axes:
xy -> u=x,v=y; xz -> u=x,v=z; yz -> u=y,v=z.
For example xz,0 samples y=0. Limits are metres in the plane, relative to its point.
The xz shorthand uses normal -y so u=x,v=z is right-handed (xy uses +z; yz uses +x).
This determines the sign of the saved Bn component, not the in-plane projection.

For an arbitrary plane:

```matlab
q = create_vector_plane_query([0 0 0],[1 1 0], ...
    "UpVector","z","ULimits",[-.3 .3],"VLimits",[-.5 .5], ...
    "Resolution",[41 51],"Name","Oblique projected field");
```

The normal and up vectors are normalised. UpVector is projected into the plane
to define increasing v; u=cross(up,normal). UpVector cannot be parallel to normal.
If limits are omitted, the projection of the dataset bounds defines the candidate
rectangle; points outside actual coverage still return NaN.

2D arrows are **projections**, not complete 3D vectors:
B_parallel = B - (B dot n)*n; plotted components are (B dot u, B dot v).
Q saves Bx,By,Bz, Bn, B_parallel and both magnitudes. The omitted normal-component
fraction is recorded in metadata and printed. A purely normal field produces no
projected arrows; that does not imply the actual field is zero.

By default the colourbar is |B_parallel| in tesla. ColorMagnitude="total" instead
colours by |B| and labels it accordingly, while arrow directions remain projected.
Arbitrary planes use u/v labels; axes coinciding with global coordinates are labelled
x/y/z where those coordinates are identical. The basis and point are recorded.

### Full 3D vectors sampled on a plane

```matlab
q = create_vector_plane_query("xz",0,"Mode","3d", ...
    "ULimits",[-.8 .8],"VLimits",[-1.4 1.4], ...
    "MaxArrows",200,"Name","Full B on a plane");
```

This samples the same plane but displays all three components in world coordinates.
A planar export can support this if it contains all three B components.
It does **not** reconstruct the field throughout a volume.

### True 3D volume

```matlab
q = create_vector_volume_query( ...
    [-.4 .4;-.3 .3;-.5 .5], ...
    "Resolution",[13 13 13],"MaxArrows",350, ...
    "Seeding","variation","Name","Central test volume");
```

Bounds have rows [xmin xmax; ymin ymax; zmin zmax], in metres.
They must have positive extent in every direction; [] uses the dataset bounds.
The box is also drawn as a light wireframe.
A genuine sampled 3D dataset is required. A singleton-plane dataset cannot be
extruded or extrapolated into a volume; unsupported volume queries fail clearly.

For a rotated/translated box:

```matlab
q = create_vector_volume_query([-.2 .2;-.2 .2;-.4 .4], ...
    "Pose",[.1 0 0 0 pi/4 0],"Resolution",[11 11 17]);
```

Bounds are in the local box frame, transformed using the existing
coord_local2global convention, [x y z yaw pitch roll], SI/radians.
Only sampling locations are transformed; this does not rotate the source field.
For a transformed field itself, use the existing virtual dataset operations.
Explicit bounds are required with a nonzero pose.

## 2. Candidate points, arrow density and interpretation

Resolution controls the **candidate lattice cached in Q**, not necessarily the
number of plotted arrows. It has [Nu Nv] counts for a plane and [Nx Ny Nz] for a box.
Choose counts roughly proportional to physical side lengths for near-isotropic spacing.
The default candidates are 41x41 for a plane and 13x13x13 for a volume.
A hard 50,000-candidate limit prevents accidental giant Q files.

MaxArrows is a maximum, not a promise to fill the budget. Uniform mode keeps a
regular sublattice and does not fill material holes with extra arrows.
Adaptive modes retain a coarse uniform baseline, then add spatially separated seeds:
- Seeding="magnitude": prefer larger displayed-vector magnitudes.
- Seeding="variation": prefer greater sampled-vector spatial variation.

The variation score approximates the Frobenius norm of changes along the candidate
axes: tangential derivatives of the projected B for 2D, tangential derivatives of
full B for a 3D plane, or all three directions for a volume. It is a seeding heuristic
in T/m, **not a validated FEM gradient output**. Candidate samples in known material
are masked before this score is differentiated, so stencils crossing those masks
are not used as high-importance values. NaN scores fall back to spatial coverage.
Unknown/missing geometry cannot provide those material masks.

Importance is capped at its 95th percentile before ranking, so one interface spike
does not consume all adaptive arrows. Extra seeds are selected deterministically
using importance and distance to existing seeds, with minimum separation of
1.5 times the smallest candidate-grid step. There is no random re-seeding between
plots. The baseline fraction is UniformFraction=.7 (allowed .5..1), subject to lattice
rounding and removal of invalid/material points.

**Arrow density is deliberately biased in adaptive mode. It is not a flux-density
measure or a streamline plot.** Arrows show local vectors, not integrated field lines.
Uniform seeding is recommended for quantitative visual comparisons.

## 3. Length, colour and clutter controls

```matlab
q = create_vector_plane_query("xz",0, ...
    "LengthMode","uniform","ColorBy","magnitude","ColorScale","linear");
```

- LengthMode="uniform": equal glyph lengths; direction and colour carry information.
- LengthMode="linear": length proportional to displayed |B|, with a 99th-percentile
  length reference and clipping to prevent long arrows overlapping.
- LengthMode="sqrt": compressed length variation for wide magnitude ranges.
- ArrowFraction=.65: maximum glyph length relative to the smallest displayed
  inter-arrow spacing; allowed up to .8. Lengths are symbolic metres, not field units.
- ColorBy="magnitude": sequential navy-blue-gold colourbar in T.
- ColorBy="none": uniform dark navy arrows and no colourbar.
- ColorScale="log": logarithmic magnitude colours (positive values only), useful
  when important weak-field structure spans many orders of magnitude.
- ColorLimits=[lo hi]: explicit magnitude limits; nonnegative for linear,
  strictly positive for log.
- MinMagnitude=0: optional absolute display cutoff in T; a relative 1e-12 cutoff
  also removes numerical projection noise.
- LineWidth=1 and MaxArrows control visibility. Equal aspect ratios preserve directions.
- ExcludeMaterials=true hides origins inside known closed component meshes.
  Open/unrepairable meshes warn; no material classification is invented.
- ShowGeometry=false removes geometry overlays for a clearer field-only view.

Magnitude colours use a dedicated scale, separate from signed scalar fields or
scalar gradients. Full |B| and projected |B_parallel| are different classes, and
ordinary versus difference vectors also have separate scales. Comparable vector
queries in a run share their class limits. Use one linear/log mapping and consistent
explicit limits per class. Magnitudes use the full eligible range by default, not
the scalar-gradient 99th-percentile colour cap. Difference-vector colours represent
|B_A-B_B|, never |B_A|-|B_B|.

The native quiver autoscaler is disabled; the code sets glyph lengths explicitly:
https://www.mathworks.com/help/matlab/ref/quiver3.html

In 3D, non-overlap in physical space cannot guarantee non-overlap in the camera view.
Reduce MaxArrows, inspect individual planes or rotate the view when a volume is busy.
Do not pile several case/plane arrow sets into one group: this is rejected.
Use separate vector groups/figures and shared scales, or query a virtual vector
difference. Scalar heatmaps and vector arrows also cannot share one plot group.

## 4. Replotting from Q

```matlab
style = plotStyle();
style.vector = struct("MaxArrows",200,"Seeding","variation", ...
    "LengthMode","sqrt","ColorScale","log");
plot_field(Q,style);
```

Display overrides can change Mode (for planes), MaxArrows, Seeding, UniformFraction,
LengthMode, ColorBy, ColorMagnitude, ColorScale, ColorLimits, MinMagnitude,
ArrowFraction, ExcludeMaterials, LineWidth and ShowGeometry without re-querying.
Resolution, bounds, plane point/normal/up direction and pose change the sampling
locations and require a new query. All candidate B components, projected/full
variation scores and material masks are already cached.

Each vector query creates its own figure; Group must be unique within the run.
There is no separate Overview flag: Mode="3d" creates the 3D vector figure itself.
Simple Biot-Savart remains unchanged and explicitly rejects vector queries.

The usual scientific defaults apply: no axes title, provenance in the figure/tab
name, enlarged fonts, visible ticks, role-based geometry legends and stable export
filenames via stable_plot_basename. Metadata records projection, displayed arrow
count, seeding/length rules, symbolic glyph scale and colour limits.

## 5. Run the provided example

1. Run query_vector_example.m using the existing TwoCoil_andYoke planar export.
2. Run plot_vector_example.m. It creates uniform/projected, variation/projected,
   and full-vector 3D-plane views.
3. Stable PNGs are exported by default to COMSOL/Graphs/VectorExample using this
   PC's configured OneDrive root. Set SAVE_PLOTS=false for an interactive preview.
4. For a true volume, uncomment/configure the separate volume-case example only
   after exporting an appropriate COMSOL 3D field volume.

Validation: addpath("tests"); test_vector_queries
The test uses analytic fields for projection/3D-volume checks and exercises the
existing saved-Q plotting path, deterministic density limits and material exclusion.
