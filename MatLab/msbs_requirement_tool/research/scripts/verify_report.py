"""Render every report page and audit layout/data invariants."""
from pathlib import Path
import json, csv, math
import pypdfium2 as pdf
import pdfplumber
from PIL import Image, ImageOps, ImageDraw
ROOT=Path(__file__).resolve().parents[2]; R=ROOT/'research'; out=R/'qa'/'report';out.mkdir(parents=True,exist_ok=True)
doc=pdf.PdfDocument(str(R/'MSBS_Aerodynamic_Requirements_Report.pdf'))
for i in range(len(doc)):
    im=doc[i].render(scale=1.65).to_pil();im.save(out/f'page_{i+1:02}.png')
for start in range(0,len(doc),6):
    canvas=Image.new('RGB',(900,1290),'#d9e1e5');draw=ImageDraw.Draw(canvas)
    for j in range(start,min(start+6,len(doc))):
        im=Image.open(out/f'page_{j+1:02}.png');im.thumbnail((435,600));x=(j-start)%2*450;y=(j-start)//2*430
        # Compact six-page contact sheet; full-size pages remain for review.
        im.thumbnail((300,410));canvas.paste(im,(x,y));draw.text((x+305,y+10),str(j+1),fill='black')
    canvas.save(out/f'contact_{start//6+1}.png')
issues=[]
with pdfplumber.open(R/'MSBS_Aerodynamic_Requirements_Report.pdf') as doc2:
    for i,page in enumerate(doc2.pages):
        for w in page.extract_words():
            if w['x0']<30 or w['x1']>page.width-30 or w['top']<28 or (w['bottom']>page.height-39 and w['top']<page.height-39):
                issues.append((i+1,w['text'],round(w['x0']),round(w['x1']),round(w['top']),round(w['bottom'])))
print(json.dumps(dict(pages=len(doc),layout_boundary_issues=issues),indent=2))
with (R/'outputs'/'selected_fixed_configuration_results.csv').open(newline='') as f:
    T=list(csv.DictReader(f))
max_trace=max(abs(float(r['gxx_Tpm'])+float(r['gyy_Tpm'])+float(r['gzz_Tpm'])) for r in T)
max_force_balance=max(abs(float(r['F'+a+'_mag_req_N'])-float(r['F'+a+'_inertial_demand_N'])+float(r['F'+a+'_aero_N'])+float(r['F'+a+'_gravity_N'])+float(r['F'+a+'_other_N'])) for r in T for a in ['x','y','z'])
max_origin_error=0
for r in T:
    g=[[float(r['gxx_Tpm']),float(r['gxy_Tpm']),float(r['gxz_Tpm'])],[float(r['gxy_Tpm']),float(r['gyy_Tpm']),float(r['gyz_Tpm'])],[float(r['gxz_Tpm']),float(r['gyz_Tpm']),float(r['gzz_Tpm'])]]
    pos=[float(r[k]) for k in ['x_C_T_m','y_C_T_m','z_C_T_m']]
    for i,axis in enumerate('xyz'):
        err=float(r['BO'+axis+'_T'])-float(r['B'+axis+'_T'])+sum(g[i][j]*pos[j] for j in range(3))
        max_origin_error=max(max_origin_error,abs(err))
audit=dict(selected_rows=len(T),max_gradient_trace_Tpm=max_trace,max_force_balance_error_N=max_force_balance,max_field_origin_error_T=max_origin_error,max_speed_mps=max(float(r['speed_mps']) for r in T))
assert max_trace<1e-9 and max_force_balance<1e-8 and max_origin_error<1e-10
assert audit['max_speed_mps']<=50
(R/'outputs'/'verification_summary.json').write_text(json.dumps(audit,indent=2))
print(json.dumps(audit,indent=2))
