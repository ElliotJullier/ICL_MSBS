function cfg = standaloneCase(family,H,blockage,orientation,fraction,N)
%STANDALONECASE Operating-window portfolio with LW-PLA and air cylinder cases.
arguments
    family (1,1) string
    H (1,1) double
    blockage (1,1) double
    orientation (1,1) string
    fraction (1,1) double
    N (1,1) double = 72
end
if any(family==["cylinder_parked","cylinder_crossflow"])
    cfg=localCylinder(family,H,blockage,orientation,fraction,N);
elseif family=="cylinder_inline"
    error('msbsstudy:InlineEvidence', ...
        'Matsuda air response has no phase-resolved drag; Nishihara measured forced drag in water.');
else
    cfg=msbsstudy.revisionCase(family,H,blockage,orientation,fraction,N);
end
cfg.scenarios=cfg.scenarios(cfg.scenarios.speed_mps>=5 & cfg.scenarios.speed_mps<=50,:);
if isempty(cfg.scenarios)
    error('msbsstudy:OperatingWindow','No source-matched rows within 5–50 m/s.');
end
cfg.mass.solid_abs_density_kgm3=[];
cfg.mass.solid_body_density_kgm3=540;
cfg.meta.preferred_selection="fixed_hardware";
end

function cfg=localCylinder(family,H,b,orientation,fraction,N)
cfg=msbsreq.defaultConfig();
[parked,driven]=msbsstudy.airCylinderInputs();
nu=1.81e-5/1.225;
AR=3.2;
if family=="cylinder_crossflow",AR=4.5;end
D=H*sqrt(b/AR);
span=AR*D;
cfg.tunnel.cross_section.width_m=H;
cfg.tunnel.cross_section.height_m=H;
if orientation=="up",cfg.frames.tunnel_to_earth.yaw_pitch_roll_deg=[0 -90 0];end
cfg.geometry.type="cylinder";
cfg.geometry.sizing.mode="absolute";
cfg.geometry.sizing.cylinder_diameter_m=D;
cfg.geometry.sizing.cylinder_length_m=span;
cfg.geometry.sizing.cylinder_axis="y";
cfg.geometry.aero_reference_area.mode="manual";
cfg.geometry.aero_reference_area.value_m2=D*span;
cfg.output.enable=false;
cfg.visualisation.enable=false;
cfg.magnetic.cost.sensitivity_when_significant=false;
cfg.magnets.mode="manual_sets";
cfg.magnets.remanence_selection="minimum";
if family=="cylinder_parked"
    T=table("Re"+parked.Re,parked.Re*nu/D,parked.CD_mean,parked.Re,parked.CL_rms_context, ...
        'VariableNames',{'scenario_name','speed_mps','CD','Re','CL_rms_context'});
    T.operating_group=T.scenario_name;
    T.source_id=repmat("Ajmal2026_Table2_p4_stationary_mean",height(T),1);
    T.wall_envelope_fraction=repmat(max(D,span)/H,height(T),1);
else
    cfg.motion.mode="specified";
    cfg.motion.frame="T";
    cfg.position.mode="specified";
    cfg.scenario_set.relationship="time_history";
    T=localMotion(driven,D,span,H,nu,N);
end
cfg.scenarios=T;
cfg.scenarios.Re_length_m=repmat(D,height(T),1);
cfg.scenarios.Re_basis=repmat("source_matched",height(T),1);
cfg.scenarios.projected_blockage_ratio=repmat(b,height(T),1);
cfg.scenarios.aspect_ratio=repmat(AR,height(T),1);
cfg.meta=struct('family',family,'case_id',family+"_T"+compose('%03d',100*H)+"_b"+compose('%02d',100*b)+"_"+orientation+"_v"+100*fraction, ...
    'orientation',orientation,'tunnel_side_m',H,'target_maximum_blockage',b,'magnet_volume_fraction',fraction);
cfg=msbsreq.resolveConfig(cfg);
g=msbsreq.buildGeometry(cfg,msbsreq.buildTunnel(cfg));
cfg.magnets.sets=msbsstudy.cappedMagnets(g,H,{eye(3)},fraction,false);
end

function T=localMotion(driven,D,span,H,nu,N)
U=driven.Re(1)*nu/D;
freq=U./(D*driven.reduced_velocity);
amax=(2*pi*freq).^2.*driven.A_over_D*D;
maxAcceleration=50; % Preliminary study screen, not a facility rating.
keep=amax<=maxAcceleration & U>=5 & U<=50;
if ~any(keep)
    error('msbsstudy:MotionWindow','Blackburn Re160k at %.2f m/s; smallest reconstructed drive acceleration %.1f m/s² exceeds the 50 m/s² screen or speed is out of range.',U,min(amax));
end
phase=(0:N-1)'*2*pi/N;
T=table();
for k=find(keep).'
    w=2*pi*freq(k);
    % Phase origin at the lower displacement extremum gives +cos for a
    % and +sin for v, as in Blackburn Eq. 7.
    z=-driven.A_over_D(k)*D*cos(phase);
    v=driven.A_over_D(k)*D*w*sin(phase);
    lift=sqrt(2)*(driven.CL_a_rms(k)*cos(phase)+driven.CL_v_rms(k)*sin(phase));
    group=driven.state(k);
    row=table(group+"_phase"+(0:N-1)',repmat(U,N,1),zeros(N,1),lift,phase/w,phase,z,v,-w^2*z, ...
        'VariableNames',{'scenario_name','speed_mps','CD','CL','time_s','phase_rad','z_C_T_m','vz_C_T_mps','a_z'});
    for name=["x_C_T_m","y_C_T_m","vx_C_T_mps","vy_C_T_mps","a_x","a_y", ...
            "omega_x","omega_y","omega_z","alpha_x","alpha_y","alpha_z"]
        row.(name)=zeros(N,1);
    end
    row.operating_group=repmat(group,N,1);
    row.scenario_group_id=row.operating_group;
    row.Re=repmat(driven.Re(k),N,1);
    row.A_over_D=repmat(driven.A_over_D(k),N,1);
    row.reduced_velocity=repmat(driven.reduced_velocity(k),N,1);
    row.frequency_Hz=repmat(freq(k),N,1);
    row.acceleration_peak_mps2=repmat(amax(k),N,1);
    row.source_id=repmat("BlackburnMelbourne1997_Fig7_p422_motion_correlated_lift_only",N,1);
    row.wall_envelope_fraction=max(span,D+2*abs(z))/H;
    assert(all(row.wall_envelope_fraction<1));
    T=[T;row]; %#ok<AGROW>
end
end
