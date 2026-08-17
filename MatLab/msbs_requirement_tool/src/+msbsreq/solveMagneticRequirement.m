function solution = solveMagneticRequirement(map, requiredWrench, scales, cfg)
%SOLVEMAGNETICREQUIREMENT Solve the scaled minimum-field/gradient problem.
% The map uses physical coordinates [B; gxx gyy gxy gxz gyz]. The solve is
% performed in an orthonormal symmetric trace-free gradient basis so the
% gradient part of the Euclidean minimum norm is exactly ||G||_F.
arguments
    map (1,1) struct
    requiredWrench (6,1) double {mustBeFinite}
    scales (1,1) struct
    cfg (1,1) struct
end

P=localGradientCoordinateTransform();
Tbasis=blkdiag(eye(3),P);
Dobjective=diag([repmat(cfg.magnetic.field_scale_T,1,3), ...
    repmat(cfg.magnetic.gradient_scale_Tpm,1,5)]);
Dw=diag([repmat(1/scales.force_N,1,3),repmat(1/scales.moment_Nm,1,3)]);
A_scaled=Dw*map.A*Tbasis*Dobjective;
w_scaled=Dw*requiredWrench;
y=lsqminnorm(A_scaled,w_scaled);
x=Tbasis*Dobjective*y;

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
solution.scaled_solution_norm=norm(y);
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

function P=localGradientCoordinateTransform()
% q are orthonormal symmetric trace-free coordinates; p=P*q gives
% p=[gxx gyy gxy gxz gyz]. Therefore ||q||_2=||G||_F.
P=[ 1/sqrt(2),  1/sqrt(6), 0,         0,         0; ...
   -1/sqrt(2),  1/sqrt(6), 0,         0,         0; ...
    0,          0,         1/sqrt(2), 0,         0; ...
    0,          0,         0,         1/sqrt(2), 0; ...
    0,          0,         0,         0,         1/sqrt(2)];
end
