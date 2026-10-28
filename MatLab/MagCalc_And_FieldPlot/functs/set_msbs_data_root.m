function p = set_msbs_data_root(root)
%SET_MSBS_DATA_ROOT Save this PC's COMSOL root outside Git in MATLAB prefs.
root=string(root);
if ~isscalar(root) || ~isfolder(root) || ~isfolder(fullfile(root,"Datasets"))
    error("MSBS:DataRoot","Supply the existing COMSOL root containing Datasets.");
end
if strlength(string(getenv("MSBS_DATA_ROOT")))>0
    warning("MSBS:EnvironmentOverride","MSBS_DATA_ROOT overrides the saved preference until unset.");
end
setpref("MSBS","DataRoot",char(root)); p=msbs_paths();
fprintf("MSBS data root: %s\n",p.dataRoot);
end
