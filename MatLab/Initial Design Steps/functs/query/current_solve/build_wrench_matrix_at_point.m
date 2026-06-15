function A = build_wrench_matrix_at_point(F, G, p, m_global, nCoils)
% Builds A (6xnCoils) such that [F;T] = A * I at point p.
%
% ----- INPUTS -----
% F: per-coil field interpolants (struct with cells Bx,By,Bz)
% G: per-coil gradient interpolants (struct with 9 derivative cell fields)
% p: 1x3 point [x y z] in global frame
% m_global: 3x1 dipole moment vector in global frame
% nCoils: number of coils
%
% ----- OUTPUTS -----
% A: 6xnCoils mapping from currents to wrench [Fx;Fy;Fz;Tx;Ty;Tz]

xq = p(1);
yq = p(2);
zq = p(3);

A = zeros(6, nCoils);

for k = 1:nCoils

    % ---- B_k(p) per unit current ----
    Bk = [F.Bx{k}(yq,xq,zq);
          F.By{k}(yq,xq,zq);
          F.Bz{k}(yq,xq,zq)];

    % ---- GradB_k(p) per unit current ----
    GradBk = [G.dBx_dx{k}(yq,xq,zq), G.dBx_dy{k}(yq,xq,zq), G.dBx_dz{k}(yq,xq,zq);
              G.dBy_dx{k}(yq,xq,zq), G.dBy_dy{k}(yq,xq,zq), G.dBy_dz{k}(yq,xq,zq);
              G.dBz_dx{k}(yq,xq,zq), G.dBz_dy{k}(yq,xq,zq), G.dBz_dz{k}(yq,xq,zq)];

    % ---- Force and torque per unit current ----
    % F = (m · ∇)B  ->  F = (GradB) * m
    Fk = GradBk * m_global;

    % T = m × B
    Tk = cross(m_global, Bk);

    A(:,k) = [Fk; Tk];

end

end
