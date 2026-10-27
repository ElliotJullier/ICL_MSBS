function runStudies(casesInput)
% RUNSTUDIES Run several MSBS aerodynamic-load-to-magnetic-requirement
% studies. Input is list of filenames in cases folder. Calls runStudy for
% each case name.

for i = 1:numel(casesInput)
    fprintf("\n[%d/%d] Running %s\n", i, numel(casesInput), casesInput(i));
    try
        runStudy(casesInput(i));
    catch ME
        fprintf(2, "FAILED: %s\n%s\n", casesInput(i), ...
            getReport(ME, "extended", "hyperlinks", "off"));
    end
end