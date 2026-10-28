%% 
%% query_TwoCoil_yoke_study.m
% Queries for TwoCoil_andYoke, no-yoke mesh comparison and centreline leakage.
clear; close all;
projectDir = fileparts(mfilename("fullpath"));
addpath(genpath(fullfile(projectDir,"functs")));
paths = msbs_paths();

% Dataset exports are planar x-z grids at y=0, in metres and tesla.
caseDefs = struct([]);
caseDefs(1).caseName = "TwoCoil_andYoke";
caseDefs(1).model = "comsol_precomputed";
caseDefs(1).datasetFile = "TwoCoil_andYoke_Planar.txt";
caseDefs(1).opRequest = struct("mode","precomputed","layerIndex",1);
caseDefs(1).geometryModel = "TwoCoil_andYoke";
caseDefs(1).geometryOptions = {"InputScale",1};
caseDefs(1).queries = { ...
    create_plane_field_query("xz",0,"z","Group","plane_Bz","Name","Bz", "ShowGeometry",true), ...
    create_plane_field_query("xz",0,"x","Group","plane_Bx","Name","Bx", "ShowGeometry",true), ...
    create_plane_gradient_query("xz",0,"z","z","Group","plane_dBz_dz","Name","dBz/dz", "ShowGeometry",true), ...
    create_plane_gradient_query("xz",0,"z","x","Group","plane_dBz_dx","Name","dBz/dx", "ShowGeometry",true), ...
    create_plane_gradient_query("xz",0,"x","z","Group","plane_dBx_dz","Name","dBx/dz", "ShowGeometry",true), ...
    create_plane_gradient_query("xz",0,"x","x","Group","plane_dBx_dx","Name","dBx/dx", "ShowGeometry",true) ...
    };

lineStart = [0 0 -1.5];
lineEnd   = [0 0  1.5];
zoomStart = [0 0  1.2]; % Include the final 0.1 m of yoke (ends at z=+1.3 m).
zoomEnd   = [0 0  2.0]; % export domain maximum z is +2 m.
nLine = 601;
lineCases = [ ...
    struct("label","TwoCoil_andYoke", "file","TwoCoil_andYoke_Planar.txt"), ...
    struct("label","TwoCoil_noYoke", "file","TwoCoil_noYoke_Planar.txt"), ...
    struct("label","TwoCoil_noYoke_diffMesh", "file","TwoCoil_noYoke_diffMesh_Planar.txt") ...
    ];
for k = 1:numel(lineCases)
    idx = k + 1;
    caseDefs(idx).caseName = lineCases(k).label;
    caseDefs(idx).model = "comsol_precomputed";
    caseDefs(idx).datasetFile = lineCases(k).file;
    caseDefs(idx).opRequest = struct("mode","precomputed","layerIndex",1);
    caseDefs(idx).queries = { ...
        create_line_field_query(lineStart,lineEnd,"z","NPoints",nLine,"Group","line_Bz","Name","Centreline Bz","ShowGeometry",true), ...
        create_line_gradient_query(lineStart,lineEnd,"z","GradientDirection","z","NPoints",nLine,"Group","line_dBz_dz","Name","Centreline dBz/dz","ShowGeometry",true), ...
        create_line_field_query(zoomStart,zoomEnd,"z","NPoints",301,"Group","leakage_Bz","Name","Leakage Bz","ShowGeometry",true) ...
        };
end

% Compare no-yoke meshes as Bz(noYoke) - Bz(noYoke, diffMesh).
% Display the TwoCoil_andYoke coils in this plane, omitting the yoke mesh.
coilOnly = struct( ...
    "file",{"coil_bottom.stl","coil_top.stl"}, ...
    "role",{"coil","coil"}, ...
    "name",{"Bottom coil","Top coil"}, ...
    "pose",{zeros(1,6),zeros(1,6)});
% The virtual-field dataset inherits display geometry from its first source.
caseDefs(3).geometryModel = "TwoCoil_andYoke";
caseDefs(3).geometryOptions = {"InputScale",1,"Components",coilOnly};
% Each line case needs its own physical geometry for the material bands.
caseDefs(2).geometryModel = caseDefs(1).geometryModel;
caseDefs(2).geometryOptions = caseDefs(1).geometryOptions;
caseDefs(4).geometryModel = caseDefs(3).geometryModel;
caseDefs(4).geometryOptions = caseDefs(3).geometryOptions;
caseDefs(5).caseName = "TwoCoil_noYoke minus TwoCoil_noYoke_diffMesh";
caseDefs(5).model = "virtual_field";
caseDefs(5).combination = struct("cases",[3 4],"weights",[1 -1],"poses",zeros(2,6));
caseDefs(5).queries = {create_plane_field_query("xz",0,"z", ...
    "Group","noYoke_mesh_difference_Bz","Name","Bz mesh difference", "ShowGeometry",true)};

[Q,queryFile] = run_query_batch(caseDefs,"TwoCoil_yoke_study");
fprintf("Query output: %s\n",queryFile);
fprintf("Data root: %s\n",paths.dataRoot);
