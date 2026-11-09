"""Build the standalone MSBS report, operating percentiles and audit tables."""
import math

import numpy as np
import pandas as pd
from reportlab.graphics.shapes import Circle, Drawing, Line, Polygon, Rect, String
from reportlab.lib import colors
from reportlab.platypus import BaseDocTemplate, Frame, PageTemplate
from reportlab.platypus.tableofcontents import TableOfContents

import build_revision_report as b
from build_revision_report import (
    B, G, INK, M, W, ACCENT, COMPONENTS, GRID, GREY, J, TUNNELS,
    cad, case_label, chart, fmt, maxrow, operation, para, ref, short_set, table, tunnel_name,
)

OUT = b.RESEARCH / "outputs" / "standalone"
PDF = b.RESEARCH / "MSBS_Aerodynamic_Requirements_Standalone.pdf"
KEYS = {
    B: "Local max ||B|| [T]", "B_norm_T": "||B_C|| [T]", "B_O_norm_T": "||B_O|| [T]",
    G: "||G||F [T/m]", "G_max_abs_Tpm": "Max |G_ij| [T/m]", **COMPONENTS,
}
AIR = "cylinder_crossflow"


class Report(BaseDocTemplate):
    def afterFlowable(self, flowable):
        if hasattr(flowable, "toc_entry"):
            number, title = flowable.toc_entry
            key = "section-" + number
            self.canv.bookmarkPage(key)
            self.canv.addOutlineEntry(title, key)
            self.notify("TOCEntry", (0, title, self.page, key))


def footer(canvas, doc):
    canvas.setStrokeColor(GRID)
    canvas.line(47, 39, 548, 39)
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(GREY)
    canvas.drawString(47, 25, "Imperial MSBS  /  aerodynamic requirements  /  LW-PLA portfolio")
    canvas.drawRightString(548, 25, str(doc.page))


def section(number, title):
    b.chapter(number, title)
    b.STORY[-1].toc_entry = number, title


def controls(row):
    if abs(row.value) < 1e-12:
        return "Zero"
    return case_label(row) + " / " + operation(row)


def target_rows(df):
    """Choose observed component-wise max/P90 from equal-weight groups."""
    rows = []
    for fraction, sub in df.groupby("magnet_volume_fraction", sort=False):
        for label, sample in [("All installations", sub)]+[
            (tunnel_name(h,o),b.selected_slice(sub,h,o)) for h,o in TUNNELS
        ]:
            for field in KEYS:
                peaks=sample.loc[sample[field].abs().groupby(
                    [sample.case_id,sample.operating_group],sort=False).idxmax()]
                order=peaks.assign(magnitude=peaks[field].abs()).sort_values("magnitude",kind="stable")
                n=len(order)
                for stat,idx in [("P90",math.ceil(.9*n)-1),("Maximum",n-1)]:
                    r=order.iloc[idx]
                    entry=r[["case_id","family","operating_group","scenario_name","magnet_set_name",
                             "speed_mps","Re","source_phase_rad","target_maximum_blockage","magnet_volume_fraction"]].to_dict()
                    rows.append(dict(**entry,panel=label,metric=field,statistic=stat,n=n,value=r[field],magnitude=abs(r[field])))
    return pd.DataFrame(rows)


def overview(steady,driven):
    para("IMPERIAL COLLEGE LONDON  /  MAGNETIC SUSPENSION AND BALANCE SYSTEM","Eyebrow")
    para("Aerodynamic cases and<br/>magnetic requirements","Title2")
    para("This study estimates the magnetic field and spatial field gradients needed to suspend wind-tunnel models "
         "without a mechanical sting. It compares two square test sections, horizontal and upward flow, three blockage "
         "targets, and two installed magnet volumes. The outputs are local field requirements for later coil design.")
    a,g=[maxrow(steady,k) for k in (B,G)]
    para(f"<b>Steady operating envelope.</b> The strongest local field is <b>{fmt(a[B])} T</b> and the "
         f"largest gradient Frobenius norm is <b>{fmt(g[G])} T/m</b> over the fixed-hardware, source-matched "
         "5–50 m/s cases. The 25 kg study is a separate analysis at unchanged outer geometry.")
    table(["Peak","Value","Controlling case","U [m/s]","Re"],[
        (label,fmt(r[key],4),tunnel_name(r.tunnel_side_m,r.orientation)+" / "+case_label(r)+" / "+operation(r),
         fmt(r.speed_mps),f"{r.Re:,.0f}") for key,label,r in [(B,"Local field [T]",a),(G,"Gradient [T/m]",g)]
    ],[93,55,243,53,57])
    if not driven.empty:
        p=maxrow(driven,G)
        para(f"<b>Air-driven cylinder supplement.</b> The motion-correlated transverse histories reach "
             f"<b>{fmt(p[G])} T/m</b>. These histories include model inertia and phase-resolved lift. "
             "Their aerodynamic load coverage is partial, so they have their own results table.")
    para("Use the results section for component values and outlier-resistant percentiles. The following sections "
         "explain model coverage, the hardware choices, the limitations of the field merit index, and the effect of "
         "reducing magnet mass. The source working includes coefficient locations and coordinate conversions.")
    b.chapter("CONTENTS","Contents")
    toc=TableOfContents()
    toc.levelStyles=[b.styles["Body"]]
    toc.dotsMinLevel=0
    b.STORY.append(toc)


