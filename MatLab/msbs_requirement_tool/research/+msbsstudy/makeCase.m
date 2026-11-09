function cfg = makeCase(family,tunnelSide,blockage,orientation,magnetVolumeFraction,phaseSamples)
%MAKECASE Reproducible literature/screening cases, parameters always in SI.
% Blockage is the maximum tested projected area. Geometry never varies by row.
if nargin<6,phaseSamples=72;end
root=string(fileparts(fileparts(fileparts(mfilename('fullpath')))));
rho=1.225;mu=1.81e-5;nu=mu/rho;
family=string(family); cfg=msbsreq.defaultConfig();
cfg.tunnel.cross_section.width_m=tunnelSide;cfg.tunnel.cross_section.height_m=tunnelSide;
cfg.visualisation.enable=false;cfg.output.enable=false;
cfg.magnets.remanence_selection="minimum";
cfg.scenario_set.relationship="fixed_envelope";
cfg.meta.family=family;cfg.meta.magnet_volume_fraction=magnetVolumeFraction;
cfg.meta.target_maximum_blockage=blockage;
cfg.meta.evidence_status="source_fit_with_transfer_assumptions";
switch family
    case "sphere"
        D=sqrt(4*blockage*tunnelSide^2/pi);
        cfg.geometry.type="sphere";cfg.geometry.sizing.mode="absolute";cfg.geometry.sizing.diameter_m=D;
        % Add a pre-crisis point that the five legacy points omit.
        Re=[150000;250000;300000;370000;500000;600000]; CD=[.510;.500;.480;.070;.080;.085];
        U=Re*nu/D;keep=U<=50;Re=Re(keep);CD=CD(keep);U=U(keep);
        cfg.scenarios=table("Re"+string(Re),U,CD,Re,'VariableNames',{'scenario_name','speed_mps','CD','Re'});
        cfg.scenarios.source_id=repmat("Achenbach1972_Fig4_p568_approx",height(cfg.scenarios),1);
        cfg.meta.evidence_status="approximate_figure_read_with_transfer_assumptions";
    case "cuboid"
        states=[0 0;0 -45;25 -45;45 -45;90 -45]; d=[11;9;5];
        Q=diag([-1 1 -1]);R=cell(5,1);ap=zeros(5,1);
        for k=1:5
            R{k}=Q*msbsreq.rotationZYX([-states(k,2) states(k,1) 0],"deg");
            n=abs(R{k}.'*[1;0;0]);ap(k)=dot(n,[d(2)*d(3);d(1)*d(3);d(1)*d(2)]);
        end
        d=d*sqrt(blockage*tunnelSide^2/max(ap));
        cfg.geometry.type="cuboid";cfg.geometry.sizing.mode="absolute";cfg.geometry.sizing.nominal_dimensions_m=d;
        cfg.geometry.aero_reference_area.mode="manual";cfg.geometry.aero_reference_area.value_m2=d(1)*d(2);
        cfg.geometry.aero_reference_length.mode="manual";cfg.geometry.aero_reference_length.value_m=d(1);
        cfg.aero.mode="direct_wrench";cfg.aero.direct_wrench_frame="T";T=table();
        for U=[10 25 40 50]
            for k=1:5
                C=msbsstudy.jannCoefficients(states(k,1),states(k,2));
                F=.5*rho*U^2*prod(d(1:2))*C(1:3).';
                M=R{k}*(.5*rho*U^2*prod(d(1:2))*d(1)*C(4:6).');
                row=table("U"+U+"_a"+states(k,1)+"_b"+states(k,2),U,F(1),F(2),F(3),M(1),M(2),M(3),R(k),rho*U*d(1)/mu, ...
                    states(k,1),states(k,2),"Jann2013_Table2p11_Table8p17", ...
                    'VariableNames',{'scenario_name','speed_mps','Fx_aero_N','Fy_aero_N','Fz_aero_N','Mx_aero_Nm','My_aero_Nm','Mz_aero_Nm','attitude_R_TB','Re','source_alpha_deg','source_beta_deg','source_id'});
                T=[T;row]; %#ok<AGROW>
            end
        end
        cfg.scenarios=T;
    case "ahmed"
        cfg=case_ahmed35_meile_bodymag_yaw_t06_h();
        cfg=localScaleLegacy(cfg,tunnelSide,blockage);
        % Define new B origin at bounding-box centre, x downstream, z upward.
        % Source Fig1: floor datum is x=182+202=384 mm from the nose.
        scale=cfg.geometry.sizing.custom.outer_dimensions_m(1)/1.044;
        P=scale*[-.138;0;-.194];
        cfg.geometry.aero_reference_point_B_m=P;
        cfg.scenarios.aero_reference_point_B_m=repmat({P},height(cfg.scenarios),1);
        % Meile Fig5: positive beta turns the nose toward +y, hence the
        % downstream-pointing body x axis rotates toward -y in T.
        cfg.scenarios.yaw_deg=-cfg.scenarios.beta_deg;
        % Current legacy rows use approximate readings from Figs18/20.
        cfg.meta.evidence_status="approximate_figure_read_with_transfer_assumptions";
    case {"naca0012","sc20714"}
        cfg=feval("case_"+family+"_chordmag_a00_t06_h");T=cfg.scenarios;
        if family=="naca0012",angles=[7 12];else,angles=[7 16];end
        for a=angles
            other=feval("case_"+family+"_chordmag_a"+compose('%02d',a)+"_t06_h");T=[T;other.scenarios]; %#ok<AGROW>
        end
        cfg.scenarios=T;cfg=localScaleLegacy(cfg,tunnelSide,blockage);
        % +x_B is leading edge to trailing edge, +z_B upward. Positive AoA
        % raises the leading edge, so R_y(+AoA), not the legacy -AoA.
        cfg.scenarios.pitch_deg=abs(cfg.scenarios.pitch_deg);
        if family=="naca0012"
            % Vaddi PDF p8 calls negative source Cm nose-up. Map that prose
            % to tool +My (nose-up), and also retain the opposite sign as an
            % explicitly labelled convention-uncertainty branch.
            cfg.scenarios.Cm=-cfg.scenarios.Cm;
            alt=cfg.scenarios(cfg.scenarios.pitch_deg==7,:);
            alt.Cm=-alt.Cm;alt.scenario_name=alt.scenario_name+"_Cm_sign_alternative";
            alt.source_id=alt.source_id+"_moment_sign_uncertainty";
            cfg.scenarios=[cfg.scenarios;alt];
        end
        if blockage==.20
            if family=="naca0012",AR=1.25;else,AR=1.5;end
            cfg=localShortenAirfoil(cfg,AR);
            cfg.meta.aspect_ratio=AR;
        else
            cfg.meta.aspect_ratio=3;
        end
        % All attitudes of one article are solved with one immutable magnet.
        cfg.meta.evidence_status="legacy_engineering_screen_not_source_verified";
    case {"cylinder_crossflow","cylinder_inline"}
        AR=8;if blockage==.20,AR=4;end
        cfg.meta.aspect_ratio=AR;
        D=tunnelSide*sqrt(blockage/AR);L=AR*D;
        if L>=tunnelSide,error('msbsstudy:SpanExceedsTunnel','AR=8 cylinder span exceeds tunnel at this blockage.');end
        cfg.geometry.type="cylinder";cfg.geometry.sizing.mode="absolute";
        cfg.geometry.sizing.cylinder_diameter_m=D;cfg.geometry.sizing.cylinder_length_m=L;cfg.geometry.sizing.cylinder_axis="y";
        cfg.motion.mode="specified";cfg.position.mode="specified";cfg.scenario_set.relationship="time_history";
        T=table();phi=(0:phaseSamples-1)'*2*pi/phaseSamples;N=numel(phi);
        if family=="cylinder_crossflow"
            % Carberry2001 PDF p4 Fig2a, approximate paired black/diamond readings.
            states=[.806 .26 160;.869 1.55 -20;1.04 2.25 -40];
            St=.748*.0254/.090;AD=.5;
        else
            % Nishihara2005 source not in supplied archive: retained as screen.
            states=[1.7 .95 1.05 5;2.2 1.27 .5 20;2.7 1.45 .25 0;3.5 1.2 .12 35;5 1.03 .1 -90];AD=.05;
            cfg.meta.evidence_status="legacy_engineering_screen_not_source_verified";
        end
        for Re=[2300 5000]
            U=Re*nu/D;if U>7,continue,end
            for k=1:size(states,1)
                CD=1.2*ones(N,1);CL=zeros(N,1);ax=zeros(N,1);az=ax;x=ax;z=ax;vx=ax;vz=ax;
                if family=="cylinder_crossflow"
                    f=states(k,1)*St*U/D;CL=states(k,2)*sin(phi+deg2rad(states(k,3)));
                    source="Carberry2001_p526_Fig2a_Eq2_drag_assumed_1p2";
                    om=2*pi*f;z=AD*D*sin(phi);vz=AD*D*om*cos(phi);az=-om^2*z;
                else
                    f=U/(states(k,1)*D);CD=states(k,2)+states(k,3)*sin(phi+deg2rad(states(k,4)));
                    source="Nishihara2005_legacy_unverified";
                    om=2*pi*f;x=AD*D*sin(phi);vx=AD*D*om*cos(phi);ax=-om^2*x;
                end
                group="Re"+Re+"_state"+k;
                row=table(group+"_phase"+string((0:N-1)'),repmat(U,N,1),CD,CL,phi/om,repmat(group,N,1), ...
                    x,zeros(N,1),z,vx,zeros(N,1),vz,ax,zeros(N,1),az, ...
                    'VariableNames',{'scenario_name','speed_mps','CD','CL','time_s','scenario_group_id','x_C_T_m','y_C_T_m','z_C_T_m','vx_C_T_mps','vy_C_T_mps','vz_C_T_mps','a_x','a_y','a_z'});
                for name=["omega_x","omega_y","omega_z","alpha_x","alpha_y","alpha_z"],row.(name)=zeros(N,1);end
                row.source_id=repmat(source,N,1);row.Re=repmat(Re,N,1);
                row.A_over_D=repmat(AD,N,1);row.frequency_Hz=repmat(f,N,1);row.phase_rad=phi;
                row.source_state_parameter=repmat(states(k,1),N,1);
                T=[T;row]; %#ok<AGROW>
            end
        end
        cfg.scenarios=T;
        if family=="cylinder_crossflow",cfg.meta.evidence_status="paired_lift_figure_read_drag_assumed_transfer";end
end
cfg=msbsreq.resolveConfig(cfg);
cfg.tunnel.cross_section.width_m=tunnelSide;cfg.tunnel.cross_section.height_m=tunnelSide;
switch string(orientation)
    case "h",cfg.frames.tunnel_to_earth.yaw_pitch_roll_deg=[0 0 0];
    case "up",cfg.frames.tunnel_to_earth.yaw_pitch_roll_deg=[0 -90 0];
    otherwise,error('msbsstudy:InvalidOrientation','Use h or up.');
end
cfg.meta.family=family;cfg.meta.magnet_volume_fraction=magnetVolumeFraction;
cfg.meta.target_maximum_blockage=blockage;cfg.meta.orientation=string(orientation);
cfg.meta.case_id=family+"_T"+compose('%03d',round(100*tunnelSide))+"_b"+compose('%02d',round(100*blockage))+"_"+orientation+"_v"+round(100*magnetVolumeFraction);
cfg.output.enable=false;cfg.visualisation.enable=false;
cfg.magnets.remanence_selection="minimum";
cfg=msbsreq.resolveConfig(cfg);tunnel=msbsreq.buildTunnel(cfg);geo=msbsreq.buildGeometry(cfg,tunnel);
cfg.magnets.mode="automatic";cfg.magnets.automatic.direction_candidates_B=eye(3);
cfg.magnets.automatic.centre_offset_B_m=zeros(3,1);cfg.magnets.automatic.dipole_moment_override_Am2=[];
cfg.magnets.automatic.linear_shrink_fraction=.05;
% Shell mass anchored to large maximum-fit magnet, then held fixed across all sets/sizes.
[big,~]=msbsreq.buildMagnetSets(cfg,geo,root);
cfg.mass.non_magnet_mass_kg=.30*big(1).magnets.mass_kg;
cfg.mass.total_mass_override_kg=[];cfg.mass.inertia_override_B_kgm2=[];cfg.mass.centre_of_mass_override_B_m=[];
cfg.magnets.automatic.linear_shrink_fraction=1-.95*magnetVolumeFraction^(1/3);
% Three automatic single magnets plus five auxiliary placement concepts.
if any(family==["cuboid","ahmed"])
    [singles,~]=msbsreq.buildMagnetSets(cfg,geo,root);
    sets=struct([]);
    for k=1:3
        m=singles(k).magnets;
        keep={'name','dimensions_local_m','centre_B_m','R_BM','grade','magnetisation_direction_M'};
        sets(k).name="single_axis"+k;sets(k).magnets=rmfield(m,setdiff(fieldnames(m),keep));
    end
    cfg.magnets.sets=[sets msbsstudy.auxiliaryLayouts(geo.inscribed_cuboid.dimensions_B_m,geo.inscribed_cuboid.centre_B_m,magnetVolumeFraction)];
    cfg.magnets.mode="manual_sets";
end
cfg.scenarios.evidence_status=repmat(string(cfg.meta.evidence_status),height(cfg.scenarios),1);
cfg.scenarios.blockage_target=repmat(blockage,height(cfg.scenarios),1);
if isfield(cfg.meta,'aspect_ratio'),cfg.scenarios.aspect_ratio=repmat(cfg.meta.aspect_ratio,height(cfg.scenarios),1);end
cfg.scenarios=msbsstudy.checkClearance(cfg,geo,tunnel);
end

function cfg=localShortenAirfoil(cfg,AR)
% Keep c:b:t shape except for b/c, then uniformly resize to restore blockage.
f=sqrt(3/AR);g=cfg.geometry.sizing.custom;
g.outer_dimensions_m=g.outer_dimensions_m*f;g.outer_dimensions_m(2)=g.outer_dimensions_m(1)*AR;
g.inscribed_cuboid_dimensions_m=g.inscribed_cuboid_dimensions_m*f;
g.inscribed_cuboid_centre_m=g.inscribed_cuboid_centre_m*f;
g.reference_length_m=g.reference_length_m*f;
g.volume_m3=g.volume_m3*f^3*(AR/3);
cfg.geometry.sizing.custom=g;
cfg.geometry.aero_reference_length.value_m=cfg.geometry.aero_reference_length.value_m*f;
cfg.geometry.aero_reference_span.value_m=g.outer_dimensions_m(2);
cfg.geometry.aero_reference_point_B_m=cfg.geometry.aero_reference_point_B_m*f;
cfg.scenarios.Re=cfg.scenarios.speed_mps*g.reference_length_m/(1.81e-5/1.225);
end

function cfg=localScaleLegacy(cfg,H,beta)
f=(H/.6)*sqrt(beta/.10);g=cfg.geometry.sizing.custom;
for name=string(fieldnames(g)).'
    if contains(name,'area'),g.(name)=g.(name)*f^2;
    elseif contains(name,'volume'),g.(name)=g.(name)*f^3;
    elseif isnumeric(g.(name)),g.(name)=g.(name)*f;end
end
cfg.geometry.sizing.custom=g;
cfg.geometry.aero_reference_area.value_m2=cfg.geometry.aero_reference_area.value_m2*f^2;
cfg.geometry.aero_reference_length.value_m=cfg.geometry.aero_reference_length.value_m*f;
cfg.geometry.aero_reference_span.value_m=cfg.geometry.aero_reference_span.value_m*f;
cfg.geometry.aero_reference_point_B_m=cfg.geometry.aero_reference_point_B_m*f;
T=cfg.scenarios;
for name=["Fx_aero_N","Fy_aero_N","Fz_aero_N"],if ismember(name,T.Properties.VariableNames),T.(name)=T.(name)*f^2;end,end
for name=["Mx_aero_Nm","My_aero_Nm","Mz_aero_Nm"],if ismember(name,T.Properties.VariableNames),T.(name)=T.(name)*f^3;end,end
if ismember('aero_reference_point_B_m',T.Properties.VariableNames),T.aero_reference_point_B_m=cellfun(@(p)p*f,T.aero_reference_point_B_m,'UniformOutput',false);end
if ismember('Re',T.Properties.VariableNames),T.Re=T.speed_mps*g.reference_length_m/(1.81e-5/1.225);end
if ismember('Re_L',T.Properties.VariableNames),T.Re_L=T.speed_mps*g.outer_dimensions_m(1)/(1.81e-5/1.225);end
cfg.scenarios=T;
end
