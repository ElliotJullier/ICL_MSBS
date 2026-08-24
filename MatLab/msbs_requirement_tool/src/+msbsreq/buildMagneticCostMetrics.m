function metrics = buildMagneticCostMetrics(geometry, tunnel, cfg)
%BUILDMAGNETICCOSTMETRICS Define primary and sensitivity magnetic cost metrics.
% Each metric is the RMS field over a centred isotropic reference cube:
%   J^2 = ||B0||^2 + (Lref^2/12) ||G||_F^2.
% The primary cube side is the largest resolved model outer dimension.
arguments
    geometry (1,1) struct
    tunnel (1,1) struct
    cfg (1,1) struct
end

Lmodel=max(geometry.outer_dimensions_B_m);
Lwt=sqrt(tunnel.area_m2);
primary=localMetric("model_characteristic_rms",Lmodel,"model",1.0,NaN,true);

allMetrics=primary;
weights=cfg.magnetic.cost.sensitivity_gradient_weight_factors(:).';
for alpha=weights
    if abs(alpha-1)<=1e-14,continue,end
    id="model_weight_"+localSafeNumber(alpha);
    allMetrics(end+1,1)=localMetric(id,alpha*Lmodel,"model_weight",alpha,NaN,false); %#ok<AGROW>
end
fractions=cfg.magnetic.cost.sensitivity_tunnel_length_fractions(:).';
for fraction=fractions
    id="tunnel_fraction_"+localSafeNumber(fraction);
    allMetrics(end+1,1)=localMetric(id,fraction*Lwt,"tunnel_fraction",NaN,fraction,false); %#ok<AGROW>
end
% Remove duplicate metric IDs while preserving user-specified order.
[~,keep]=unique(string({allMetrics.id}),'stable');
allMetrics=allMetrics(sort(keep));

metrics=struct();
metrics.primary=primary;
metrics.sensitivity=allMetrics;
metrics.model_characteristic_length_m=Lmodel;
metrics.tunnel_characteristic_length_m=Lwt;
metrics.definition="RMS field over a centred isotropic reference cube";
end

function metric=localMetric(id,Lref,source,weight,fraction,isPrimary)
if ~(isscalar(Lref)&&isfinite(Lref)&&Lref>0)
    error('msbsreq:InvalidMagneticReferenceLength','Magnetic reference cube side must be positive and finite.');
end
metric=struct();
metric.id=string(id);
metric.reference_source=string(source);
metric.reference_cube_side_m=Lref;
metric.gradient_equivalent_length_m=Lref/sqrt(12);
metric.gradient_weight_factor=weight;
metric.tunnel_length_fraction=fraction;
metric.is_primary=isPrimary;
metric.cost_definition="sqrt(||B0||_2^2 + (Lref^2/12)*||G||_F^2)";
end

function text=localSafeNumber(value)
text=replace(compose('%.6g',value),'.','p');
text=replace(text,'-','m');
text=replace(text,'+','');
end
