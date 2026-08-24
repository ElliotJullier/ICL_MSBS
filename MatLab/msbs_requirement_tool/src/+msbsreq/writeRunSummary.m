function writeRunSummary(study, outputPath)
%WRITERUNSUMMARY Write a plain-language Markdown summary for a completed run.
arguments
    study (1,1) struct
    outputPath (1,1) string
end
cfg=study.config_resolved;geom=study.geometry;S=study.summary.magnet_set_summary;
lines=strings(0,1);
lines(end+1)="# MSBS requirement run summary";
lines(end+1)="";
lines(end+1)="**Case:** `"+cfg.meta.case_id+"`  ";
lines(end+1)="**Description:** "+cfg.meta.description+"  ";
lines(end+1)="**Timestamp:** "+study.metadata.timestamp+"  ";
lines(end+1)="**Scenarios:** "+height(study.scenarios)+"  ";
lines(end+1)="**Magnet sets:** "+numel(study.magnet_sets);
lines(end+1)="";
lines(end+1)="## Resolved experiment";
lines(end+1)="";
lines(end+1)=sprintf('- Tunnel: %s, area %.6g m^2, air density %.6g kg/m^3.',study.tunnel.cross_section_type,study.tunnel.area_m2,study.tunnel.rho_kgm3);
lines(end+1)=sprintf('- Model: %s, outer dimensions [%.6g, %.6g, %.6g] m.',geom.type,geom.outer_dimensions_B_m);
lines(end+1)=sprintf('- Nominal projected area: %.6g m^2; nominal blockage: %.4g (%.3g%%).',geom.projected_area_nominal_m2,geom.nominal_blockage_ratio,100*geom.nominal_blockage_ratio);
lines(end+1)=sprintf('- Aerodynamic reference area S: %.6g m^2; pitch reference c: %.6g m; roll/yaw reference b: %.6g m.',geom.reference_area_m2,geom.reference_length_m,geom.reference_span_m);
lines(end+1)="- Aerodynamic source mode: `"+cfg.aero.mode+"`.";
lines(end+1)="- Motion mode: `"+cfg.motion.mode+"`.";
lines(end+1)="- E/T/B frames are used; +x_T is the wind/tunnel downstream direction and all final loads and magnetic requirements are reported in T.";
lines(end+1)="- One scenario row represents one simultaneous physical state; no Cartesian product or time interpolation is performed.";
lines(end+1)="";
lines(end+1)="## Magnet and mass assumptions";
lines(end+1)="";
for i=1:numel(study.magnet_sets)
    set=study.magnet_sets(i);mp=study.mass_properties(i);
    lines(end+1)="### "+set.name;
    lines(end+1)=sprintf('- Total magnet volume: %.6g m^3; sum of individual dipole magnitudes: %.6g A m^2.',sum([set.magnets.volume_m3]),sum([set.magnets.dipole_moment_magnitude_Am2]));
    lines(end+1)=sprintf('- Total model mass: %.6g kg; magnet mass %.6g kg; distributed shell mass %.6g kg.',mp.total_mass_kg,mp.magnet_mass_kg,mp.shell_mass_kg);
    lines(end+1)="- Mass/inertia model: "+mp.model_note;
