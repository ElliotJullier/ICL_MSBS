"""Build the revision PDF and reproducible summary tables from MATLAB outputs."""
from pathlib import Path
from xml.sax.saxutils import escape
import math

import numpy as np
import pandas as pd
from reportlab.graphics import renderSVG
from reportlab.graphics.shapes import Circle, Drawing, Line, Polygon, Rect, String
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.utils import ImageReader
from reportlab.platypus import (
    Image, PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle,
)

RESEARCH = Path(__file__).resolve().parents[1]
OUT = RESEARCH / "outputs" / "revision"
PDF = RESEARCH / "MSBS_Aerodynamic_Requirements_Revision.pdf"
FIG = OUT / "charts"
W = 501
INK = colors.HexColor("#173048")
GREY = colors.HexColor("#566577")
GRID = colors.HexColor("#dbe2eb")
ACCENT = colors.HexColor("#176885")
FAMILIES = {
    "sphere": ("Sphere", "#3977ad"),
    "cuboid": ("Cuboid", "#d88325"),
    "ahmed": ("Ahmed", "#945692"),
    "naca0012": ("NACA 0012", "#269375"),
    "cylinder_crossflow": ("Transverse cylinder", "#b74852"),
}
TUNNELS = [(.6, "h"), (.6, "up"), (1., "h"), (1., "up")]
MODES = {"independent_group": "Swap", "fixed_hardware": "Fixed"}
G = "G_frobenius_Tpm"
B = "B_local_max_norm_T"
M = "total_mass_kg"
J = "selected_cost_T"
METRICS = [(G, "||G||F [T/m]", 1.), (B, "Local ||B|| [T]", .05), (M, "Model mass [kg]", 10.)]
COMPONENTS = {
    **{f"B{k}_T": f"B_C,{k} [T]" for k in "xyz"},
    **{f"BO{k}_T": f"B_O,{k} [T]" for k in "xyz"},
    **{f"g{k}_Tpm": f"G_{k} [T/m]" for k in ("xx", "yy", "zz", "xy", "xz", "yz")},
}

styles = getSampleStyleSheet()
styles.add(ParagraphStyle("Body", fontSize=9.3, leading=13, textColor=INK, spaceAfter=7))
styles.add(ParagraphStyle("Small", parent=styles["Body"], fontSize=7.8, leading=10.2, spaceAfter=4))
styles.add(ParagraphStyle("Cell", parent=styles["Small"], fontSize=7.2, leading=8.8, spaceAfter=0))
styles.add(ParagraphStyle("HeadCell", parent=styles["Cell"], fontName="Helvetica-Bold", textColor=colors.white))
styles.add(ParagraphStyle("Title2", fontName="Helvetica-Bold", fontSize=26, leading=30, textColor=INK, spaceAfter=14))
styles.add(ParagraphStyle("Section", fontName="Helvetica-Bold", fontSize=17, leading=22, textColor=INK, spaceAfter=9))
styles.add(ParagraphStyle("Eyebrow", fontName="Helvetica-Bold", fontSize=9, leading=12, textColor=ACCENT, spaceAfter=7))
STORY = []


def para(txt, style="Body"):
    STORY.append(Paragraph(txt, styles[style]))


def chapter(number, title):
    if STORY:
        STORY.append(PageBreak())
    para(number, "Eyebrow")
    para(title, "Section")


def table(headers, rows, widths=None):
    rows = [[Paragraph(escape(str(x)), styles["HeadCell"]) for x in headers]] + [
        [Paragraph(escape(str(x)), styles["Cell"]) for x in row] for row in rows
    ]
    t = Table(rows, colWidths=widths or [W / len(headers)] * len(headers), repeatRows=1, hAlign="LEFT")
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), INK),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#edf3f8")]),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("TOPPADDING", (0, 0), (-1, -1), 3.3),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 3.3),
    ]))
    STORY.extend([t, Spacer(1, 8)])


def ref(label, url):
    return f'<link href="{url}" color="#176885">{escape(label)}</link>'


def fmt(x, n=3):
    if abs(x)<1e-12:
        return "0"
    return f"{x:.{n}g}"


def tunnel_name(h, orient):
    return f"{h:g} m {'horizontal' if orient == 'h' else 'upward'}"


def case_label(row):
    return f"{FAMILIES[row.family][0]}, {100 * row.target_maximum_blockage:g}%, V{100 * row.magnet_volume_fraction:g}"


def operation(row):
    phase = f", phase {math.degrees(row.source_phase_rad):.0f} deg" if pd.notna(row.source_phase_rad) else ""
    return f"{row.operating_group}{phase}"


def short_set(name):
    if name.startswith("layout"):
        layout, axis=name.split("_main_axis")
        return f"L{layout[6:]} / {'xyz'[int(axis)-1]}"
    if name.startswith("single_body_"):
        return "Body "+name.removeprefix("single_body_").replace("30"," 30°")
    return "Tunnel x"


def selected_slice(df, h, orient):
    return df[(df.tunnel_side_m == h) & (df.orientation == orient)]


def maxrow(df, key):
    return df.loc[df[key].abs().idxmax()]


def peak_records(df):
    grouped = df.groupby(["case_id", "operating_group", "selection_mode"], sort=False)
    peaks = grouped[[G, B, M, J]].max().reset_index()
    meta = df[["case_id", "family", "tunnel_side_m", "orientation", "target_maximum_blockage", "magnet_volume_fraction"]].drop_duplicates()
    return peaks.merge(meta, on="case_id", validate="many_to_one")


def draw_plot_axes(d, x, y, w, h, xticks, yticks, xlabel, ylabel):
    for v, label in yticks:
        d.add(Line(x, y+h*v, x+w, y+h*v, strokeColor=GRID, strokeWidth=.55))
        d.add(String(x-5, y+h*v-2, label, textAnchor="end", fontSize=7, fillColor=GREY))
    for v, label in xticks:
        d.add(String(x+w*v, y-12, label, textAnchor="middle", fontSize=7, fillColor=GREY))
    d.add(Line(x, y, x+w, y, strokeColor=INK, strokeWidth=.7))
    d.add(Line(x, y, x, y+h, strokeColor=INK, strokeWidth=.7))
    d.add(String(x+w/2, y-24, xlabel, textAnchor="middle", fontSize=8, fillColor=INK))
    d.add(String(x, y+h+4, ylabel, fontSize=7, fillColor=GREY))


def chart(d, name):
    renderSVG.drawToFile(d, str(FIG / f"{name}.svg"))
    STORY.append(d)


def legend(d, x, y, fams=FAMILIES):
    for family in fams:
        label, c = FAMILIES[family]
        d.add(Rect(x, y, 8, 8, fillColor=colors.HexColor(c), strokeColor=None))
        d.add(String(x+11, y, label, fontSize=8, fillColor=INK))
        x += 17 + 4.3*len(label)


