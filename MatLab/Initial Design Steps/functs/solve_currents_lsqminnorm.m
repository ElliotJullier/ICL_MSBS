function I = solve_currents_lsqminnorm(A, b)
% Solves A*I ≈ b using MATLAB's minimum-norm least squares solver.
%
% Works for under/overdetermined and rank-deficient systems.
%
% ----- INPUTS -----
% A: MxN mapping matrix
% b: Mx1 target vector
%
% ----- OUTPUTS -----
% I: Nx1 current solution

I = lsqminnorm(A, b);

end
