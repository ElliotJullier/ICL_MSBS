function metrics = buildMagneticCostMetrics(geometry, tunnel, cfg)
%BUILDMAGNETICCOSTMETRICS Define primary and sensitivity magnetic cost metrics.
% Primary metric: RMS affine-field magnitude over a centred isotropic cube
% whose side is the largest resolved model outer dimension.
% Sensitivity metrics are deliberately split into two families:
%   1) relative B/G length-scale costs, Jrel^2=||B0||^2+ell^2||G||_F^2;
%   2) reference-volume RMS-field costs, where ell=Lref/sqrt(12).
arguments
    geometry (1,1) struct
    tunnel (1,1) struct
    cfg (1,1) struct
end

Lmodel=max(geometry.outer_dimensions_B_m);
Lwt=sqrt(tunnel.area_m2);
primary=localVolumeMetric("volume_model_characteristic",Lmodel,"model",NaN,true);

allMetrics=primary;
relativeLengths=cfg.magnetic.cost.sensitivity_relative_length_scales_m(:).';
for ell=relativeLengths
    id="relative_length_"+localSafeNumber(ell)+"m";
    allMetrics(end+1,1)=localRelativeMetric(id,ell,false); %#ok<AGROW>
end
fractions=cfg.magnetic.cost.sensitivity_tunnel_length_fractions(:).';
for fraction=fractions
    id="volume_tunnel_fraction_"+localSafeNumber(fraction);
    allMetrics(end+1,1)=localVolumeMetric(id,fraction*Lwt,"tunnel_fraction",fraction,false); %#ok<AGROW>
end

% Remove duplicate IDs while preserving configured order.
[~,keep]=unique(string({allMetrics.id}),'stable');
allMetrics=allMetrics(sort(keep));

metrics=struct();
metrics.primary=primary;
metrics.sensitivity=allMetrics;
metrics.model_characteristic_length_m=Lmodel;
metrics.tunnel_characteristic_length_m=Lwt;
metrics.primary_definition="RMS affine-field magnitude over a centred isotropic model-scale cube";
metrics.relative_definition="Field-equivalent relative cost sqrt(||B0||^2 + ell^2||G||_F^2)";
end

function metric=localVolumeMetric(id,Lref,source,fraction,isPrimary)
if ~(isscalar(Lref)&&isfinite(Lref)&&Lref>0)
    error('msbsreq:InvalidMagneticReferenceLength','Magnetic reference cube side must be positive and finite.');
end
metric=localBaseMetric();
metric.id=string(id);
metric.metric_type="reference_volume_rms";
metric.reference_source=string(source);
metric.reference_cube_side_m=Lref;
metric.relative_length_scale_m=NaN;
metric.gradient_equivalent_length_m=Lref/sqrt(12);
metric.tunnel_length_fraction=fraction;
metric.is_primary=isPrimary;
metric.cost_definition="sqrt(||B0||_2^2 + (Lref^2/12)*||G||_F^2)";
metric.cost_interpretation="RMS affine-field magnitude over centred reference cube";
end

function metric=localRelativeMetric(id,ell,isPrimary)
if ~(isscalar(ell)&&isfinite(ell)&&ell>0)
    error('msbsreq:InvalidMagneticRelativeLength','Relative field/gradient length scale must be positive and finite.');
end
metric=localBaseMetric();
metric.id=string(id);
metric.metric_type="relative_length";
metric.reference_source="relative_weight";
metric.reference_cube_side_m=NaN;
metric.relative_length_scale_m=ell;
metric.gradient_equivalent_length_m=ell;
metric.tunnel_length_fraction=NaN;
metric.is_primary=isPrimary;
metric.cost_definition="sqrt(||B0||_2^2 + ell^2*||G||_F^2)";
metric.cost_interpretation="Relative field/gradient regularisation using one length scale ell";
end

function metric=localBaseMetric()
metric=struct('id',"",'metric_type',"",'reference_source',"", ...
    'reference_cube_side_m',NaN,'relative_length_scale_m',NaN, ...
    'gradient_equivalent_length_m',NaN,'tunnel_length_fraction',NaN, ...
    'is_primary',false,'cost_definition',"",'cost_interpretation',"");
end

function text=localSafeNumber(value)
text=replace(compose('%.6g',value),'.','p');
text=replace(text,'-','m');
text=replace(text,'+','');
end
