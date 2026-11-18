"""Present the 15 and 35 m/s runs in the supplied Rev6 report format."""
import argparse
from io import BytesIO
from pathlib import Path
from xml.sax.saxutils import escape

import pandas as pd
import numpy as np
from pypdf import PdfReader, PdfWriter
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import Image, PageBreak, Paragraph, SimpleDocTemplate, Table, TableStyle

from update_rev6_exports import AERO, MAGNETIC, read


INK = colors.HexColor("#192835")
TEAL = colors.HexColor("#1d6567")
GREY = colors.HexColor("#445d6b")
PALE = colors.HexColor("#edf3f4")
WIDTH = A4[0]-96
FAMILIES = {"sphere":"Sphere","square_prism":"Square prism","clark_y":"Clark Y",
            "ahmed":"35° Ahmed body","cuboid":"Cuboid"}
SOURCES = {"sphere":"Achenbach (1972), Fig. 4","square_prism":"van Hinsberg (2021), Table 1 and Fig. 2",
           "clark_y":"Zimmerman (1932), NACA TR 431","ahmed":"Meile et al. (2016), Figs. 18/20",
           "cuboid":"Jann and Geisbauer (2013), Tables 2 and 8"}
LABELS = dict(zip(MAGNETIC,["B<sub>"+i+"</sub>" for i in
                            ("x","y","z","xx","xy","xz","yy","yz","zz")]
                  + ["||B||","||Jacobian(B)||<sub>F</sub>"]))
LABELS.update({key:f"{key[0]}<sub>{key[1]}</sub>" for key in AERO})


def fmt(v,figures=4):
    return f"{v:.{figures}g}" if pd.notna(v) else "—"


def value(r):
    unit = ("N" if r.metric.startswith("F") else "N m") if r.metric in AERO else (
        "T/m" if r.metric.endswith("Tpm") else "T")
    return f"{fmt(r.signed_value)} {unit}"


def box(row):
    return " × ".join(f"{1000*v:.0f}" for v in np.fromstring(row.model_dimensions_B_m.strip("[]"),sep=" "))


def state(row):
    return str(row.scenario_name).replace("alpha","α ").replace("_beta",", β ").replace(
        "yaw","yaw ").replace("incidence","incidence ")


def coverage_label(row):
    return {"coefficient_transfer_outside_factor_two":"Re extrapolation beyond factor two",
            "coefficient_transfer_within_factor_two":"coefficient transfer within factor two",
            "below_source_Re_range_coefficient_transfer":"below measured Re range",
            "interpolated_smooth_sphere_curve":"smooth-sphere curve interpolation",
            "inside_source_range":"within measured Re range"}[row.Re_basis]


