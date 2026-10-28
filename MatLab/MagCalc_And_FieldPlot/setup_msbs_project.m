function paths = setup_msbs_project()
%SETUP_MSBS_PROJECT Add this project's functions, independent of pwd.
project=fileparts(mfilename("fullpath"));
addpath(genpath(fullfile(project,"functs"))); paths=msbs_paths();
end
