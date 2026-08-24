function solution = solveMagneticRequirement(map, requiredWrench, scales, cfg, costMetric)
%SOLVEMAGNETICREQUIREMENT Solve one scaled minimum-cost magnetic problem.
% The physical map uses x=[B; gxx gyy gxy gxz gyz]. The five gradient
% coordinates are mapped to an orthonormal symmetric trace-free basis q, for
% which ||q||_2=||G||_F. Each configured cost is represented by one length
% ell so that y=[B0;ell*q] and ||y||_2^2=||B0||^2+ell^2||G||_F^2.
% For a reference cube ell=Lref/sqrt(12), making ||y|| the exact affine-field
% RMS magnitude over that cube. For a relative-length sensitivity metric ell
% is simply the chosen field/gradient trade-off length, with no energy claim.
arguments
    map (1,1) struct
    requiredWrench (6,1) double {mustBeFinite}
    scales (1,1) struct
    cfg (1,1) struct
    costMetric (1,1) struct
end

P=msbsreq.gradientCoordinateTransform();
Tbasis=blkdiag(eye(3),P);
ell=costMetric.gradient_equivalent_length_m;
if ~(isscalar(ell)&&isfinite(ell)&&ell>0)
    error('msbsreq:InvalidMagneticCostMetric','gradient_equivalent_length_m must be positive and finite.');
end
% z=[B0;q]=Tcost*y. Thus lsqminnorm's Euclidean norm of y is exactly the
% configured quadratic magnetic cost for this metric.
Tcost=diag([ones(1,3),repmat(1/ell,1,5)]);
Dw=diag([repmat(1/scales.force_N,1,3),repmat(1/scales.moment_Nm,1,3)]);
A_scaled=Dw*map.A*Tbasis*Tcost;
w_scaled=Dw*requiredWrench;
y=lsqminnorm(A_scaled,w_scaled);
x=Tbasis*Tcost*y;

[achieved,localFields]=msbsreq.evaluateMagneticWrench(x,map.positions_T_m,map.dipoles_T_Am2);
residual=achieved-requiredWrench;
scaledResidual=Dw*residual;
denominator=norm(w_scaled);
if denominator<1e-15
    relativeResidual=norm(scaledResidual);
else
    relativeResidual=norm(scaledResidual)/denominator;
end
G=msbsreq.constructGradient(x);
tol=cfg.validation.gradient_tolerance;
if norm(G-G.','fro')>tol || abs(trace(G))>tol
    error('msbsreq:GradientConstraintViolation', ...
        ['Constructed field gradient violates the configured source-free ', ...
         'symmetry or trace tolerance.']);
end

costValue=norm(y);
mu0=4*pi*1e-7;
isVolumeMetric=string(costMetric.metric_type)=="reference_volume_rms";
solution=struct();
solution.x=x;
solution.B0_T=x(1:3);
solution.G_Tpm=G;
solution.B_at_each_magnet_T=localFields;
solution.B0_norm_T=norm(x(1:3));
if isempty(localFields)
    solution.B_local_max_norm_T=solution.B0_norm_T;
else
    solution.B_local_max_norm_T=max(vecnorm(localFields,2,1));
end
solution.G_frobenius_Tpm=norm(G,'fro');
solution.G_max_abs_component_Tpm=max(abs(G),[],'all');
solution.magnetic_cost_metric_id=costMetric.id;
solution.magnetic_cost_metric_type=costMetric.metric_type;
solution.reference_cube_side_m=costMetric.reference_cube_side_m;
solution.relative_length_scale_m=costMetric.relative_length_scale_m;
solution.gradient_equivalent_length_m=ell;
solution.magnetic_cost_value_T=costValue;
if isVolumeMetric
    solution.magnetic_cost_rms_T=costValue;
    solution.mean_vacuum_energy_density_Jpm3=costValue^2/(2*mu0);
    solution.relative_field_gradient_cost_T=NaN;
else
    solution.magnetic_cost_rms_T=NaN;
    solution.mean_vacuum_energy_density_Jpm3=NaN;
    solution.relative_field_gradient_cost_T=costValue;
end
solution.achieved_wrench_T=achieved;
solution.residual_wrench_T=residual;
solution.force_residual_N=residual(1:3);
solution.moment_residual_Nm=residual(4:6);
solution.force_residual_norm_N=norm(residual(1:3));
solution.moment_residual_norm_Nm=norm(residual(4:6));
solution.relative_scaled_residual=relativeResidual;
solution.controllable=relativeResidual<=cfg.magnetic.acceptance_relative_residual;
solution.rank=map.rank;
solution.condition_number=map.condition_number;
solution.singular_values=map.singular_values;
solution.left_null_space=map.left_null_space;
end
