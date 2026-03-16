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
target.rows_to_control = [1]; % 1 - Fx, 2 - Fy, 3 - Fz, 4 - Tx, 5 - Ty, 6 - Tz. Combinations of this so ([3 5] would mean control Fz and Ty)
target.override_currents = []; % Optional, an array of currents for the coils to produce, will overwrite calculated currents required as defined by the previous variables

queries = {
    struct("type","fundamental_plane","plane","xy","value",0,"component","x")
    struct("type","fundamental_plane","plane","xz","value",0,"component","x")
    struct("type","fundamental_plane","plane","yz","value",0,"component","x")
    %struct("type","line","start",[0 0 0],"end",[0.4 0.2 0],"component","z","nPoints",200)
};

Q_3 = field_query("coilfield_run3.mat", magnet, target, queries);
% save("Q_run12.mat", "Q");