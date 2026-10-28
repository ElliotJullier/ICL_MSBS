function path = resolve_msbs_file(name,kind)
%RESOLVE_MSBS_FILE Resolve explicit paths or data-root/project-relative files.
if nargin<2, kind="datasets"; end
name=string(name);
if ~isscalar(name) || strlength(name)==0 || endsWith(name,".lnk","IgnoreCase",true)
    error("MSBS:FilePath","Supply a file/folder path, not a Windows .lnk.");
end
p=msbs_paths();
if isfile(name) || isfolder(name), path=name; return; end
if ~isfield(p,kind), error("MSBS:PathKind","Unknown path kind: %s",kind); end
for candidate=[fullfile(p.(kind),name),fullfile(p.project,name)]
    if isfile(candidate) || isfolder(candidate), path=candidate; return; end
end
error("MSBS:MissingFile","Cannot find '%s' in %s. Data root: '%s'. Use set_msbs_data_root on this PC.",name,kind,p.dataRoot);
end
