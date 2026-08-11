function writeRunSummary(study, outputPath)
%WRITERUNSUMMARY Write a plain-language Markdown summary for a completed run.
arguments
    study (1,1) struct
    outputPath (1,1) string
end
cfg=study.config_resolved; geom=study.geometry; S=study.summary.magnet_set_summary;
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
lines(end+1)=sprintf('- Tunnel: %s, area %.6g m^2, air density %.6g kg/m^3.', ...
    study.tunnel.cross_section_type,study.tunnel.area_m2,study.tunnel.rho_kgm3);
lines(end+1)=sprintf('- Model: %s, outer dimensions [%.6g, %.6g, %.6g] m.', ...
    geom.type,geom.outer_dimensions_B_m);
lines(end+1)=sprintf('- Nominal projected area: %.6g m^2; nominal blockage: %.4g (%.3g%%).', ...
    geom.projected_area_nominal_m2,geom.nominal_blockage_ratio,100*geom.nominal_blockage_ratio);
if isfinite(geom.reference_span_m)
    lines(end+1)=sprintf('- Aerodynamic reference area: %.6g m^2; reference length c: %.6g m; reference span b: %.6g m.', ...
        geom.reference_area_m2,geom.reference_length_m,geom.reference_span_m);
else
    lines(end+1)=sprintf('- Aerodynamic reference area: %.6g m^2; reference length c: %.6g m.', ...
        geom.reference_area_m2,geom.reference_length_m);
end
lines(end+1)="- Aerodynamic source mode: `"+cfg.aero.mode+"`.";
lines(end+1)=sprintf('- Speed range: %.6g to %.6g m/s; CD %.6g to %.6g; CL %.6g to %.6g; Cm %.6g to %.6g.', ...
    cfg.tunnel.speed.lower,cfg.tunnel.speed.upper,cfg.aero.CD.lower,cfg.aero.CD.upper, ...
    cfg.aero.CL.lower,cfg.aero.CL.upper,cfg.aero.Cm.lower,cfg.aero.Cm.upper);
lines(end+1)="- Motion mode: `"+cfg.motion.mode+"`.";
if cfg.aero.mode=="coefficients_6dof"
    lines(end+1)=sprintf('- Six-DOF coefficient ranges: CD %.6g..%.6g; CY %.6g..%.6g; CL %.6g..%.6g; Cl %.6g..%.6g; Cm %.6g..%.6g; Cn %.6g..%.6g.', ...
        cfg.aero.CD.lower,cfg.aero.CD.upper,cfg.aero.CY.lower,cfg.aero.CY.upper, ...
        cfg.aero.CL.lower,cfg.aero.CL.upper,cfg.aero.Cl.lower,cfg.aero.Cl.upper, ...
        cfg.aero.Cm.lower,cfg.aero.Cm.upper,cfg.aero.Cn.lower,cfg.aero.Cn.upper);
end
lines(end+1)="";
lines(end+1)="## Magnet and mass assumptions";
lines(end+1)="";
for i=1:numel(study.magnet_sets)
    set=study.magnet_sets(i); mp=study.mass_properties(i);
    lines(end+1)="### "+set.name;
    lines(end+1)=sprintf('- Total magnet volume: %.6g m^3; total dipole magnitude: %.6g A m^2.', ...
        sum([set.magnets.volume_m3]),sum([set.magnets.dipole_moment_magnitude_Am2]));
    lines(end+1)=sprintf('- Total model mass: %.6g kg; magnet mass %.6g kg; distributed shell mass %.6g kg.', ...
        mp.total_mass_kg,mp.magnet_mass_kg,mp.shell_mass_kg);
    lines(end+1)="- Mass/inertia model: "+mp.model_note;
end
lines(end+1)="";
lines(end+1)="## Magnetic requirement envelopes";
lines(end+1)="";
lines(end+1)="The residual threshold is dimensionless: it is the norm of the force/moment-scaled unachieved wrench divided by the similarly scaled requested wrench. The configured acceptance threshold is `"+ ...
    compose('%.3g',cfg.magnetic.acceptance_relative_residual)+"`.";
lines(end+1)="";
lines(end+1)="| Magnet set | Worst force (N) | Worst moment (N m) | Max local B (T) | Max ||G||F (T/m) | Max relative residual | Accepted |";
lines(end+1)="|---|---:|---:|---:|---:|---:|:---:|";
for i=1:height(S)
    lines(end+1)=sprintf('| %s | %.6g (%s) | %.6g (%s) | %.6g | %.6g | %.3g (%s) | %s |', ...
        S.magnet_set_name(i),S.maximum_force_norm_N(i),S.maximum_force_scenario_id(i), ...
        S.maximum_moment_norm_Nm(i),S.maximum_moment_scenario_id(i), ...
        S.maximum_local_B_norm_T(i),S.maximum_G_frobenius_Tpm(i), ...
        S.maximum_relative_scaled_residual(i),S.maximum_residual_scenario_id(i), ...
        string(S.all_scenarios_acceptable(i)));
end
lines(end+1)="";
lines(end+1)="**Set selection:** "+study.summary.best_selection_note;
if strlength(study.summary.best_magnet_set_id)>0
    lines(end+1)="Selected set: **"+study.summary.best_magnet_set_name+"** (`"+study.summary.best_magnet_set_id+"`).";
end
lines(end+1)="";
lines(end+1)="## Interpretation";
lines(end+1)="";
lines(end+1)="- These values are required applied-field and first-order field-gradient requirements under the point-dipole model. They are not coil currents, coil power, controller gains, or proof that a practical coil system can generate the result.";
lines(end+1)="- Component-wise envelope values can come from different scenarios. Use `scenario_results.csv` and the recorded scenario IDs when a simultaneous physical load case is required.";
lines(end+1)="- A set is residual-accepted only when every requested wrench is reproduced within the configured dimensionless residual threshold. This does not by itself establish hardware feasibility.";
lines(end+1)="- Remanence values are configurable placeholders and must be checked against the exact purchased Magnet Store magnet and operating temperature.";
lines(end+1)="";
lines(end+1)="## Warnings";
lines(end+1)="";
if isempty(study.warnings)
    lines(end+1)="No warnings.";
else
    for warning=study.warnings(:).'
        lines(end+1)="- "+warning;
    end
end
lines(end+1)="";
lines(end+1)="## Detailed files";
lines(end+1)="";
lines(end+1)="- `scenario_results.csv`: one row per scenario and magnet set.";
lines(end+1)="- `magnet_set_summary.csv`: set-level envelopes and residual acceptance.";
if cfg.requirement_resolution.enable
    lines(end+1)="- `resolution_results.csv`: baseline-plus-perturbation incremental field/gradient requirements.";
end
lines(end+1)="- `results_full.mat`: full-precision MATLAB study struct and intermediate records.";
lines(end+1)="- `config_raw.*` and `config_resolved.*`: supplied and fully resolved inputs.";
lines(end+1)="- `configuration.png/.pdf`, `worst_case_*.png/.pdf`, and `magnetic_field_*.png/.pdf`: review figures.";

fid=fopen(outputPath,'w');
if fid<0,error('msbsreq:FileWrite','Could not write run summary.');end
cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s',char(strjoin(lines,newline)+newline));
end
