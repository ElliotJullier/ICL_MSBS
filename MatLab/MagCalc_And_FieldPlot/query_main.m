clear
close all
% Resolve functions relative to this template, independent of MATLAB's pwd.
projectDir=fileparts(mfilename("fullpath"));
addpath(genpath(fullfile(projectDir,"functs")));
paths=msbs_paths();

% First use on another PC (once, then remove/comment the line):
% set_msbs_data_root("D:/your/OneDrive/.../COMSOL");
% This PC is detected from its Imperial OneDrive location automatically.

caseDefs=struct([]);
caseDefs(1).caseName="COMSOL single excitation";
caseDefs(1).model="comsol_precomputed";
caseDefs(1).datasetFile="2Coil_andYoke_OneCoilExcitation.txt";
caseDefs(1).opRequest=struct("mode","precomputed","layerIndex",1);

% Geometry is imported directly from STL/<exact .mph basename>/.
% Files: coil_*.stl (green), yoke_*.stl (grey), core_*.stl (purple).
% All in assembly coordinates. InputScale=1 for metres; 1e-3 for mm.
geometryModel="2Coil_andYoke";
if isfolder(fullfile(paths.stl,geometryModel)) || isfolder(fullfile(paths.stl,geometryModel+".mph"))
    caseDefs(1).geometryModel=geometryModel;
    caseDefs(1).geometryOptions={"InputScale",1};
else
    warning("MSBS:GeometryNotExported","Export component STLs to %s to enable geometry.",fullfile(paths.stl,geometryModel));
end
caseDefs(1).queries={ ...
    create_plane_field_query("xz",0,"z","Group",1,"Overview",true,"ShowGeometry",true), ...
    create_line_field_query([0 0 -1],[0 0 1],"z","NPoints",300,"Group",2,"Overview",true,"ShowGeometry",true), ...
    create_line_gradient_query([0 0 -1],[0 0 1],"z","GradientDirection","z", ...
        "NPoints",300,"Group",2,"ShowGeometry",true) ...
};

% Arbitrary field projection, plane and derivative directions (volume data):
% create_custom_plane_field_query([0 0 0],[1 1 0],[1 0 1], ...
%     "UpVector","z","ULimits",[-0.5 0.5],"VLimits",[-0.5 0.5])
% create_custom_plane_gradient_query([0 0 0],[1 1 0],[1 0 1],"z")

% Parametric export example (one varied parameter only):
% caseDefs(1).datasetOptions={"ParameterName","I","ParameterValues",[1 5 10]};
% caseDefs(1).opRequest.layerIndex=2;
% With complete COMSOL headers, parameter identities are read automatically.

% Lazy A/10-B or transformed sum: source cases must precede the combination.
% caseDefs(3).caseName="A divided by 10 minus B";
% caseDefs(3).model="virtual_field";
% caseDefs(3).combination=struct("cases",[1 2],"weights",[0.1 -1], ...
%     "poses",zeros(2,6));
% caseDefs(3).queries=caseDefs(1).queries;
% Poses reuse coord_local2global: [x y z yaw pitch roll], metres/radians.

[Q,queryFile]=run_query_batch(caseDefs,"COMSOL");