def conventions():
    section("01","Conventions and the sizing model")
    table(["Term","How it is used"],[
        ("H and blockage","H is the square tunnel side, 0.6 m or 1 m. Blockage is the largest projected model area at the tested attitudes divided by H². Use 3%, 10% and 20% as geometric targets."),
        ("Tunnel and body axes","The tunnel frame T uses +x downstream. Its +z is upward in the horizontal installation. B denotes body axes. In the upward-flow installation Earth gravity points along −x in T."),
        ("C and O","C is the model centre of mass. O is the fixed tunnel origin. The magnetic field is referenced to one of these two points."),
        ("B_C and B_O","Magnetic field vectors at C and O. For a displacement r_C from O to C, B_O = B_C − G r_C."),
        ("Local max ||B||","Largest Euclidean field magnitude at any installed magnet centre in one state."),
        ("Gradient G","G_ij gives the change of field component i with position j. It is symmetric and trace-free in this local, source-free model. ||G||F combines all nine entries in quadrature."),
        ("V100 and V10","V100 is the large capped fit for each candidate layout. V10 has 10% of that candidate's volume. The assembly, including spacing, stays within 30% of H on each evaluated axis."),
        ("State and campaign","A state is one steady speed and attitude, or one instant of a driven history. A campaign groups all states for one article, tunnel orientation, blockage and magnet-volume policy."),
    ],[102,399])
    para("Use air density 1.225 kg/m³ and dynamic viscosity 1.81 × 10<super>−5</super> Pa·s. "
         "For characteristic length D or l, Re = U × length / nu. Resize the article to its blockage and solve for U at "
         "the source Reynolds number. The 5–50 m/s planning window filters the states. The aerodynamic "
         "coefficients are converted with dynamic pressure q = ½ rho U² and the source reference area and length.")
    para("Each magnetic solution balances aerodynamic load and gravity while delivering the prescribed acceleration. "
         "A magnetic dipole m sees force G m and a local torque m × B. An off-centre magnet adds a lever torque. "
         "The solver checks the resulting wrench, meaning the combined force and moment, about C.")


def useful_results(steady,driven,targets):
    section("02","Useful results")
    para("These targets use one installed arrangement throughout each campaign. Each metric has its own controlling state. "
         "For the 90th percentile (P90), sort the absolute values of the selected state results and take the observed "
         "value at rank ceil(0.90 × n). For a time history, take its per-metric peak once before sorting. The "
         "steady tables weight each tested state equally. P90 describes the test grid. It is independent of any assumed operating probability.")
    table(["Tunnel","Volume","States","Local ||B|| max / P90 [T]","||G||F max / P90 [T/m]"],[
        (panel,f"V{100*v:g}",t.n.iloc[0],
         f"{fmt(x.loc[(B,'Maximum')])} / {fmt(x.loc[(B,'P90')])}",
         f"{fmt(x.loc[(G,'Maximum')])} / {fmt(x.loc[(G,'P90')])}")
        for (panel,v),t in targets.groupby(["panel","magnet_volume_fraction"],sort=False)
        for x in [t.set_index(["metric","statistic"]).magnitude]
    ],[123,54,54,133,137])
    para("The magnitude table is suitable for comparing channel sizing. The CSV also retains the sign and simultaneous "
         "wrench for each observed state. Component percentiles are selected separately and can come from different tests.")
    for (panel,v),t in targets.groupby(["panel","magnet_volume_fraction"],sort=False):
        if panel=="All installations":
            continue
        b.chapter("02  /  USEFUL RESULTS",f"{panel} · V{100*v:g}")
        peak=t[t.statistic=="Maximum"].set_index("metric")
        pct=t[t.statistic=="P90"].set_index("metric")
        table(["Metric","Maximum |value|","Max case / state","U [m/s] / Re","P90 |value|","P90 case / state"],[
            (label,fmt(peak.loc[k,"magnitude"],4),controls(peak.loc[k]),
             f"{fmt(peak.loc[k,'speed_mps'])} / {peak.loc[k,'Re']:,.0f}",
             fmt(pct.loc[k,"magnitude"],4),controls(pct.loc[k]))
            for k,label in KEYS.items()
        ],[84,62,123,61,59,112])
        para(f"Sample size n = {t.n.iloc[0]}. Zero-value ties use an arbitrary representative state. "
             "See useful_results_max_p90.csv for signed values, the P90 speed and Reynolds number, and the installed layout.", "Small")
    b.chapter("02  /  AIR-DRIVEN SUPPLEMENT","Motion-correlated transverse cylinder")
    if driven.empty:
        para("No source-matched histories met the operating and acceleration limits.")
        return
    rows=[]
    for _,s in driven.groupby("case_id",sort=False):
        r=maxrow(s,G)
        rows.append((tunnel_name(r.tunnel_side_m,r.orientation),f"{100*r.target_maximum_blockage:g}%",
                     f"V{100*r.magnet_volume_fraction:g}",fmt(r.speed_mps),r.operating_group,
                     fmt(r.acceleration_peak_mps2),fmt(r[G],4),fmt(s[B].max(),4)))
    table(["Installation","Blockage","Volume","U [m/s]","Peak G history","Peak a [m/s²]","||G||F [T/m]","Local B [T]"],
          rows,[96,52,47,48,89,64,57,48])
    para("These rows cover Blackburn and Melbourne's phase-locked lift component, body inertia and gravity. Mean drag, "
         "unsteady drag and residual lift were left outside the reconstructed wrench. This table sizes the specified "
         "transverse demand only. The separate CSV provides the same max/P90 extraction for the available driven histories. "
         "With small sample sizes the observed P90 can equal the maximum.")


def coverage(df,manifest):
    section("03","Which cases fit the tunnels")
    rows=[]
    for name,sub in df.groupby("family",sort=False):
        r=[]
        for h in (.6,1):
            s=sub[sub.tunnel_side_m==h]
            r.append(f"{s.case_id.nunique()} / {len(b.peak_records(s))}")
        rows.append((b.FAMILIES[name][0],*r, f"{fmt(sub.speed_mps.min())}–{fmt(sub.speed_mps.max())}"))
    table(["Family","0.6 m campaigns / groups","1 m campaigns / groups","Matched U [m/s]"],rows,[122,130,130,119])
    para(f"The two installations and two volume policies are counted separately. There are <b>{df.case_id.nunique()} campaigns</b> "
         f"with data and <b>{len(b.peak_records(df))} operating groups</b>. Each steady state is one group. Each driven history "
         f"counts as one group, however many phase samples it contains. The requested grid has {len(manifest)} campaign slots, "
         f"with {int((manifest.status!='ran').sum())} exclusions for speed, acceleration or source coverage.")
    para("The 1 m tunnel has more campaigns because the larger bodies can reach the same source Re at a lower speed. "
         "For Ahmed, 10% blockage requires about 65.1 m/s in the 0.6 m tunnel and 39.0 m/s in the 1 m tunnel. "
         "The smaller tunnel retains 20% at 46.0 m/s. The 1 m tunnel retains 10% and 20%. For driven crossflow, "
         "the larger diameter also reduces acceleration at matched Re and drive ratios. The 0.6 m tunnel retains "
         "20% blockage and the 1 m tunnel retains 10% and 20% at the provisional 50 m/s² acceleration screen.")
    chart(b.coverage_chart(df),"source_matched_airspeeds")
    para("Water-channel Re = 4,000, the SC(2)-0714 section and phase-unresolved inline data are outside the solved portfolio. "
         "The source working explains which evidence each uploaded paper provides. The coverage CSV records rejected geometry "
         "and speed combinations.", "Small")


