"""Build the single, self-contained scientific report from audited results."""
from pathlib import Path
import csv, json, math, hashlib, html
from collections import Counter
from PIL import Image as PILImage
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, Image, KeepTogether
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.graphics.shapes import Drawing, Line, String, Circle, Rect, Polygon

ROOT=Path(__file__).resolve().parents[2]; RESEARCH=ROOT/'research'; OUT=RESEARCH/'outputs'; QA=RESEARCH/'qa'
def read(p):
    with p.open(encoding='utf-8-sig',newline='') as f:return list(csv.DictReader(f))
summary=json.loads((OUT/'analysis_summary.json').read_text())
cases=read(OUT/'case_comparison.csv'); rows=read(OUT/'selected_fixed_configuration_results.csv')
manifest=read(OUT/'study_manifest.csv'); ids={m['case_id']:f'C{i+1:03}' for i,m in enumerate(manifest)}
names={'sphere':'Sphere','cuboid':'DLR cuboid','ahmed':'Ahmed 35 deg','naca0012':'NACA 0012','sc20714':'SC(2)-0714','cylinder_crossflow':'Crossflow cylinder','cylinder_inline':'Inline cylinder'}
def n(r,k):return float(r[k])
def fmt(x,d=4):
    x=float(x)
    return f'{x:.{d}g}' if x else '0'
def vec(r,keys):return '['+', '.join(fmt(n(r,k),5) for k in keys)+']'
def state(family,part,scenario):
    return next(r for r in rows if r['family']==family and part in r['case_id'] and r['scenario_name']==scenario)
S=summary['summaries']; global_s=S['selected_all']; anchored=S['selected_source_anchored']
styles=getSampleStyleSheet()
styles.add(ParagraphStyle(name='TitleMS',fontName='Helvetica-Bold',fontSize=24,leading=29,textColor=colors.HexColor('#153d52'),spaceAfter=14))
styles.add(ParagraphStyle(name='SubMS',fontSize=12,leading=16,textColor=colors.HexColor('#4b6877'),spaceAfter=10))
styles.add(ParagraphStyle(name='BodyMS',fontSize=9.3,leading=13,spaceAfter=7))
styles.add(ParagraphStyle(name='SmallMS',fontSize=7.4,leading=10,spaceAfter=4))
styles.add(ParagraphStyle(name='CellMS',fontSize=7.1,leading=9))
styles.add(ParagraphStyle(name='EquationMS',fontName='Courier',fontSize=8.1,leading=12,spaceBefore=5,spaceAfter=8))
styles['Heading1'].textColor=colors.HexColor('#153d52');styles['Heading1'].fontSize=17;styles['Heading1'].leading=21
styles['Heading2'].fontSize=11.5;styles['Heading2'].leading=15;styles['Heading2'].spaceBefore=8
story=[];md=[]
def p(text,style='BodyMS'):
    story.append(Paragraph(html.escape(str(text)).replace('\n','<br/>'),styles[style]));md.append(str(text)+'\n')
def rich(text,style='BodyMS'):
    story.append(Paragraph(text,styles[style]));md.append(text+'\n')
def h(text):story.append(Paragraph(html.escape(text),styles['Heading1']));md.append('# '+text+'\n')
def h2(text):story.append(Paragraph(html.escape(text),styles['Heading2']));md.append('## '+text+'\n')
def eq(text):p(text,'EquationMS')
def page():story.append(PageBreak());md.append('\n---\n')
def table(headers,data,widths=None):
    vals=[[Paragraph(html.escape(str(x)),styles['CellMS']) for x in row] for row in [headers]+data]
    t=Table(vals,colWidths=widths,repeatRows=1,hAlign='LEFT')
    t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#e4eef2')),('TEXTCOLOR',(0,0),(-1,0),colors.HexColor('#153d52')),('VALIGN',(0,0),(-1,-1),'TOP'),('BOTTOMPADDING',(0,0),(-1,-1),5),('TOPPADDING',(0,0),(-1,-1),5),('LINEBELOW',(0,0),(-1,0),.6,colors.HexColor('#a5bac5')),('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.white,colors.HexColor('#f4f7f8')])]))
    story.append(t);story.append(Spacer(1,8))
    md.extend(['| '+' | '.join(map(str,headers))+' |','|'+'---|'*len(headers)]+['| '+' | '.join(map(str,row))+' |' for row in data]+[''])
def fig(filename,caption,crop=None,width=470,maxheight=310):
    path=QA/filename
    if crop:
        im=PILImage.open(path);w,hx=im.size;im=im.crop(tuple(int(v*s) for v,s in zip(crop,[w,hx,w,hx])))
        dest=QA/(path.stem+'_crop.png');im.save(dest);path=dest
    im=PILImage.open(path);w,hx=im.size;f=min(width/w,maxheight/hx)
    story.append(Image(str(path),width=w*f,height=hx*f,hAlign='LEFT'));p(caption,'SmallMS')
    md.append(f'![{caption}](qa/{path.name})\n')
def source_ref(num,text,url=None):
    if url:rich(f'[{num}] {html.escape(text)} <link href="{html.escape(url,quote=True)}" color="#176b8a">Primary source</link>.','SmallMS')
    else:p(f'[{num}] {text}','SmallMS')
