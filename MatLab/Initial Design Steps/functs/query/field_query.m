function Q = field_query(load_filename, magnet, target, queries)
% This function loads a saved magnetic field file, builds interpolants,
% solves currents, and evaluates requested queries.
%
% ----- INPUTS -----
% load_filename: string, e.g. "coilfield_run12.mat"
%
% magnet: struct with fields
%   .pose   [1x6] [x y z yaw pitch roll]
%   .remanence
%   .volume
%   .magnetisation_direction_local [3x1]
%
% target: struct with fields
%   .force             [3x1]
%   .torque            [3x1]
%   .forceFrame        "global" or "local"
%   .torqueFrame       "global" or "local"
%   .rows_to_control   vector in [1..6]
%   .override_currents vector (optional)
%
% queries: cell array of query structs
%
% ----- OUTPUT -----
% Q: lean struct containing only inputs, essential intermediate outputs,
%    and plotting-ready queried results

% ------------------------- Load saved field -------------------------
[coils, ~, field] = load_coilfield_mat(load_filename);
nCoils = size(field.mag_field_unit, 3);
if ismatrix(field.mag_field_unit) && size(field.mag_field_unit,1) == 3
    nCoils = 1;
end

% ------------------------- Build interpolants -------------------------
F = build_percoil_interpolants(field);
G = build_percoil_gradient_interpolants(field);

% ------------------------- Magnet definition -------------------------
mu_0 = 1.2256e-6; % N/A^2

m_local = magnet.remanence ./ mu_0 .* ...
          magnet.volume .* ...
          magnet.magnetisation_direction_local(:);

m_global = coord_local2global(m_local, ...
    [0, 0, 0, magnet.pose(4), magnet.pose(5), magnet.pose(6)]);

% ------------------------- Desired force/torque -------------------------
F_des = target.force(:);
T_des = target.torque(:);

if target.forceFrame == "local"
    F_des = coord_local2global(F_des, ...
        [0, 0, 0, magnet.pose(4), magnet.pose(5), magnet.pose(6)]);
end

if target.torqueFrame == "local"
    T_des = coord_local2global(T_des, ...
        [0, 0, 0, magnet.pose(4), magnet.pose(5), magnet.pose(6)]);
end

b = [F_des; T_des];

% ------------------------- Build mapping matrix -------------------------
p = magnet.pose(1:3);
A = build_wrench_matrix_at_point(F, G, p, m_global, nCoils);

if isempty(target.rows_to_control)
    A_used = A;
    b_used = b;
else
    A_used = A(target.rows_to_control, :);
    b_used = b(target.rows_to_control);
end

% ------------------------- Solve currents -------------------------
I_solved = lsqminnorm(A_used, b_used);

if isfield(target, 'override_currents') && ~isempty(target.override_currents)
    I_use = target.override_currents(:).';
    isOverridden = true;
else
    I_use = I_solved(:).';
    isOverridden = false;
end

printCurrents(coils, I_use, isOverridden)

% ------------------------- Package lean outputs -------------------------
Q = struct();

Q.input = struct();
Q.input.load_filename = load_filename;
Q.input.magnet = magnet;
Q.input.target = target;
Q.input.queries = queries;

Q.intermediate = struct();
Q.intermediate.currents = struct();
Q.intermediate.currents.current = I_use;
Q.intermediate.currents.isOverridden = isOverridden;

Q.intermediate.magnet = struct();
Q.intermediate.magnet.m_global = m_global;

Q.plotting = struct();
Q.plotting.results = cell(size(queries));

% ------------------------- Evaluate requested queries -------------------------
for k = 1:numel(queries)
    q = queries{k};

    switch lower(string(q.type))
        case "fundamental_plane"
            Q.plotting.results{k} = get_fundamental_plane(field, I_use, q);
        case "line"
            Q.plotting.results{k} = query_line(field, F, I_use, q);

        case "custom_plane"
            Q.plotting.results{k} = query_custom_plane(field, F, I_use, q);

        otherwise
            error("Unknown query type: " + string(q.type));
    end
end

end
