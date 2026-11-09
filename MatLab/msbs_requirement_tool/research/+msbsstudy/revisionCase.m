function cfg = revisionCase(family,H,blockage,orientation,fraction,N)
%REVISIONCASE Construct one source-matched portfolio configuration in SI.
arguments
    family (1,1) string
    H (1,1) double
    blockage (1,1) double
    orientation (1,1) string
    fraction (1,1) double
    N (1,1) double = 72
end
rho=1.225;
nu=1.81e-5/rho;
cfg=msbsreq.defaultConfig();
switch family
    case "sphere"
        cfg=msbsstudy.makeCase(family,H,blockage,orientation,fraction,N);
        cfg.scenarios.Re_length_m=repmat(cfg.geometry.sizing.diameter_m,height(cfg.scenarios),1);
        cfg.scenarios.operating_group=cfg.scenarios.scenario_name;
        cfg.meta.source_condition="Achenbach Fig 4, selected measured drag curve";
    case "cuboid"
        cfg=msbsstudy.makeCase(family,H,blockage,orientation,fraction,N);
        T=cfg.scenarios(1:5,:);
        d=cfg.geometry.sizing.nominal_dimensions_m;
        Re=165000;
        U=Re*nu/d(1);
        T=localRetarget(T,U,Re,d(1));
        T.scenario_name="alpha"+T.source_alpha_deg+"_beta"+T.source_beta_deg;
        T.operating_group=T.scenario_name;
        cfg.scenarios=T;
        cfg.meta.source_condition="Jann and Geisbauer 2013 fully turbulent URANS";
    case "ahmed"
        cfg=msbsstudy.makeCase(family,H,blockage,orientation,fraction,N);
        d=cfg.geometry.sizing.custom.outer_dimensions_m;
        % Trapezoidal rear roof, full-width prism, rounded nose omitted.
        xz=[-.522 -.144;.522 -.144;.522 .144-(1.044-.822)*tand(35);.300 .144;-.522 .144];
        R=msbsreq.rotationZYX([-15 0 0],"deg");
        points=R*localPrismVertices(xz,.389);
        [~,area]=convhull(points(2,:),points(3,:));
        scale=H*sqrt(blockage/area);
        f=1.044*scale/d(1);
        cfg=localAhmedGeometry(cfg,xz,scale,f);
        T=cfg.scenarios(1:2,:);
        % Approximate source Re from 30 m/s and the reported maximum Re
        % at 40 m/s in section 2.5. Preserve the source ground datum.
        Re=2.73e6*(30/40);
        U=Re*nu/(1.044*scale);
        T=localRetarget(T,U,Re,1.044*scale);
        T{:,["Fx_aero_N","Fy_aero_N","Fz_aero_N"]}=T{:,["Fx_aero_N","Fy_aero_N","Fz_aero_N"]}*f^2;
        T{:,["Mx_aero_Nm","My_aero_Nm","Mz_aero_Nm"]}=T{:,["Mx_aero_Nm","My_aero_Nm","Mz_aero_Nm"]}*f^3;
        T.aero_reference_point_B_m=repmat({cfg.geometry.aero_reference_point_B_m},height(T),1);
        T.scenario_name="yaw"+T.beta_deg;
        T.operating_group=T.scenario_name;
        T.source_id=repmat("Meile2016_Figs18_20_U30",height(T),1);
        cfg.scenarios=T;
        cfg.meta.source_condition="Meile Figs 18/20, fixed-ground transfer";
    case "cylinder_crossflow"
        if blockage>=.10
            error('msbsstudy:SourceSpan','AR=10 reaches or exceeds a tunnel wall at 10%% or 20%%.');
        end
        D=H*sqrt(blockage/10);
        cfg.geometry.type="cylinder";
        cfg.geometry.sizing.mode="absolute";
        cfg.geometry.sizing.cylinder_diameter_m=D;
        cfg.geometry.sizing.cylinder_length_m=10*D;
        cfg.geometry.sizing.cylinder_axis="y";
        cfg.geometry.aero_reference_area.mode="manual";
        cfg.geometry.aero_reference_area.value_m2=10*D^2;
        cfg.motion.mode="specified";
        cfg.motion.frame="T";
        cfg.position.mode="specified";
        cfg.scenario_set.relationship="time_history";
        cfg.scenarios=localMorse(D,4000*nu/D,N);
        cfg.meta.source_condition="Morse and Williamson, end-plate transfer; assumed mean drag";
    case "naca0012"
        [cfg,hasData]=msbsstudy.revisionWing(cfg,H,blockage);
        if ~hasData
            error('msbsstudy:WingEvidence','Finite-wing source digitisation is unavailable.');
        end
    otherwise
        error('msbsstudy:ExcludedEvidence','No usable load and geometry match for this family.');
