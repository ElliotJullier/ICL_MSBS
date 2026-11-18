"""Screen the re-run Rev6 study and rebuild the result exports."""
from pathlib import Path
import argparse
import shutil

import numpy as np
import pandas as pd


SPEEDS = (15, 35)
MASS_LIMIT = 25
MAGNETIC = ("Bx_T", "By_T", "Bz_T", "Bxx_Tpm", "Bxy_Tpm", "Bxz_Tpm",
            "Byy_Tpm", "Byz_Tpm", "Bzz_Tpm", "B_norm_T", "Jacobian_B_frobenius_Tpm")
AERO = ("Fx_aero_N", "Fy_aero_N", "Fz_aero_N", "Mx_aero_Nm", "My_aero_Nm", "Mz_aero_Nm")
ID = ["case_id", "rev6_scenario_id", "magnet_set_id"]
RENAMES = {
    **{f"g{k}_Tpm":f"B{k}_Tpm" for k in ("xx", "yy", "zz", "xy", "xz", "yz")},
    "G_frobenius_Tpm":"Jacobian_B_frobenius_Tpm",
    "G_max_abs_Tpm":"Jacobian_B_max_abs_Tpm",
}
SOLVED = [*AERO, *MAGNETIC, "Jacobian_B_max_abs_Tpm", "B_at_magnets_T",
          "B_local_max_norm_T", "magnetic_cost_rms_T", "mean_vacuum_energy_density_Jpm3",
          "relative_scaled_residual", "force_residual_norm_N", "moment_residual_norm_Nm",
          "force_req_norm_N", "moment_req_norm_Nm", "BOx_T", "BOy_T", "BOz_T", "controllable",
          "map_rank", "map_condition_number",
          *(f"{component}_mag_req_{unit}" for unit, prefix in (("N","F"),("Nm","M")) for component in (prefix+"x",prefix+"y",prefix+"z"))]


def read(folder, name):
    return pd.read_csv(folder / f"{name}.csv", low_memory=False)


def write(table, folder, name):
    table.to_csv(folder / f"{name}.csv", index=False)


def peaks(data, metrics, prefix=""):
    rows = []
    for metric in metrics:
        values = data[prefix + metric]
        best = values.abs().idxmax()
        rows.append({"metric":metric, "signed_value":values.loc[best],
                     "magnitude":abs(values.loc[best]), **data.loc[best].to_dict()})
    return pd.DataFrame(rows)


