"""Rebuild the final envelope from current per-case CSVs; never combine loads."""
from pathlib import Path
import csv
import json
import math
import sys
from collections import Counter

sys.stdout.reconfigure(encoding='utf-8')
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'research'/'outputs'
def read(path):
    with path.open(newline='',encoding='utf-8-sig') as f:return list(csv.DictReader(f))
def number(row,key,default=float('nan')):
    try:return float(row.get(key,''))
    except (ValueError,TypeError):return default
def write(path,rows):
    if not rows:return
    fields=list(dict.fromkeys(k for r in rows for k in r))
    with path.open('w',newline='',encoding='utf-8') as f:
        w=csv.DictWriter(f,fieldnames=fields);w.writeheader();w.writerows(rows)

manifest=read(OUT/'study_manifest.csv')
assert len(manifest)==168
selected=[];all_rows=[];case_summaries=[];accepted_fixed=[]
for m in manifest:
    if m['status']!='ran':continue
    path=OUT/m['case_id']/'scenario_results.csv';T=read(path)
    ids=list(dict.fromkeys(r['magnet_set_id'] for r in T))
    valid_ids=[s for s in ids if max(number(r,'relative_scaled_residual') for r in T if r['magnet_set_id']==s)<=1e-6]
    assert len(T)==int(m['result_rows']),(m['case_id'],len(T),m['result_rows'])
    for r in T:
        r['evidence_tier']='conditional_screen' if r['family'] in ['naca0012','sc20714','cylinder_inline'] else 'source_anchored_transfer'
        r['fixed_set_accepted']=str(r['magnet_set_id'] in valid_ids).lower()
        r['selected_fixed_set']=str(r['magnet_set_id']==m['best_fixed_set_id']).lower()
    all_rows.extend(T)
    accepted_fixed.extend(r for r in T if r['magnet_set_id'] in valid_ids)
    best=[r for r in T if r['magnet_set_id']==m['best_fixed_set_id']]
    if not best:raise RuntimeError('No accepted immutable arrangement: '+m['case_id'])
    assert m['best_fixed_set_id'] in valid_ids
    selected.extend(best)
    first=best[0]
    Re=[number(r,'Re',number(r,'Re_L')) for r in best]
    case_summaries.append(dict(case_id=m['case_id'],family=first['family'],tunnel_side_m=first['tunnel_side_m'],
        blockage=first['blockage_target'],orientation=first['orientation'],volume_fraction=first['magnet_volume_fraction'],
        selected_set=first['magnet_set_name'],n_scenarios=len(best),n_candidates=len(ids),n_accepted_fixed=len(valid_ids),
        max_B_C_T=max(number(r,'B_norm_T') for r in best),max_B_local_T=max(number(r,'B_local_max_norm_T') for r in best),
        max_G_F_Tpm=max(number(r,'G_frobenius_Tpm') for r in best),max_G_entry_Tpm=max(number(r,'G_max_abs_Tpm') for r in best),
        max_cost_T=max(number(r,'magnetic_cost_rms_T') for r in best),max_residual=max(number(r,'relative_scaled_residual') for r in best),
        total_mass_kg=first['total_mass_kg'],non_magnet_mass_kg=first['non_magnet_mass_kg'],magnet_volume_m3=first['magnet_volume_m3'],
        U_min=min(number(r,'speed_mps') for r in best),U_max=max(number(r,'speed_mps') for r in best),
        Re_min=min(Re),Re_max=max(Re),aspect_ratio=first.get('aspect_ratio',''),evidence_tier=first['evidence_tier']))
write(OUT/'all_scenario_results.csv',all_rows)
write(OUT/'selected_fixed_configuration_results.csv',selected)
write(OUT/'case_comparison.csv',case_summaries)
components=['Bx_T','By_T','Bz_T','gxx_Tpm','gyy_Tpm','gzz_Tpm','gxy_Tpm','gxz_Tpm','gyz_Tpm','BOx_T','BOy_T','BOz_T']
norms=['B_norm_T','B_local_max_norm_T','G_frobenius_Tpm','G_max_abs_Tpm','magnetic_cost_rms_T','force_req_norm_N','moment_req_norm_Nm']
extrema=[];summaries={}
for name,rows in [('selected_all',selected),('selected_source_anchored',[r for r in selected if r['evidence_tier']=='source_anchored_transfer']),('all_accepted_fixed',accepted_fixed)]:
    summaries[name]={}
    for key in components+norms:
        kinds=['maximum'] if key in norms else ['minimum','maximum','maximum_absolute']
        for kind in kinds:
            r=(min(rows,key=lambda r:number(r,key)) if kind=='minimum' else max(rows,key=lambda r:abs(number(r,key)) if kind=='maximum_absolute' else number(r,key)))
            record=dict(envelope=name,metric=key,extremum=kind,value=number(r,key),**r)
            extrema.append(record)
            if kind in ['maximum_absolute','maximum']:summaries[name][key]=record
write(OUT/'component_extrema_full_states.csv',extrema)
summary=dict(requested_studies=len(manifest),ran_studies=sum(m['status']=='ran' for m in manifest),
    total_solved_rows=len(all_rows),selected_rows=len(selected),accepted_fixed_rows=len(accepted_fixed),
    maximum_selected_residual=max(number(r,'relative_scaled_residual') for r in selected),
    family_counts=dict(Counter(r['family'] for r in selected)),summaries=summaries)
(OUT/'analysis_summary.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
for tier in ['selected_all','selected_source_anchored']:
    print(tier)
    for metric in ['B_norm_T','B_local_max_norm_T','G_frobenius_Tpm','G_max_abs_Tpm']:
        r=summaries[tier][metric];print(metric,round(r['value'],8),r['case_id'],r['scenario_name'],r['magnet_set_name'])
print({k:v for k,v in summary.items() if k!='summaries'})