end
if any(cfg.scenarios.speed_mps>50) && all(cfg.scenarios.speed_mps>50)
    error('msbsstudy:MatchedSpeed','Re-matched speed %.3g m/s exceeds 50 m/s.',min(cfg.scenarios.speed_mps));
end
cfg.scenarios=cfg.scenarios(cfg.scenarios.speed_mps<=50,:);
cfg.tunnel.cross_section.width_m=H;
cfg.tunnel.cross_section.height_m=H;
if orientation=="up",cfg.frames.tunnel_to_earth.yaw_pitch_roll_deg=[0 -90 0];end
cfg.output.enable=false;
cfg.visualisation.enable=false;
cfg.magnets.remanence_selection="minimum";
cfg.magnets.mode="manual_sets";
cfg.mass.non_magnet_mass_kg=[];
cfg.mass.solid_abs_density_kgm3=1050;
cfg.magnetic.cost.sensitivity_when_significant=false;
cfg.meta.family=family;
cfg.meta.case_id=family+"_T"+compose('%03d',100*H)+"_b"+compose('%02d',100*blockage)+"_"+orientation+"_v"+100*fraction;
cfg.meta.orientation=orientation;
cfg.meta.tunnel_side_m=H;
cfg.meta.target_maximum_blockage=blockage;
cfg.meta.magnet_volume_fraction=fraction;
cfg.meta.preferred_selection="static_swappable";
if family=="cylinder_crossflow",cfg.meta.preferred_selection="fixed_hardware";end
cfg=msbsreq.resolveConfig(cfg);
tunnel=msbsreq.buildTunnel(cfg);
geometry=msbsreq.buildGeometry(cfg,tunnel);
scenarios=msbsreq.buildScenarioTable(cfg);
attitudes=scenarios.R_TB.';
cfg.magnets.sets=msbsstudy.cappedMagnets(geometry,H,attitudes,fraction, ...
    any(family==["cuboid","ahmed","naca0012"]));
cfg.scenarios=localClearance(cfg,geometry,tunnel,scenarios);
cfg.scenarios.source_condition=repmat(cfg.meta.source_condition,height(cfg.scenarios),1);
cfg.scenarios.Re_basis=repmat("source_matched",height(cfg.scenarios),1);
assert(all(abs(cfg.scenarios.speed_mps.*cfg.scenarios.Re_length_m/nu-cfg.scenarios.Re)<1e-5));
end

function T=localRetarget(T,U,Re,L)
factor=(U./T.speed_mps).^2;
for n=["Fx_aero_N","Fy_aero_N","Fz_aero_N","Mx_aero_Nm","My_aero_Nm","Mz_aero_Nm"]
    T.(n)=T.(n).*factor;
end
T.speed_mps(:)=U;
T.Re=repmat(Re,height(T),1);
T.Re_length_m=repmat(L,height(T),1);
end

function cfg=localAhmedGeometry(cfg,xz,scale,f)
g=cfg.geometry.sizing.custom;
g.outer_dimensions_m=[1.044;.389;.288]*scale;
g.projected_area_m2=.389*.288*scale^2;
g.reference_area_m2=.112*scale^2;
g.reference_length_m=1.044*scale;
g.inscribed_cuboid_dimensions_m=[.722;.389;.288]*scale;
g.inscribed_cuboid_centre_m=[-.061;0;0]*scale;
g.solid_profile_xz_m=xz*scale;
[g.volume_m3,g.solid_centroid_B_m,g.solid_unit_density_inertia_B_m5]= ...
    msbsstudy.prismProperties(g.solid_profile_xz_m,.389*scale);
