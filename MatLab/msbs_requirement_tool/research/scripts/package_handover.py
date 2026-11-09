"""Copy an explicit, hashed handover package to the user-authorised OneDrive folder."""
from pathlib import Path
import hashlib, json, shutil, subprocess, sys, zipfile
from datetime import date

ROOT=Path(__file__).resolve().parents[2];RESEARCH=ROOT/'research'
DELIVERY_DATE=date.fromisoformat(sys.argv[1]).isoformat()
DEST=Path("C:/Users/'ej221'/OneDrive - Imperial College London/PhD/21 Design and Procurement/21-2 EM Coils/COMSOL/Temp Matlab Forces/2026-11-06_MSBS_Requirements")
MARKER=DEST/'MSBS_PACKAGE_MARKER.txt'
if DEST.exists() and not MARKER.exists():
    raise RuntimeError('Refusing to overwrite an existing non-package directory: '+str(DEST))
DEST.mkdir(parents=True,exist_ok=True)
MARKER.write_text(f'MSBS aerodynamic requirements study of 2026-11-06; packaged on {DELIVERY_DATE}.\n')
git=Path('C:/Program Files/Git/cmd/git.exe')
def gitval(*args):return subprocess.check_output([str(git),'-C',str(ROOT),*args],text=True).strip()
commit=gitval('rev-parse','HEAD');branch=gitval('branch','--show-current')
for name in ['MSBS_Aerodynamic_Requirements_Report.pdf','MSBS_Aerodynamic_Requirements_Report.md','WORK_LOG_AND_AGENT_HANDOFF.md','report_build_record.json']:
    shutil.copy2(RESEARCH/name,DEST/name)
summaries=DEST/'Summary_Tables';summaries.mkdir(exist_ok=True)
for name in ['study_manifest.csv','case_comparison.csv','component_extrema_full_states.csv','geometry_comparison.csv','phase_resolution.csv','verification_summary.json','analysis_summary.json']:
    shutil.copy2(RESEARCH/'outputs'/name,summaries/name)

toolzip=DEST/'MSBS_Requirement_Tool_Complete_Snapshot.zip'
with zipfile.ZipFile(toolzip,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for path in sorted(ROOT.rglob('*')):
        if not path.is_file():continue
        rel=path.relative_to(ROOT)
        if rel.parts[0]=='results':continue  # unrelated historical runs
        if 'matlab_preferences' in rel.parts or 'local_sources' in rel.parts:continue
        if 'qa' in rel.parts and path.parent.name=='report':continue # rendered report QA, not needed to restore
        if path.suffix.lower() in ['.asv','.m~']:continue
        z.write(path,Path('msbs_requirement_tool')/rel)

sourcezip=DEST/'Source_Papers_and_Original_Handover.zip'
inventory=[]
sources=sorted((RESEARCH/'local_sources').glob('*.pdf'))
sources.append(Path("C:/Users/'ej221'/OneDrive - Imperial College London/PhD/11 Literature/Read/Sawada_NAL 60CM MAGNETIC SUSPENSION AND BALANCE SYSTEM.PDF"))
with zipfile.ZipFile(sourcezip,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for path in sources:
        z.write(path,Path('Source_Papers')/path.name)
        inventory.append(dict(file=path.name,bytes=path.stat().st_size,sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
    handover=Path("C:/Users/'ej221'/Downloads/MSBS_Aerodynamic_Cases_and_Requirement_Tool_Handover.md")
    z.write(handover,handover.name)
    z.writestr('source_inventory.json',json.dumps(inventory,indent=2))

readme=f'''# Start here - MSBS requirements handover

Study dated 6 November 2026; packaged {DELIVERY_DATE}. This folder is in the Imperial College London OneDrive COMSOL area under `Temp Matlab Forces`.

1. Read `MSBS_Aerodynamic_Requirements_Report.pdf` (24 pages).
2. Read `WORK_LOG_AND_AGENT_HANDOFF.md` for the full source audit, implementation/execution log, reproduction commands and outstanding scientific caveats.
3. `Summary_Tables` contains directly readable study comparisons, complete-state component extrema, geometry and verification tables.
4. Extract `MSBS_Requirement_Tool_Complete_Snapshot.zip` to any working directory. It contains the entire tool source/cases/tests/docs, all 168 exact MAT inputs and generated results, source-page images needed to rebuild the report, and execution logs. Unrelated historical results are excluded.
5. Extract `Source_Papers_and_Original_Handover.zip` for all supplied and additionally retrieved primary PDFs (14 papers), the original handover and a source hash inventory. Keep this private to the authorised OneDrive area; these PDFs were not committed to GitHub.
6. On another computer with MATLAB, change to the extracted `msbs_requirement_tool`, run `runAllTests`, then use the commands in the handoff. Codex is not required.

## GitHub code

- Repository: https://github.com/ElliotJullier/ICL_MSBS
- Branch: `{branch}`
- Snapshot commit: `{commit}`
- Code: https://github.com/ElliotJullier/ICL_MSBS/tree/{branch}/MatLab/msbs_requirement_tool
- Report: https://github.com/ElliotJullier/ICL_MSBS/blob/{branch}/MatLab/msbs_requirement_tool/research/MSBS_Aerodynamic_Requirements_Report.pdf

This commit includes code, documentation, constructors/tests, the report and agent handoff. Large generated outputs and private source PDFs are in these OneDrive archives.

## Scientific status

168 study configurations ran; 96,096 primary candidate/state solves; all 76 tests passed. Conditional all-case maxima: |B_C|=0.55652291 T, ||G||F=35.80899712 T/m and largest tensor entry=28.73187792 T/m. The source-anchored subset gives max local field=0.09958346 T and max ||G||F=3.69979029 T/m. These are provisional applied-field requirements, not validated low-Re aerodynamics or coil ratings. Read the assumptions before using the larger values as a specification.

See `DELIVERY_MANIFEST.json` for archive hashes. The local OneDrive client sync status is recorded separately after copy verification; a filesystem copy alone is not proof of remote synchronisation.
'''
(DEST/'START_HERE.md').write_text(readme,encoding='utf-8')
files=[]
for path in sorted(DEST.rglob('*')):
    if path.is_file() and path.name not in ['DELIVERY_MANIFEST.json','SYNC_STATUS.md']:
        files.append(dict(file=str(path.relative_to(DEST)),bytes=path.stat().st_size,sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
record=dict(study_date='2026-11-06',delivery_date=DELIVERY_DATE,git_branch=branch,git_commit=commit,source_paper_count=len(sources),files=files)
(DEST/'DELIVERY_MANIFEST.json').write_text(json.dumps(record,indent=2),encoding='utf-8')
for archive in [toolzip,sourcezip]:
    with zipfile.ZipFile(archive) as z:
        bad=z.testzip()
        if bad:raise RuntimeError('Archive failed CRC verification: '+bad)
print(json.dumps(dict(destination=str(DEST),commit=commit,branch=branch,files=len(files),bytes=sum(f['bytes'] for f in files),archives=[str(toolzip),str(sourcezip)]),indent=2))