class SizingReport:
    def __init__(self, source, out):
        self.source, self.out = source, out
        self.story = []
        self.a = read(out,"appendix_magnetic_cases")
        self.s = self.a[self.a.selected_fixed].copy()
        self.coverage = read(out,"coverage")
        self.motion = read(out,"oscillating_cylinder_summary")
        self.mag = read(out,"key_magnetic_maxima")
        self.aero = read(out,"key_aerodynamic_maxima")
        self.styles = {
            "body":ParagraphStyle("body",fontName="Helvetica",fontSize=9.4,leading=13.1,textColor=INK,spaceAfter=7),
            "small":ParagraphStyle("small",fontName="Helvetica",fontSize=8.4,leading=10.8,textColor=GREY,spaceAfter=5),
            "title":ParagraphStyle("title",fontName="Helvetica-Bold",fontSize=28,leading=32,textColor=INK,spaceAfter=12),
            "section":ParagraphStyle("section",fontName="Helvetica-Bold",fontSize=21,leading=24,textColor=INK,spaceAfter=10),
            "sub":ParagraphStyle("sub",fontName="Helvetica-Bold",fontSize=13,leading=17,textColor=TEAL,spaceBefore=6,spaceAfter=5),
            "cell":ParagraphStyle("cell",fontName="Helvetica",fontSize=7.8,leading=9.5,textColor=INK),
            "compact":ParagraphStyle("compact",fontName="Helvetica",fontSize=7.4,leading=8.7,textColor=INK),
            "head":ParagraphStyle("head",fontName="Helvetica-Bold",fontSize=7.6,leading=9.2,textColor=colors.white),
        }

    def p(self, text, style="body"):
        self.story.append(Paragraph(text,self.styles[style]))

    def table(self, headers, rows, fractions, dense=False):
        contents = [[Paragraph(str(h),self.styles["head"]) for h in headers]]
        style = self.styles["compact" if dense else "cell"]
        contents.extend([Paragraph(str(v),style) for v in r] for r in rows)
        t = Table(contents,colWidths=[f*WIDTH/sum(fractions) for f in fractions],repeatRows=1)
        t.setStyle(TableStyle([
            ("BACKGROUND",(0,0),(-1,0),TEAL),
            ("ROWBACKGROUNDS",(0,1),(-1,-1),[colors.white,PALE]),
            ("VALIGN",(0,0),(-1,-1),"TOP"),("LEFTPADDING",(0,0),(-1,-1),6),
            ("RIGHTPADDING",(0,0),(-1,-1),4),("TOPPADDING",(0,0),(-1,-1),2 if dense else 4),
            ("BOTTOMPADDING",(0,0),(-1,-1),2 if dense else 4),
            ("LINEBELOW",(0,-1),(-1,-1),.5,colors.HexColor("#afc6cc")),
        ]))
        self.story.append(t)

    def page(self):
        self.story.append(PageBreak())

    def methods(self):
        self.p("Magnetic suspension and balance<br/>sizing","title")
        self.p("1 m sizing at 15 and 35 m/s and 60 cm Sawada benchmarks","small")
        self.p("1 &nbsp; Methods","section")
        self.p("The sizing grid uses a 1 m × 1 m test section. Each model is scaled to 3%, 10% or 20% maximum "
               "projected blockage across the tested attitudes. The geometry and attitude grid are fixed across speeds. "
               "All steady cases are run at 15 and 35 m/s with air density 1.225 kg/m³ and viscosity 1.81 × 10<super>−5</super> Pa s.")
        self.p("Aerodynamic loads and frames","sub")
        self.p("Tunnel +x follows the flow. Tunnel +z is up in the horizontal installation. Force is qS times the "
               "force coefficient, and moment at the source reference is qSL times its coefficient. The dynamic pressure "
               "q is half the air density times speed squared. The cuboid uses tunnel-axis forces and body-axis moments. "
               "The Ahmed body uses digitised body-axis loads at the source floor datum. Moments are shifted to assembly "
               "centre of mass C using the lever arm from C to the source point.")
        self.p("Model mass and magnet selection","sub")
        self.p('The model uses solid LAST-A-FOAM FR-7120 rigid polyurethane foam at 320 kg/m³ '
               '(<link href="https://www.generalplastics.com/products/fr-7100" color="#1d6567">General Plastics</link>). '
               "Subtract the magnet "
               "cavities and add the N52 magnets at 7,500 kg/m³. Each policy keeps the original geometry and magnet layout "
               "dimensions. V100 is each layout's fit within the 0.30 m installed envelope. V25 retains 25% of that fit volume. "
               "Screen out every candidate whose complete assembly exceeds 25 kg before selecting hardware.")
        self.p("One layout must cover both speeds and every attitude in its campaign. Among layouts that can balance the "
               "aerodynamic wrench and both gravity biases, choose the lowest worst-case affine-field RMS over a cube "
               "with side equal to the longest model dimension. The cuboid and Ahmed body require six-axis authority.")
        self.p("Aerodynamic demand, weight support and motion","sub")
        self.p("The steady magnetic solve balances the aerodynamic wrench. Solve the weight support separately with the "
               "same dipoles and pose, using +mg along tunnel z for horizontal flow or tunnel x for upward flow and zero net "
               "moment at C. Add the corresponding bias field and Jacobian to the aerodynamic solution for an installation. "
               "The moving-case demand is body inertia minus available aerodynamic force, with weight support applied separately.")
        self.p("The local affine model is B(r) = B(C) + Jacobian(B)(r − C). The Jacobian is symmetric and trace-free. "
               "B<sub>ij</sub> is the derivative of B<sub>i</sub> with respect to x<sub>j</sub>. Its Frobenius norm uses all nine entries.")

    def aerodynamics(self):
        self.page()
        self.p("Square prism at 15 and 35 m/s","sub")
        self.p("The smooth square prism uses van Hinsberg's (C<sub>D</sub>, C<sub>L</sub>, C<sub>m</sub>) values "
               "at 0°, −22.5° and −45° of (2.15, 0, 0), (1.90, 0.15, −0.116) and (2.25, 0, 0). "
               "The reference area is side × span, the moment length is the square side, and the sectional load is "
               "integrated along the span. The 900 mm span cap lowers the 20% model's aspect ratio to 5.73 from 10. "
               "The source blockage was 10–14% before wall correction. The 20% case has added confinement and end-condition uncertainty.")
        prism=self.s[self.s.family.eq("square_prism")]
        self.table(["Max blockage","Body size (mm)","Re at 15 / 35 m/s","Peak Fx (N) 15 / 35","Peak |Fz| (N)","Peak |My| (N m)"],[
            (f"{100*b:g}%",box(g.iloc[0])," / ".join(f"{x.Re.iloc[0]:,.0f}" for x in groups),
             *[" / ".join(fmt(x[key].abs().max()) for x in groups) for key in ("Fx_aero_N","Fz_aero_N","My_aero_Nm")])
            for b,g in prism.groupby("target_maximum_blockage")
            for groups in [[g[g.speed_mps.eq(v)] for v in (15,35)]]
        ],[60,88,92,90,80,87])
        self.p("Load pairs give 15 then 35 m/s. The 3% and 10% cases at 15 m/s fall below the source's measured "
               "Re range of 100,000 to 10 million. Their coefficients are low-Re transfers.","small")
        self.p("Clark Y, Ahmed body, cuboid and sphere","sub")
        self.p("The wing retains the Clark Y near-stall conditions and quarter-chord moments reconstructed from "
               "Zimmerman's resultant coefficients and centre of pressure. Its capped 20% span gives AR 1.91 "
               "versus 1.5 for the corresponding source wing. Ahmed uses the 35° body at 0° and 15° yaw. The finite "
               "11:9:5 cuboid retains five Jann attitudes.")
        self.table(["Family","Blockage","Body size (mm)","Re at 15 / 35 (million)","Source Re (million)","Re factor 15 / 35"],[
            (FAMILIES[f],f"{100*b:g}%",box(g.iloc[0]),
             " / ".join(f"{x.Re.iloc[0]/1e6:.3f}" for x in groups),fmt(g.source_Re.iloc[0]/1e6),
             " / ".join(fmt(x.source_Re_factor.iloc[0],3) for x in groups))
            for (f,b),g in self.a[self.a.family.isin(["clark_y","ahmed","cuboid"])].groupby(
                ["family","target_maximum_blockage"],sort=False)
            for groups in [[g[g.speed_mps.eq(v)] for v in (15,35)]]
        ],[75,52,100,112,78,80],dense=True)
        self.p("The Re factor is the larger of model/source and source/model Reynolds numbers. Values above two "
               "are flagged coefficient extrapolations. Sphere drag is interpolated on the log-Re axis using the "
               "approximate Achenbach smooth-sphere curve. The 15 m/s small sphere sits before the drag crisis, "
               "so its drag can exceed the 35 m/s result.","small")

    def motion_pages(self):
        self.page()
        self.p("Clark Y aerodynamic inputs and V25 forces","sub")
        wing=self.s[self.s.family.eq("clark_y") & self.s.magnet_volume_fraction.eq(.25)]
        self.table(["Blockage / AoA","AR","CL / CD / Cm,c/4","U (m/s)","Fx / Fz (N)","My at C (N m)","Magnet / total (N)"],[
            (f"{100*r.target_maximum_blockage:g}% / {r.scenario_name.removeprefix('alpha')}°",fmt(r.aspect_ratio,3),
             f"{r.source_CL:.3f} / {r.source_CD:.3f} / {r.source_Cm:.3f}",r.speed_mps,
             f"{r.Fx_aero_N:.1f} / {r.Fz_aero_N:.1f}",f"{r.My_aero_Nm:.2f}",
             f"{r.magnet_weight_N:.1f} / {r.total_weight_N:.1f}")
            for r in wing.sort_values(["target_maximum_blockage","speed_mps"]).itertuples()
        ],[83,42,105,47,71,65,84])
        self.p("Forced motion near cylinder vortex shedding","sub")
        self.p("The transverse comparison prescribes sinusoidal motion near the fixed-cylinder shedding frequency. "
               "Lock-in is identified when the wake follows the drive across a frequency band and the independent shedding "
               "peak disappears. The main model diameters × spans are 81.6 × 367, 149 × 671 and 211 × 949 mm.")
        self.p("Okamoto, Uematsu and Taguwa forced a 60 mm air cylinder at Re = 19,000 and A/D = 0.05. "
               "Their fixed-cylinder St = 0.202 and lock-in band corresponds to U/(fD) of 4.63–5.38. At fD/U = 0.204, "
               "the reconstructed lift uses amplitude C<sub>L</sub> ≈ 1.62 and a lead of about 40° relative to displacement. "
               "Zasso et al.'s free air-cylinder replay at Re near 50,000 uses A/D = 0.10, U/(fD) ≈ 5.56, "
               "C<sub>L</sub> amplitude 1.25 and zero lead. The sectional lift transfer assumes spanwise coherence.")
        self.p("The added 15 and 35 m/s transverse cases reuse the prescribed A/D = 0.05 and U/(fD) ≈ 4.90. "
               "The inline cases use A/D = 0.05 and U/(fD) ≈ 2.48, near twice the fixed-cylinder shedding frequency. "
               "At both new speeds the phase exports give imposed kinematics and inertia. The available sources do "
               "not establish the synchronised air loads for these drive points. The 25 m/s long-span transverse "
               "comparison, with 31.6 mm diameter and 950 mm span, keeps its published-load transfer.")
        self.p("With f = U/[D × U/(fD)], peak inertia is mass × A × (2πf)². The next page shows V25. "
               "Both volume policies are available in the CSV for assemblies within 25 kg. The V100 motion "
               "assemblies at 10% and 20% blockage exceed the limit.","small")
        self.page()
        for mode in ("transverse","inline"):
            self.p(mode.capitalize(),"sub")
            rows=self.motion[self.motion.direction.eq(mode) & self.motion.magnet_fraction.eq(.25)].sort_values(
                ["geometry","blockage","speed_mps"],ascending=[False,True,True])
            self.table(["Blockage","U (m/s)","Re","A/D · U/(fD)","f (Hz)","Mag. wt. (N)","Lift amp. (N)","Inertia pk (N)"],[
                (f"{100*r.blockage:g}%"+(" long" if r.geometry!="span_ratio_4p5" else ""),
                 f"{r.speed_mps:.2f}",f"{r.Re/1e3:.1f}k",f"{r.A_over_D:.2f} · {r.U_over_fD:.2f}",
                 f"{r.frequency_Hz:.1f}",f"{r.magnet_weight_N:.1f}",fmt(r.lift_amplitude_N,3),f"{r.inertia_peak_N:.2f}")
                for r in rows.itertuples()
            ],[57,54,58,82,52,64,64,66],dense=True)
        self.p("A dash in the lift column indicates an inertia-only calculation. Sources are Okamoto et al. (2002) and Zasso et al. (2008).","small")

    def key_results(self):
        self.page()
        self.p("2 &nbsp; Key results","section")
        self.p("The 1 m envelope uses mass-screened fixed hardware. Each component is ranked by absolute magnitude "
               "and reported with its sign. The Reynolds flags identify coefficient transfers.")
        self.p("Aerodynamic load maxima","sub")
        self.table(["Load","Peak at 15 m/s","Peak at 35 m/s","Governing model and state at the envelope","Re · projected blockage"],[
            (LABELS[k],*[value(group[group.envelope.eq(str(v))].iloc[0]) for v in (15,35)],
             f"{FAMILIES[r.family]}<br/>{state(r)} · {coverage_label(r)}",
             f"{r.Re:,.0f}<br/>{100*r.projected_blockage_ratio:.2f}%")
            for k,group in self.aero.groupby("metric",sort=False)
            for r in [group[group.envelope.eq("combined")].iloc[0]]
        ],[43,79,79,195,100])
        self.p("Peak aerodynamic field and Jacobian by speed","sub")
        self.table(["Volume","U (m/s)","Peak ||B|| (T)","Governing model","Peak ||Jacobian(B)||F (T/m)","Governing model"],[
            (f"V{100*v:g}",u,fmt(x.signed_value),f"{FAMILIES[x.family]} · {100*x.target_maximum_blockage:g}%",
             fmt(y.signed_value),f"{FAMILIES[y.family]} · {100*y.target_maximum_blockage:g}%")
            for (u,v),g in self.mag[self.mag.envelope.ne("combined")].groupby(["speed_mps","magnet_volume_fraction"])
            for x,y in [(g[g.metric.eq("B_norm_T")].iloc[0],g[g.metric.eq("Jacobian_B_frobenius_Tpm")].iloc[0])]
        ],[54,49,78,106,104,106])
        exclusions=self.coverage[self.coverage.status.ne("ran")]
        self.p("25 kg assembly screen","sub")
        self.p(f"{self.s.case_id.nunique()} of {len(self.coverage)} steady campaigns retain a feasible fixed layout. "
               "A V100 or V25 campaign requires at least one original layout that both fits the mass limit and "
               "meets its wrench requirements. The table gives the lightest candidate for each excluded campaign.")
        self.table(["Excluded family","Blockage","Volume","Lightest candidate (kg)","Reason"],[
            (FAMILIES[r.family],f"{100*r.blockage:g}%",f"V{100*r.magnet_volume_fraction:g}",
             fmt(r.lightest_candidate_kg),r.reason) for r in exclusions.itertuples()
        ],[100,59,54,96,188],dense=True)

    def magnetic_pages(self):
        for volume in (1,.25):
            maxima=self.mag[self.mag.envelope.eq("combined") & self.mag.magnet_volume_fraction.eq(volume)]
            for heading,metrics in [
                ("Field at the centre of mass",(*MAGNETIC[:3],"B_norm_T")),
                ("Normal Jacobian components",("Bxx_Tpm","Byy_Tpm","Bzz_Tpm")),
                ("Shear components and Jacobian norm",("Bxy_Tpm","Bxz_Tpm","Byz_Tpm","Jacobian_B_frobenius_Tpm")),
            ]:
                self.page()
                self.p(f"Magnetic field and Jacobian maxima · V{100*volume:g}","sub")
                self.p(f"{heading}. Entries give the governing state across 15 and 35 m/s. The model bounding box "
                       "is the exterior size along body x, y and z. B and ||B|| are evaluated at C.","small")
                rows=maxima[maxima.metric.isin(metrics)]
                for _,g in rows.groupby("magnetic_case_id",sort=False):
                    r=g.iloc[0]
                    self.p(f"{FAMILIES[r.family]} · {escape(state(r))}","sub")
                    self.p(" &nbsp;|&nbsp; ".join(f"<b>{LABELS[z.metric]} = {value(z)}</b>" for z in g.itertuples()))
                    self.p(f"Re {r.Re:,.0f} &nbsp;|&nbsp; {r.speed_mps:g} m/s &nbsp;|&nbsp; "
                           f"{100*r.projected_blockage_ratio:.2f}% projected blockage &nbsp;|&nbsp; {SOURCES[r.family]}","small")
                    self.p(f"<b>Body bounding box</b> {box(r)} mm &nbsp;|&nbsp; {coverage_label(r)}"
                           f"<br/><b>Layout</b> {r.magnet_set_name} &nbsp;|&nbsp; {r.magnetic_case_id}"
                           f"<br/><b>Magnet / total weight</b> {r.magnet_weight_N:.2f} / {r.total_weight_N:.2f} N "
                           f"({r.magnet_mass_kg:.3g} / {r.total_mass_kg:.3g} kg)"
                           f"<br/><b>Magnetisation in tunnel axes</b> {escape(str(r.magnetisation_T))}","small")
                    self.p("F ["+", ".join(fmt(r[k]) for k in AERO[:3])+"] N &nbsp;|&nbsp; M ["
                           +", ".join(fmt(r[k]) for k in AERO[3:])+"] N m","small")
                if len(set(rows.magnetic_case_id))<=2:
                    for r in rows.drop_duplicates("magnetic_case_id").itertuples():
                        img=self.source/"cad"/f"{r.case_id}_{r.rev6_scenario_id}_{r.magnet_set_id}.png"
                        if img.exists():
                            self.story.append(Image(str(img),width=175,height=140,kind="proportional"))
                            self.p(f"Installed layout for {FAMILIES[r.family]}, {escape(state(r))}. "
                                   "Gold is the main magnet and green marks auxiliary magnets.","small")
                            break

    def gravity(self):
        for orientation,axis in (("horizontal","z"),("upward","x")):
            self.page()
            title="horizontal flow" if orientation=="horizontal" else "vertically upward flow"
            self.p(f"Gravity support maxima · {title}","section")
            self.p(f"Gravity-only solutions balance weight along tunnel +{axis} with zero moment about C. "
                   "The support bias for a given pose and magnet layout is independent of speed.")
            for key,caption in [("key_gravity_maxima","Fixed aerodynamic hardware"),
                                ("single_magnet_gravity_maxima","Single-magnet layouts")]:
                self.p(caption,"sub")
                x=read(self.out,key).query("support_orientation == @orientation")
                self.table(["Metric","Signed peak V100 / V25","Governing case and layout V100 / V25","Weight (N) V100 / V25"],[
                    (LABELS[k]," / ".join(value(r) for r in g.itertuples()),
                     "<br/>".join(f"{FAMILIES[r.family]} {100*r.target_maximum_blockage:g}% · {escape(state(r))} · {r.magnet_set_name}"
                                  for r in g.itertuples()),
                     " / ".join(f"{r.total_weight_N:.1f}" for r in g.itertuples()))
                    for k,g in x.sort_values("magnet_volume_fraction",ascending=False).groupby("metric",sort=False)
                ],[65,129,226,77],dense=True)
            self.p("The fixed-layout table uses the selected steady hardware. The single-magnet table covers "
                   "mass-compliant single-magnet candidates that can supply the gravity bias.","small")

    def appendix(self):
        self.page()
        self.p("3 &nbsp; Appendix","section")
        self.p("Case data and reproduction","sub")
        self.p(f"The case table contains {len(self.a):,} candidate-state rows at 15 and 35 m/s. "
               f"The fixed selections contain {len(self.s)} states. The mass screen is applied at the installed layout level. "
               "The raw MATLAB export includes a 50 m/s comparison against the supplied study for verification.")
        self.table(["Companion file","Contents"],[
            ("appendix_magnetic_cases.csv / selected_steady_states.csv","Candidate and selected layouts with speeds, bounding boxes, masses, wrench, affine field, Jacobian and support biases."),
            ("key_aerodynamic_maxima.csv / key_magnetic_maxima.csv","Exact controlling rows by speed and for the full envelope, retaining the signed and absolute values. Magnetic rows also split V100 and V25."),
            ("coverage.csv / mass_screen.csv","Campaign status and candidate-level foam, magnet and total masses."),
            ("installed_magnets_and_mass.csv / hardware_rankings.csv","Magnet dimensions and positions and fixed-layout merit ranking after screening."),
            ("gravity_support.csv / key_gravity_maxima.csv / single_magnet_gravity_maxima.csv","Gravity support biases and signed peaks for both installations."),
            ("oscillating_cylinder_summary.csv and phase exports","Motion comparison including kinematics-only phase traces at 15 and 35 m/s. The exclusions CSV records assemblies above the mass cap."),
            ("sawada_60cm_matlab.csv / sawada_60cm_calibration.csv","Published 60 cm sphere comparison and accompanying calibration."),
            ("inputs / sphere_drag_curve.csv","Updated MATLAB inputs and approximate sphere drag interpolation knots."),
            ("clark_y_alpha17_magnetisation_comparison.csv","Retargeted wing-aligned and tunnel-aligned magnet comparison at both speeds."),
        ],[207,290])
        self.p("Join the magnetic maxima and gravity export to the appendix using magnetic_case_id. "
               "R<sub>TB</sub> maps body vectors to tunnel axes. For upward flow, R<sub>ET</sub> is a −90° rotation "
               "about y. Transform the Jacobian by left-multiplying by R<sub>ET</sub> and right-multiplying by "
               "its transpose. The reproduction commands accompany the report.","small")
        self.p("Aerodynamic sources","sub")
        for f,link in [
            ("sphere","https://doi.org/10.1017/S0022112072000874"),
            ("cuboid","https://doi.org/10.2514/6.2013-1282"),
            ("ahmed","https://doi.org/10.1016/j.ijheatfluidflow.2015.11.002"),
            ("clark_y","https://ntrs.nasa.gov/citations/19930091504"),
            ("square_prism","https://elib.dlr.de/141240/"),
        ]:
            self.p(f'<link href="{link}" color="#1d6567">{SOURCES[f]}</link>',"small")

    def build(self):
        self.methods()
        self.aerodynamics()
        self.motion_pages()
        self.key_results()
        self.magnetic_pages()
        self.gravity()
        self.appendix()
        temp=BytesIO()
        doc=SimpleDocTemplate(temp,pagesize=A4,leftMargin=48,rightMargin=48,topMargin=46,bottomMargin=45,
                              title="Magnetic suspension and balance sizing at 15 and 35 m/s")
        doc.build(self.story,onFirstPage=footer,onLaterPages=footer)
        changed=PdfReader(temp)
        assert len(changed.pages)==14, f"Unexpected revised page count: {len(changed.pages)}"
        original=PdfReader(self.source/"MSBS_1m_Aerodynamic_and_Magnetic_Sizing.pdf")
        assert "Sawada 60 cm sphere benchmark" in original.pages[4].extract_text()
        merged=PdfWriter()
        for p in changed.pages[:4]:
            merged.add_page(p)
        for p in original.pages[4:6]:
            merged.add_page(p)
        for p in changed.pages[4:]:
            merged.add_page(p)
        merged.add_metadata({"/Title":doc.title})
        for name,idx in [("Methods",0),("Cylinder motion",2),("Sawada benchmark",4),("Key results",6),
                         ("V100 maxima",7),("V25 maxima",10),("Gravity support",13),("Appendix",15)]:
            merged.add_outline_item(name,idx)
        merged.write(self.out/"MSBS_1m_Aerodynamic_and_Magnetic_Sizing_15_and_35mps.pdf")


def footer(canvas, doc):
    width,_=A4
    canvas.setStrokeColor(colors.HexColor("#afc6cc"))
    canvas.line(48,37,width-48,37)
    canvas.setFillColor(GREY)
    canvas.setFont("Helvetica",8)
    canvas.drawString(48,24,"Imperial MSBS  /  Sizing and benchmarks")
    canvas.drawRightString(width-48,24,str(doc.page+(2 if doc.page>=5 else 0)))


if __name__ == "__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source",type=Path)
    parser.add_argument("output",type=Path)
    args=parser.parse_args()
    SizingReport(args.source,args.output).build()