def steady_exports(source, out):
    archive = read(source, "appendix_magnetic_cases")
    original = archive.rename(columns={"scenario_id":"rev6_scenario_id"}).set_index(ID)
    solved = read(out, "matlab_steady_solves").rename(columns=RENAMES)
    baseline = solved[solved.speed_mps == 50].set_index(ID).loc[original.index]
    # Check keys, mass, aero and the solutions that met the original wrench.
    assert len(baseline) == len(original) == 1146 and original.index.is_unique
    for field in ["total_mass_kg", "magnet_volume_m3", *AERO]:
        np.testing.assert_allclose(baseline[field], original[field], atol=1e-8)
    feasible = original.controllable.eq(1)
    for field in MAGNETIC:
        np.testing.assert_allclose(baseline.loc[feasible,field], original.loc[feasible,field], atol=1e-8)
    tables = []
    for speed in SPEEDS:
        new = solved[solved.speed_mps == speed].set_index(ID).loc[original.index]
        table = original.copy()
        table[SOLVED] = new[SOLVED]
        table["speed_mps"] = speed
        table["scenario_id"] = new.scenario_id
        table["scenario_name"] = new.scenario_name
        table["Re"] = new.Re
        table.loc[table.Re_L.notna(),"Re_L"] = new.Re
        table["dynamic_pressure_Pa"] *= (speed/50)**2
        table["operating_group"] = new.scenario_name.astype(str) + f" at {speed} m/s"
        scale = np.full(len(table), (speed/50)**2)
        sphere = table.family.eq("sphere").to_numpy()
        sphere_ratio = new.loc[sphere,"CD"]/original.loc[sphere,"source_CD"]
        scale[sphere] *= sphere_ratio.to_numpy()
        table.loc[sphere,["source_CD","Cx_T"]] = np.column_stack((new.loc[sphere,"CD"],new.loc[sphere,"CD"]))
        for column in ("aero_input_force","aero_input_moment"):
            table[column] = [
                "["+" ".join(f"{v*factor:.15g}" for v in np.fromstring(value.strip("[]"),sep=" "))+"]"
                for value,factor in zip(table[column],scale)
            ]
        ratio = np.maximum(table.Re/table.source_Re,table.source_Re/table.Re)
        table["source_Re_factor"] = ratio
        table["Re_basis"] = np.select(
            [sphere,table.family.eq("square_prism") & table.Re.lt(1e5),ratio.gt(2),ratio.notna()],
            ["interpolated_smooth_sphere_curve","below_source_Re_range_coefficient_transfer",
             "coefficient_transfer_outside_factor_two","coefficient_transfer_within_factor_two"],
            default="inside_source_range")
        table = table.reset_index()
        table["aerodynamic_case_id"] = table.case_id + "/" + table.scenario_id
        table["magnetic_case_id"] = table.aerodynamic_case_id + "/" + table.magnet_set_id
        tables.append(table)
    all_rows = pd.concat(tables,ignore_index=True)
    all_rows["passes_mass_limit"] = all_rows.total_mass_kg.le(MASS_LIMIT)
    all_rows["sizing_eligible"] = (
        all_rows.passes_mass_limit & all_rows.controllable.eq(1)
        & all_rows.support_horizontal_controllable.eq(1) & all_rows.support_upward_controllable.eq(1)
        & (~all_rows.family.isin(["cuboid","ahmed"]) | all_rows.map_rank.eq(6))
    )
    all_rows["selected_fixed"] = False
    ranks = []
    for case_id, group in all_rows.groupby("case_id",sort=False):
        layouts = group.groupby("magnet_set_id",sort=False)
        scores = layouts.magnetic_cost_rms_T.max()[layouts.sizing_eligible.all()].sort_values(kind="stable")
        for rank,(set_id,score) in enumerate(scores.items(),1):
            ranks.append({"case_id":case_id,"magnet_set_id":set_id,"rank":rank,"worst_J_T":score})
        if not scores.empty:
            all_rows.loc[group.index[group.magnet_set_id.eq(scores.index[0])],"selected_fixed"] = True
    all_rows["eligible_for_maxima"] = all_rows.selected_fixed
    selected = all_rows[all_rows.selected_fixed]
    audit = all_rows.drop_duplicates(["case_id","magnet_set_id"])[
        ["case_id","family","magnet_set_id","magnet_set_name","magnet_mass_kg","total_mass_kg",
         "passes_mass_limit","selected_fixed"]].copy()
    audit["foam_mass_kg"] = audit.total_mass_kg - audit.magnet_mass_kg
    coverage = read(source,"coverage")
    winners = selected.drop_duplicates("case_id").set_index("case_id")
    coverage["status"] = coverage.case_id.map(
        lambda c: "ran" if c in winners.index else
        ("mass_limit" if not audit.loc[audit.case_id.eq(c),"passes_mass_limit"].any()
         else "no_mass_eligible_fixed_layout"))
    coverage["lightest_candidate_kg"] = coverage.case_id.map(audit.groupby("case_id").total_mass_kg.min())
    coverage["selected_mass_kg"] = coverage.case_id.map(winners.total_mass_kg)
    coverage["selected_layout"] = coverage.case_id.map(winners.magnet_set_name)
    coverage["reason"] = coverage.status.map({
        "mass_limit":"All installed layouts exceed 25 kg",
        "no_mass_eligible_fixed_layout":"No assembly at or below 25 kg meets all wrench and support requirements"})
    gravity_cols = ["magnetic_case_id","case_id","scenario_name","speed_mps","magnet_set_name",
                    "total_mass_kg","total_weight_N","magnet_mass_kg"]
    gravity_cols += [c for c in all_rows if c.startswith("support_")]
    write(selected[gravity_cols],out,"gravity_support")
    for name,data in [
        ("key_gravity_maxima",selected),
        ("single_magnet_gravity_maxima",all_rows[all_rows.passes_mass_limit & all_rows.magnet_count.eq(1)]),
    ]:
        gravity=[]
        for orientation in ("horizontal","upward"):
            prefix="support_"+orientation+"_"
            for _,group in data[data[prefix+"controllable"].eq(1)].groupby("magnet_volume_fraction"):
                gravity.append(peaks(group,MAGNETIC,prefix).assign(support_orientation=orientation))
        write(pd.concat(gravity,ignore_index=True),out,name)

    for name,data in [("appendix_magnetic_cases",all_rows),("selected_steady_states",selected),
                      ("coverage",coverage),("mass_screen",audit),("hardware_rankings",pd.DataFrame(ranks))]:
        write(data,out,name)
    magnetic = pd.concat([peaks(g,MAGNETIC).assign(envelope=str(s))
                          for (s,_),g in selected.groupby(["speed_mps","magnet_volume_fraction"])] +
                         [peaks(g,MAGNETIC).assign(envelope="combined")
                          for _,g in selected.groupby("magnet_volume_fraction")],ignore_index=True)
    write(magnetic,out,"key_magnetic_maxima")
    aero = pd.concat([peaks(g,AERO).assign(envelope=str(s)) for s,g in selected.groupby("speed_mps")] +
                     [peaks(selected,AERO).assign(envelope="combined")],ignore_index=True)
    write(aero,out,"key_aerodynamic_maxima")
    compact = ["metric","envelope","magnet_volume_fraction","signed_value","magnitude","case_id","scenario_name",
               "speed_mps","Re","total_mass_kg","model_dimensions_B_m","magnetic_case_id","Re_basis"]
    write(magnetic[compact],out,"magnetic_maxima_volume_comparison")
    installed = read(source,"installed_magnets_and_mass").merge(
        audit[["case_id","magnet_set_id","passes_mass_limit","selected_fixed"]],
        on=["case_id","magnet_set_id"],validate="many_to_one")
    write(installed,out,"installed_magnets_and_mass")


