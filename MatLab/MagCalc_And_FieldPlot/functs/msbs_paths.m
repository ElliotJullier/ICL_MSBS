function p = msbs_paths()
%MSBS_PATHS Priority: environment MSBS_DATA_ROOT, local preference, OneDrive.
p.project=string(fileparts(fileparts(mfilename("fullpath"))));
root=string(getenv("MSBS_DATA_ROOT"));
if strlength(root)==0 && ispref("MSBS","DataRoot"), root=string(getpref("MSBS","DataRoot")); end
if strlength(root)==0
    suffix=fullfile("PhD","21 Design and Procurement","21-2 EM Coils","COMSOL");
    bases=[string(getenv("OneDriveCommercial")),fullfile(string(getenv("USERPROFILE")),"OneDrive - Imperial College London")];
    for base=bases
        candidate=fullfile(base,suffix);
        if strlength(base)>0 && isfolder(candidate), root=candidate; break; end
    end
end
p.dataRoot=root; p.models=fullfile(root,"COMSOL Files"); p.datasets=fullfile(root,"Datasets");
p.java=fullfile(root,"Java");
if ~isfolder(p.java) && isfolder(fullfile(root,"Java COMSOL")), p.java=fullfile(root,"Java COMSOL"); end
p.stl=fullfile(root,"STL"); p.graphs=fullfile(root,"Graphs");
p.queryOutputs=fullfile(p.project,"Q outputs"); p.metadata=fullfile(p.graphs,"plot_metadata");
if strlength(root)==0, p.metadata=""; end % Let the writer report missing setup.
end