end
lines(end+1)="";
lines(end+1)="## Magnetic requirement envelopes";
lines(end+1)="";
lines(end+1)="The primary magnetic cost is the RMS affine-field magnitude over a centred isotropic reference cube whose side is the largest resolved model dimension. With B(r)=B0+G r this gives J^2=||B0||2^2+(Lref^2/12)||G||F^2 and a mean vacuum-energy-density proxy J^2/(2 mu0). The residual threshold tests wrench reproduction, not whether a practical coil system exists.";
lines(end+1)="Gradient-to-moment coupling is classified from the magnetic influence map. Exact/insignificant coupling uses the primary solve only; significant coupling can trigger the configured reference-length sensitivity suite, stored separately from the primary results.";
lines(end+1)="";
lines(end+1)="| Magnet set | Worst force (N) | Worst moment (N m) | Max local B (T) | Max ||G||F (T/m) | Max RMS-field cost (T) | Coupling | Max relative residual | Accepted |";
lines(end+1)="|---|---:|---:|---:|---:|---:|---|---:|:---:|";
for i=1:height(S)
    lines(end+1)=sprintf('| %s | %.6g (%s) | %.6g (%s) | %.6g | %.6g | %.6g | %s | %.3g (%s) | %s |',S.magnet_set_name(i),S.maximum_force_norm_N(i),S.maximum_force_scenario_id(i),S.maximum_moment_norm_Nm(i),S.maximum_moment_scenario_id(i),S.maximum_local_B_norm_T(i),S.maximum_G_frobenius_Tpm(i),S.maximum_magnetic_cost_rms_T(i),S.coupling_class(i),S.maximum_relative_scaled_residual(i),S.maximum_residual_scenario_id(i),string(S.all_scenarios_acceptable(i)));
end
lines(end+1)="";
lines(end+1)="**Fixed-configuration set selection:** "+study.summary.best_selection_note;
lines(end+1)="**Independent-scenario ranking:** each scenario is also evaluated using its lowest-cost residual-acceptable magnet set and ranked hardest-first; see `independent_scenario_ranking.csv`.";
if strlength(study.summary.best_magnet_set_id)>0,lines(end+1)="Selected set: **"+study.summary.best_magnet_set_name+"** (`"+study.summary.best_magnet_set_id+"`).";end
lines(end+1)="";
lines(end+1)="## Interpretation";
lines(end+1)="";
lines(end+1)="- Aerodynamic, gravity, inertial and optional static external wrenches are first transformed to T and referenced to the model centre of mass. Their simultaneous balance defines the required magnetic wrench.";
lines(end+1)="- Every magnet in a manual set has its own position and dipole direction. All magnets share the same first-order external field B(r)=B0+G r; they see different B at different positions but the same constant G.";
lines(end+1)="- These are coil-independent field and gradient requirements. Coil currents, winding geometry, power, thermal limits and controller design are outside this program.";
lines(end+1)="- Operating-point sweeps such as speed and coefficient changes belong in scenario rows. Changes that alter physical geometry, such as tunnel size with blockage sizing, should normally be separate case files.";
lines(end+1)="";
lines(end+1)="## Warnings";
lines(end+1)="";
if isempty(study.warnings),lines(end+1)="No warnings.";else,for warning=study.warnings(:).',lines(end+1)="- "+warning;end,end
lines(end+1)="";
lines(end+1)="## Detailed files";
lines(end+1)="";
lines(end+1)="- `scenario_results.csv`: one row per simultaneous scenario and magnet set.";
lines(end+1)="- `magnet_set_summary.csv`: per-set envelopes, coupling classification and residual acceptance.";
lines(end+1)="- `scenario_extrema.csv`: actual scenarios producing each component/norm/magnetic extreme; extrema are never combined into a fictitious wrench.";
lines(end+1)="- `fixed_configuration_ranking.csv`: minimax ranking when one magnet configuration must cover all scenarios.";
lines(end+1)="- `independent_scenario_ranking.csv`: hardest-first scenario ranking after selecting the best acceptable magnet set independently for each scenario.";
lines(end+1)="- `magnetic_cost_sensitivity.csv`: alternate reference-length solutions for significantly coupled records only (written when present).";
lines(end+1)="- `results_full.mat`: full-precision MATLAB study struct and intermediate records.";
lines(end+1)="- `config_raw.*` and `config_resolved.*`: supplied and fully resolved inputs.";
lines(end+1)="- `configuration.png/.pdf`, `worst_case_*.png/.pdf`, and `magnetic_field_*.png/.pdf`: review figures.";
fid=fopen(outputPath,'w');if fid<0,error('msbsreq:FileWrite','Could not write run summary.');end
cleanup=onCleanup(@()fclose(fid));fprintf(fid,'%s',char(strjoin(lines,newline)+newline));
end
