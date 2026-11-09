"""Extract a reproducible, page-indexed local source inventory (no OCR)."""
from pathlib import Path
import hashlib
import json
import zipfile
import sys
import logging
from pypdf import PdfReader
logging.getLogger('pypdf').setLevel(logging.ERROR)
sys.stdout.reconfigure(encoding='utf-8')

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "research" / "local_sources"
OUT.mkdir(parents=True, exist_ok=True)
if len(sys.argv) > 1:
    import pypdfium2 as pdf
    pattern, page_list = sys.argv[1:3]
    target = next(OUT.glob(pattern + '*.pdf'), None)
    if target is None:
        inv = json.loads((OUT / 'inventory.json').read_text())
        target = Path(next(x['file'] for x in inv if pattern.lower() in x['file'].lower()))
    pages = page_list.split(',')
    doc = pdf.PdfDocument(str(target))
    if page_list.startswith('find:'):
        needle=page_list[5:].lower()
        print(str(target))
        for idx in range(len(doc)):
            txt=doc[idx].get_textpage().get_text_range()
            if needle in txt.lower():
                print(f'PDF page {idx+1}: '+txt[-550:])
        raise SystemExit()
    qa = OUT.parent / 'qa'
    qa.mkdir(exist_ok=True)
    for num in pages:
        idx = int(num) - 1
        print(f'=== PDF PAGE {num} ===\n' + doc[idx].get_textpage().get_text_range())
        doc[idx].render(scale=1.7).to_pil().save(qa / f'{target.stem[:18]}_p{num}.png')
    raise SystemExit()
DOWNLOADS = Path("C:/Users/'ej221'/Downloads")
with zipfile.ZipFile(DOWNLOADS / "Papers.zip") as archive:
    for item in archive.infolist():
        if item.filename.lower().endswith('.pdf'):
            # Flatten only explicitly selected PDFs; do not trust archive paths.
            (OUT / Path(item.filename).name).write_bytes(archive.read(item))
sawada = Path("C:/Users/'ej221'/OneDrive - Imperial College London/PhD/11 Literature/Read/Sawada_NAL 60CM MAGNETIC SUSPENSION AND BALANCE SYSTEM.PDF")
sources = sorted(OUT.glob('*.pdf')) + [sawada]
inventory = []
for source in sources:
    reader = PdfReader(source)
    pages = [p.extract_text() or '' for p in reader.pages]
    stem = source.stem
    (OUT / (stem + '.txt')).write_text('\n\n'.join(f'=== PDF PAGE {i+1} ===\n{p}' for i,p in enumerate(pages)), encoding='utf-8')
    inventory.append(dict(file=str(source), text_file=stem+'.txt', pages=len(pages), sha256=hashlib.sha256(source.read_bytes()).hexdigest(), characters=[len(t) for t in pages]))
(OUT / 'inventory.json').write_text(json.dumps(inventory, indent=2), encoding='utf-8')
print(json.dumps(inventory, indent=2))
