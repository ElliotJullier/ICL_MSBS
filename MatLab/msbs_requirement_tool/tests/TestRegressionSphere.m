classdef TestRegressionSphere < matlab.unittest.TestCase
    methods(Test)
        function workedSphereExampleRuns(testCase)
            cfg=case_sphere_example();
            cfg.output.enable=false;
            cfg.visualisation.enable=false;
            study=runStudy(cfg);
            testCase.verifyEqual(height(study.scenarios),385);
            testCase.verifyEqual(height(study.results),385*3);
            testCase.verifyEqual(study.config_resolved.magnets.automatic.linear_shrink_fraction,0);
            testCase.verifyEqual(study.tunnel.width_m,0.60,'AbsTol',1e-14);
            testCase.verifyEqual(study.tunnel.height_m,0.60,'AbsTol',1e-14);
        end
        function fixedSphereOutputs(testCase)
            root=string(fileparts(fileparts(mfilename('fullpath'))));
            cfg=case_minimal_example();cfg.output.enable=false;cfg.visualisation.enable=false;
            resolved=msbsreq.resolveConfig(cfg);t=msbsreq.buildTunnel(resolved);
            g=msbsreq.buildGeometry(resolved,t);[sets,~]=msbsreq.buildMagnetSets(resolved,g,root);
            mp=msbsreq.calculateMassProperties(resolved,g,sets(1));
            S=msbsreq.buildScenarioTable(resolved);
            loads=msbsreq.calculateRequiredMagneticWrench(resolved,t,g,S(1,:),mp);
            map=msbsreq.buildMagneticMap(sets(1),loads.scenario.R_TB,mp.centre_of_mass_B_m);
            scales=struct('force_N',norm(loads.required_magnetic_wrench_T(1:3)), ...
                'moment_Nm',1e-9);
            sol=msbsreq.solveMagneticRequirement(map,loads.required_magnetic_wrench_T,scales,resolved);
            testCase.verifyEqual(g.shape.diameter_m,0.21409489393833253,'RelTol',1e-11);
            testCase.verifyEqual(sets(1).magnets.volume_m3,0.001888587222247466,'RelTol',1e-11);
            testCase.verifyEqual(mp.total_mass_kg,18.413725416912794,'RelTol',1e-11);
            testCase.verifyEqual(loads.required_magnetic_wrench_T(1),-9.9225,'AbsTol',1e-10);
            testCase.verifyEqual(loads.required_magnetic_wrench_T(3),180.57696035976784,'RelTol',1e-11);
            testCase.verifyEqual(sol.G_Tpm(1,1),-0.0045376493376592195,'RelTol',1e-9);
            testCase.verifyEqual(sol.G_Tpm(1,3),0.08257948345407061,'RelTol',1e-9);
        end
    end
end