def wing_orientation_export(source, out):
    # Rev6 supplies results only for this comparison. With geometry, dipole
    # and coefficients fixed, the feasible affine solution is linear in q.
    original = read(source,"clark_y_alpha17_magnetisation_comparison")
    original = original[original.total_mass_kg.le(MASS_LIMIT)].copy()
    assert original.controllable.eq(1).all() and original.speed_mps.eq(50).all()
    rows=[]
    for speed in SPEEDS:
        table=original.copy()
        factor=(speed/50)**2
        table["speed_mps"]=speed
        table["Re"]*=speed/50
        table["source_Re_factor"]=np.maximum(table.Re/table.source_Re,table.source_Re/table.Re)
        table["scenario_id"]=f"U{speed}_S00001"
        table["aerodynamic_case_id"]=table.case_id+"/"+table.scenario_id
        table["magnetic_case_id"]=table.aerodynamic_case_id+"/"+table.magnet_set_id
        table["operating_group"]=table.scenario_name+f" at {speed} m/s"
        numerical=[c for c in SOLVED if c in table and c not in {
            "B_at_magnets_T","controllable","map_rank","map_condition_number",
            "relative_scaled_residual","mean_vacuum_energy_density_Jpm3"}]
        table[numerical]*=factor
        table["dynamic_pressure_Pa"]*=factor
        table["mean_vacuum_energy_density_Jpm3"]*=factor**2
        for column in ("B_at_magnets_T","aero_input_force","aero_input_moment"):
            table[column]=[
                "["+";".join(
                    " ".join(f"{number*factor:.15g}" for number in np.fromstring(part,sep=" "))
                    for part in value.strip("[]").split(";"))+"]"
                for value in table[column]
            ]
        rows.append(table)
    write(pd.concat(rows,ignore_index=True),out,"clark_y_alpha17_magnetisation_comparison")


def motion_exports(source, out):
    original = read(source,"oscillating_cylinder_summary")
    previous = original[original.speed_mps.eq(50)]
    additions = []
    for speed in SPEEDS:
        rows = previous.copy()
        rows.speed_mps = speed
        for column in ("Re","frequency_Hz"):
            rows[column] *= speed/50
        for column in ("peak_accel_mps2","inertia_peak_N"):
            rows[column] *= (speed/50)**2
        rows.source = "Prescribed kinematics and inertia only"
        additions.append(rows)
    motion = pd.concat([original[original.speed_mps.ne(50)],*additions],ignore_index=True)
    accepted = motion.total_mass_kg.le(MASS_LIMIT)
    write(motion[~accepted],out,"oscillating_cylinder_mass_exclusions")
    write(motion[accepted],out,"oscillating_cylinder_summary")
    phase = read(source,"oscillating_cylinder_phase")
    phase = phase[phase.total_mass_kg.le(MASS_LIMIT)].copy()
    phase["direction"] = "transverse"
    # Use the archived phase convention, N52 moment and single-axis response.
    # New speeds have no synchronized aerodynamic contribution.
    new_phases = []
    for r in motion[accepted & motion.speed_mps.isin(SPEEDS)].itertuples(index=False):
        theta = np.arange(72)*2*np.pi/72
        frame = pd.DataFrame([r._asdict()]*len(theta))
        frame["phase_deg"] = np.rad2deg(theta)
        frame["time_s"] = theta/(2*np.pi*r.frequency_Hz)
        displacement = r.amplitude_m*np.sin(theta)
        inertia = -r.inertia_peak_N*np.sin(theta)
        axis = "z" if r.direction=="transverse" else "x"
        frame["motion_axis_T"] = axis
        frame["displacement_T_m"] = displacement
        frame["inertial_force_N"] = inertia
        if r.direction=="transverse":
            frame["Bzz_inertia_only_Tpm"] = inertia/(1.43/(4*np.pi*1e-7)*r.magnet_mass_kg/7500)
        new_phases.append(frame)
    write(phase,out,"oscillating_cylinder_phase")
    write(pd.concat(new_phases,ignore_index=True),out,"oscillating_cylinder_kinematics_phase")


def main(source, out):
    steady_exports(source,out)
    wing_orientation_export(source,out)
    motion_exports(source,out)
    for name in ("sawada_60cm_calibration.csv","sawada_60cm_matlab.csv"):
        shutil.copy2(source/name,out/name)
    shutil.copy2(source/"inputs/sawada_60cm_fit_magnet.mat",out/"inputs/sawada_60cm_fit_magnet.mat")


if __name__ == "__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source",type=Path)
    parser.add_argument("output",type=Path)
    args=parser.parse_args()
    main(args.source,args.output)
