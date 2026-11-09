function run_standalone_portfolio(out)
%RUN_STANDALONE_PORTFOLIO Generate active air/LW-PLA studies and unit roll maps.
root=string(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'research'));
if nargin==0,out=fullfile(root,'research','outputs','standalone');end
run_requirements_revision(out,"standalone");
audit_roll_layouts(out);
export_revision_cad(out,"standalone");
end
