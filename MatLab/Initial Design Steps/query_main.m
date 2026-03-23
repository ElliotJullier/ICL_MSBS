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
target.override_currents = [5.14, 5.51]; % Optional, an array of currents for the coils to produce, will overwrite calculated currents required as defined by the previous variables

queries = {
    struct("type","fundamental_plane","plane","xz","value",0,"component","z", "group", 1, "inOverview", true)
    % struct("type","fundamental_plane","plane","xz","value",0,"component","x", "group", 2, "inOverview", true)
    % struct("type","fundamental_plane","plane","yz","value",-0.5,"component","x")
    % struct("type","fundamental_plane","plane","yz","value",0.5,"component","x")
    % struct("type", "custom_plane", "point", [0 0 0], "normal", [0.2 1 1], "component", "x", "resolution", [150 150]) % Equivalent to fundamental xy plane, resolution is option and can be a scalar
    struct("type","line","start",[0 0 -120/1000],"end",[0 0 120/1000],"component","z","nPoints",200, "group", 2, "legendName", "Full Biot-Savart") % nPoints and group are optional
};

Q_case1_BiotSavartFull = field_query("coilfield_run1.mat", magnet, target, queries);
save("Q_case1_BiotSavartFull.mat", "Q_case1_BiotSavartFull");

% ------ Simple on-axis Biot-Savart helper ------

% Q_case1_BiotSavartSimple = simple_biotsavart_query( ...
    % "coilfield_run0b.mat", ...
    % target.override_currents, ...
    % {struct("type","line","start",[0.5 0 0],"end",[-0.5 0 0],"component","x","nPoints",200, "group", 2, "legendName", "On-axis Biot-Savart")}, ...
    % "caseName", "Q_case1_BiotSavartSimple", ...
    % "sourceName", "analytical_simple_biotsavart");

% save("Q_case1_BiotSavartSimple.mat", "Q_case1_BiotSavartSimple");
