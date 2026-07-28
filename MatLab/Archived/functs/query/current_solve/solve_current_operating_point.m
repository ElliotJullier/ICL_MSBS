function op = solve_current_operating_point(dataset, magnet, target)
%SOLVE_CURRENT_OPERATING_POINT Solve coil currents for a requested wrench.
%
% This requires a superposable per-coil field dataset. The field and
% gradient interpolants are built only here, not during ordinary field
% queries.

if ~isfield(dataset, "B") || ~dataset.supportsSuperposition
    error("Current solving requires a superposable per-coil dataset.B.");
end

nCoils = size(dataset.B, 5);
Fint = build_percoil_interpolants(dataset);
Gint = build_percoil_gradient_interpolants(dataset);

mu0 = 4*pi*1e-7;

mDir = magnet.magnetisation_direction_local(:);
if norm(mDir) < eps
    error("magnet.magnetisation_direction_local must be non-zero.");
end
mDir = mDir ./ norm(mDir);

m_local = magnet.remanence ./ mu0 .* magnet.volume .* mDir;
m_global = coord_local2global(m_local, [0, 0, 0, magnet.pose(4), magnet.pose(5), magnet.pose(6)]);

F_des = target.force(:);
T_des = target.torque(:);

if strcmpi(string(target.forceFrame), "local")
    F_des = coord_local2global(F_des, [0, 0, 0, magnet.pose(4), magnet.pose(5), magnet.pose(6)]);
end
if strcmpi(string(target.torqueFrame), "local")
    T_des = coord_local2global(T_des, [0, 0, 0, magnet.pose(4), magnet.pose(5), magnet.pose(6)]);
end

b = [F_des; T_des];
p = magnet.pose(1:3);
A = build_wrench_matrix_at_point(Fint, Gint, p, m_global, nCoils);

if ~isfield(target, "rows_to_control") || isempty(target.rows_to_control)
    rows = 1:6;
else
    rows = target.rows_to_control;
end

A_used = A(rows, :);
b_used = b(rows);
I_solved = lsqminnorm(A_used, b_used);

op = struct();
op.mode = "solve";
op.currents = I_solved(:).';
op.magnet = magnet;
op.target = target;
op.rowsToControl = rows;
op.residualNorm = norm(A_used*I_solved - b_used);
op.m_global = m_global;
end
