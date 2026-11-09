"""Package the standalone report and user-supplied evidence to a chosen folder."""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
from zipfile import ZIP_DEFLATED, ZipFile


RESEARCH = Path(__file__).resolve().parents[1]
TOOL = RESEARCH.parent
ROOT = TOOL.parents[1]
OUT = RESEARCH / "outputs" / "standalone"
SOURCES = {
    "Ajmal_2026_10.1016_j.jfluidstructs.2026.104658.pdf": "ajmal.pdf",
    "Matsuda_2003_10.1016_S0167-6105(02)00336-7.pdf": "matsuda.pdf",
    "Blackburn_1997_10.1006_jfls.1997.0086.pdf": "blackburn.pdf",
    "Nishihara_2005_10.1016_j.jfluidstructs.2005.02.003.pdf": "nishihara.pdf",
    "Azadeh-Ranjbar_2018_10.1063_1.5042774.pdf": "azadeh.pdf",
    "Li_2025_10.1016_j.expthermflusci.2025.111488.pdf": "li.pdf",
}


def main(dest):
    dest.mkdir(parents=True, exist_ok=True)
    git = shutil.which("git") or r"C:\Program Files\Git\cmd\git.exe"
    commit = subprocess.check_output([git,"rev-parse","HEAD"],cwd=ROOT,text=True).strip()
    branch = subprocess.check_output([git,"branch","--show-current"],cwd=ROOT,text=True).strip()
    code = dest / "MSBS_Standalone_Code.zip"
    subprocess.run([git,"archive","--format=zip",f"--output={code}",commit,TOOL.relative_to(ROOT).as_posix()],
                   cwd=ROOT,check=True)
    data = dest / "MSBS_Standalone_Results_and_CAD.zip"
    with ZipFile(data,"w",ZIP_DEFLATED) as z:
        for p in sorted(OUT.rglob("*")):
            if p.is_file():
                z.write(p,p.relative_to(OUT).as_posix())
        z.write(RESEARCH/"standalone_run.log","logs/standalone_run.log")
    papers = dest / "Supplied_Source_Papers.zip"
    with ZipFile(papers,"w",ZIP_DEFLATED) as z:
        for name,source in SOURCES.items():
            z.write(RESEARCH/"local_sources"/source,name)
    files = [code,data,papers]
    for base,names in (
        (RESEARCH,("MSBS_Aerodynamic_Requirements_Standalone.pdf","STANDALONE_WORK_LOG.md")),
        (OUT,("useful_results_max_p90.csv","driven_history_max_p90.csv","mass_cap_campaigns.csv","coverage.csv")),
    ):
        for name in names:
            files.append(dest/name)
            shutil.copy2(base/name,files[-1])
    for p in (code,data,papers):
        with ZipFile(p) as z:
            assert z.testzip() is None
    record = {"git_commit":commit,"git_branch":branch,"files":[
        {"file":p.name,"bytes":p.stat().st_size,"sha256":hashlib.sha256(p.read_bytes()).hexdigest()} for p in files
    ]}
    (dest/"DELIVERY_MANIFEST.json").write_text(json.dumps(record,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(record,indent=2))


if __name__=="__main__":
    main(Path(sys.argv[1]).resolve())