def chart():
    D=Drawing(480,310)
    palette=[colors.HexColor(x) for x in ['#176b8a','#ce6337','#176b8a','#ce6337']]
    for i,fam in enumerate(['cuboid','ahmed','sc20714','cylinder_crossflow']):
        left=35+(i%2)*240;bottom=45+(1-i//2)*145;ww=185;hh=95
        D.add(String(left,bottom+hh+17,names[fam],fontName='Helvetica-Bold',fontSize=9))
        for j,y in enumerate([.1,1,10,100]):
            yy=bottom+(math.log10(y)+1)/3*hh
            D.add(Line(left,yy,left+ww,yy,strokeColor=colors.HexColor('#dce4e8'),strokeWidth=.5))
            D.add(String(left-20,yy-2,str(y),fontSize=7))
        D.add(Line(left,bottom,left,bottom+hh,strokeWidth=.7));D.add(Line(left,bottom,left+ww,bottom,strokeWidth=.7))
        for b in [.03,.1,.2]:
            xx=left+(b-.03)/.17*ww;D.add(String(xx-4,bottom-12,str(round(b*100)),fontSize=7))
        for j,(H,fraction) in enumerate([(.6,1),(.6,.1),(1,1),(1,.1)]):
            pts=[]
            for b in [.03,.1,.2]:
                c=[r for r in cases if r['family']==fam and float(r['tunnel_side_m'])==H and float(r['blockage'])==b and float(r['volume_fraction'])==fraction]
                y=max(float(r['max_G_F_Tpm']) for r in c)
                xx=left+(b-.03)/.17*ww;yy=bottom+(math.log10(y)+1)/3*hh;pts.append((xx,yy))
                D.add(Circle(xx,yy,2,fillColor=palette[j],strokeColor=palette[j]))
            for a,b in zip(pts,pts[1:]):D.add(Line(*a,*b,strokeColor=palette[j],strokeWidth=1.2,strokeDashArray=[3,2] if H==1 else None))
    D.add(String(35,12,'x: maximum projected blockage (%)   y: max ||G||F (T/m), log scale',fontSize=8))
    D.add(String(35,0,'Blue: large magnet; orange: 10% volume. Solid: 0.6 m; dashed: 1 m. Worst H/up.',fontSize=7.5))
    return D

p('MSBS aerodynamic loads and magnetic requirements','TitleMS')
p('Source audit, coordinate working, software changes and 168-study screening comparison','SubMS')
p('6 November 2026 | Square tunnels: 0.6 m and 1.0 m | Horizontal and upward flow')
h2('Calculated targets and their scope')
p(f'The study solves {summary["total_solved_rows"]:,} simultaneous scenario/magnet combinations. All {summary["ran_studies"]} requested configurations have a residual-accepted fixed arrangement. The envelope below uses the best immutable arrangement for each physical model and operating envelope; it does not switch magnets between phase or speed rows.')
table(['Envelope','Max |B_C| (T)','Max local |B_i| (T)','Max ||G||F (T/m)','Max tensor entry (T/m)'],[
    ['All conditional screens',*[fmt(global_s[k]['value'],5) for k in ['B_norm_T','B_local_max_norm_T','G_frobenius_Tpm','G_max_abs_Tpm']]],
    ['Source-anchored subset',*[fmt(anchored[k]['value'],5) for k in ['B_norm_T','B_local_max_norm_T','G_frobenius_Tpm','G_max_abs_Tpm']]]],[160,76,78,83,83])
p('These are provisional applied-field targets under a local affine-field model. The large all-case gradient is controlled by the small SC(2)-0714 magnet and the transfer of Re=2 million section data to much lower-Re models. It is a conditional sizing screen, not a validated tunnel aerodynamic envelope or a coil-current specification.')
p('The source-anchored subset contains sphere, cuboid, Ahmed and crossflow-cylinder cases. It still includes explicit transfer assumptions, approximate graph readings and assumed cylinder mean drag. The narrower label describes provenance, not validation at 20% blockage.')
h2('Decisions incorporated')
p('The small magnet has 10% of the corresponding large magnet volume: each dimension is multiplied by 0.464159. Blockage is the maximum projected area over the selected attitudes, with one fixed model throughout each sweep. Vertical flow is upward. At 20% blockage, shorter spans are used where the original aspect ratios cannot fit. Each model retains the same residual non-magnet mass when magnet volume changes.')
p('A single permanent dipole cannot provide arbitrary six-axis control. Five auxiliary placement concepts are compared for each six-component cuboid/Ahmed model, with three automatic main-magnet axes per concept. Only arrangements accepted for every scenario enter the design envelope.')
page()

h('1. Coverage and literature audit')
p('The portfolio is broad enough for an initial load-mechanism screen: drag crisis, sharp-edge separated 3D loading, yaw/ground-effect wake changes, lifting sections, and phase-dependent forced translation. It does not establish a universal six-axis dynamic envelope: angular-motion bounds, gust spectra, peak six-component Ahmed switching histories, finite-wing loads and actuator dynamics remain outside the established evidence.')
table(['Source supplied','Role and selected points','Audit outcome'],[
['Achenbach 1972 [1]','Sphere; six Re/CD points spanning subcritical and post-crisis flow','Fig4, PDF p4 / printed p568. Approximate readings; added Re=300k before crisis.'],
['Jann & Geisbauer 2013 [2]','Body A 11:9:5; (alpha,beta)=(0,0),(0,-45),(25,-45),(45,-45),(90,-45)','Tables2/8, PDF pp11/17, recomputed Fourier sums. Six simultaneous coefficients.'],
['Meile 2011 [3]; 2016 [4]','35-deg Ahmed body, beta=0 and +15 deg','2016 Figs18/20 give approximate means. 12.5-deg switching lacks a paired six-component history.'],
['Carberry et al. 2001 [5]','A/D=.5, f/f0=.806,.869,1.04; before/after wake transition','Fig2a amplitude/phase and Eq2 used together. Mean drag is an explicit assumption.'],
['Morse & Williamson 2009, two papers [6,7]; Williamson & Roshko 1988 [8]','Wake/regime diversity and controlled-motion interpretation','Regime maps support selection, not an interchangeable six-channel load database.'],
['McAlister et al. 1978 [9]','NACA0012 dynamic-stall context','Re=2.5e6; most motion 15+10 sin(wt) deg, reduced frequency up to .25. Not a steady low-Re polar.'],
['Jenkins 1989 [10]','SC(2)-0714 identity and transonic data','M=.60-.76, alpha=-2..6 deg; cannot substantiate low-speed alpha=16 deg.'],
['Carberry et al. 2005, named in handover','Additional wake/force validation','Absent from Papers.zip. Ten PDFs supplied for eleven listed aerodynamic references.'],
['Sawada et al. 2004 [11]','Auxiliary-magnet / roll-control reference','Fig4, PDF p2, and pp2-3 establish main magnet plus pair-magnet roll control.']],[123,168,189])
p('Additional primary manuscripts were retrieved for the airfoil audit: NASA TM-81912 [12], Vaddi et al. [13], and Oruganti & Narsipur [14]. The supplied archive does not contain the Nishihara inline-force paper cited by the current cases. Its numerical rows remain unverified legacy screens. Source file hashes and page counts are retained locally; the research scripts recreate the inventory from the supplied archive.')
page()

h('2. Common coordinates and governing balance')
p('All output forces, moments, fields and gradients use one right-handed tunnel frame T: +x downstream, +z upward in the horizontal installation, and y completing the triad. Earth gravity is [0,0,-9.80665] m/s2. R_ET maps tunnel vectors to Earth. For upward flow R_ET=Ry(-90 deg), so gravity_T=[-9.80665,0,0] m/s2. Rotating the installation changes gravity; it does not change aerodynamic coefficient signs.')
eq('q = rho U^2 / 2;  Re = rho U L_Re / mu\nw_mag = [m a_C; I_T alpha + omega x (I_T omega)] - w_aero - w_gravity - w_other\nM_C = M_P + (r_P - r_C) x F   (all vectors in the same frame)')
p('Air uses rho=1.225 kg/m3 and mu=1.81e-5 Pa s; nu=1.477551e-5 m2/s. All speed/Re calculations use this same nu, replacing legacy metadata that sometimes used 1.5e-5. Reynolds number is computed from actual dimensions and speed; it is not a solver speed input.')
table(['Family','Source-to-tool conversion','Reference convention'],[
['Sphere','F_T=[D,0,0]; moments zero by symmetry assumption','S=pi D^2/4; L_Re=D; reference at geometric centre.'],
['DLR cuboid','Retain paper body Bp: x upstream, z downward. Q=diag(-1,1,-1). R_TBp=Q Rz(-beta) Ry(alpha). F_T=qS[CD,CY,CL]; M_T=R_TBp qSl[Cl,Cm,Cn].','S=l*w, all moments use l; moments about geometric centre. Q is a proper rotation.'],
['Ahmed','Body x downstream, z upward. Source positive beta points nose toward +y: R_TB=Rz(-beta). Rotate both body forces and body moments.','Aref=.112s^2; roll length=.327s; pitch/yaw length=.470s. Source floor datum retained and shifted to resolved CoM.'],
['Airfoils','Body x from leading to trailing edge; z upward. Positive AoA raises leading edge: R_TB=Ry(+AoA). Lift/drag already in T.','S=c*b; Cm about quarter chord at [-c/4,0,0]_B. Positive tool My is nose-up.'],
['Cylinder','Paper transverse y becomes +z_T; source lift sign and displacement phase both map together.','S=D*L; L_Re=D. Rigid-body inertia is separate from measured fluid force.']],[70,252,158])
p('The cuboid, Ahmed yaw and airfoil pitch conversions differ from legacy case assumptions. New constructors contain the corrected transformations; legacy files are preserved. The explicit attitude_R_TB input avoids Euler-angle ambiguities. NACA moment signs are treated as an uncertainty branch because the Vaddi text calls negative source Cm nose-up.')
page()

h('3. Sphere: extraction and complete worked example')
p('Achenbach Fig4 (PDF p4, printed p568) plots measured total drag coefficient against log Reynolds number. Read the smooth-sphere circle symbols against the linear CD axis and logarithmic Re axis. Values below are approximate visual samples, not high-precision digitisation. Indicative reading tolerances are about 0.01-0.02 in CD away from the crisis, with much larger Re-location uncertainty through the steep drop; no statistical confidence interval is inferred.')
table(['Re','CD used','Interpretation'],[[150000,.510,'Subcritical'],[250000,.500,'Subcritical'],[300000,.480,'Added pre-crisis high-drag point'],[370000,.070,'Near drag minimum'],[500000,.080,'Post-crisis'],[600000,.085,'Post-crisis']],[90,80,310])
fig('experiments-on-the_p4.png','Source evidence: Achenbach [1], Fig4, printed p568. Original graph; values are approximate.',crop=(.09,.075,.90,.39),maxheight=210)
r=state('sphere','T060_b10_h_v100','Re250000')
D=math.sqrt(4*.1*.6**2/math.pi);U=250000*(1.81e-5/1.225)/D;q=.5*1.225*U**2
eq(f'A_T=.6^2=.36 m2; S=.10 A_T=.036 m2; D=sqrt(4S/pi)={D:.9f} m\nU=Re mu/(rho D)={U:.7f} m/s; q={q:.6f} Pa\nD_force=q S CD={n(r,"Fx_aero_N"):.7f} N\nF_mag,req={vec(r,["Fx_mag_req_N","Fy_mag_req_N","Fz_mag_req_N"])} N\nB_C={vec(r,["Bx_T","By_T","Bz_T"])} T; ||G||F={fmt(r["G_frobenius_Tpm"],7)} T/m')
p(f'For {ids[r["case_id"]]}, selected {r["magnet_set_name"]}, total mass is {fmt(r["total_mass_kg"],7)} kg. Magnet moment uses Br=1.43 T and m_d=Br V/mu0, with mu0=4 pi 1e-7 and V={fmt(r["magnet_volume_m3"],7)} m3. A centred z magnet has Gxz=Fx/m_d and Gzz=Fz/m_d; minimum Frobenius norm gives Gxx=Gyy=-Gzz/2 and other free entries zero. Thus a zero torque case needs no CoM field, while its gravity force still needs a gradient.')
p('At fixed Re and blockage, U is inversely proportional to model diameter and aerodynamic drag is identical in the two geometrically similar tunnels. Magnet volume and weight are not identical. Points requiring U>50 m/s are omitted with their absent Re visible in the exported rows. The entire crisis is not bounded by these six discrete samples.')
page()

h('4. Cuboid: tabulated coefficients, axes and processing')
p('Use Body A, not Body B or the hemispherical shell. Source dimensions are 110 x 90 x 50 mm; S=9900 mm2 and l=110 mm (PDF p3). Source computations used approximately Re_l=165000, U=18 m/s (p5). The paper symmetrises rotating-URANS results to approximate steady zero-rate behaviour (pp9-10); it does not supply a measured six-axis history. Reynolds/Mach dependence is omitted by the source model. Repeating its coefficients over U=10,25,40,50 m/s is an explicit transfer assumption.')
eq('C(alpha) = a0 + sum_i [a_i cos(i alpha) + b_i sin(i alpha)]\nAt beta=0 use Table2 (p11); at beta=-45 deg use Table8 (p17).\nAngles enter trig functions in radians; retain all eight tabulated harmonics.')
table(['alpha,beta deg','CD','CY','CL','Cl_Bp','Cm_Bp','Cn_Bp'],[
['0,0','.375300','0','0','0','0','0'],['0,-45','.554500','.108900','0','0','0','.014200'],['25,-45','.743947','-.032449','.402542','.025319','.046606','.015231'],['45,-45','.894500','-.182400','.300200','.021991','.037300','.019104'],['90,-45','1.000900','-.374500','0','.043100','0','.000100']],[80,66,66,66,66,66,70])
fig('jann-geisbauer-201_p17.png','Source evidence: Jann & Geisbauer [2], Table8 and Table9, PDF p17. Table8 is transcribed in jannCoefficients.m.',crop=(.11,.08,.90,.47),maxheight=215)
eq('Example alpha=25, beta=-45 deg:\nR_TBp = [-.640856  .707107 -.298836;\n          .640856  .707107  .298836;\n          .422618  0       -.906308]')
r=state('cuboid','T060_b10_h_v100','U25_a25_b-45')
p(f'For {ids[r["case_id"]]} at U=25 m/s, dimensionalise force with q*l*w and moment with q*l*w*l, then rotate the source-body moment with the matrix above. The resulting aerodynamic force is {vec(r,["Fx_aero_N","Fy_aero_N","Fz_aero_N"])} N and moment about the resolved CoM is {vec(r,["Mx_aero_Nm","My_aero_Nm","Mz_aero_Nm"])} N m. Required magnetic force is {vec(r,["Fx_mag_req_N","Fy_mag_req_N","Fz_mag_req_N"])} N and moment is {vec(r,["Mx_mag_req_Nm","My_mag_req_Nm","Mz_mag_req_Nm"])} N m. All six remain paired in this one state.')
p('The largest selected cuboid projection sets model scale: Aproj=|nx|wh+|ny|lh+|nz|lw, n=R_TBp^T e_x. Scale all lengths by sqrt(beta*A_T/max(Aproj_unit)). Moments are not multiplied by planform span: all three source moment coefficients use l.')
page()

h('5. Ahmed body: yaw, datum and missing switching wrench')
p('Meile 2016 Fig1 (PDF p2, printed p35) supplies the 1044 x 389 x 288 mm outer dimensions, 50 mm ground clearance and support/datum dimensions. Section2.3 and Figs5-6 (PDF p4) distinguish wind-fixed and model-fixed measurements. Figs18 and20 (PDF pp9-10) are read at the same beta and U=30 m/s, giving paired mean body-axis coefficients. Approximate tolerance for these manual reads is 0.02-0.04 per component; zero lateral symmetry values are assumptions.')
table(['beta deg','CD','CS','CL','CMR','CMP','CMY'],[[0,.29,0,0,0,.08,0],[15,.43,.81,.57,.53,-.17,.26]],[78,67,67,67,67,67,67])
fig('1-s2.0-S0142727X15_p4.png','Source evidence: Meile [4], Fig5, PDF p4. Positive beta rotates downstream body x toward -y_T.',crop=(.07,.375,.49,.72),maxheight=195,width=235)
eq('s = model_length/1.044\nF_B = q (.112 s^2) [CD,CS,CL]\nM_P,B = q (.112 s^2) [.327s CMR, .470s CMP, .470s CMY]\nP_B = s [(.182+.202)-.522, 0, -(.050+.144)]\n    = s [-.138,0,-.194] m; R_TB=Rz(-beta)\nM_C,T = R_TB M_P,B + R_TB(P_B-r_C,B) x R_TB F_B')
p('The new body origin is the outer bounding-box centre. This gives P_x=-0.138s m from Fig1, rather than the legacy -0.085s m. The inscribed constant-section prism is x=100..822 mm from the nose, centred 61 mm forward of bounding-box centre. This declared proxy and datum choice are retained explicitly; a CAD-defined CoM would require a fresh reference conversion.')
r=state('ahmed','T060_b10_h_v100','U25_beta15_bodymag')
p(f'Example {ids[r["case_id"]]}, U=25 m/s, beta=15 deg: after rotation and the CoM shift the aerodynamic wrench is F={vec(r,["Fx_aero_N","Fy_aero_N","Fz_aero_N"])} N, M={vec(r,["Mx_aero_Nm","My_aero_Nm","Mz_aero_Nm"])} N m. The selected fixed arrangement is {r["magnet_set_name"]}. The reference point is a measurement datum on the floor, not a centre of pressure.')
p('Source means are reused at U=10,25,40 m/s as load-transfer screens, not measurements at those model Reynolds numbers. A comparable floor at 50s mm clearance is assumed. Rotating the tunnel vertically also rotates this floor/model arrangement conceptually; an isolated suspended body without the floor would need different aerodynamic data. The paper identifies switching near 12.5 deg and Re-dependent changes. It shows lift histories, but not a full synchronised six-component history suitable for a six-axis peak case. No invented six-component switching row is used.')
page()

h('6. Airfoils: what can and cannot be taken from the sources')
h2('SC(2)-0714')
p('The supplied Jenkins report is transonic. NASA TM-81912 was therefore obtained separately. Its Fig11, printed pp61,63,65 (PDF pp63,65,67), gives low-speed section lift, quarter-chord moment and drag polar at M=.15, fixed transition. The lowest source Re is 2 million. Approximate curve reads retained below are taken from the same Re curve; drag is read at the corresponding lift. They are transferred unchanged to the model Re and are not demonstrated conservative bounds.')
table(['AoA deg','CD','CL','Cm quarter chord','Status'],[[0,.012,.50,-.115,'Graph-read section screen'],[7,.0165,1.20,-.110,'Graph-read section screen'],[16,.043,1.84,-.067,'Near source high-lift/stall region; model stall not established']],[60,60,60,105,195])
fig('NASA_TM81912_p63.png','NASA TM-81912 [12], Fig11a, printed p61 / PDF p63. Circles are Re=2e6.',crop=(.08,.04,.92,.82),maxheight=180)
h2('NACA 0012')
p('Vaddi plasma-OFF Fig5 (PDF p8) gives approximately CL(.0)=0, CL(6)=.70, CL(8)=.90; CD(0)=.0122, CD(6)=.0140 and CD(8)=.0198 at Re=201k. Linear interpolation to 7 deg gives CL=.80 and CD=.0169. Source Cm(6) is about -.0052 and Cm(8) about -.0032, giving -.0042 at 7 deg. The paper calls negative moment nose-up. The constructor maps that prose to tool +My, and includes the opposite sign as a labelled convention-uncertainty branch.')
p('For 12 deg, lift is retained from legacy approximate reference-curve reads/interpolation associated with Oruganti & Narsipur. The obtained author manuscript places NACA0012 in Fig10, PDF p8 (the legacy file cites Fig17, a version-dependent locator). CD=.053 and Cm=0 at 12 deg remain engineering assumptions. Legacy Re-dependent CL rows are held during geometry scaling; they are not freshly validated polars at each new Re. This family remains a conditional screen.')
p('All section forces use planform c*b, not frontal blockage area. At 20% blockage, NACA AR is 1.25 and SC AR is 1.5, versus AR=3 at 3%/10%. Section coefficients applied to these short finite wings omit a validated induced-drag/tip-flow correction. The 20% variants quantify the stated proxy, not an experimentally verified finite-wing comparison.')
page()

h('7. Forced cylinders: phase-consistent fluid and inertia loads')
p('Carberry 2001 [5], PDF pp2-4 (printed pp524-526): water-channel U=.090 m/s, D=.0254 m, L=.3175 m, AR=12.5, Re=2300, stationary shedding frequency f0=.748 Hz. A/D=.5 and y=A sin(2 pi f t). Fig2a supplies simultaneous lift amplitude and phase. Choose three operating states around the transition; the source identifies .806 as low-frequency/2P and .869 as high-frequency/2S. The higher-frequency point extends force severity within the measured curve.')
table(['f/f0','CL amplitude','Phase deg','Approximate reading / interpretation'],[[.806,.26,160,'Small lift, nearly opposite displacement'],[.869,1.55,-20,'After abrupt wake/phase transition'],[1.04,2.25,-40,'High-frequency larger lift']],[66,85,70,259])
fig('1-s2.0-S0889974600_p4.png','Carberry [5], Fig2a, printed p526 / PDF p4: black dots are CL amplitude, diamonds are phase. Both are read at the same frequency.',crop=(.18,.40,.83,.64),maxheight=190)
eq('St0 = f0 D_source / U_source = .2111022\nD = H sqrt(beta/AR); L=AR D; U=Re mu/(rho D)\nf = (f/f0) St0 U/D; A=.5 D; theta=2 pi f t\nz=A sin(theta); vz=2 pi f A cos(theta); az=-(2 pi f)^2 z\nCL(theta)=CL_amp sin(theta+phi_lift); CD(theta)=1.2 (assumed)\nFz_mag = m az - qDL CL(theta) + m g    (horizontal tunnel)')
r=anchored['G_frobenius_Tpm'];p(f'The controlling source-anchored gradient state is {ids[r["case_id"]]}, {r["scenario_name"]}: U={fmt(r["speed_mps"],6)} m/s, f={fmt(r["frequency_Hz"],6)} Hz, Re={fmt(r["Re"],6)}, CL={fmt(r["CL"],6)}, a_z={fmt(r["a_Cz_T_mps2"],6)} m/s2. Required force is {vec(r,["Fx_mag_req_N","Fy_mag_req_N","Fz_mag_req_N"])} N. Its ||G||F={fmt(r["G_frobenius_Tpm"],7)} T/m occurs at one actual phase, not at independently selected aerodynamic/inertial extrema.')
p('The paper subtracts the structural inertial tare before reporting lift. Its fluid lift includes fluid acceleration effects. Accordingly no generic added-mass term is added; the actual MSBS model inertia is added separately in Newton-Euler balance. Graph readings are approximately +/-0.05 in CL at low amplitude, +/-0.1 at high amplitude, and +/-5-10 deg phase. These are reading estimates, not experimental uncertainty statistics.')
p('Air studies use Re=2300 and5000, with U<=7 m/s, AR=8 at 3%/10% and AR=4 at20%. Re=5000, changed aspect ratio/end conditions and confinement require transfer assumptions. The inline cases retain A/D=.05 and lambda*=1.7,2.2,2.7,3.5,5 with legacy mean/harmonic drag and phase; those exact coefficients cannot be verified from the supplied PDFs. Their labels are screening coordinates, not confirmed wake identities.')
page()
h('7a. Conditional input ledger and phase resolution')
p('The following inputs are exposed because a repeatable numerical result is not the same as a checked source extraction. The inline rows below are retained engineering screens from the existing case files. Their cited Nishihara Fig8/9 source is absent from the supplied archive. No claim is made that the numbers have been newly extracted from that paper.')
table(['lambda*=U/(fD)','Mean CD','Harmonic CD amplitude','Phase wrt displacement (deg)'],[[1.7,.95,1.05,5],[2.2,1.27,.50,20],[2.7,1.45,.25,0],[3.5,1.20,.12,35],[5,1.03,.10,-90]],[100,85,130,165])
eq('Inline: x=.05D sin(theta); ax=-(2 pi f)^2 x\nCD=CD_mean+CD_amp sin(theta+phi); f=U/(lambda*D)\nFx_mag=m ax-qDL CD-Fx_gravity; other aero components assumed zero')
p('The NACA12-deg legacy rows use CD=.053 and Cm=0 for all three speeds. The baseline0.6m/10% geometry uses CL=.8200,.8587746649,1.010157855 at U=10,25,40 m/s, respectively. They are associated with approximate low-Re reference-curve values, then held when the physical model is rescaled. Their many decimal places reflect arithmetic/interpolation, not source reading precision. Re is recalculated from the resized chord; coefficients are not represented as newly measured at that Re.')
p('The mean-drag-only crossflow assumption CD=1.2 omits drag harmonics and unsteady moments. Its three lift states use the paired amplitude/phase entries on the previous page. Inline and crossflow rigid-body inertia use the resolved model mass in each arrangement, not the source water-channel cylinder mass. Angular rates/accelerations are zero in these studies.')
phase=read(OUT/'phase_resolution.csv')
table(['Family','Samples/cycle','Max ||G||F (T/m)','Max entry (T/m)','Relative shortfall vs288'],[[r['family'].replace('cylinder_',''),r['phase_samples'],fmt(r['max_G_F_Tpm'],7),fmt(r['max_G_entry_Tpm'],7),fmt(r['relative_G_shortfall_vs_288'],3)] for r in phase],[100,90,105,90,95])
p('Resolution check: the0.6m/3% horizontal,10%-volume cylinder screens are rerun at72,144 and288 phase samples for each speed/state group. Their controlling gradient maxima agree at displayed precision. This verifies those sampled harmonic envelopes; it does not bound neglected source harmonics or coefficient uncertainty. The six extra runs are validation runs, additional to the168-study comparison.')
page()

h('8. Geometry, magnet size and five auxiliary concepts')
p('For square tunnel side H, A_T=H^2. The blockage parameter controls geometrically similar model size, never a force multiplier. At every selected attitude the orthographic projection and conservative wall envelope are checked. This is geometric blockage only; solid/wake blockage corrections to the aerodynamic coefficients are not invented.')
table(['Geometry','At 3% and10%','At20% / consequence'],[
['Sphere and cuboid','One uniformly scaled article per blockage/tunnel','Same shape; all selected attitudes fit.'],
['Ahmed','Bounded silhouette proxy at maximum yaw15 deg','Same aspect ratio and scaled source floor gap; mesh projection not integrated.'],
['Transverse cylinder','AR=8; L/H=sqrt(8 beta)','AR=8 would give L/H=1.265 and cannot fit. Approved AR=4 gives .8944.'],
['NACA0012 wing','AR=3; common geometry across0,7,12 deg','Approved AR=1.25. Span shortened, chord increased to restore20%.'],
['SC(2)-0714 wing','AR=3; common geometry across0,7,16 deg','Approved AR=1.5. Changes finite-wing applicability.']],[115,170,195])
p('Large single magnets occupy 95% of each dimension of the valid inscribed cuboid (85.7375% of its volume), allowing a geometric margin. They are large cuboid proxies, not a CAD-optimised magnet of arbitrary shape. The 10%-volume alternative scales all dimensions by .464159. The earlier 15%-of-tunnel magnet cap is not applied: the current request compares containment-limited magnets. Automatic +x_B,+y_B,+z_B magnetisations are alternative immutable builds, not three magnets installed together or a magnet turning independently inside a pitched model.')
p('For six-component cuboid/Ahmed loads, auxiliaries reserve space by using smaller separated components. d=[dx,dy,dz] is the valid inscribed cuboid; centres below are fractions of d relative to its centre. Dimensions are normalised fractions before equal-volume scaling. Auxiliary plus/minus dipoles cancel their uniform-field net moment and supply gradient-mediated torque. Main magnet axes are tested automatically. Some axis/layout combinations remain rank deficient and are rejected.')
table(['Layout','Centres and magnetisations','Dimensions / reason'],[
['L1','Main at0; pair at +/- .37dy e_y, dipoles +/-e_z','Main [.9,.4,.9]; pair each [.9,.22,.9]. Lateral lever plus transverse dipoles for roll authority.'],
['L2','Same lateral centres, dipoles +/-e_y','Same dimensions. Radial pair tests a different independent gradient-to-roll channel.'],
['L3','Main at0; pair at +/- .37dz e_z, dipoles +/-e_y','Main [.9,.9,.4]; pair [.9,.9,.22]. Vertical separation trades lateral room for height.'],
['L4','Same vertical centres, dipoles +/-e_z','Same dimensions. Radial vertical alternative.'],
['L5','Main at0; four auxiliaries at +/- .34dy e_y and +/- .34dz e_z. y pair +/-e_z; z pair +/-e_y','All five [.95,.32,.32]. Two moment arms distribute authority; cancellation can also worsen conditioning.']],[55,213,212])
p('All five layouts have equal total magnet volume .4864*V_envelope before the small-volume factor. L1-L4 dimensions are scaled by (.4864/.6804)^(1/3); L5 already has .4864. Volumes are matched across these five concepts, although they are smaller than the near-fill single magnet. Magnets remain disjoint and contained. Shrinking preserves centre separations. Sawada Fig4 motivates a main magnet plus pairs, but these dimensions, locations, N52 material and polarities are new engineering choices, not an asserted reconstruction of JAXA hardware.')
page()
h('8a. Physical dimensions and aerodynamic references')
geometries=read(OUT/'geometry_comparison.csv');geo_by_id={r['case_id']:r for r in geometries}
p('Dimensions below are for the0.6m tunnel. All lengths, magnet dimensions and offsets scale by5/3 for the1.0m tunnel at the same blockage; areas scale by25/9 and volumes by125/27. H/up flow has identical body/magnet geometry. The force reference area S is listed separately from projected blockage area. Body dimensions are in the family-specific body axes declared in Section2.')
data=[]
for family in names:
    for beta in [.03,.1,.2]:
        c=next(c for c in cases if c['family']==family and float(c['tunnel_side_m'])==.6 and float(c['blockage'])==beta and c['orientation']=='h' and float(c['volume_fraction'])==1)
        g=geo_by_id[c['case_id']]
        data.append([names[family],str(round(100*beta)), ' x '.join(fmt(float(g[k])*1000,4) for k in ['Lx_m','Ly_m','Lz_m']), ' x '.join(fmt(float(g[k])*1000,4) for k in ['envelope_x_m','envelope_y_m','envelope_z_m']),fmt(g['reference_area_m2'],6)])
table(['Family','beta%','Body extents (mm)','Inscribed cuboid (mm)','S (m2)'],data,[113,35,120,132,80])
p('For any row, large single-magnet dimensions are .95 times the inscribed-cuboid dimensions, while the10%-volume alternative is another factor .464159 smaller. Multi-magnet dimensions follow Section8 and the equal-volume factor. Exact selected magnet dimensions, centres, magnetisation vectors, CoM and inertia are exported in selected_geometry_and_magnets.json; no rounding from this table enters the solver.')
p(f'The final clearance audit reconstructs body origin as r_origin,T=r_C,T-R_TB*r_C,B for the selected fixed arrangement. It then tests the complete bounding envelope plus prescribed displacement at every scenario. The largest cross-section wall fraction is {max(float(g["maximum_wall_fraction_selected"]) for g in geometries):.6f}, below1 for all168 selected arrangements. This includes the actual off-centre CoM, rather than equating CoM and body origin.')
page()

h('9. Magnetic solution, fixed mass and field origin')
eq('B(rho) = B_C + G rho; G=G^T; trace(G)=0\nF_i=G m_i\nM_i=rho_i x (G m_i) + m_i x (B_C+G rho_i)\nx=[B_Cx,B_Cy,B_Cz,gxx,gyy,gxy,gxz,gyz]; A x=w_mag\nB_O = B_C - G r_C,T; one common G in both reference systems')
p('Local offsets rho_i are measured from each arrangement\'s resolved CoM. Translation changes the fixed-origin intercept B_O, not the local A or the common gradient. Cylinder positions and velocities are analytic and explicitly specified; no acceleration is integrated across independent rows. Absolute CoM is distinct from body-origin plotting placement. For pure harmonic helper motion, analytic position is supported only without angular oscillation.')
p('The source-free symmetric trace-free gradient has five independent degrees of freedom. Its orthonormal basis makes the norm equal to ||G||F. Force and moment residual equations have separate whole-study scales. The solver first minimises scaled wrench residual and then the configured magnetic norm. Passing residual does not establish coil or control-system feasibility.')
eq('J^2 = |B_C|^2 + (L_ref^2/12) ||G||F^2\nL_ref = max(model outer dimensions); u_proxy=J^2/(2 mu0)\nChosen fixed set = arg min_j max_k J_jk, accepted for every scenario k')
p('J is the analytic RMS affine field in a CoM-centred reference cube, and u_proxy is a vacuum-equivalent applied-field energy-density proxy. Neither is coil stored energy, power, current or voltage. Each physical case retains its own reference length. Cross-model J rankings therefore compare case-dependent regularisation; B and G targets are also reported separately. Significant-coupling sensitivity solves use alternate lengths already present in v0.4.1; they are exported separately.')
p('Magnet assumptions: generic N52 minimum Br=1.43 T, density7500 kg/m3, uniform magnetisation factor1. m_d=Br*V/mu0. For each physical body, residual mass=.30 times the near-fill large single magnet mass. This residual mass is then held fixed for all candidate layouts and both volume fractions. Total mass=magnet mass+residual mass. The residual is a uniform outer-primitive proxy about body origin; cavities are not subtracted. Per-magnet cuboid inertia and parallel-axis shifts are included. No CAD-derived shell or measured mass is claimed.')
p(f'Large near-fill magnets can make physically heavy test articles: selected total masses span {min(n(r,"total_mass_kg") for r in rows):.3g} to {max(n(r,"total_mass_kg") for r in rows):.3g} kg. These are consequences of the stated containment-limited solid-NdFeB comparison. Hardware mass, grade, packaging, demagnetisation and coil limits need independent design choices before procurement.')
page()

h('10. Tool audit, implemented changes and verification')
table(['Capability','Baseline v0.4.1','Action for this study'],[
['Paired 6-component states; frame rotation; moment shift; per-set mass/inertia','Available','Retained; corrected source case transformations in new constructors.'],
['STF field/gradient solve, residual acceptance, extrema, minimax/maximin','Available','Retained; design targets use only an accepted fixed set.'],
['Automatic magnetisation axes; manual auxiliaries','Available','Three main axes plus five engineered equal-volume layouts.'],
['Scenario relationship and ordered history semantics','Missing','Added independent/fixed_envelope/time_history; validate monotonic grouped timestamps.'],
['Absolute CoM / tunnel-origin field','Missing','Added nominal, specified and pure translational harmonic positions; export B_O=B_C-G r_C.'],
['Mass independent of magnet shrink','Only manual total overrides','Added mass.non_magnet_mass_kg; legacy factor remains backward-compatible.'],
['Source attitude without Euler ambiguity','Euler rows','Added attitude_R_TB proper-rotation cell input.'],
['Maximum attitude blockage, shorter-span models, batch comparison','Case-specific/manual','New reproducible research constructors and run manifest; added wall/sweep and layout-disjointness checks.'],
['Numerical acceleration integration, CAD projection, coil currents/dynamics','Missing','Deferred: not required for explicit analytic current motion; requires further physical data.']],[135,115,230])
p('Baseline repository commit: f4012c9060cb1cc6afe49fd9ccb42b80e7ac1a4d. All65 original tests passed before changes. Final suite:76 passed,0 failed,0 incomplete. New tests cover affine-origin field invariance, translation leaving local solve unchanged, harmonic position/acceleration consistency, grouped timestamp ordering, fixed residual mass under10%-volume shrink, source Fourier values, source rotations, auxiliary rank/equal volumes/no overlap, approved shorter-span clearance and upward gravity. Existing tests cover Newton-Euler gyroscopic demand, gradient constraints, moment shifts, load equivalence, ranking and exports.')
p('The first updated run exposed missing documentation entries, which were added before the passing final run. Scientific batches were recomputed after source sign and datum corrections. The batch does not substitute old saved results. Source files are hashed in the report build record. Code and report are published on the research branch; the final commit and delivery status are recorded in the OneDrive handover manifest.')
h2('Reproduce')
eq("MATLAB: cd('<repository>/MatLab/msbs_requirement_tool')\nrunAllTests\naddpath('src','cases','research'); run_portfolio\nPython: research/scripts/analyse_results.py\n        research/scripts/build_report.py")
p('Every study folder retains its exact study_input.mat, primary scenario CSV, per-set summary, extrema, both ranking tables, warnings and significant-coupling sensitivity results. The MAT input is directly runnable through runStudy. The global component-extrema CSV retains the complete simultaneous source/result row. The report is generated from current per-case files, with no mixing of independent component extrema into a new wrench.')
page()

h('11. Comparative results and interpretation')
table(['Family','Max local B (T)','Max ||G||F (T/m)','Controlling study / meaning'],[
    [names[f],fmt(max(float(c['max_B_local_T']) for c in cases if c['family']==f),5),fmt(max(float(c['max_G_F_Tpm']) for c in cases if c['family']==f),5),
     ids[max((c for c in cases if c['family']==f),key=lambda c:float(c['max_G_F_Tpm']))['case_id']]] for f in names],[155,90,110,125])
story.append(chart());p('Each line takes the harder of horizontal/upward for that family, tunnel size and magnet volume. The20% cylinder/airfoil points change aspect ratio and therefore are not a pure blockage-only continuation.','SmallMS')
p('Small magnets increase aerodynamic force per dipole and retain the same shell mass. For pure gravity, the near-fill versus10%-volume gradient ratio is approximately (0.4/0.1)/(1.3/1)=3.077 when both use the same direction and no torque coupling. Aerodynamic contributions can increase this further. At fixed U under uniform geometric scaling, aerodynamic G scales approximately1/model length, while aerodynamic torque/dipole field is approximately size-invariant; gravity-related field and coupling can have different scaling.')
p('The crossflow gradient maximum comes from prescribed acceleration and lift sharing the same phase. Frequency/acceleration are not controller-feasible merely because speeds are low. Horizontal and upward gravity can either add to or oppose a given aerodynamic demand. A larger speed is not always the controlling field state, especially for offset/auxiliary configurations where gradient torque and field torque trade off.')
page()

h('12. Per-component target maxima with original states')
p('The following are largest absolute signed entries over the selected immutable arrangements, including conditional airfoil/inline screens. Each row names the actual state that produces it. These entries define a component capacity envelope; using all their magnitudes simultaneously would create an untested field/gradient combination. CoM field B_C and fixed-origin intercept B_O are different quantities.')
metrics=[('Bx_T','B_Cx (T)'),('By_T','B_Cy (T)'),('Bz_T','B_Cz (T)'),('gxx_Tpm','Gxx (T/m)'),('gyy_Tpm','Gyy (T/m)'),('gzz_Tpm','Gzz (T/m)'),('gxy_Tpm','Gxy (T/m)'),('gxz_Tpm','Gxz (T/m)'),('gyz_Tpm','Gyz (T/m)'),('BOx_T','B_Ox (T)'),('BOy_T','B_Oy (T)'),('BOz_T','B_Oz (T)')]
table(['Quantity','Signed value at |max|','Study','Scenario','Selected arrangement'],[[label,fmt(global_s[k]['value'],7),ids[global_s[k]['case_id']],global_s[k]['scenario_name'],global_s[k]['magnet_set_name']] for k,label in metrics],[80,90,40,145,125])
h2('Controlling gradient: complete simultaneous state')
r=global_s['G_frobenius_Tpm']
p(f'{ids[r["case_id"]]} = {r["case_id"]}; {r["scenario_id"]} / {r["scenario_name"]}; {r["magnet_set_name"]}. U={fmt(r["speed_mps"])} m/s, model Re={fmt(r.get("Re",0),7)}, blockage3%, upward flow,10% magnet volume. The following values coexist in this state:')
eq(f'F_aero={vec(r,["Fx_aero_N","Fy_aero_N","Fz_aero_N"])} N\nM_aero,C={vec(r,["Mx_aero_Nm","My_aero_Nm","Mz_aero_Nm"])} N m\nF_gravity={vec(r,["Fx_gravity_N","Fy_gravity_N","Fz_gravity_N"])} N\nF_mag,req={vec(r,["Fx_mag_req_N","Fy_mag_req_N","Fz_mag_req_N"])} N\nM_mag,req={vec(r,["Mx_mag_req_Nm","My_mag_req_Nm","Mz_mag_req_Nm"])} N m\nB_C={vec(r,["Bx_T","By_T","Bz_T"])} T\nG=[{vec(r,["gxx_Tpm","gxy_Tpm","gxz_Tpm"])};\n   {vec(r,["gxy_Tpm","gyy_Tpm","gyz_Tpm"])};\n   {vec(r,["gxz_Tpm","gyz_Tpm","gzz_Tpm"])}] T/m')
p(f'Maximum residual across all selected rows is {summary["maximum_selected_residual"]:.3g}; acceptance threshold is1e-6. Rejected arrangements are retained in the candidate CSV but excluded from this envelope. component_extrema_full_states.csv also provides signed minima/maxima, source-anchored maxima and the wider envelope of every accepted fixed candidate.')
page()

h('13. Limits, assumptions and the next decisions')
p('The requested comparisons are computationally complete for the stated proxies. The report cannot turn unsupported inputs into validated aerodynamic evidence. In particular, the SC short-wing lower-Re transfer controls the largest targets; the inline harmonic coefficients lack a checked primary PDF; NACA12-deg drag/moment and its scaled-Re lift remain assumptions. The source-anchored subset should be used as a separate provisional engineering reference.')
table(['Assumption / limitation','Consequence and action'],[
['20% geometric blockage; no source-specific correction','Treat as confinement sensitivity. Obtain confined-model data/validated CFD before calling it a tunnel load prediction.'],
['Shorter span at20%','AR changes to4 /1.25 /1.5 for cylinder/NACA/SC. Hold aspect ratio fixed only when comparing3% versus10%.'],
['Approximate figure reads','Rounding is intentionally limited. Re-extract digital data for precision; repeat coupled amplitude/phase uncertainty studies before design margins.'],
['Constant coefficient transfer across speed/Re','Multiple speeds are tested, but this does not constitute multiple measured polars. Especially important for stall, drag crisis and Ahmed switching.'],
['Steady6D cases and prescribed cylinder translation','No quantified rotational dynamic envelope or closed-loop gust specification. Define angular amplitude/rate/acceleration demands separately.'],
['Only three automatic single-magnet axes','Best means best among enumerated candidates, not a global continuous orientation optimum. Positive and negative axes are equivalent for unconstrained symmetric field capacity; oblique axes remain a possible extension.'],
['Generic magnet properties / large solid magnets','Specify real magnet grade/part data and buildable shell mass. The thin airfoil magnet fit is a legacy proxy, not a fresh CAD containment proof.'],
['Common affine field and point-dipole abstraction','No coil maps, current/voltage/thermal limits, slew, field higher derivatives or control stability. Auxiliary centre fields differ from B_C.'],
['Model-dependent RMS objective','Selected configuration can change with reference length; significant-coupling sensitivity tables enable a separate robustness review. No universal coil-power optimum is claimed.']],[155,325])
p('Recommended next evidence step: obtain the Nishihara2005 full paper and a low-Re finite-wing SC(2)-0714 force/moment dataset (or validated CFD) for the actual short-span geometries. Then replace the conditional rows and rerun the same matrix. For Ahmed transition sizing, obtain synchronized six-axis data or specify a physically justified uncertainty model rather than combine unrelated mean and peak components.')
p('No numerical coil ratings or safety factor are assigned here. Any design margin must be chosen after separating aerodynamic uncertainty, magnet material uncertainty, trajectory bandwidth and actuator field-map limitations. A single “maximum field” without its tensor, position, fixed arrangement and original load state would conceal those distinctions.')
page()

h('14. References and source locations')
source_ref(1,'Achenbach (1972), Experiments on the flow past spheres at very high Reynolds numbers, JFM54,565-575. Fig4 p568; apparatus p566.','https://doi.org/10.1017/S0022112072000874')
source_ref(2,'Jann & Geisbauer (2013), Approximated Steady Aerodynamic Coefficients for Two Cuboids and a Hemispherical Shell Used in Airdrop Simulation, AIAA2013-1282. Geometry p3; axes Fig9 p9; Tables2/8 pp11/17.','https://doi.org/10.2514/6.2013-1282')
source_ref(3,'Meile et al. (2011 issue), Experiments and Numerical Simulations on the Aerodynamics of the Ahmed Body, CFD Letters3(1),32-39. Context/validation.','https://akademiabaru.com/submit/index.php/cfdl/article/view/3333')
source_ref(4,'Meile et al. (2016), Non-symmetric bi-stable flow around the Ahmed body, IJHFF57,34-47. Figs1,5,6,18,20; Section2.3; Section5.3.','https://doi.org/10.1016/j.ijheatfluidflow.2015.11.002')
source_ref(5,'Carberry, Sheridan & Rockwell (2001), Forces and wake modes of an oscillating cylinder, JFS15,523-532. Fig2a and Eq2 on p526; method pp524-525.','https://doi.org/10.1006/jfls.2000.0363')
source_ref(6,'Morse & Williamson (2009), Fluid forcing, wake modes, and transitions for a cylinder undergoing controlled oscillations, JFS25,697-712. Regime-map context.','https://doi.org/10.1016/j.jfluidstructs.2008.12.003')
source_ref(7,'Morse & Williamson (2009), Prediction of vortex-induced vibration response by employing controlled motion, JFM634,5-39. Controlled/free-motion interpretation.','https://www.cambridge.org/core/journals/journal-of-fluid-mechanics/article/abs/prediction-of-vortex-induced-vibration-response-by-employing-controlled-motion/5895EE0EFCECDC64607C687FE34F3C62')
source_ref(8,'Williamson & Roshko (1988), Vortex formation in the wake of an oscillating cylinder, JFS2,355-381. Wake topology context.','https://doi.org/10.1016/S0889-9746(88)90058-8')
source_ref(9,'McAlister, Carr & McCroskey (1978), Dynamic Stall Experiments on the NACA0012 Airfoil, NASA TP-1100. Experiment PDF p12.','https://ntrs.nasa.gov/citations/19780009057')
source_ref(10,'Jenkins (1989), NASA SC(2)-0714 Airfoil Data Corrected for Sidewall Boundary-Layer Effects, NASA TP-2890. Summary PDF p2.','https://ntrs.nasa.gov/citations/19890008197')
source_ref(11,'Sawada, Suda & Kunimasu (2004), NAL60cm Magnetic Suspension and Balance System, ICAS2004-3.1.2. Fig4 p2; roll discussion and Table1 p3.','https://www.icas.org/icas_archive/ICAS2004/PAPERS/182.PDF')
source_ref(12,'Harris, McGhee & Allison (1980), Low-Speed Aerodynamic Characteristics of a14-Percent-Thick NASA Phase2 Supercritical Airfoil Designed for a Lift Coefficient of0.7, NASA TM-81912. Fig11a/b/c printed pp61/63/65; PDF pp63/65/67.','https://ntrs.nasa.gov/api/citations/19830013896/downloads/19830013896_Redacted.pdf')
source_ref(13,'Vaddi et al., Active Flow Control of NACA0012 airfoil using Sawtooth Direct Current Augmented Dielectric Barrier Discharge Plasma Actuator, author manuscript. Fig5 PDF p8; passive curves only.','https://arxiv.org/abs/2106.11453')
source_ref(14,'Oruganti & Narsipur, Airfoil Lift Calculation Using Wind Tunnel Wall Pressures, author manuscript2006.09560. NACA reference curves Fig10 PDF p8.','https://arxiv.org/abs/2006.09560')
p('Unverified inline attribution: Nishihara, Kaneko & Watanabe (2005), JFS20,505-518, DOI10.1016/j.jfluidstructs.2005.02.003. Publication identity was located; the numerical Fig8/9 readings in the legacy cases were not checked against full text. The Carberry2005 reference from the handover is also not present in the supplied archive.','SmallMS')
p('Reproducibility paths (relative to tool root): research/outputs/study_manifest.csv; case_comparison.csv; selected_fixed_configuration_results.csv; all_scenario_results.csv; component_extrema_full_states.csv. Input MAT files and candidate/sensitivity outputs are in each case_id subfolder. Appendix study IDs below map directly to the full case names in the manifest.','SmallMS')

for fam in names:
    page();h('Appendix: '+names[fam]+' - every study')
    p('H=horizontal, U=upward flow. V%=magnet volume relative to the corresponding large version. B=max local magnet-centre norm; G=max tensor Frobenius norm over the fixed arrangement. An arrangement is chosen once for all speeds/attitudes/phases in that study. Model-dependent RMS field cost determines that choice.','SmallMS')
    data=[]
    for c in cases:
        if c['family']!=fam:continue
        data.append([ids[c['case_id']],c['tunnel_side_m'],str(round(100*float(c['blockage']))),c['orientation'].replace('h','H').replace('up','U'),str(round(100*float(c['volume_fraction']))),c['selected_set'].replace('Automatic ','').replace('layout','L').replace('_main_axis','/axis'),fmt(c['max_B_local_T'],4),fmt(c['max_G_F_Tpm'],4),fmt(c['total_mass_kg'],4)])
    table(['ID','H(m)','beta%','Flow','V%','Selected set','B(T)','G(T/m)','Mass(kg)'],data,[36,31,34,31,27,132,48,54,50])
    c0=next(c for c in cases if c['family']==fam)
    p('Study ID mapping: '+ '; '.join(ids[c['case_id']]+'='+c['case_id'] for c in cases if c['family']==fam),'SmallMS')
    p('Each reported maximum belongs to an actual result row. Component maxima and their complete six-component load/field states are in component_extrema_full_states.csv. For all candidates rather than the selected fixed set, inspect the per-case scenario and sensitivity CSVs.','SmallMS')

def footer(canvas,doc):
    canvas.saveState();canvas.setStrokeColor(colors.HexColor('#cad8de'));canvas.line(38,35,557,35)
    canvas.setFont('Helvetica',7);canvas.setFillColor(colors.HexColor('#526c79'))
    canvas.drawString(38,23,'MSBS aerodynamic requirement study | 6 November 2026 | Conditional engineering screen')
    canvas.drawRightString(557,23,str(doc.page));canvas.restoreState()

report=RESEARCH/'MSBS_Aerodynamic_Requirements_Report.pdf'
doc=SimpleDocTemplate(str(report),pagesize=A4,rightMargin=38,leftMargin=38,topMargin=38,bottomMargin=47,
    title='MSBS aerodynamic cases and magnetic requirements',author='MSBS research working record')
doc.build(story,onFirstPage=footer,onLaterPages=footer)
(RESEARCH/'MSBS_Aerodynamic_Requirements_Report.md').write_text('\n'.join(md),encoding='utf-8')
sources=list((ROOT/'src').rglob('*.m'))+list((RESEARCH/'+msbsstudy').glob('*.m'))+list((ROOT/'tests').glob('*.m'))+list((ROOT/'cases').glob('*.m'))+list((RESEARCH/'scripts').glob('*.py'))+list(RESEARCH.glob('*.m'))+list((ROOT/'data').glob('*.csv'))
hashes={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sources}
(RESEARCH/'report_build_record.json').write_text(json.dumps(dict(baseline_commit='f4012c9060cb1cc6afe49fd9ccb42b80e7ac1a4d',tests='76 passed, 0 failed, 0 incomplete',source_sha256=hashes,report_sha256=hashlib.sha256(report.read_bytes()).hexdigest()),indent=2),encoding='utf-8')
print(report)