cfg.geometry.sizing.custom=g;
cfg.geometry.aero_reference_point_B_m=scale*[-.138;0;-.194];
cfg.geometry.aero_reference_area.value_m2=cfg.geometry.aero_reference_area.value_m2*f^2;
cfg.geometry.aero_reference_length.value_m=cfg.geometry.aero_reference_length.value_m*f;
cfg.geometry.aero_reference_span.value_m=cfg.geometry.aero_reference_span.value_m*f;
end

function T=localMorse(D,U,N)
reads=msbsstudy.morseInputs();
phi=(0:N-1)'*2*pi/N;
T=table();
for k=find(reads.run).'
    f=U/D*reads.fD_over_U(k);
    w=2*pi*f;
    z=reads.A_over_D(k)*D*sin(phi);
    wake=reads.wake(k);
    row=table(wake+"_phase"+string((0:N-1)'),repmat(U,N,1), ...
        repmat(1.2,N,1),reads.CY_fundamental(k)*sin(phi+deg2rad(reads.phase_deg(k))), ...
        phi/w,phi,z,reads.A_over_D(k)*D*w*cos(phi),-w^2*z, ...
        'VariableNames',{'scenario_name','speed_mps','CD','CL','time_s','phase_rad','z_C_T_m','vz_C_T_mps','a_z'});
    for name=["x_C_T_m","y_C_T_m","vx_C_T_mps","vy_C_T_mps","a_x","a_y", ...
            "omega_x","omega_y","omega_z","alpha_x","alpha_y","alpha_z"]
        row.(name)=zeros(N,1);
    end
    row.operating_group=repmat(wake,N,1);
    row.scenario_group_id=row.operating_group;
    row.Re=repmat(4000,N,1);
    row.Re_length_m=repmat(D,N,1);
    row.A_over_D=repmat(reads.A_over_D(k),N,1);
    row.fD_over_U=repmat(reads.fD_over_U(k),N,1);
    row.frequency_Hz=repmat(f,N,1);
    row.source_id=repmat("MorseWilliamson2009_"+reads.source_figure(k),N,1);
    T=[T;row]; %#ok<AGROW>
end
end

function T=localClearance(cfg,geometry,tunnel,scenarios)
T=cfg.scenarios;
d=geometry.outer_dimensions_B_m;
T.projected_blockage_ratio=zeros(height(T),1);
T.wall_envelope_fraction=zeros(height(T),1);
for k=1:height(T)
    R=scenarios.R_TB{k};
    shift=scenarios.r_C_T_m{k}(:);
    ext=abs(R)*d;
    switch geometry.type
        case "sphere"
            A=pi*d(1)^2/4;
        case "cylinder"
            A=d(1)*d(2);
        case "custom"
            p=R*localPrismVertices(geometry.shape.solid_profile_xz_m,d(2));
            [~,A]=convhull(p(2,:),p(3,:));
            % Bound the silhouette about the nominal model origin.
            ext=2*max(abs(p),[],2);
        otherwise
            A=dot(abs(R(1,:)),[d(2)*d(3) d(1)*d(3) d(1)*d(2)]);
    end
    T.projected_blockage_ratio(k)=A/tunnel.area_m2;
    T.wall_envelope_fraction(k)=max((ext(2:3)+2*abs(shift(2:3)))/tunnel.width_m);
end
if any(T.wall_envelope_fraction>=1)
    error('msbsstudy:WallClearance','Model motion reaches a test-section wall.');
end
end

function p=localPrismVertices(xz,span)
n=size(xz,1);
p=[xz(:,1) -ones(n,1)*span/2 xz(:,2);xz(:,1) ones(n,1)*span/2 xz(:,2)].';
end
