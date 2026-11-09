"""Package the committed MATLAB tool, revision results, and handoff for OneDrive."""
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
OUT = RESEARCH / "outputs" / "revision"


def main(destination):
    destination.mkdir(parents=True, exist_ok=True)
    git = shutil.which("git") or r"C:\Program Files\Git\cmd\git.exe"
    commit = subprocess.check_output([git, "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    code = destination / "MSBS_Revision_Code.zip"
    subprocess.run([git, "archive", "--format=zip", f"--output={code}", commit, str(TOOL.relative_to(ROOT)).replace("\\", "/")],
                   cwd=ROOT, check=True)
    data = destination / "MSBS_Revision_Results_and_CAD.zip"
    with ZipFile(data, "w", ZIP_DEFLATED) as archive:
        for path in sorted(OUT.rglob("*")):
            if path.is_file():
                archive.write(path, str(path.relative_to(OUT)).replace("\\", "/"))
        for name in ("revision_final_run.log", "revision_run.log", "revision_audit.log"):
            archive.write(RESEARCH / name, f"logs/{name}")
        figure = RESEARCH / "local_sources" / "Chinwicharnam_2016_Fig6.jpg"
        if figure.exists():
            archive.write(figure, f"evidence/{figure.name}")
            archive.writestr("evidence/README.md",
                             "# Isolated NACA 0012 wing data\n\n"
                             "Fig. 6, Chinwicharnam and Thipyopas (2016), CC BY-NC 3.0. "
                             "Publisher figure used for the approximate digitisation.\n\n"
                             "[Primary article](https://doi.org/10.1177/1756829316638206)\n")
    for name in ("MSBS_Aerodynamic_Requirements_Revision.pdf", "REVISION_WORK_LOG.md"):
        shutil.copy2(RESEARCH / name, destination / name)
    for name in ("component_targets.csv", "coverage.csv", "distribution_statistics.csv"):
        shutil.copy2(OUT / name, destination / name)
    for path in [code, data]:
        with ZipFile(path) as archive:
            assert archive.testzip() is None
    files = [destination / name for name in (
        code.name, data.name, "MSBS_Aerodynamic_Requirements_Revision.pdf", "REVISION_WORK_LOG.md",
        "component_targets.csv", "coverage.csv", "distribution_statistics.csv",
    )]
    manifest = {
        "git_commit": commit,
        "git_branch": subprocess.check_output([git, "branch", "--show-current"], cwd=ROOT, text=True).strip(),
        "files": [
            {"file": p.name, "bytes": p.stat().st_size, "sha256": hashlib.sha256(p.read_bytes()).hexdigest()}
            for p in files
        ],
    }
    (destination / "DELIVERY_MANIFEST.json").write_text(json.dumps(manifest, indent=2)+"\n", encoding="utf-8")
    print(json.dumps(manifest, indent=2))


if __name__ == "__main__":
    main(Path(sys.argv[1]).resolve())