def histograms(peaks, key, xlabel, width):
    top = peaks[key].max()
    n = max(3, int(math.ceil(top / width)))
    # Display all original bins, with a separate labelled zoom for the core.
    edges = np.arange(n+1)*width
    d = Drawing(W, 348)
    legend(d, 38, 331)
    bins = {}
    for i, (H, orient) in enumerate(TUNNELS):
        x, y, pw, ph = 39+251*(i%2), 197-155*(i//2), 198, 99
        sample = selected_slice(peaks, H, orient)
        d.add(String(x, y+ph+17, f"{tunnel_name(H, orient)}   n={len(sample)}", fontName="Helvetica-Bold", fontSize=9, fillColor=INK))
        counts = np.array([
            np.histogram(sample[sample.family == family][key], edges)[0]
            for family in FAMILIES
        ])
        ymax = max(2, int(math.ceil(counts.sum(axis=0).max()/4)*4))
        dX, dY = pw/n, ph/ymax
        tick_step=max(1,int(math.ceil(n/7)))
        ticks=sorted(set(list(range(0,n+1,tick_step))+[n]))
        draw_plot_axes(d, x, y, pw, ph, [(j/n,fmt(edges[j])) for j in ticks],
                       [(f, str(int(f*ymax))) for f in (0, .5, 1)], xlabel,
                       "Articles and sets" if key==M else "Operating groups")
        for j in range(n):
            bottom = 0
            for family, count in zip(FAMILIES, counts[:, j]):
                if count:
                    d.add(Rect(x+j*dX+.2, y+bottom*dY, max(dX-.4,.3), count*dY,
                               strokeColor=None, fillColor=colors.HexColor(FAMILIES[family][1])))
                bottom += count
        bins[(H, orient)] = counts
    return d, edges, bins


def scatter(peaks):
    d = Drawing(W, 335)
    legend(d, 38, 319)
    xmax = math.ceil(peaks[M].max()/25)*25
    ymax = math.ceil(peaks[G].max())
    for i, (H, orient) in enumerate(TUNNELS):
        x, y, pw, ph = 39+251*(i%2), 189-151*(i//2), 198, 98
        p = selected_slice(peaks, H, orient)
        d.add(String(x, y+ph+17, tunnel_name(H, orient), fontName="Helvetica-Bold", fontSize=9, fillColor=INK))
        draw_plot_axes(d, x, y, pw, ph, [(f, fmt(f*xmax)) for f in (0,.25,.5,.75,1)],
                       [(f, fmt(f*ymax)) for f in (0,.5,1)], "Mass [kg]", "||G||F [T/m]")
        for r in p.itertuples():
            c=colors.HexColor(FAMILIES[r.family][1])
            d.add(Circle(x+getattr(r,M)/xmax*pw, y+getattr(r,G)/ymax*ph, 2.5,
                         strokeColor=c, strokeWidth=.7, fillColor=c if r.magnet_volume_fraction == 1 else colors.white))
    return d


def coverage_chart(df):
    d=Drawing(W,190)
    legend(d, 42, 170)
    x,y,w,h=97,33,388,110
    low,high=.5,50
    xf=lambda v: x+math.log(v/low,high/low)*w
    for u in [.5,1,2,5,10,20,50]:
        d.add(Line(xf(u),y,xf(u),y+h,strokeColor=GRID,strokeWidth=.6))
        d.add(String(xf(u),y-12,str(u),fontSize=8,textAnchor="middle",fillColor=GREY))
    for i,(family,(label,hexcol)) in enumerate(FAMILIES.items()):
        yy=y+h-i*22-12
        d.add(String(x-6,yy-2,label,fontSize=7.6,textAnchor="end",fillColor=INK))
        sub=df[df.family==family].drop_duplicates(["case_id","speed_mps"])
        for r in sub.itertuples():
            c=colors.HexColor(hexcol)
            d.add(Circle(xf(r.speed_mps),yy+(2 if r.tunnel_side_m==1 else -2),2.6,
                         fillColor=c if r.tunnel_side_m==1 else colors.white,strokeColor=c,strokeWidth=.7))
    d.add(String(x+w/2,8,"Re-matched airspeed [m/s]   |   hollow 0.6 m, filled 1 m",
                 textAnchor="middle",fontSize=8,fillColor=INK))
    return d


def wake_map(reads):
    d=Drawing(W,252)
    x,y,w,h=53,43,419,170
    kmin,kmax=.06,.51
    xp=lambda k:x+w*(k-kmin)/(kmax-kmin)
    yp=lambda a:y+h*a/1.6
    regions=[
        ("P+S", "#9dcfb3", [(2,1.6),(4.78,1.6),(4.63,1.27),(4.38,1.06),(4.07,.94),(2,1.08)], (.43,1.35)),
        ("2P", "#f8d28d", [(4.78,1.6),(12,1.6),(12.2,1.32),(11.4,.99),(10.4,.72),(9.3,.5),(7.9,.27),(6.2,.09),(4.8,0),(5.8,.4),(5.6,.7),(4.07,.94),(4.55,1.25)], (.118,1.04)),
        ("2S", "#8ec4df", [(4.07,.94),(4.8,.83),(5.48,.64),(5.82,.42),(5.59,.22),(4.8,0),(4.14,.26),(3.85,.55),(3.9,.92)], (.197,.46)),
        ("2Po", "#d09cc6", [(4.52,.89),(4.95,.95),(5.43,.92),(6.03,.82),(6.24,.63),(6.02,.5),(5.76,.52),(5.52,.67),(5.07,.76)], (.143,.86)),
    ]
    d.add(Rect(x,y,w,h,fillColor=colors.HexColor("#f1f3f7"),strokeColor=None))
    for label,col,points,(kp,ap) in regions:
        pts=[val for l,a in points for val in (xp(1/l),yp(a))]
        d.add(Polygon(pts,fillColor=colors.HexColor(col),strokeColor=colors.white,strokeWidth=.9))
        d.add(String(xp(kp),yp(ap),label,textAnchor="middle",fontName="Helvetica-Bold",fontSize=9,fillColor=INK))
    draw_plot_axes(d,x,y,w,h,[((v-kmin)/(kmax-kmin),fmt(v)) for v in [.1,.2,.3,.4,.5]],
                   [(v/1.6,fmt(v)) for v in [0,.4,.8,1.2,1.6]],"Reduced frequency fD/U = 1/(lambda/D)","Reduced amplitude A/D")
    # Three distinct force-history locations, one of which has two branches.
    for i,(k,a,label,include) in enumerate([(1/5.6,.36,"1",True),(1/6,.36,"2",True),
                                            (1/6,.78,"3",True),(1/4.4,1.34,"4",False)]):
        dx=[10,-10,10,9][i]
        d.add(Circle(xp(k),yp(a),3.3,fillColor=INK if include else colors.white,strokeColor=INK))
        d.add(String(xp(k)+dx,yp(a)+7,label,fontName="Helvetica-Bold",fontSize=8,fillColor=INK))
    d.add(String(63,231,"Adapted wake regions from Fig. 3(a)   |   numbers key the measured traces below",
                 fontName="Helvetica-Bold",fontSize=8.7,fillColor=INK))
    d.add(String(xp(.085),yp(.13),"Unlabelled areas include",fontSize=6.8,fillColor=GREY))
    d.add(String(xp(.085),yp(.07),"coalescing / unsynchronised flow",fontSize=6.8,fillColor=GREY))
    return d


def pair_diagram():
    d=Drawing(W,142)
    for x,title in [(11,"Uniform B along +y"),(261,"Gradient with Gyy > Gxx")]:
        d.add(Rect(x,16,229,109,fillColor=colors.HexColor("#edf3f8"),strokeColor=None))
        d.add(String(x+10,109,title,fontName="Helvetica-Bold",fontSize=10,fillColor=INK))
        for y,sign in [(79,1),(48,-1)]:
            d.add(Rect(x+93,y-7,44,14,fillColor=colors.HexColor("#57b89c"),strokeColor=None))
            start=x+115-14*sign
            tip=x+115+14*sign
            d.add(Line(start,y,tip,y,strokeColor=INK,strokeWidth=2))
            d.add(Polygon([tip,y,tip-7*sign,y+4,tip-7*sign,y-4],fillColor=INK,strokeColor=None))
            d.add(String(x+37,y-2,"+r" if sign==1 else "-r",fontSize=9,fillColor=INK))
            torque=("+z torque" if sign==1 else "-z torque") if x==11 else "+z net contribution"
            d.add(String(x+144,y-2,torque,fontSize=7.7,fillColor=INK))
        d.add(String(x+10,25,"Torques cancel" if x==11 else "Torques add, forces cancel",
                     fontSize=8,fillColor=ACCENT))
    return d


def cad(pattern, height=196):
    match=next(iter(sorted((OUT/"cad").glob(pattern))),None)
    if match:
        x,y=ImageReader(str(match)).getSize()
        STORY.append(Image(str(match),width=min(W,height*x/y),height=min(height,W*y/x),hAlign="CENTER"))


def export_tables(df, peaks):
    fields=[B,G,M,J,"B_norm_T","B_O_norm_T","G_max_abs_Tpm",*COMPONENTS]
    rows=[]
    for label,sub in [("all",df)]+[(tunnel_name(h,o),selected_slice(df,h,o)) for h,o in TUNNELS]:
        for f in fields:
            r=maxrow(sub,f)
            rows.append(dict(panel=label,metric=f,signed_value=r[f],abs_value=abs(r[f]),
                             case_id=r.case_id,scenario_name=r.scenario_name,operating_group=r.operating_group,
                             phase_rad=r.source_phase_rad,magnet_set_id=r.magnet_set_id,
                             magnet_set_name=r.magnet_set_name,selection_mode=r.selection_mode,
                             speed_mps=r.speed_mps,Re=r.Re,map_rank=r.map_rank))
    pd.DataFrame(rows).to_csv(OUT/"component_targets.csv",index=False)
    peaks.to_csv(OUT/"operating_group_peaks.csv",index=False)
    by_case=[]
    for (cid,mode), s in df.groupby(["case_id","selection_mode"],sort=False):
        for f in fields:
            r=maxrow(s,f)
            by_case.append(dict(case_id=cid,selection_mode=mode,metric=f,signed_value=r[f],
                                operating_group=r.operating_group,scenario_name=r.scenario_name,
                                speed_mps=r.speed_mps,Re=r.Re,magnet_set_name=r.magnet_set_name))
    pd.DataFrame(by_case).to_csv(OUT/"preferred_case_extrema.csv",index=False)
    summaries=[]
    for f,_,_ in METRICS:
        sample=df.drop_duplicates(["case_id","magnet_set_id"]) if f==M else peaks
        for (h,o),p in sample.groupby(["tunnel_side_m","orientation"],sort=False):
            v=p[f]
            summaries.append([h,o,f,len(v),v.min(),v.median(),v.quantile(.90),v.quantile(.95),v.max()])
    pd.DataFrame(summaries,columns=["tunnel_side_m","orientation","metric","n","min","median","p90","p95","max"]).to_csv(
        OUT/"distribution_statistics.csv",index=False)


def footer(canvas, doc):
    canvas.setStrokeColor(GRID)
    canvas.line(47,39,548,39)
    canvas.setFont("Helvetica",8)
    canvas.setFillColor(GREY)
    canvas.drawString(47,25,"MSBS aerodynamic sizing  /  Revision 2  /  9 November 2026")
    canvas.drawRightString(548,25,str(doc.page))


def main():
    FIG.mkdir(exist_ok=True)
    selected=pd.read_csv(OUT/"selected_primary.csv",low_memory=False)
    df=selected[
        ((selected.preferred_selection=="static_swappable") & (selected.selection_mode=="independent_group")) |
        ((selected.preferred_selection=="fixed_hardware") & (selected.selection_mode=="fixed_hardware"))
    ].copy()
    df["B_O_norm_T"]=np.linalg.norm(df[["BOx_T","BOy_T","BOz_T"]],axis=1)
    peaks=peak_records(df)
    coverage=pd.read_csv(OUT/"coverage.csv")
    sens=pd.read_csv(OUT/"selection_sensitivity.csv",keep_default_na=False)
    reads=pd.read_csv(OUT/"morse_figure_reads.csv")
    candidates=pd.read_csv(OUT/"candidates.csv",low_memory=False)
    export_tables(df,peaks)
    report_overview(df,peaks,coverage,candidates)
    report_sources(df,reads)
    report_design(df,selected,sens)
    report_distributions(df,peaks)
    report_appendices(df)
    doc=SimpleDocTemplate(str(PDF),pagesize=(595.28,841.89),leftMargin=47,rightMargin=47,
                          topMargin=49,bottomMargin=51,title="MSBS aerodynamic requirements revision",
                          author="MSBS engineering study")
    doc.build(STORY,onFirstPage=footer,onLaterPages=footer)


def report_overview(df,peaks,coverage,candidates):
    para("IMPERIAL MSBS  /  PRELIMINARY SIZING  /  REVISION 2", "Eyebrow")
    para("Aerodynamic cases and<br/>magnetic requirements", "Title2")
    b,g,m=[maxrow(df,key) for key in (B,G,M)]
    para(f"Across {df.case_id.nunique()} solved configurations, the selected-hardware envelope reaches "
         f"<b>{fmt(b[B])} T</b> at a magnet centre and <b>{fmt(g[G])} T/m</b> in gradient Frobenius norm. "
         f"The heaviest selected article is <b>{fmt(m[M],4)} kg</b>. These maxima occur in the cases listed below. "
         "All loads use source Reynolds numbers or explicitly identified harmonic approximations at a source Reynolds number.")
    table(["Limit","Value","Controlling case","U [m/s]","Re","Magnet set"],[
        (title,fmt(r[key],4),tunnel_name(r.tunnel_side_m,r.orientation)+" / "+case_label(r)+" / "+operation(r),
         fmt(r.speed_mps),f"{r.Re:,.0f}",r.magnet_set_name)
        for key,title,r in [(B,"Local field [T]",b),(G,"Gradient [T/m]",g),(M,"Mass [kg]",m)]
    ],[72,40,190,47,52,100])
    table(["Tunnel","Cases","Operating groups","Max local B [T]","Max ||G||F [T/m]","Max mass [kg]"],[
        (tunnel_name(h,o),s.case_id.nunique(),len(selected_slice(peaks,h,o)),fmt(s[B].max()),
         fmt(s[G].max()),fmt(s[M].max(),4))
        for h,o in TUNNELS for s in [selected_slice(df,h,o)]
    ],[115,41,75,86,101,83])
    para(f"The previous 35.81 T/m limit came from the SC(2)-0714 section-coefficient transfer across Reynolds regimes. "
         f"The revised target excludes that transfer and changes both magnet fit and mass. The earlier 503 kg was an "
         "uncapped Ahmed model with a shell mass proportional to magnet mass. The current study still contains "
         "heavy solid-body articles and high gradients when a small magnet must support their weight. "
         f"The solver evaluated {len(candidates):,} candidate/phase rows. Section 7 compares their selected requirements by tunnel.")
    if (OUT/"PplusS_trace_sensitivity.csv").exists():
        p=pd.read_csv(OUT/"PplusS_trace_sensitivity.csv")
        r=maxrow(p,G)
        para(f"<b>Separate P+S sensitivity.</b> A phase-independent screen from the displayed vortex-force trace gives "
             f"{fmt(r[G])} T/m for the {tunnel_name(r.tunnel_side_m,r.orientation)} cylinder at "
             f"{100*r.target_maximum_blockage:g}% blockage and {100*r.magnet_volume_fraction:g}% magnet volume. "
             "The report keeps that conditional result "
             "outside the reconstructed-history envelope. Treat the higher-amplitude P+S motion as a separate design decision.")
    para("Read the component tables as separate absolute channel targets. The signed values belong to actual simultaneous solutions, "
         "but maxima in different rows can come from different experiments. The exported rows retain the complete field, tensor, and wrench.")
    chapter("01  /  SETUP", "Coordinates, field notation and matching")
    table(["Quantity","Definition"],[
        ("T, E, B and M","T is tunnel axes (+x downstream, +z upward for horizontal flow). E is Earth axes. B is model axes. M is a magnet block’s local axes. All are right-handed."),
        ("O and C","O is the fixed tunnel field origin. C is the calculated model centre of mass. Magnet positions and aerodynamic moments are shifted to C for the solve."),
        ("B_C and B_O","Vectors evaluated at C and O. The tool exports Bx/By/Bz at C and BOx/BOy/BOz at O. B_O = B_C − G r_C."),
        ("Local B","max_i ||B_C + G R_TB(r_i,B − r_C,B)||. This is the largest Euclidean magnitude among magnet centres in the same row."),
        ("G","G_ij = dB_i/dx_j in T, symmetric and trace-free. ||G||F is the square root of the sum of all nine squared entries. A maximum component is a separate quantity."),
        ("Installation","Same body-to-flow attitudes and aero signs in both installations. Horizontal g_T = [0,0,−g]. Upward g_T = [−g,0,0], using R_ET = Ry(−90 deg)."),
        ("Steady six-axis load","Three forces and three moments at one fixed pose, with zero prescribed velocity, angular rate and acceleration. Cuboid and Ahmed require rank 6 as well as a small load residual."),
        ("Dynamic load","Each transverse-cylinder history includes the rigid body's prescribed translation, acceleration and phase-dependent fluid force. No rotational motion is prescribed."),
    ],[92,409])
    para("Use air density 1.225 kg/m³ and dynamic viscosity 1.81e−5 Pa·s, so nu = 1.47755e−5 m²/s. "
         "At each target geometry, set U = Re<sub>source</sub> nu / L<sub>Re</sub>. Then q = 0.5 rho U². "
         "A source speed can differ from the new tunnel speed even at identical Re. Cases above 50 m/s are excluded. "
         "The source length is diameter for sphere and cylinder, streamwise reference body length for Jann and Meile, and chord for NACA.")
    chart(coverage_chart(df),"matched_speed_coverage")
    chapter("02  /  COVERAGE", "Geometry, Reynolds number and exclusions")
    rows=[]
    for family in coverage.family.unique():
        sub=coverage[coverage.family==family]
        ran=df[df.family==family]
        if ran.empty:
            label={"sc20714":"SC(2)-0714","cylinder_inline":"Inline cylinder"}[family]
            text="CAD only. Low-speed section source starts at Re 2 million; finite-wing transfer excluded." if family=="sc20714" else "Legacy numbers lack verified forced-oscillation coefficient and AR data."
            rows.append((label,0,"—","—",text))
            continue
        bs=sorted(ran.target_maximum_blockage.unique()*100)
        rows.append((FAMILIES[family][0],ran.case_id.nunique(),"/".join(fmt(b) for b in bs),
                     f"{fmt(ran.speed_mps.min())}–{fmt(ran.speed_mps.max())}",
                     {"sphere":"Measured drag-crisis curve, six selected Re.",
                      "cuboid":"Re 165,000. URANS mean coefficients.",
                      "ahmed":"Re ≈ 2.05 million. Omit those requiring more than 50 m/s.",
                      "naca0012":"AR 1, measured force and moment at three chord Re.",
                      "cylinder_crossflow":"AR 10, Re 4,000. 8% substitute for 10%; 20% omitted."}[family]))
    table(["Family","Cases","Max blockage [%]","U [m/s]","Evidence boundary"],rows,[105,36,65,74,221])
    para("Blockage is the largest geometric silhouette divided by H² over the specified attitudes. It sizes one article for "
         "the attitude sweep. For the cuboid, the projected area is the sum of face areas weighted by the direction cosines. "
         "For Ahmed and the wing it comes from the projected profile-prism silhouette. End plates, stings and fake floors "
         "are outside the blockage calculation. No wall-interference correction was applied at 20%.")
    para("The 8% transverse case deliberately retains the source span-to-diameter ratio. With AR = L/D = 10, "
         "L/H = sqrt(AR × blockage), so 3%, 8%, 10% and 20% require span ratios of 0.548, 0.894, 1.000 and 1.414. "
         "At 20%, even zero end clearance requires AR ≤ 5. A freely suspended short cylinder has different end flow and spanwise correlation. "
         "The supplied sources give no quantitative justification for transferring the Morse loads to that geometry.")
    para("At the selected maximum angle of 45 deg the AR = 1 wing spans about 0.52 H at 20% blockage. "
         "The original AR = 3 wings would need different finite-span data, especially at high incidence. "
         "Retaining the isolated wing's measured AR also retains its induced drag and tip-flow contribution in the source coefficients.")
    para("Previous section 7a was an input audit. It separated legacy values copied from old case files, assumptions used to fill gaps, "
         "and a check that the phase grid sampled the assumed harmonic peaks. The revised evidence pages put these distinctions beside the cases "
         "they affect. A phase-grid check addresses numerical sampling. It cannot establish the amplitude of missing harmonics or the validity of a coefficient transfer.")


def report_sources(df, reads):
    chapter("03A  /  SOURCE WORKING", "Sphere and sharp-edged cuboid")
    para("<b>Sphere.</b> Achenbach Fig. 4, printed p. 568, gives the measured drag crisis. Read representative pre-crisis, "
         "crisis and post-crisis points by tracing the experimental curve horizontally to Re and vertically to C<sub>D</sub>. "
         "The narrow transition is sensitive to roughness, turbulence and point placement. Use D = H sqrt(4 blockage / pi), "
         "F<sub>x</sub> = q pi D² C<sub>D</sub>/4 and symmetry for the other mean loads. "
         +ref("Achenbach (1972), Fig. 4","https://doi.org/10.1017/S0022112072000874"))
    table(["Re_D","150,000","250,000","300,000","370,000","500,000","600,000"],
          [["C_D ≈",.510,.500,.480,.070,.080,.085]], [69,72,72,72,72,72,72])
    cad("sphere_T060*b10*single_body_x.png",143)
    para("<b>Cuboid.</b> Jann and Geisbauer Body A, 110 × 90 × 50 mm, uses S = l w and length l for all three moment coefficients. "
         "Tables 2 and 8, PDF pp. 11 and 17, tabulate eight Fourier harmonics. Evaluate "
         "C(alpha) = a<sub>0</sub> + sum[a<sub>i</sub> cos(i alpha) + b<sub>i</sub> sin(i alpha)] at beta 0 or −45 deg. "
         "Use their stated Re = 165,000 and recompute U with this study's air properties. Their source U = 18 m/s and l = 0.110 m "
         "would imply about 134,000 at this study's viscosity. The stated Re is treated as the source label, with that discrepancy retained "
         "as source uncertainty. The fit represents steady coefficients inferred from fully turbulent URANS. "
         +ref("Jann and Geisbauer (2013), Tables 2 and 8","https://doi.org/10.2514/6.2013-1282"))
    table(["alpha, beta [deg]","C_D","C_Y","C_L","C_l,Bp","C_m,Bp","C_n,Bp"],[
        ("0, 0",.3753,0,0,0,0,0),("0, −45",.5545,.1089,0,0,0,.0142),
        ("25, −45",.7439,-.0324,.4025,.0253,.0466,.0152),
        ("45, −45",.8945,-.1824,.3002,.0220,.0373,.0191),
        ("90, −45",1.0009,-.3745,0,.0431,0,.0001)
    ],[91,66,66,66,70,70,72])
    para("Source Bp points upstream in x and down in z at its zero attitude. Use "
         "R<sub>T,Bp</sub> = diag(−1,1,−1) R<sub>z</sub>(−beta) R<sub>y</sub>(alpha). "
         "Multiply force coefficients by qlw in T. Multiply moments by qlw·l in Bp and rotate into T. "
         "The aerodynamic datum is the geometric centre. The tool shifts the moments to C.", "Small")
    cad("cuboid_T060*b10*layout1_main_axis1.png",143)

    chapter("03B  /  SOURCE WORKING", "Yawed Ahmed body")
    para("Use Meile et al. Fig. 1 for the 1.044 × 0.389 × 0.288 m body, 35 deg slant and 50 mm ground gap. "
         "Read the 0 and 15 deg points in Figs. 18 and 20, printed pp. 42–43, on the same beta and U = 30 m/s curves. "
         "Read uncertainty is of order 0.02–0.04 in each plotted coefficient. Use source symmetry for head-on lateral force, "
         "roll and yaw. Derive source Re ≈ 2.0475 million from 2.73 million at 40 m/s in §2.5. "
         +ref("Meile et al. (2016), Figs. 1, 18 and 20","https://doi.org/10.1016/j.ijheatfluidflow.2015.11.002"))
    table(["beta [deg]","C_D","C_S","C_L","C_roll","C_pitch","C_yaw"],[
        (0,.29,0,0,0,.08,0),(15,.43,.81,.57,.53,-.17,.26)
    ],[83,69,69,69,70,70,71])
    para("Let s = new body length / 1.044 m. F<sub>B</sub> = q(.112s²)[C<sub>D</sub>, C<sub>S</sub>, C<sub>L</sub>]. "
         "Moments about the source floor datum P use q(.112s²) times [.327s C<sub>roll</sub>, .470s C<sub>pitch</sub>, "
         ".470s C<sub>yaw</sub>]. P<sub>B</sub> = s[.182+.202-.522, 0, −(.050+.144)] m from the source geometry. "
         "R<sub>TB</sub> = R<sub>z</sub>(−beta). Add R(P−C) × F<sub>T</sub> to the rotated moment.")
    cad("ahmed_T100*b10*layout1_main_axis1.png")
    para("The CAD and mass integration use a full-width extrusion with a trapezoidal rear roof. Front fillets and mounting stings are omitted. "
         "The cap checks the actual CAD magnet box corners, including the full auxiliary span. The source ground condition and scaled floor gap "
         "remain assumptions for the new installation. In upward flow this is a co-rotated ground surrogate. The paper's bistability near "
         "12.5 deg is a reason to obtain synchronized measurements before using this case as an unsteady control limit.")
    para("Matched U excludes both 3% Ahmed sizes and the 0.6 m/10% size. The approximate required speeds are 119, 71.3 and 65.1 m/s, "
         "respectively. Retained data use the 0.6 m/20%, 1 m/10% and 1 m/20% geometry in both gravity orientations.")

    chapter("03C  /  SOURCE WORKING", "Finite NACA 0012 at AR = 1")
    para("Chinwicharnam and Thipyopas Fig. 6 panels (a), (b) and (c) report simultaneous lift, drag and quarter-chord moment "
         "for the isolated rectangular wing. Table 1 gives chord and span of 0.30 m. Their 1 m square KU facility measured "
         "the diamond, circle and square series at chord Re 129,000, 215,000 and 300,000. The figure also includes a separate "
         "Supaero comparison, which is outside these rows. The selected attitudes cover attached flow, first stall and the later "
         "high-incidence branch. Figure labels put positive moment nose-up, mapped to +M<sub>y,T</sub>. "
         +ref("Chinwicharnam and Thipyopas (2016), Fig. 6","https://doi.org/10.1177/1756829316638206"))
    wing=df[(df.family=="naca0012") & (df.orientation=="h") & (df.tunnel_side_m==.6)
            & (df.target_maximum_blockage==.03) & (df.magnet_volume_fraction==1)]
    table(["Re_c","alpha [deg]","C_L","C_D","C_m,c/4","U at 0.6 m/3% [m/s]"],[
        (f"{r.Re:,.0f}",r.operating_group.split("alpha")[-1],fmt(r.CL),fmt(r.CD),fmt(r.Cm),fmt(r.speed_mps))
        for r in wing.itertuples()
    ],[75,84,60,60,92,130])
    para("For each angle, project the actual NACA 4-digit profile into the y–z plane. With chord from nose to tail, "
         "positive pitch rotates +x<sub>B</sub> toward −z<sub>T</sub>. Use qbc[C<sub>D</sub>, 0, C<sub>L</sub>] and "
         "qbc² C<sub>m</sub> about B-coordinate x = −c/4, then shift to C. Other mean force and moment components use midspan symmetry. "
         "Approximate figure reading precision is about 0.02–0.04 for force coefficients and 0.005–0.01 for moment. "
         +ref("NASA four-digit ordinate method","https://ntrs.nasa.gov/citations/19970008124"))
    cad("naca0012_T060*single_tunnel_x_at_last_pose.png",163)
    para("The magnet fit prism is between 10% and 55% chord. The available height is the lowest upper ordinate minus the "
         "highest lower ordinate throughout that interval. The sampled NACA profile and section prism are used for CAD, projected area "
         "and ABS mass. The source AR of 1 is retained even at 20% blockage. Wall effects remain outside the sizing model.", "Small")

    chapter("03D  /  SOURCE WORKING", "Morse and Williamson wake selection")
    para("Their water-channel experiment imposed transverse motion at Re<sub>D</sub> = 4,000, D = 38.1 mm and span 381 mm. "
         "A fixed end plate sat 2 mm below the cylinder. The channel section was 381 × 508 mm and turbulence was below 0.9%. "
         "This corresponds to geometric blockage about 7.5% and a plate gap of 0.0525 D. The air studies preserve Re, L/D, "
         "A/D and fD/U. Transfer assumes the source end conditions can be approximated, especially near the mode transitions. "
         +ref("Morse and Williamson (2009), §2 and Figs. 3, 7, 8, 10","https://doi.org/10.1016/j.jfluidstructs.2008.12.003"))
    chart(wake_map(reads),"morse_reduced_frequency_wake_map")
    table(["Map","Wake","A/D","lambda/D","fD/U","C_Y amp.","Phase [deg]","Source / disposition"],[
        (key,r.wake,fmt(r.A_over_D),fmt(r.lambda_over_D),fmt(r.fD_over_U),
         fmt(r.CY_fundamental) if r.run else "—", fmt(r.phase_deg) if r.run else "—", src)
        for key,r,src in zip(["1","2","3","3","4"],reads.itertuples(),
                            ["Fig. 7, total force","Fig. 7, total force","Fig. 10, low branch",
                             "Fig. 10, high branch","Fig. 8, strong 2f; held out"])
    ],[35,76,43,49,50,62,65,121])
    para("Read the lower plots of Fig. 7 and the right-hand plots of Fig. 10 for total force and phase. Use the typical half peak-to-peak "
         "coefficient and nearby phase plateau for each branch. The two Fig. 10 modes can occur at the same drive state. "
         "They are separate periodic branches, with transient switching loads unresolved. Read approximately to 0.1–0.2 coefficient "
         "units and 10–20 deg. P+S remains on the map because it bounds a different wake family. Its Fig. 8 vortex force "
         "contains substantial 2f energy and lacks the phase-aligned total-force trace needed for this reconstruction.")
    para("At theta = 2 pi f t, prescribe z<sub>C,T</sub> = A sin(theta), a<sub>z</sub> = −(2 pi f)² z. "
         "Use C<sub>L</sub>(theta) = C<sub>Y</sub> sin(theta + phase) and D L as reference area. The source transverse force includes "
         "fluid added mass. The rigid-body demand m a is calculated separately. Set C<sub>D</sub> = 1.2 as a mean-drag sizing "
         "assumption. Drag harmonics and unmeasured moments are outside these cases. Carberry was the previous load source and "
         "is retained as context only. "+ref("Carberry et al. (2001)","https://doi.org/10.1006/jfls.2000.0363"),"Small")

    if (OUT/"PplusS_trace_sensitivity.csv").exists():
        chapter("03E  /  SOURCE WORKING", "P+S diagnostic and phase resolution")
        p=pd.read_csv(OUT/"PplusS_trace_sensitivity.csv")
        r=maxrow(p,G)
        para("Fig. 8 P+S shows a short vortex-force trace and a clear 2f peak. The plotted magnitude reaches about 12. "
             "Round that displayed peak to 13 and use the source's Eq. 3 to bound the potential-force amplitude, "
             "2 pi³ (A/D)/(lambda/D)². At A/D = 1.34 and lambda/D = 4.4 this adds "
             f"{fmt(r.Cpotential_amp)} to the coefficient allowance. The signs of that total-force allowance are each "
             "tested at both extrema of prescribed acceleration. This is a phase-independent envelope of the assumed forcing "
             "range and the specified motion, conditional on the short trace representing the intended coefficient bound.")
        table(["P+S phase [deg]","Assumed C_L","a_z [m/s²]","F_z,aero [N]","F_z,req [N]","||G||F [T/m]"],[
            (f"{math.degrees(a.drive_phase_rad):.0f}",fmt(a.CL),fmt(a.a_Cz_T_mps2),fmt(a.Fz_aero_N),
             fmt(a.Fz_mag_req_N),fmt(getattr(a,G))) for a in p[p.case_id==r.case_id].itertuples()
        ],[88,75,84,80,84,90])
        para(f"The strongest diagnostic row has U = {fmt(r.speed_mps)} m/s, Re = {r.Re:,.0f} and "
             f"a<sub>z</sub> = {fmt(r.a_Cz_T_mps2)} m/s². It uses the same fixed magnet as the 0.6 m horizontal "
             "3% cylinder with 10% magnet volume. Most of the increase comes from the larger prescribed acceleration. "
             "The assumed force extrema are not phase-aligned observations. A synchronized P+S dataset is needed for a design history.")
        table(["Tunnel","Conditional peak ||G||F [T/m]","Blockage","Magnet V%"],[
            (tunnel_name(h,o),fmt(a[G],4),fmt(100*a.target_maximum_blockage),fmt(100*a.magnet_volume_fraction))
            for h,o in TUNNELS for a in [maxrow(selected_slice(p,h,o),G)]
        ],[133,167,98,103])
        q=pd.read_csv(OUT/"phase_resolution_check.csv")
        table(["Samples/cycle","Peak ||G||F [T/m]","Largest |G_ij| [T/m]","Controlling branch"],[
            (a.samples_per_cycle,fmt(getattr(a,G),6),fmt(a.G_max_abs_Tpm,6),a.wake) for a in q.itertuples()
        ],[99,125,136,141])
        para("The phase-resolution check repeats the controlling included geometry with its selected hardware. "
             "The displayed stability applies to the fundamental histories. It does not cover the unresolved harmonics.")

    chapter("03F  /  SOURCE WORKING", "Geometry-only and deferred cases")
    cad("cylinder_crossflow_T060*b08*single_body_x.png",162)
    table(["Case","Geometric evidence","Aerodynamic disposition"],[
        ("Crossflow cylinder","3% and 8% at AR 10, full span and lateral travel shown in the input data.",
         "Matched Re = 4,000. Wakes 2S, 2P and 2Po in the envelope. 10%/20% require new end-condition or AR data."),
        ("Inline cylinder","Same cylinder primitives can be reused with streamwise motion. Shortening changes spanwise end flow.",
         "Exclude the legacy Fig. 8/9 coefficients. Nishihara is a forced-motion source to obtain. Cagney and Balabani infer drag from freely vibrating motion."),
        ("SC(2)-0714","NASA TP-2890 Table I measured profile ordinates, linearly connected in the MATLAB geometry preview.",
         "NASA TM-81912 Fig. 11 lowest curve is Re 2 million, Mach .15, fixed transition and section geometry. No suitable matched finite-wing wrench."),
    ],[98,181,222])
    cad("sc20714_geometry_only_single_body_x.png",163)
    para("The SC(2)-0714 preview keeps an AR = 3 example at 10% maximum blockage over its CAD attitudes. "
         "Its conservative fit box comes from the tabulated profile, independently of the aerodynamic exclusion. "
         +ref("NASA TP-2890, Table I","https://ntrs.nasa.gov/citations/19890008197")+" · "+
         ref("NASA TM-81912, Fig. 11","https://ntrs.nasa.gov/citations/19830013896"),"Small")
    para("Use Nishihara et al. with its force amplitudes, phases, Re, span, end conditions and drag mean if those can be verified. "
         "The open Cagney and Balabani experiment covers Re 1,150–5,400 and can support a separate free-vibration case once its "
         "inferred forcing and geometry are digitised. "+ref("Nishihara et al. (2005)","https://doi.org/10.1016/j.jfluidstructs.2005.02.003")+
         " · "+ref("Cagney and Balabani (2016)","https://discovery.ucl.ac.uk/id/eprint/1477168/"),"Small")

    chapter("03G  /  SOURCE WORKING","Worked loads from the selected rows")
    para("Each line is one simultaneous solver row from the 0.6 m horizontal tunnel. The state strings key the CSVs. "
         "Rounding shown here is for interpretation. These examples use the same q, geometry and load references as the source working.")
    def vector(row,names):
        return "["+", ".join(fmt(row[n],4) for n in names)+"]"
    sample=[]
    for family in FAMILIES:
        subset=df[(df.family==family)&(df.tunnel_side_m==.6)&(df.orientation=="h")&
                  (df.magnet_volume_fraction==.1)]
        sample.append(maxrow(subset,G))
    table(["Case and source state","U [m/s] / Re","F_aero,T [N]","M_aero,C,T [N m]","F_mag,T [N]"],[
        (case_label(r)+" / "+operation(r),f"{fmt(r.speed_mps)} / {r.Re:,.0f}",
         vector(r,[f"F{k}_aero_N" for k in "xyz"]),vector(r,[f"M{k}_aero_Nm" for k in "xyz"]),
         vector(r,[f"F{k}_mag_req_N" for k in "xyz"])) for r in sample
    ],[144,80,93,92,92])
    r=sample[0]
    q=.5*r.rho_kgm3*r.speed_mps**2
    area=math.pi*r.Re_length_m**2/4
    para(f"<b>Example sphere.</b> D = {fmt(r.Re_length_m,5)} m and C<sub>D</sub> = {fmt(r.CD)} give "
         f"q = {fmt(q,5)} Pa and A = {fmt(area,5)} m². Multiplying gives "
         f"F<sub>x,aero</sub> = {fmt(q*area*r.CD,5)} N. Gravity gives "
         f"F<sub>z,gravity</sub> = {fmt(r.Fz_gravity_N,5)} N. "
         "The steady magnetic force reverses the sum of those forces.")
    para("For the three moment-producing shapes the table shows the moment after transfer to C. For the cylinder, the magnetic "
         "load also includes m a. This is why the cylinder's aerodynamic load can be small at the phase with the largest gradient.")


def report_design(df,selected,sens):
    chapter("04  /  HARDWARE", "Magnet envelope, rotation and mass")
    para("For square tunnel side H, installed magnet extent is capped at 0.30 H on each body axis and on each tunnel "
         "axis at every evaluated attitude. That is 0.18 m for the 0.6 m tunnel and 0.30 m for the 1 m tunnel. "
         "For an assembly, take the maximum and minimum projected coordinates over all corners of all magnets. "
         "This is an installed axis-wise extent check. The space diagonal of an individual cuboid is a separate dimension.")
    para("Start with 95% of a guaranteed-fit internal prism. A single axis-aligned block fills the available capped dimensions. "
         "Candidate directions include the three body axes, 30 deg in each of the xy and xz planes, and alignment with the tunnel "
         "x axis at the last selected attitude when distinct. The magnet is always magnetised along its own +x axis. "
         "Axis permutations refit the same physical prism. Oblique blocks are rotated and reduced until their corners fit, "
         "so both moment magnitude and direction can change. These are a discrete library of candidate builds.")
    para("For each of five auxiliary layouts, cap the whole arrangement by scaling centres and dimensions together if needed. "
         "Then compare a 100% version and a 10% version of that same capped magnet volume. Each linear magnet dimension is "
         "multiplied by 0.1^(1/3) = 0.464159. The auxiliary centre locations retain their capped lever arms in the small version. "
         "Different selected layouts at the two volumes can have different absolute volume ratios. The layout CSV records both.")
    cad("naca0012_T100*single_body_xz30.png",150)
    cad("naca0012_T100*single_tunnel_x_at_last_pose.png",150)
    para("The left MATLAB view shows an opaque exterior. The right shows the same pose as an outline with solid magnet blocks "
         "and arrows. A saved geometry can be redrawn for any candidate and attitude with plot_revision_cad. "
         "The fore-to-aft wing profile is the same one used to certify the internal fit and compute inertia.", "Small")

    chapter("05  /  HARDWARE", "Auxiliary dipoles and six-axis control")
    para("Sawada, Suda and Kunimasu Fig. 4 shows a NAL rolling-moment model with a magnet pair. Their side-coil "
         "excitation demonstrates the roll-control principle. The five sizing layouts below explore different lever "
         "directions in our body envelope. They are geometric candidates for the affine solver. "
         +ref("Sawada et al. (2004), Figs. 4–6","https://www.icas.org/icas_archive/ICAS2004/PAPERS/182.PDF"))
    chart(pair_diagram(),"opposed_auxiliary_dipoles")
    para("For equal opposite moments +m and −m placed at +r and −r, F<sub>pair</sub> = Gm + G(−m) = 0. "
         "Uniform field torques sum to (m − m) × B = 0. In a gradient, local-field torque "
         "m × (G r) and the lever torque r × (G m) each have the same sign at the two magnets. "
         "Thus tau<sub>pair</sub> = 2[m × (G r) + r × (G m)]. The main magnet still supplies net force and uniform-field torque.")
    para("The diagram uses r along +y and m along +x. Its diagonal-gradient example gives tau<sub>z</sub> "
         "= 2mr(G<sub>yy</sub> − G<sub>xx</sub>). The two gradient terms can oppose within each contribution. "
         "Changing the pair orientation changes which components couple, and the map rank is checked for each candidate.")
    table(["Layout","Offset axis","Auxiliary magnetisation","Placement purpose"],[
        ("1","±y_B","±z_B","Use the available lateral spacing with a transverse dipole."),
        ("2","±y_B","±y_B","Compare dipoles parallel to lateral offsets."),
        ("3","±z_B","±y_B","Use thickness for the offset and put dipoles across it."),
        ("4","±z_B","±z_B","Compare dipoles parallel to vertical offsets."),
        ("5","±y_B and ±z_B","±z_B and ±y_B","Use two independent opposed pairs and compare rank and cost."),
    ],[49,101,137,214])
    cad("cuboid_T060*b10*layout5_main_axis1.png",156)
    para("For each layout, the three main magnet orientations are tested. Six independent wrench directions are required "
         "for cuboid and Ahmed. Some layouts and main axes fail this rank check. For the force-only and symmetry-plane cases, "
         "a rank-five single magnet can balance the specified load. That leaves one independently commanded torque direction unavailable.", "Small")

    chapter("06A  /  MASS PROPERTIES", "Solid ABS, cavities and centre of mass")
    para("The previous mass model assigned a fraction of the large magnet mass to the rest of the body. The revised model "
         "starts with the full solid shape at an assumed ABS density of 1,050 kg/m³. It subtracts each magnet's volume "
         "at the ABS density, then adds the magnet at its grade-table density (7,500 kg/m³ for N52). The N52 dipole "
         "uses minimum remanence 1.43 T, m = B<sub>r</sub>V/mu<sub>0</sub>. The material and remanence are sizing inputs.")
    para("For the solid, use analytic primitive inertia or integrate the profile polygon extruded along the span. "
         "For every oriented cuboid, rotate its centroid inertia into B and shift it to a common point. "
         "In the signed volume sum, the outer ABS and magnets enter positive and the cavities negative. "
         "C = sum(m<sub>i</sub> r<sub>i</sub>) / sum(m<sub>i</sub>). "
         "At C, add each I<sub>i</sub> plus m<sub>i</sub>[(r·r)I − rr<super>T</super>], with r measured from C. "
         "The geometry and rotated boxes are shared with the CAD renderer. A separating-axis test rejects overlapping cavity volume.")
    m=maxrow(df,M)
    para(f"The heaviest selected article is {tunnel_name(m.tunnel_side_m,m.orientation)}, {case_label(m)}, "
         f"with {fmt(m.non_magnet_mass_kg,4)} kg of solid ABS outside the cavities and "
         f"{fmt(m.total_mass_kg-m.non_magnet_mass_kg,4)} kg of magnets. "
         f"With the same hardware the magnets alone would still weigh {fmt(m.total_mass_kg-m.non_magnet_mass_kg,4)} kg. "
         "A thin ABS shell requires a specified thickness, closure, ribs and magnet mounts. The current implementation "
         "gives a consistent solid-body upper mass for the same materials. It excludes structural hardware and discrete ballast.")
    table(["Build stage","Implementation effort and verification"],[
        ("Solid body and cavities","Implemented with analytic shapes and polygon extrusions. Uses the same primitives as the MATLAB plots and exports mass, C and the full inertia tensor."),
        ("Uniform hollow shell","A bounded next step for spheres, tubes and cuboids. Subtract a second analytic solid or an inward-offset prism. Keep magnet mounts inside the shell cavity and avoid double-counting volumes."),
        ("Buildable assembly","The harder part is the physical design. A printable wing or slanted body needs a closed wall, keyed holders, ribs and fasteners. Define them in CAD, then integrate solids or import the assembled mass properties. Validate against a scale and a balance test."),
    ],[113,388])
    para("Gravity enters F<sub>req</sub> = m a − F<sub>aero</sub> − m g<sub>T</sub>. "
         "For steady cases, mass changes gravity and the wrench reference C. In the transverse history it also multiplies the "
         "prescribed acceleration. Inertia about C matters when angular acceleration or angular velocity is prescribed.")

    chapter("06B  /  MERIT INDEX", "Selecting the limiting hardware")
    para("The solver first finds a minimum-cost field and gradient for each eligible scenario and installed set. "
         "A candidate is eligible at relative scaled wrench residual ≤ 10<super>−6</super>, with rank 6 additionally required "
         "for cuboid and Ahmed. Let J(s,j;L) be that row's RMS field cost. For a centred cube of side L, "
         "<b>J² = ||B<sub>C</sub>||² + (L²/12)||G||<sub>F</sub>²</b>. "
         "This follows by averaging the square of the affine field over the cube. Default L is the maximum outer body dimension. "
         "A longer L weights gradients more heavily. J is a field-equivalent sizing index in tesla.")
    table(["Use","Operation","What it answers"],[
        ("Swappable static","max_s min_j J(s,j)","Choose hardware independently for each steady point, then size to the hardest of those best choices."),
        ("One fixed build","min_j max_s J(s,j)","Choose the single set that covers every required state at the lowest worst cost."),
        ("Independent histories","max_g min_j max_phase J(g,phase,j)","Choose hardware between separate histories only. Every phase within one run uses the same magnet set."),
        ("Easiest trial","min_s min_j J(s,j)","Identify an initial feasible steady test. It is outside the limiting hardware criterion."),
    ],[111,126,264])
    para("The main targets use swappable static selection for sphere, cuboid, Ahmed and NACA. They use fixed hardware across "
         "all transverse-cylinder histories and phases. A static campaign with a sealed model should use the fixed results. "
         "Choosing the worst orientation among all candidates would size for a deliberately adverse build. It is useful as a "
         "sensitivity screen if the magnet orientation is uncontrolled, while the minimum over build choices answers the design question.")
    primary=sens[sens.metric=="L_model"].copy()
    primary["penalty_pct"]=100*(primary.fixed_worst_J_T/primary.independent_worst_J_T-1)
    table(["Illustrative fixed-hardware cost penalty","Swappable or per-history J [T]","Fixed J [T]","Increase"],[
        (r.case_id,fmt(r.independent_worst_J_T,4),fmt(r.fixed_worst_J_T,4),f"{r.penalty_pct:.1f}%")
        for r in primary.nlargest(5,"penalty_pct").itertuples()
    ],[222,117,83,79])
    table(["Selection policy","Peak local B [T]","Peak ||G||F [T/m]"],[
        ("Preferred by family",fmt(df[B].max(),4),fmt(df[G].max(),4)),
        ("All fixed",fmt(selected[selected.selection_mode=="fixed_hardware"][B].max(),4),
         fmt(selected[selected.selection_mode=="fixed_hardware"][G].max(),4)),
        ("Static swaps and swaps between histories",fmt(selected[selected.selection_mode=="independent_group"][B].max(),4),
         fmt(selected[selected.selection_mode=="independent_group"][G].max(),4)),
    ],[241,130,130])

    chapter("06C  /  MERIT INDEX", "Reference-length sensitivity")
    base=primary.set_index("case_id")
    rows=[]
    for key,label in [("L_half","0.5 × L_model"),("L_double","2 × L_model"),("L_30pct_tunnel","0.30 × H")]:
        s=sens[sens.metric==key].set_index("case_id").reindex(base.index)
        count_fixed=(s.fixed_winner!=base.fixed_winner)
        count_static=(s.independent_winners!=base.independent_winners)
        rows.append((label,len(s),int(count_fixed.sum()),int(count_static.sum()),
                     ", ".join(sorted(set(s.index[count_fixed].str.split("_T").str[0]))) or "—"))
    table(["Reference cube","Cases","Fixed winner changes","Group choice changes","Families with fixed changes"],rows,
          [101,43,99,105,153])
    para("For each length, the affine constrained minimisation is solved again with the same wrench and feasibility criteria. "
         "The sensitivity is therefore a comparison of re-optimised fields, gradients and magnet rankings. The CSVs contain "
         "the full fixed candidate ranking and the per-group winners. Exact or numerical ties keep candidate order for the "
         "selected set. A change of winner can reflect a small cost separation.")
    pivot=sens.pivot(index="case_id",columns="metric",values="fixed_winner")
    altered=pivot[pivot.nunique(axis=1)>1]
    sample=altered.head(8)
    if not sample.empty:
        table(["Example case","0.5 L","L model","2 L","0.30 H"],[
            (idx,r.L_half,r.L_model,r.L_double,r.L_30pct_tunnel) for idx,r in sample.iterrows()
        ],[229,68,68,68,68])
    para("Use the model-scale RMS comparison for this sizing pass. A later coil calculation can replace the scalar tradeoff "
         "with a physical map, saturation limits and current or thermal cost. The affine field model and its solver are the "
         "same in every revision run.")


def report_distributions(df,peaks):
    names={G:"gradient",B:"field",M:"mass"}
    articles=df.drop_duplicates(["case_id","magnet_set_id"])
    for i,(key,label,width) in enumerate(METRICS):
        chapter(f"07{chr(65+i)}  /  DISTRIBUTION",label)
        sample=articles if key==M else peaks
        d,edges,counts=histograms(sample,key,label,width)
        chart(d,names[key]+"_histograms_by_tunnel")
        unit="selected article and set within each tunnel" if key==M else "static operating point or peak over one complete dynamic history"
        para(f"Each observation is one {unit}. Counts are grouped by family. "
             f"The bin width is {width:g} in the plotted units. Horizontal and upward installations have the same bins. "
             "The four panels have separate count scales.", "Small")
        table(["Tunnel","n","Median","P90","P95","Maximum","Controlling configuration"],[
            (tunnel_name(h,o),len(v),fmt(v.median(),4),fmt(v.quantile(.90),4),fmt(v.quantile(.95),4),
             fmt(v.max(),4),case_label(r)+" / "+operation(r))
            for h,o in TUNNELS for v in [selected_slice(sample,h,o)[key]]
            for r in [maxrow(selected_slice(df,h,o),key)]
        ],[101,28,51,51,51,59,160])
        rows=[]
        for (h,o),c in counts.items():
            for family,counts_f in zip(FAMILIES,c):
                for j,n in enumerate(counts_f):
                    rows.append([h,o,family,edges[j],edges[j+1],n])
        pd.DataFrame(rows,columns=["tunnel_side_m","orientation","family","bin_left","bin_right","count"]).to_csv(
            OUT/f"{names[key]}_histogram_counts.csv",index=False)
        if key==G:
            r=maxrow(df,G)
            para(f"The upper tail comes from the small-magnet cylinder. At the controlling phase, "
                 f"a<sub>z</sub> = {fmt(r.a_Cz_T_mps2,4)} m/s², "
                 f"m a<sub>z</sub> = {fmt(r.Fz_inertial_demand_N,4)} N, "
                 f"F<sub>z,aero</sub> = {fmt(r.Fz_aero_N,4)} N, and "
                 f"F<sub>z,gravity</sub> = {fmt(r.Fz_gravity_N,4)} N. "
                 "Its gradient primarily accelerates and supports the article. The oscillation is severe at low airspeed because "
                 "the physical frequency scales as U/D. These numbers describe the tested design grid, with no probability weighting.")
        elif key==B:
            para("The sphere and centred translating-cylinder magnets often have essentially zero local field for these "
                 "specified loads because the required wrench is a force with zero torque. Their gradients remain nonzero. "
                 "At a fixed tunnel origin, B<sub>O</sub> can be nonzero during translation even when B<sub>C</sub> = 0. "
                 "The Ahmed field tail reflects torque and the spatial separation of the opposed magnets.")
        else:
            para("The mass distribution counts distinct selected sets within each geometry, volume and installation. The "
                 "0.6 m and 1 m mass tails differ because the outer volume grows cubically at fixed geometry ratios while "
                 "the cap and fit determine how much can be replaced by dense NdFeB. Large solid test bodies should be treated "
                 "as distinct heavy builds, even where the gradient ranking is favourable.")
    chapter("07D  /  DISTRIBUTION", "Mass, blockage and the gradient tail")
    chart(scatter(peaks),"mass_vs_gradient_by_tunnel")
    para("Filled markers denote 100% capped magnet volume. Open markers denote 10%. "
         "Each point is a static operating point or complete history peak. Coincident results can overplot.")
    table(["Blockage","Operating groups","Median ||G||F [T/m]","Peak ||G||F [T/m]","Peak local B [T]","Peak mass [kg]"],[
        (f"{100*b:g}%",len(p),fmt(p[G].median()),fmt(p[G].max()),fmt(p[B].max()),fmt(p[M].max(),4))
        for b,p in peaks.groupby("target_maximum_blockage",sort=True)
    ],[67,75,110,105,76,68])
    para("The 8% bin is the AR-preserving cylinder substitute. Higher blockage changes geometry, mass and speed "
         "together under Re matching. At fixed Re the characteristic aerodynamic load can stay similar as U falls and "
         "area rises, while weight increases. The plot shows where a heavy model is a separate issue from high magnetic gradient.")


def report_appendices(df):
    chapter("08  /  NEXT DECISIONS", "Limits and experimental priorities")
    table(["Priority","Proposed next decision"],[
        ("Reynolds and end effects","Keep the source-matched points as the design evidence. For missing high speeds, add measured coefficients with overlapping Re or an explicit short interpolation supported on both sides. Do not transfer the Re 4,000 cylinder to 50 m/s."),
        ("20% and short-span cases","Retain 20% as a geometric stress case with no wall correction. Use AR = 1 finite-wing data for NACA. Keep the cylinder at 3%/8% until end-plated or freely suspended AR ≤ 5 force and phase data are available."),
        ("Cylinder wake coverage","Acquire a displacement-synchronised force history or raw harmonic data for P+S and multi-mode transitions. Verify the fixed-endplate geometry or measure the free-ended response. Add measured drag harmonics where they matter."),
        ("Inline and SC(2)-0714","Obtain the Nishihara source and extract a verified load history. Use a lower-Re, finite-span SC section study with comparable AR and a moment reference, or leave it outside the design basis."),
        ("Ahmed ground plane","Match the source floor gap and boundary layer before using yaw loads as validation targets. Use a synchronised six-channel time history for bistability if needed."),
        ("Heavy test articles","Decide an allowed mass and how magnets will be mounted. Start with 3% or a CAD-defined hollow assembly for the heavy sphere and Ahmed geometries. Recompute the CoM and inertia after selecting ribs, holders and joints."),
        ("Magnet and coils","Verify actual magnets, fit and remanence from vendor data. Carry the reported component maxima and their simultaneous wrench rows into later coil mapping."),
    ],[112,389])
    para("Each case input is saved as a MATLAB MAT file. The tabular outputs include the complete phase/wrench rows, all tested "
         "hardware, both selection modes, and the sensitivity rankings. Printed numbers are rounded to sizing precision.")
    chapter("APPENDIX A  /  COMPONENT TARGETS","Envelope across all installations")
    keys={B:"Max local ||B|| [T]",G:"||G||F [T/m]","G_max_abs_Tpm":"Largest |G_ij| [T/m]",**COMPONENTS}
    table(["Component or norm","Signed value","Tunnel / controlling case","U [m/s]","Re","Set"],[
        (label,fmt(r[key],4),tunnel_name(r.tunnel_side_m,r.orientation)+" / "+case_label(r)+" / "+operation(r),
         fmt(r.speed_mps),f"{r.Re:,.0f}",short_set(r.magnet_set_name))
        for key,label in keys.items() for r in [maxrow(df,key)]
    ],[108,57,207,40,54,35])
    para("L1–L5 refer to the auxiliary layouts in Section 5. The letter after the slash is the main magnet's body-axis direction. "
         "The short set labels are expanded in the complete CSV output.")
    for h,o in TUNNELS:
        panel=selected_slice(df,h,o)
        chapter("APPENDIX A  /  COMPONENT TARGETS",tunnel_name(h,o))
        keys={B:"Max local ||B|| [T]",G:"||G||F [T/m]",**COMPONENTS}
        table(["Component or norm","Signed value","Control case / state","U [m/s]","Re","Set"],[
            (label,fmt(r[key],4),case_label(r)+" / "+operation(r),fmt(r.speed_mps),f"{r.Re:,.0f}",short_set(r.magnet_set_name))
            for key,label in keys.items() for r in [maxrow(panel,key)]
        ],[99,59,163,42,51,87])
        para("The component target is the magnitude of the signed entry shown. The field norms and Frobenius norm are "
             "positive by definition. Symmetry supplies G<sub>yx</sub>, G<sub>zx</sub> and G<sub>zy</sub> from the paired entries. "
             "At very small field or gradient values, displayed signs may reflect numerical roundoff.")
        chapter("APPENDIX B  /  CASE LIMITS",tunnel_name(h,o))
        rows=[]
        for _,s in panel.groupby("case_id",sort=False):
            g,b=maxrow(s,G),maxrow(s,B)
            rows.append((
                FAMILIES[g.family][0]+f" / {100*g.target_maximum_blockage:g}%",
                f"{100*g.magnet_volume_fraction:g}",MODES[g.selection_mode],
                fmt(g[G],4),f"{fmt(g.speed_mps)} / {g.Re:,.0f}",short_set(g.magnet_set_name),
                fmt(b[B],4),f"{fmt(b.speed_mps)} / {b.Re:,.0f}",short_set(b.magnet_set_name),
            ))
        para("U is in m/s. The G and B columns can be controlled by different states. The CSVs include the full group name, "
             "phase and signed component rows. Swap selects a set per steady operating point. Fixed selects one set per dynamic study.","Small")
        table(["Family / blockage","Magnet V%","Mode","||G||F [T/m]","G U / Re","G set","Local ||B|| [T]","B U / Re","B set"],
              rows,[92,44,47,49,69,40,51,69,40])


if __name__ == "__main__":
    main()
