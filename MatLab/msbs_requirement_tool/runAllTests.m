function results = runAllTests()
%RUNALLTESTS Run the complete MATLAB Unit Test suite for this project.

projectRoot = fileparts(mfilename('fullpath'));
originalPath = path;
pathCleanup = onCleanup(@()path(originalPath)); %#ok<NASGU>
addpath(projectRoot);
addpath(fullfile(projectRoot, 'src'));
addpath(fullfile(projectRoot, 'cases'));
addpath(fullfile(projectRoot, 'tests'));

suite = testsuite(fullfile(projectRoot, 'tests'), 'IncludeSubfolders', true);
results = run(suite);
disp(results);

if any([results.Failed]) || any([results.Incomplete])
    error('msbsreq:TestsFailed', ...
        'One or more tests failed or were incomplete. Review the displayed test results.');
end
end
