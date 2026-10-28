function folder = msbs_graphs_dir(varargin)
%MSBS_GRAPHS_DIR Resolve an export subfolder under this PC's OneDrive root.
% No folders/files are created until the calling script exports a figure.
paths=msbs_paths();
if strlength(paths.dataRoot)==0 || ~isfolder(paths.dataRoot)
    error("MSBS:GraphRoot","Configure this PC's synced COMSOL root using set_msbs_data_root before exporting plots.");
end
folder=fullfile(paths.graphs,varargin{:});
end
