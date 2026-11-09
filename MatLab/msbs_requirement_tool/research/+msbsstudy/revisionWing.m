function [cfg,hasData] = revisionWing(cfg,H,blockage,family,AR)
%REVISIONWING Rectangular profile extrusion and isolated-wing test data.
arguments
    cfg (1,1) struct
    H (1,1) double
    blockage (1,1) double
    family (1,1) string = "naca0012"
    AR (1,1) double = 1
end
hasData=family=="naca0012" && AR==1;
angles=[0;10;25;45];
if ~hasData,angles=[0;7;16];end
[upper,lower]=localProfile(family);
profile=[upper;flipud(lower(2:end,:))];
profile(:,1)=profile(:,1)-.5;
projected=profile*[-sind(angles).';cosd(angles).'];
heights=max(projected,[],1)-min(projected,[],1);
c=H*sqrt(blockage/(AR*max(heights)));
span=AR*c;
if span>=H,error('msbsstudy:WingSpan','Selected wing span reaches or exceeds a tunnel wall.');end
S=c*span;
% Common box fits between the upper and lower ordinates throughout the
% selected chord interval. Include all piecewise-linear profile vertices.
lim=[.10 .55];
x=[lim(:);upper(upper(:,1)>lim(1)&upper(:,1)<lim(2),1); ...
    lower(lower(:,1)>lim(1)&lower(:,1)<lim(2),1)];
lo=max(interp1(lower(:,1),lower(:,2),x));
hi=min(interp1(upper(:,1),upper(:,2),x));
g=struct();
g.outer_dimensions_m=[c;span;(max(profile(:,2))-min(profile(:,2)))*c];
g.projected_area_m2=heights(1)*S;
g.reference_area_m2=S;
g.reference_length_m=c;
g.reference_span_m=span;
g.inscribed_cuboid_dimensions_m=[diff(lim)*c;.98*span;(hi-lo)*c];
g.inscribed_cuboid_centre_m=[mean(lim)-.5;0;mean([lo hi])]*c;
g.solid_profile_xz_m=profile*c;
[g.volume_m3,g.solid_centroid_B_m,g.solid_unit_density_inertia_B_m5]= ...
    msbsstudy.prismProperties(g.solid_profile_xz_m,span);
cfg.geometry.type="custom";
cfg.geometry.sizing.mode="absolute";
cfg.geometry.sizing.custom=g;
cfg.geometry.aero_reference_area.mode="manual";
cfg.geometry.aero_reference_area.value_m2=S;
cfg.geometry.aero_reference_length.mode="manual";
cfg.geometry.aero_reference_length.value_m=c;
cfg.geometry.aero_reference_span.mode="manual";
cfg.geometry.aero_reference_span.value_m=span;
cfg.geometry.aero_reference_point_B_m=[-.25*c;0;0];
cfg.meta.source_condition="Chinwicharnam and Thipyopas 2016 Fig 6, isolated wing AR=1";
if ~hasData,return,end

% Figure 6 a/b/c, respectively. Columns are the diamond, circle and square
% KU series. Reads are rounded to the source plot resolution.
Re=[129000 215000 300000];
CL=[0 0 0;.42 .40 .37;.88 .85 .82;.83 .80 .76];
CD=[.08 .06 .09;.13 .10 .12;.48 .45 .42;.87 .83 .81];
Cm=[0 0 0;-.008 -.015 -.016;.071 .064 .061;.148 .143 .147];
T=table();
for i=1:numel(Re)
    n=numel(angles);
    re=repmat(Re(i),n,1);
    U=re*(1.81e-5/1.225)/c;
    label="Re"+re+"_alpha"+angles;
    row=table(label,U,angles,zeros(n,1),zeros(n,1),CD(:,i),CL(:,i),Cm(:,i),re,repmat(c,n,1), ...
        repmat("ChinwicharnamThipyopas2016_Fig6_p7_KU",n,1),label,repmat(AR,n,1), ...
        'VariableNames',{'scenario_name','speed_mps','pitch_deg','yaw_deg','roll_deg','CD','CL','Cm','Re', ...
        'Re_length_m','source_id','operating_group','aspect_ratio'});
    T=[T;row]; %#ok<AGROW>
end
cfg.scenarios=T;
end

function [upper,lower]=localProfile(family)
if family=="naca0012"
    x=.5*(1-cos(linspace(0,pi,301).'));
    z=.6*(.2969*sqrt(x)-.1260*x-.3516*x.^2+.2843*x.^3-.1015*x.^4);
    upper=[x z];lower=[x -z];
else
    % NASA TP-2890 Table I, a subset of the measured ordinates on each face.
    upper=[0 0;.002 .0095;.005 .0158;.01 .0219;.02 .0293;.03 .0343;.05 .0411;.07 .0462; ...
        .10 .0518;.15 .0585;.20 .0632;.25 .0664;.30 .0685;.35 .0696;.38 .0698;.40 .0697; ...
        .45 .0692;.50 .0678;.55 .0656;.60 .0625;.65 .0585;.70 .0533;.75 .0469;.80 .0389; ...
        .85 .0294;.90 .0181;.95 .0049;.97 -.0009;.98 -.0039;.99 -.0071;1 -.0104];
    lower=[0 0;.002 -.0093;.005 -.016;.01 -.0221;.02 -.0295;.03 -.0344;.05 -.0412;.07 -.0462; ...
        .10 -.0517;.15 -.0585;.20 -.0633;.25 -.0666;.30 -.0687;.35 -.0696;.40 -.0692; ...
        .45 -.0676;.50 -.0644;.55 -.0588;.60 -.0509;.65 -.0410;.70 -.0302;.75 -.0192; ...
        .80 -.0093;.85 -.0027;.89 -.0008;.92 -.0016;.95 -.0049;.97 -.0085;.98 -.0109;.99 -.0137;1 -.0163];
end
end
