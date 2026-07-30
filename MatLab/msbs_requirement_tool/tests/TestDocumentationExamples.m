classdef TestDocumentationExamples < matlab.unittest.TestCase
    methods(Test)
        function quickStartCommandsAndFiles(testCase)
            root=fileparts(fileparts(mfilename('fullpath')));
            text=fileread(fullfile(root,'docs','QuickStart.md'));
            testCase.verifySubstring(text,'results = runAllTests();');
            testCase.verifySubstring(text,'study = runStudy("case_minimal_example");');
            testCase.verifyTrue(isfile(fullfile(root,'cases','case_template.m')));
            testCase.verifyTrue(isfile(fullfile(root,'docs','UserGuide.md')));
            testCase.verifyTrue(isfile(fullfile(root,'docs','TechnicalReference.md')));
        end
        function everyDefaultFieldIsDocumented(testCase)
            root=fileparts(fileparts(mfilename('fullpath')));
            defaults=fileread(fullfile(root,'src','+msbsreq','defaultConfig.m'));
            guide=fileread(fullfile(root,'docs','UserGuide.md'));
            tokens=regexp(defaults,'cfg\.([A-Za-z][A-Za-z0-9_\.]*)\s*=','tokens');
            fields=unique(string(cellfun(@(entry)entry{1},tokens,'UniformOutput',false)));
            for i=1:numel(fields)
                testCase.verifySubstring(guide,"`"+fields(i)+"`", ...
                    "Undocumented default field: "+fields(i));
            end
        end
        function outputPackageExists(testCase)
            % Execute the exact non-test command documented in QuickStart.md.
            study=runStudy("case_minimal_example");
            cleanup=onCleanup(@()localRemove(study.output_folder)); %#ok<NASGU>
            expected={'config_raw.mat','config_raw.json','config_resolved.mat','config_resolved.json', ...
                'run_metadata.json','run_summary.md','scenario_results.csv','magnet_set_summary.csv', ...
                'results_full.mat','warnings.txt','configuration.png','configuration.pdf'};
            for i=1:numel(expected)
                testCase.verifyTrue(isfile(fullfile(study.output_folder,expected{i})),expected{i});
            end
            testCase.verifyEqual(numel(dir(fullfile(study.output_folder,'worst_case_*.png'))),3);
            testCase.verifyEqual(numel(dir(fullfile(study.output_folder,'magnetic_field_*.pdf'))),3);
        end
        function inputFormsEquivalent(testCase)
            cfg=case_test_equivalence();
            a=runStudy(cfg);
            b=runStudy(@case_test_equivalence);
            c=runStudy("case_test_equivalence");
            testCase.verifyEqual(a.geometry.outer_dimensions_B_m,b.geometry.outer_dimensions_B_m,'RelTol',1e-12);
            testCase.verifyEqual(a.geometry.outer_dimensions_B_m,c.geometry.outer_dimensions_B_m,'RelTol',1e-12);
            variables={'Fx_mag_req_N','Fy_mag_req_N','Fz_mag_req_N'};
            testCase.verifyEqual(a.results{:,variables},b.results{:,variables},'RelTol',1e-12);
            testCase.verifyEqual(a.results{:,variables},c.results{:,variables},'RelTol',1e-12);
        end
    end
end
function localRemove(path)
if ~isfolder(path),return,end
parent=fileparts(path);
rmdir(path,'s');
if isfolder(parent)
    entries=dir(parent);
    entries=entries(~ismember({entries.name},{'.','..'}));
    if isempty(entries),rmdir(parent);end
end
end
