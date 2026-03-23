clear
close all;

addpath("functs");
addpath("functs/query/");
%-----------------------

magnet.pose = [0 0 0 0 0 0]; % Relative pos [x y z yaw pitch roll], units of meters and rad
magnet.remanence = 1.5; % Tesla
magnet.volume = 30/1000*pi*(10/1000)^2; 
magnet.magnetisation_direction_local = [1;0;0]; % [x y z] local magnetisation direction (converted to unit vector) 

target.force = [0.1;0;0]; % [x y z] in N
target.torque = [0;0;0]; % Torque along [x y z] axes in Nm
target.forceFrame = "global"; % "global" or "local", force in WT x coord or magnet x coord
target.torqueFrame = "global"; % "global" or "local", torque in WT x axes or magnet x axes
target.rows_to_control = []; % Leave empty for all control, 1 - Fx, 2 - Fy, 3 - Fz, 4 - Tx, 5 - Ty, 6 - Tz. Combinations of this so ([3 5] would mean control Fz and Ty)
target.override_currents = [50]; % Optional, an array of currents for the coils to produce, will overwrite calculated currents required as defined by the previous variables

queries = {
    struct("type","fundamental_plane","plane","xy","value",0,"component","x", "group", 1, "inOverview", true)
    struct("type","fundamental_plane","plane","xz","value",0,"component","x", "group", 2, "inOverview", true)
    % struct("type","fundamental_plane","plane","yz","value",-0.5,"component","x")
    % struct("type","fundamental_plane","plane","yz","value",0.5,"component","x")
    % struct("type", "custom_plane", "point", [0 0 0], "normal", [0.2 1 1], "component", "x", "resolution", [150 150]) % Equivalent to fundamental xy plane, resolution is option and can be a scalar
    struct("type","line","start",[0.5 0 0],"end",[-0.5 0 0],"component","x","nPoints",200, "group", 2, "legendName", "Full Biot-Savart") % nPoints and group are optional
};

Q_case1_BiotSavartFull = field_query("coilfield_run0b.mat", magnet, target, queries);
% save("Q_case1_BiotSavartFull.mat", "Q_1");

% ------ In-axis Biot-Savart ------

% Line defined same as one in queries for now
Q_case1_BiotSavartSimple = struct();
Q_case1_BiotSavartSimple.plotting = cell(1);
Q_case1_BiotSavartSimple.plotting{1} = struct();
Q_case1_BiotSavartSimple.plotting{1}.type = "line";
Q_case1_BiotSavartSimple.plotting{1}.component = "x";
Q_case1_BiotSavartSimple.plotting{1}.group = 2;
Q_case1_BiotSavartSimple.plotting{1}.legendName = "On-axis Biot-Savart";
%  --- START AND END POINTS ASSUMED IN LINE WITH COIL AXIS ---
Q_case1_BiotSavartSimple.plotting{1}.start = [0.5, 0, 0];
Q_case1_BiotSavartSimple.plotting{1}.end = [-0.5, 0, 0];
n = 200;
Q_case1_BiotSavartSimple.plotting{1}.X = linspace(Q_case1_BiotSavartSimple.plotting{1}.start(1), Q_case1_BiotSavartSimple.plotting{1}.end(1), n)';
Q_case1_BiotSavartSimple.plotting{1}.Y = linspace(Q_case1_BiotSavartSimple.plotting{1}.start(2), Q_case1_BiotSavartSimple.plotting{1}.end(2), n)';
Q_case1_BiotSavartSimple.plotting{1}.Z = linspace(Q_case1_BiotSavartSimple.plotting{1}.start(3), Q_case1_BiotSavartSimple.plotting{1}.end(3), n)';

Q_case1_BiotSavartSimple.plotting{1}.s = vecnorm([Q_case1_BiotSavartSimple.plotting{1}.X, Q_case1_BiotSavartSimple.plotting{1}.Y, Q_case1_BiotSavartSimple.plotting{1}.Z] - [Q_case1_BiotSavartSimple.plotting{1}.X(1), Q_case1_BiotSavartSimple.plotting{1}.Y(1), Q_case1_BiotSavartSimple.plotting{1}.Z(1)], 2, 2);

[~, geom, ~] = load_coilfield_mat("coilfield_run0b.mat");
averageR = (geom.coil_outer_radius + geom.coil_inner_radius)/2;

coil_offset = 0; % Can be used to move coil along the defined line (eg. starting at the other end for a pair of coils)

mu_0 = 1.2566*10^-6; 
Q_case1_BiotSavartSimple.plotting{1}.B = geom.N*mu_0*target.override_currents(1)*averageR^2./(2*((Q_case1_BiotSavartSimple.plotting{1}.s-coil_offset).^2 + averageR^2).^(3/2));
save("Q_case1_BiotSavartSimple.mat", "Q_case1_BiotSavartSimple");