def hardware(candidates,selected,sensitivity):
    section("04","Magnets, layouts and test hardware")
    para("The active targets assume one installed magnet arrangement per campaign. A sphere or parked cylinder may keep "
         "the same hardware while speed changes. Cuboid, Ahmed and wing attitude sweeps keep their magnets fixed in body axes. "
         "A driven cylinder keeps the same magnet through every phase and every programmed history in its campaign. "
         "A swappable comparison applies to genuinely separate trials with removable hardware and a fresh installation between trials.")
    para("The five auxiliary layouts add smaller opposed magnets at body-axis offsets. The torque pair can produce "
         "positive, negative or zero roll as its driving gradient changes. A single magnet can supply forces and transverse "
         "torques but has no uniform-field torque about its own magnetic axis. Cuboid and Ahmed candidates must span all six wrench directions. "
         "The wing uses the published symmetry-plane force and moment. The cylinder cases do not prescribe an aerodynamic roll moment. "
         "The residual threshold for a solved state is 10<super>−6</super> on the relative scaled wrench error.")
    table(["Layout","Auxiliary positions","Auxiliary directions","Main direction trial"],[
        ("L1","± body y","± body z","Body +x, +y or +z"),
        ("L2","± body y","± body y","Body +x, +y or +z"),
        ("L3","± body z","± body y","Body +x, +y or +z"),
        ("L4","± body z","± body z","Body +x, +y or +z"),
        ("L5","± body y and ± body z","± body z and ± body y","Body +x, +y or +z"),
    ],[60,150,145,146])
    para("The assembly is capped at 0.30H across its full installed width, height and length in body and tested tunnel axes. "
         "Oblique blocks are physically rotated and reduced if needed. Each V10 is one tenth of that layout's capped V100 "
         "volume, with auxiliary centres held at the same offsets. Nominal N52 remanence is represented by the grade-table "
         "minimum of 1.43 T, with 7,500 kg/m³ magnet density.")
    cad("naca0012_T060*single_body_xz30.png",137)
    cad("naca0012_T060*single_tunnel_x_at_last_pose.png",137)
    data=b.export_candidate_peaks(candidates)
    b.report_hardware_variants(data,standalone=True)
    b.report_roll_detail(standalone=True)

    section("05","Selecting the limiting hardware")
    para("There are two different decisions. <b>For a fixed article</b>, choose one arrangement and keep it installed "
         "for every planned state. <b>For separate swappable trials</b>, choose a new arrangement before each independent "
         "trial and still keep it installed for that whole trial. Changing wind speed, pitch or phase cannot change the "
         "physical magnet in a sealed or already installed article.")
    para("To compare feasible solutions consistently, the solver assigns each state and hardware combination a local "
         "RMS-field score J, in tesla. The reference cube has side L, by default the longest model dimension. "
         "J² = ||B<sub>C</sub>||² + L²||G||<sub>F</sub>²/12. The next page explains what this score measures.")
    table(["Question","Steps","Use it when"],[
        ("Which single build should cover my campaign?","For each installed set, find its highest J over all required states. Among the feasible sets, choose the one with the lowest of those peaks.","One physical model must cover a speed sweep, attitude sweep or family of driven histories."),
        ("What if I can exchange magnets between trials?","For each trial, choose the set with the lowest J. Then find the highest of those best trial scores. For a driven trial, compare each set's peak over the whole history before selecting it.","Separate fixtures or removable assemblies permit a swap. The installation plan includes the swap."),
        ("Which test should I try first?","Find the lowest feasible trial score. Check its fit, motion and availability separately.","Commissioning an individual trial."),
    ],[126,226,149])
    example=selected[selected.case_id=="cuboid_T060_b10_h_v100"]
    fixed=example[example.selection_mode=="fixed_hardware"].set_index("operating_group")
    swap=example[example.selection_mode=="independent_group"]
    table(["0.6 m horizontal cuboid, V100","Swap layout","J [T]","Fixed layout","J [T]"],[
        (r.operating_group,short_set(r.magnet_set_name),fmt(getattr(r,J),4),
         short_set(fixed.loc[r.operating_group,"magnet_set_name"]),fmt(fixed.loc[r.operating_group,J],4))
        for r in swap.itertuples()
    ],[167,107,62,103,62])
    para("Read down either J column to get its peak. The left set column can change between rows, so its peak is usable "
         "only if those swaps happen. The fixed set column follows one build, even when an individual row could be easier "
         "with a different magnet. This is why the fixed result is used for the operating targets.")

    b.chapter("05  /  SELECTION COMPARISON","How much does the choice matter?")
    s=sensitivity[sensitivity.metric=="L_model"].copy()
    s["penalty"]=100*(s.fixed_worst_J_T/s.independent_worst_J_T-1).clip(lower=0)
    n=int((s.penalty>1e-7).sum())
    swaps=s.independent_winners.str.split(";").map(lambda entries: len({x.split("=")[-1] for x in entries})>1).sum()
    para(f"The swappable calculation changes physical sets within <b>{swaps} of {len(s)}</b> campaigns. "
         f"The worst score increases under fixed hardware in <b>{n} campaigns</b>. The median increase is "
         f"{s.penalty.median():.2f}%, the 90th percentile is {s.penalty.quantile(.9):.2f}% and the largest is "
         f"{s.penalty.max():.2f}%. A changed arrangement can leave the peak score unchanged when it only helps easier states.")
    sample=s.sort_values("penalty")
    sample=pd.concat([sample.iloc[[len(sample)//2]],s.nlargest(5,"penalty")]).drop_duplicates("case_id")
    table(["Typical case and five highest penalties","Swappable peak J [T]","Fixed peak J [T]","Increase"],[
        (r.case_id,fmt(r.independent_worst_J_T,4),fmt(r.fixed_worst_J_T,4),f"{r.penalty:.2f}%")
        for r in sample.itertuples()
    ],[226,100,100,75])
    para("These percentages describe the chosen score. Local field and gradient maxima are reported directly in the useful results. "
         "The difference in J can help decide whether a swappable fixture is worthwhile. The test plan still determines whether swapping is physically representative.")
    s.to_csv(OUT/"fixed_vs_swappable.csv",index=False)


def arrow(d,x0,y0,x1,y1,color=INK,width=1.8):
    d.add(Line(x0,y0,x1,y1,strokeColor=color,strokeWidth=width))
    angle=math.atan2(y1-y0,x1-x0)
    d.add(Polygon([x1,y1,x1-8*math.cos(angle-.43),y1-8*math.sin(angle-.43),
                  x1-8*math.cos(angle+.43),y1-8*math.sin(angle+.43)],
                  fillColor=color,strokeColor=None))


def coil_graphic():
    d=Drawing(W,225)
    d.add(Rect(10,17,480,195,fillColor=colors.HexColor("#edf3f8"),strokeColor=None))
    d.add(String(25,194,"Opposite-current coaxial pair · local field about the midpoint",fontName="Helvetica-Bold",fontSize=10,fillColor=INK))
    d.add(Line(51,106,440,106,strokeColor=GREY,strokeDashArray=[4,3]))
    d.add(String(449,103,"+x",fontSize=8,fillColor=INK))
    for x,sign in [(119,1),(374,-1)]:
        for y in (52,159):
            d.add(Circle(x,y,9,fillColor=colors.HexColor("#e0a660"),strokeColor=INK))
            label="+" if (y==159)==(sign==1) else "−"
            d.add(String(x,y-3,label,textAnchor="middle",fontName="Helvetica-Bold",fontSize=11,fillColor=INK))
        d.add(Line(x,62,x,149,strokeColor=colors.HexColor("#bd813d"),strokeWidth=2))
    d.add(String(65,32,"Loop centres at ±a, equal turns N",fontSize=8,fillColor=GREY))
    d.add(Circle(245,106,4,fillColor=INK,strokeColor=None))
    arrow(d,245,106,298,137,ACCENT,2.7)
    d.add(String(303,140,"Dipole m, tilted 30°",fontSize=9,fillColor=ACCENT))
    arrow(d,245,106,309,87,colors.HexColor("#26734c"),2.7)
    d.add(String(312,75,"Resulting force Gm",fontSize=9,fillColor=colors.HexColor("#26734c")))
    d.add(String(178,78,"B_C = 0",fontSize=9,fillColor=INK))
    d.add(String(177,62,"G = diag(g, −g/2, −g/2)",fontSize=8,fillColor=INK))
    d.add(String(270,32,"Side view. Signs show opposite current senses.",fontSize=8,fillColor=GREY))
    return d


def merit_and_sensitivity(sensitivity,ranking):
    section("06","What the RMS field score can tell us")
    para("The score J measures the RMS magnitude of the affine field over a centred cube. It puts field and gradient on "
         "the same scale so the solver can compare eligible solutions. The cube size changes how strongly gradient is "
         "weighted. The score contains no coil positions, turns, electrical resistance, current limits or heating.")
    chart(coil_graphic(),"coil_pair_and_oblique_dipole")
    para("An ideal opposite-current loop pair has B<sub>C</sub> = 0 at its centre and produces an axial gradient g. "
         "Symmetry and zero divergence give transverse gradients −g/2. For a dipole tilted 30° in the x–z plane, "
         "the local force is mg[0.866, 0, −0.25]. An additional field can provide a torque, for example a z-directed "
         "field supplies a pitch torque through the dipole's x component. This coil pair alone supplies one gradient mode.")
    para("For thin circular loops of radius R at ±a, the on-axis derivative is "
         "g = 3 mu<sub>0</sub> N I R² a / (R² + a²)<super>5/2</super>. "
         "The two examples below achieve the same g, the same force on the same dipole and the same J for L = 0.30 m.")
    q=.5
    example=[]
    for radius in (.20,.30):
        a=radius/2
        current=q*(radius**2+a**2)**2.5/(3*4*math.pi*1e-7*100*radius**2*a)
        example.append((fmt(radius),fmt(a),100,f"{current:.0f}",.5,fmt(math.sqrt(1.5)*q),fmt(.3/math.sqrt(12)*math.sqrt(1.5)*q)))
    table(["R [m]","a [m]","Turns/loop","I [A]","g [T/m]","||G||F [T/m]","J [T]"],example,[62,62,70,69,72,84,82])
    para("Equal J can require different currents in different coil geometries. Real feasibility depends on whether the "
         "installed coils span the required field and gradient modes at the model location, plus their current and thermal limits. "
         "The example is a local field demonstration.")

    b.chapter("06  /  RANKING SENSITIVITY","Does changing reference length matter?")
    primary=sensitivity[sensitivity.metric=="L_model"].set_index("case_id")
    scores=ranking.set_index(["case_id","metric","magnet_set_id"])
    rows=[]
    flips=[]
    labels={"L_half":"0.5 × model length","L_double":"2 × model length","L_30pct_tunnel":"0.30 × tunnel side"}
    for key,label in labels.items():
        alt=sensitivity[sensitivity.metric==key].set_index("case_id")
        change=alt.index[alt.fixed_winner!=primary.fixed_winner]
        regret=[]
        for cid in change:
            old=primary.loc[cid,"fixed_winner"]
            new=alt.loc[cid,"fixed_winner"]
            q0=scores.loc[(cid,key,old)]
            q1=scores.loc[(cid,key,new)]
            delta=max(0,100*(q0.worst_J_T/q1.worst_J_T-1))
            regret.append(delta)
            flips.append((cid,label,short_set(q0.magnet_set_name),short_set(q1.magnet_set_name),delta))
        rows.append((label,len(alt),len(change),sum(x<=1 for x in regret),f"{max(regret,default=0):.2f}%"))
    table(["Alternative L","Campaigns","Winner changes","Changes within 1%","Largest cost gap"],rows,[132,69,103,109,88])
    para(f"All {len(primary)} campaigns are counted once for each alternative. The count includes both tunnel sizes, "
         "both flow orientations, all feasible geometry and source groups, and both magnet volume policies. "
         "A changed winner is counted even if two layouts give nearly the same score. The gap measures the extra "
         "J from retaining the original selected layout, evaluated with the alternative L.")
    if flips:
        examples=sorted(flips,key=lambda x:x[-1],reverse=True)[:5]
        table(["Largest cost gaps after a change","Alternative","Original layout","New layout","Gap"],[
            (*r[:-1],f"{r[-1]:.2f}%") for r in examples
        ],[170,122,84,72,53])
    pd.DataFrame(flips,columns=["case_id","alternative","original_layout","new_layout","regret_pct"]).to_csv(
        OUT/"reference_length_layout_changes.csv",index=False)


def statistics(steady):
    section("07","Distributions and controlling outliers")
    peaks=b.peak_records(steady)
    high=maxrow(steady,B)
    sphere=maxrow(steady[steady.family=="sphere"],M)
    ahmed=maxrow(steady[steady.family=="ahmed"],M)
    grad=maxrow(steady,G)
    d=b.scatter(peaks)
    xmax=math.ceil(peaks[M].max()/25)*25
    ymax=math.ceil(peaks[G].max())
    highlights=[(sphere,"Sphere V100",(115,7)),(ahmed,"Ahmed V100",(133,31)),
                (grad,"Wing V10",(71,74)),(high,"Ahmed V10",(105,62))]
    for r,label,(tx,ty) in highlights:
        i=TUNNELS.index((r.tunnel_side_m,r.orientation))
        x,y=39+251*(i%2),189-151*(i//2)
        px=x+r[M]/xmax*198
        py=y+r[G]/ymax*98
        d.add(Circle(px,py,4.4,strokeColor=INK,strokeWidth=1,fillColor=None))
        d.add(Line(px,py,x+tx,y+ty,strokeColor=INK,strokeWidth=.65))
        d.add(String(x+tx,y+ty+3,label,fontSize=7,textAnchor="middle",fillColor=INK))
    chart(d,"mass_gradient_outliers")
    table(["Point","Case","Mass [kg]","Local B [T]","||G||F [T/m]","Why it stands out"],[
        (label,tunnel_name(r.tunnel_side_m,r.orientation)+" / "+case_label(r),fmt(r[M],4),fmt(r[B],4),fmt(r[G],4),why)
        for label,r,why in [
            ("Sphere",sphere,"Heaviest article. The large magnet makes this a low-gradient point despite the mass."),
            ("Ahmed mass",ahmed,"Large solid-body volume and full magnet installation."),
            ("Ahmed field",high,"Peak local field. The small magnet and yaw-capable arrangement raise field demand."),
            ("Wing gradient",grad,"Highest steady gradient. The thin section restricts magnet size, and the small dipole needs a steeper gradient."),
        ]
    ],[65,151,50,52,67,116])
    paired=peaks.copy()
    paired["article"]=paired.case_id.str.replace(r"_v\d+$","",regex=True)
    pairs=paired.pivot(index=["article","operating_group"],columns="magnet_volume_fraction",values=[G,B])
    diff=pairs[G][.1]-pairs[G][1.]
    Bchange=pairs[B][.1]-pairs[B][1.]
    para(f"At matched operating groups, V10 needs a larger gradient in {int((diff>1e-9).sum())} of {len(diff)} comparisons. "
         f"The median V10/V100 gradient ratio is {fmt((pairs[G][.1]/pairs[G][1.]).median())}. "
         f"The local field increases in {int((Bchange>1e-9).sum())} comparisons. Many centred, force-only cases need "
         "essentially zero field at the magnet for either size.")
    for key,label,width,stem in [(G,"||G||F [T/m]",.25,"gradient"),(B,"Local ||B|| [T]",.05,"field")]:
        rows=[]
        scale=max(162,max(len(b.selected_slice(peaks,h,o)) for h,o in TUNNELS))
        for fraction in (1,.1):
            b.chapter("07  /  STEADY DISTRIBUTION",f"{label} · V{100*fraction:g}")
            sample=peaks[peaks.magnet_volume_fraction==fraction]
            d,edges,counts=b.histograms(sample,key,label,width,top=peaks[key].max(),ymax=scale)
            chart(d,f"{stem}_V{100*fraction:g}")
            para(f"Bin width {width:g}. The two volumes share the same horizontal bins and 0–{scale} count axis. "
                 "Each steady operating group contributes once. Motion-correlated transverse histories have their own results.")
            for (h,o),counts_by_family in counts.items():
                for family,values in zip(b.FAMILIES,counts_by_family):
                    rows.extend((h,o,fraction,family,edges[i],edges[i+1],n) for i,n in enumerate(values))
        pd.DataFrame(rows,columns=["tunnel_side_m","orientation","magnet_volume_fraction","family",
                                   "bin_left","bin_right","count"]).to_csv(OUT/f"{stem}_histogram_counts.csv",index=False)


def mass_study(baseline,limited,audit):
    section("08","Lightweight PLA and the separate 25 kg study")
    para("The baseline uses a uniform solid LW-PLA material at 540 kg/m³, corresponding to a foamed print density in "
         "a manufacturer's product data. The model fills the declared outer geometry except for the magnet cavities. "
         "Actual wall thickness, infill, fixtures and achieved density will determine the manufactured mass. "
         +ref("eSUN LW-PLA product data","https://www.esun3d.com/epla-lw-product"))
    para("The solid-body mass and inertia come from the model geometry. The calculation subtracts each cavity's material "
         "and adds its oriented magnet block. The combined centre of mass comes from the signed first moments. "
         "The combined inertia uses each part's rotated tensor and parallel-axis shift. This same geometry is used for "
         "the aerodynamic area and the CAD fit.")
    para("<b>Separate mass-limit calculation.</b> Hold the outer shape, blockage, Reynolds number, speed and all load "
         "coefficients fixed. Hold magnet centres and directions fixed within each candidate. Resize all blocks in a "
         "candidate by the same linear factor. As each magnet shrinks, its vacated cavity volume is filled by the "
         "same LW-PLA equivalent material. This represents a resized cavity design at unchanged outer size.")
    para("Let M<sub>body</sub> be the full solid model without cavities, and M<sub>100</sub> the installed mass for "
         "one candidate at V100. At retained volume fraction f, M = M<sub>body</sub> + f(M<sub>100</sub> − M<sub>body</sub>). "
         "Choose the largest f that stays at or below 25 kg, up to 1. Apply the cube root of f to the magnet dimensions. "
         "Fail the candidate if the retained volume falls below 10% of the largest capped V100 magnet assembly available "
         "for that geometry. This absolute volume floor is separate from the per-layout V10 label.")
    rows=[]
    a=audit.groupby("case_id",sort=False)
    for cid,s in a:
        raw=baseline[baseline.case_id==cid]
        exemplar=raw.iloc[0]
        keep=s[s.fixed_selected.astype(bool)]
        r=keep.iloc[0] if len(keep) else s.loc[s.retained_reference_fraction.idxmax()]
        state=r.mass_status
        if not len(keep) and (s.mass_status.str.startswith("pass")).any():
            state="fail_no_fixed_wrench_solution"
        rr=limited[limited.case_id==cid]
        rows.append(dict(case_id=cid,family=exemplar.family,tunnel_side_m=exemplar.tunnel_side_m,
                         orientation=exemplar.orientation,blockage=exemplar.target_maximum_blockage,status=state,
                         body_only_kg=r.body_only_kg,kept_V100_reference_fraction=r.retained_reference_fraction,
                         limited_mass_kg=r.limited_mass_kg if len(keep) else np.nan,
                         baseline_set=exemplar.magnet_set_name,
                         selected_set=r.magnet_set_name if len(keep) else "",
                         baseline_G_Tpm=raw[G].max(),capped_G_Tpm=rr[G].max(),capped_local_B_T=rr[B].max()))
    summary=pd.DataFrame(rows)
    summary.to_csv(OUT/"mass_cap_campaigns.csv",index=False)
    counts=summary.groupby(["tunnel_side_m","status"]).size().unstack(fill_value=0)
    table(["Result","0.6 m campaigns","1 m campaigns"],[
        (s.replace("_"," "),int(counts.loc[.6,s]),int(counts.loc[1.,s])) for s in counts.columns
    ],[265,118,118])
    para("Each geometry and installation is screened from the V100 candidates. A passing layout is re-solved at its "
         "new mass, CoM, inertia and dipole strengths. Choose one passing arrangement for the entire campaign. "
         "The baseline results and their percentiles remain separate.")
    passing=summary[summary.status.str.startswith("pass")]
    kept=int((passing.selected_set==passing.baseline_set).sum())
    para(f"{kept} of {len(passing)} passing campaigns retain the same physical layout as the V100 baseline. "
         "The CSV records the layout on both sides of the comparison.")
    b.chapter("08  /  MASS LIMIT","Failures and resized cases")
    for label,panel in summary.groupby("tunnel_side_m",sort=False):
        p=panel[panel.orientation=="h"]
        display=p[p.status!="pass_unmodified"]
        table([f"{label:g} m horizontal","Blockage","Body only [kg]","Kept reference V%","Status","G baseline / limited [T/m]"],[
            (b.FAMILIES[r.family][0],f"{100*r.blockage:g}%",fmt(r.body_only_kg),
             fmt(100*r.kept_V100_reference_fraction),r.status.replace("_"," "),
             f"{fmt(r.baseline_G_Tpm)} / {fmt(r.capped_G_Tpm)}" if pd.notna(r.capped_G_Tpm) else f"{fmt(r.baseline_G_Tpm)} / —")
            for r in display.itertuples()
        ],[106,56,64,70,102,103])
    para("The geometric failures listed above apply to both gravity orientations. The audit CSV includes each installation, "
         "passing and failing candidates, actual retained volume and required fields. Body-only failures cannot be recovered "
         "by shrinking the magnet at this material density and outer size. "
         "The 25 kg value is a study constraint. "
         +ref("HSE manual handling risk filters","https://www.hse.gov.uk/msd/manual-handling-risk-filters.htm"))


def source_working(df,driven,hardware_table):
    section("09","Where the aerodynamic inputs come from")
    para("The selected rows have a published aerodynamic quantity, a reference geometry, and a speed that matches "
         "the source Reynolds number. Figure reads use the published curve or symbol centres and are approximate. "
         "The two cylinder roles use different sources and geometries. Stationary pressure drag enters the steady "
         "envelope. The separately labelled driven result reconstructs only the phase-locked part of transverse lift.")
    table(["Evidence","Role in this study"],[
        ("Achenbach, Jann and Geisbauer, Meile, Chinwicharnam and Thipyopas","Steady sphere, cuboid, Ahmed and NACA 0012 respectively. The source-specific pages show the coefficient and coordinate conversions."),
        ("Ajmal et al.","Stationary cylinder mean drag. Forced spectra and relative phase are contextual."),
        ("Blackburn and Melbourne","Air-driven, motion-correlated transverse lift for screened drive points."),
        ("Matsuda, Nishihara, Azadeh-Ranjbar and Li","Audited for geometry, wake, motion or force comparison. The published data do not supply the missing full air wrenches used by the sizing targets."),
    ],[228,273])
    b.report_sources(df,None,hardware_table,standalone=True)

    b.chapter("09D  /  SOURCE WORKING","Parked cylinder in air")
    parked=pd.read_csv(OUT/"ajmal_stationary_inputs.csv")
    para("Ajmal et al., PDF pp. 3–4, used a 250 mm diameter, 800 mm span cylinder in air at 10% blockage, with a "
         "close ceiling and a moving bottom plate. Pressure taps at midspan supplied the sectional coefficients. "
         "Table 2 supplies the ten stationary drag means below. Preserve span/diameter = 3.2 and use "
         "F<sub>x</sub> = q × diameter × span × mean C<sub>D</sub>. Mean lift is zero by symmetry. "
         "Use the published RMS lift and Strouhal number to identify the shedding context. These statistics do not define a simultaneous peak force history. "
         +ref("Ajmal et al., Table 2 and Figs. 1 and 4","https://doi.org/10.1016/j.jfluidstructs.2026.104658"))
    table(["Re_D","Mean C_D used","RMS C_L for context","Strouhal number"],[
        (f"{r.Re:,.0f}",fmt(r.CD_mean,4),fmt(r.CL_rms_context,4),fmt(r.St,4)) for r in parked.itertuples()
    ],[111,128,132,130])
    cad("cylinder_parked_T060*b10*single_body_x.png",151)
    para("The transverse force in Ajmal's forced runs shows lock-in and hysteresis. Fig. 4, PDF p. 7, expressly "
         "qualifies the phase zero. Fig. 12, p. 13, gives spectra for Re 66,700, amplitude ratio 0.1 and a 5 Hz drive. "
         "Spectra preserve frequency content while the simultaneous signed force history requires a phase reference. "
         "This study uses the published stationary data and keeps the forced results as wake evidence.")

    b.chapter("09E  /  SOURCE WORKING","Driven transverse cylinder in air")
    v=pd.read_csv(OUT/"blackburn_motion_inputs.csv")
    para("Blackburn and Melbourne tested a 200 mm by 900 mm cylinder, span/diameter = 4.5, in smooth air at nominal "
         "Re = 160,000. Large end plates with sealed gaps limited end flow. Sections 3.1 and 3.4, printed pp. 416–418, "
         "describe removal of transducer inertia and the decomposition by motion phase. Fig. 7(a,c), p. 422, gives signed "
         "RMS lift components. Read squares for the acceleration component and triangles for the velocity component. "
         +ref("Blackburn and Melbourne, Fig. 7 and Eqs. 7–10","https://doi.org/10.1006/jfls.1997.0086"))
    table(["Label","A/D","U/(fD)","C_L,a RMS","C_L,v RMS","Retained campaign sizes"],[
        (r.state,fmt(r.A_over_D),fmt(r.reduced_velocity),fmt(r.CL_a_rms),fmt(r.CL_v_rms),
         "; ".join(f"{h:g} m/{100*x:g}%" for h,x in driven[driven.operating_group==r.state][
                   ["tunnel_side_m","target_maximum_blockage"]].drop_duplicates().itertuples(index=False,name=None)))
        for r in v.itertuples()
    ],[96,53,62,72,72,146])
    para("Map the paper's transverse direction to +z in the tunnel. For phase theta = 2 pi f t, choose "
         "z = −A cos(theta), so acceleration and velocity have the positive cos and sin references used in Eq. 7. "
         "Multiply each signed RMS value by sqrt(2) to recover its sinusoidal peak. Then "
         "F<sub>z</sub> = q D × span × sqrt(2) [C<sub>L,a</sub> cos(theta) + C<sub>L,v</sub> sin(theta)]. "
         "The article's own acceleration load m a is added separately. The source's added-mass contribution is already "
         "in its acceleration-correlated fluid force.")
    r=maxrow(driven,G)
    para(f"The limiting driven row is {tunnel_name(r.tunnel_side_m,r.orientation)}, {case_label(r)}, "
         f"{operation(r)}. The resized drive uses {fmt(r.frequency_Hz)} Hz at U = {fmt(r.speed_mps)} m/s and "
         f"peak acceleration {fmt(r.acceleration_peak_mps2)} m/s². The reconstructed aerodynamic lift is "
         f"{fmt(r.Fz_aero_N)} N at the controlling phase, with {fmt(r.Fz_inertial_demand_N)} N of prescribed body inertia "
         f"and {fmt(r.Fz_gravity_N)} N of gravity in z.")
    para("Only drive points at or below a provisional 50 m/s² are solved. At fixed Re, diameter scaling changes frequency "
         "as D<super>−2</super> and acceleration as D<super>−3</super>. Sectional motion-correlated lift is applied "
         "over the full span as a coherent approximation, supported by the comparison in Fig. 9 for the source's 2.7% "
         "motion. Free ends, residual lift and missing drag limit the transfer. The labels describe reduced frequency "
         "relative to the source shedding band. They do not assign specific wake topologies.")
    cad("cylinder_crossflow_T060*b20*single_body_x.png",137)

    b.chapter("09F  /  SOURCE WORKING","Inline and free-ended cylinder evidence")
    para("Matsuda et al., Table 1 and Figs. 3, 5 and 7–9, report free inline response in air for D = 200 mm, "
         "aspect ratios 1.8 and 6.8 and 400 mm end plates. Fig. 3 places the two response regions around reduced "
         "velocities of roughly 2 and 3. The images distinguish more symmetric first-branch shedding in one degree "
         "of freedom and alternating shedding in the second branch. The paper provides response amplitudes and "
         "mass-damping ranges. It does not give phase-resolved air drag to pair with model inertia. "
         +ref("Matsuda et al., Table 1 and Figs. 3 and 7–9","https://doi.org/10.1016/S0167-6105(02)00336-7"))
    para("Nishihara et al. measured forced inline fluid loads at Re 17,000 and 34,000, A/D = 0.05, in water. "
         "The 50 mm by 490 mm cylinder had a 3–4 mm tip clearance. Eq. 9 and Fig. 8 give a drag fundamental with "
         "a displacement phase reference after tare. At Re 34,000, approximate reads illustrate the two excitation branches. "
         "They guide a future inline air experiment. They remain outside the air sizing tables. "
         +ref("Nishihara et al., Table 1, Eq. 9 and Fig. 8","https://doi.org/10.1016/j.jfluidstructs.2005.02.003"))
    table(["Reduced velocity U/(fD)","Drag amplitude |C_D|, approx.","Phase relative to x, approx."],
          [(2.2,.46,"+20°"),(2.7,.24,"0°"),(3.45,.05,"+36°"),(5,.10,"−88°")],[150,181,170])
    para("Azadeh-Ranjbar et al., Table II, reports free-ended air response. At aspect ratios 28.8, 10 and 5 the "
         "resonance Re values are 844, 1,714 and 2,946 and the peak A/D values are 0.15, 0.27 and 0.49. "
         "These are support-dependent free responses. They show why a short free-ended article needs its own force "
         "evidence, especially at higher Reynolds number. "
         +ref("Azadeh-Ranjbar et al., Table II","https://doi.org/10.1063/1.5042774"))
    para("Next evidence for an inline wrench is an air measurement of axial drag synchronised with displacement, "
         "with a still-air inertial tare. For transverse demand beyond the motion-correlated component, obtain "
         "simultaneous lift and drag records and a reproducible absolute phase reference. Include span and end condition.")

    b.chapter("09G  /  SOURCE WORKING","Lower-Re Ahmed check")
    para("Li et al. tested a 522 × 194.5 × 144 mm 35° Ahmed body at Re 640,000 for the force measurements, "
         "with a floor-mounted six-component balance. Section 2.2 and Fig. 10 publish drag, side force and lift. "
         "They do not tabulate roll, pitch or yaw moments for these comparisons. At the source length and air viscosity "
         "used here, Re 640,000 corresponds to about 18.1 m/s. Approximate Fig. 10 reads for the 35° series are below. "
         +ref("Li et al., §2.2 and Figs. 5 and 10","https://doi.org/10.1016/j.expthermflusci.2025.111488"))
    table(["Yaw","Li C_D","Li C_L","Li |C_S|","Meile C_D","Meile C_L","Meile |C_S|"],
          [("0°",.318,0,0,.29,0,0),("15°",.44,.31,.58,.43,.57,.81)],[68,70,70,73,72,72,76])
    para("The side-force column compares magnitudes because the published yaw and lateral force signs differ. "
         "The lift and side-force changes show why importing only drag or borrowing the high-Re moments would "
         "leave the lower-Re wrench underdetermined. A lower-Re six-axis Ahmed case needs the three moments and "
         "their reference point at the same yaw and Re.")


def case_index(df):
    section("10","Case index and reproducibility")
    para("Case IDs encode family, tunnel side in centimetres, maximum blockage percent, horizontal or upward flow, "
         "and magnet volume percent. The selected tables identify the physical magnet arrangement and each controlling "
         "state. For the driven supplement, use the separately exported history targets.")
    table(["File","Contents"],[
        ("useful_results_max_p90.csv","Steady maximum and observed P90 magnitudes by installation and volume. Signed value, source state, U, Re and selected hardware are retained."),
        ("driven_history_max_p90.csv","The same statistic for the available phase-locked transverse histories, with one peak per history and metric."),
        ("coverage.csv / candidates.csv","Source-matched case grid, exclusions and all solved candidate states."),
        ("selected_primary.csv","Fixed and independently swappable selections, with state forces, moments, field and gradient."),
        ("mass_cap_campaigns.csv / mass_cap_candidates.csv / mass_cap_selected.csv","Separate mass-limit case status, failed candidates and re-solved results."),
        ("reference_length_layout_changes.csv / hardware_rankings.csv","Winner changes, score gaps and candidate rankings at each reference length."),
        ("inputs / cad","Exact MATLAB inputs and preview figures. MATLAB can reopen the FIG files."),
    ],[227,274])
    para("To reproduce the data, run run_standalone_portfolio in MATLAB with the research folder on the path. "
         "The report builder reads those tables. The handoff records the full commands.")
    for h,o in TUNNELS:
        b.chapter("10  /  CASE INDEX",tunnel_name(h,o))
        s=b.selected_slice(df,h,o)
        table(["Model / blockage","Magnet V%","Installed set","Peak local B [T]","Peak ||G||F [T/m]","G state U [m/s] / Re"],[
            (b.FAMILIES[g.family][0]+f" / {100*g.target_maximum_blockage:g}%",f"{100*g.magnet_volume_fraction:g}",
             short_set(g.magnet_set_name),fmt(p[B].max(),4),fmt(g[G],4),f"{fmt(g.speed_mps)} / {g.Re:,.0f}")
            for _,p in s.groupby("case_id",sort=False) for g in [maxrow(p,G)]
        ],[124,53,79,73,79,93])
        para("Driven cylinder rows represent the transverse supplement. Fields and gradients can be controlled by different states.", "Small")


def main():
    b.OUT=OUT
    b.FIG=OUT/"charts"
    b.FIG.mkdir(exist_ok=True)
    b.FAMILIES["cylinder_crossflow"]=("Driven cylinder","#b74852")
    b.FAMILIES["cylinder_parked"]=("Parked cylinder","#937548")
    selected=pd.read_csv(OUT/"selected_primary.csv",low_memory=False)
    active=selected[selected.selection_mode=="fixed_hardware"].copy()
    active["B_O_norm_T"]=np.linalg.norm(active[["BOx_T","BOy_T","BOz_T"]],axis=1)
    steady=active[active.family!=AIR]
    driven=active[active.family==AIR]
    targets=target_rows(steady)
    targets.to_csv(OUT/"useful_results_max_p90.csv",index=False)
    target_rows(driven).to_csv(OUT/"driven_history_max_p90.csv",index=False)
    candidates=pd.read_csv(OUT/"candidates.csv",low_memory=False)
    sensitivity=pd.read_csv(OUT/"selection_sensitivity.csv",keep_default_na=False)
    ranking=pd.read_csv(OUT/"hardware_rankings.csv")
    manifest=pd.read_csv(OUT/"coverage.csv")
    overview(steady,driven)
    conventions()
    useful_results(steady,driven,targets)
    coverage(active,manifest)
    hardware(candidates,selected,sensitivity)
    merit_and_sensitivity(sensitivity,ranking)
    statistics(steady)
    mass_study(active,pd.read_csv(OUT/"mass_cap_selected.csv",low_memory=False),pd.read_csv(OUT/"mass_cap_candidates.csv"))
    source_working(active,driven,candidates)
    case_index(active)
    doc=Report(str(PDF),pagesize=(595.28,841.89),title="MSBS aerodynamic requirements",author="MSBS engineering study")
    doc.addPageTemplates(PageTemplate(id="Main",frames=[Frame(47,51,501,741.89,leftPadding=0,rightPadding=0)],
                                      onPage=footer))
    doc.multiBuild(b.STORY)


if __name__=="__main__":
    main()
