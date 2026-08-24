classdef TestMagnetSizing < matlab.unittest.TestCase
    methods(Test)
        function magnetDatabaseLoadsWithStableHeaders(testCase)
            root=string(fileparts(fileparts(mfilename('fullpath'))));
            T=msbsreq.loadMagnetGradeTable(root);
            required=["grade","Br_nominal_T","Br_min_T","Br_max_T", ...
                "density_kgm3","temperature_C","source_reference","source_note"];
            testCase.verifyTrue(all(ismember(required,string(T.Properties.VariableNames))));
            testCase.verifyTrue(any(strcmpi(T.("grade"),"N52")));
        end
        function shrinkEveryDimension(testCase)
            [cfg,g,root]=localSetup();cfg.magnets.automatic.linear_shrink_fraction=0.1;
            [sets,~]=msbsreq.buildMagnetSets(cfg,g,root);
            expected=0.9*g.inscribed_cuboid.dimensions_B_m;
            testCase.verifyEqual(sets(1).magnets.dimensions_local_m,expected,'RelTol',1e-12);
        end
        function volumeDipoleAndMass(testCase)
            [cfg,g,root]=localSetup();[sets,~]=msbsreq.buildMagnetSets(cfg,g,root);m=sets(1).magnets;
            testCase.verifyEqual(m.volume_m3,prod(m.dimensions_local_m),'RelTol',1e-14);
            expected=m.Br_selected_T/(4*pi*1e-7)*m.volume_m3;
            testCase.verifyEqual(m.dipole_moment_magnitude_Am2,expected,'RelTol',1e-12);
            mp=msbsreq.calculateMassProperties(cfg,g,sets(1));
            testCase.verifyEqual(mp.total_mass_kg,cfg.mass.shell_mass_factor*m.mass_kg,'RelTol',1e-12);
        end
        function dipoleOverride(testCase)
            [cfg,g,root]=localSetup();cfg.magnets.automatic.dipole_moment_override_Am2=7.5;
            [sets,~]=msbsreq.buildMagnetSets(cfg,g,root);
            testCase.verifyEqual(sets(1).magnets.dipole_moment_magnitude_Am2,7.5,'AbsTol',1e-14);
        end
        function hybridCentreOfMass(testCase)
            [cfg,g,root]=localSetup();
            cfg.magnets.automatic.linear_shrink_fraction=0.1;
            cfg.magnets.automatic.centre_offset_B_m=[0.01;0;0];
            [sets,~]=msbsreq.buildMagnetSets(cfg,g,root);mp=msbsreq.calculateMassProperties(cfg,g,sets(1));
            expected=sets(1).magnets.mass_kg*0.01/mp.total_mass_kg;
            testCase.verifyEqual(mp.centre_of_mass_B_m(1),expected,'RelTol',1e-12);
        end
        function significantCouplingProducesCompactSensitivityTable(testCase)
            cfg=case_test_equivalence();cfg.output.enable=false;cfg.visualisation.enable=false;
            m.name="offset";m.dimensions_local_m=[0.03;0.02;0.02];m.centre_B_m=[0;0.08;0];
            m.R_BM=eye(3);m.grade="N52";m.magnetisation_direction_M=[1;0;0];
            m.effective_magnetisation_factor=1;m.dipole_moment_override_Am2=[];m.density_override_kgm3=[];
            cfg.magnets.mode="manual_sets";cfg.magnets.sets=struct([]);
            cfg.magnets.sets(1).name="offset_single";cfg.magnets.sets(1).magnets=m;
            study=runStudy(cfg);
            testCase.verifyEqual(study.results.coupling_class(1),"significant");
            testCase.verifyGreaterThanOrEqual(height(study.sensitivity_results),6);
            testCase.verifyTrue(all(study.sensitivity_results.scenario_id==study.results.scenario_id(1)));
            testCase.verifyTrue(any(study.sensitivity_results.metric_id=="model_characteristic_rms"));
        end
        function manualTwoMagnetStudyRuns(testCase)
            cfg=case_test_equivalence();
            m1.name="front";m1.dimensions_local_m=[0.04;0.02;0.02];m1.centre_B_m=[0.04;0;0];
            m1.R_BM=eye(3);m1.grade="N52";m1.magnetisation_direction_M=[1;0;0];
            m1.effective_magnetisation_factor=1;m1.dipole_moment_override_Am2=[];m1.density_override_kgm3=[];
            m2=m1;m2.name="rear";m2.centre_B_m=[-0.04;0;0];m2.magnetisation_direction_M=[0;1;0];
            cfg.magnets.mode="manual_sets";cfg.magnets.sets=struct([]);
            cfg.magnets.sets(1).name="two_nonparallel";cfg.magnets.sets(1).magnets=[m1 m2];
            study=runStudy(cfg);
            testCase.verifyEqual(numel(study.magnet_sets),1);
            testCase.verifyEqual(numel(study.magnet_sets(1).magnets),2);
            testCase.verifyEqual(height(study.results),height(study.scenarios));
        end
    end
end
function [cfg,g,root]=localSetup()
root=string(fileparts(fileparts(mfilename('fullpath'))));cfg=msbsreq.resolveConfig(struct());
t=msbsreq.buildTunnel(cfg);g=msbsreq.buildGeometry(cfg,t);
end
