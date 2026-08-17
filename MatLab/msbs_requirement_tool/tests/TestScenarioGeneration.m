classdef TestScenarioGeneration < matlab.unittest.TestCase
    methods(Test)
        function emptyTableCreatesNominalState(testCase)
            cfg=msbsreq.resolveConfig(struct());
            S=msbsreq.buildScenarioTable(cfg);
            testCase.verifyEqual(height(S),1);
            testCase.verifyEqual(S.scenario_name,"nominal");
        end

        function explicitRowsAreNotCrossCombined(testCase)
            raw.tunnel.speed_mps=10;
            raw.aero.CD=0.4;
            raw.scenarios=table(["low";"high"],[10;20],[0.5;0.8], ...
                'VariableNames',{'scenario_name','speed_mps','CD'});
            cfg=msbsreq.resolveConfig(raw);
            S=msbsreq.buildScenarioTable(cfg);
            testCase.verifyEqual(height(S),2);
            testCase.verifyEqual(S.speed_mps,[10;20]);
            testCase.verifyEqual(S.CD,[0.5;0.8]);
        end

        function omittedValuesUseDefaults(testCase)
            raw.tunnel.speed_mps=12;
            raw.aero.CD=0.45;
            raw.aero.CL=0.1;
            raw.scenarios=table(["one";"two"],[15;20], ...
                'VariableNames',{'scenario_name','speed_mps'});
            cfg=msbsreq.resolveConfig(raw);
            S=msbsreq.buildScenarioTable(cfg);
            testCase.verifyEqual(S.CD,[0.45;0.45]);
            testCase.verifyEqual(S.CL,[0.1;0.1]);
        end

        function maximumLimit(testCase)
            raw.max_scenarios=1;
            raw.scenarios=table(["one";"two"],'VariableNames',{'scenario_name'});
            cfg=msbsreq.resolveConfig(raw);
            root=string(fileparts(fileparts(mfilename('fullpath'))));
            testCase.verifyError(@()msbsreq.validateConfig(cfg,root),'msbsreq:TooManyScenarios');
        end

        function scenarioAttitudeOverridesNominal(testCase)
            raw.frames.body_to_tunnel.yaw_pitch_roll_deg=[0 0 0];
            raw.scenarios=table("tilted",10,20,30, ...
                'VariableNames',{'scenario_name','yaw_deg','pitch_deg','roll_deg'});
            cfg=msbsreq.resolveConfig(raw);
            S=msbsreq.buildScenarioTable(cfg);
            expected=msbsreq.rotationZYX([10 20 30],"deg");
            testCase.verifyEqual(S.R_TB{1},expected,'AbsTol',1e-12);
        end

        function specifiedMotionIsResolvedInSameRow(testCase)
            raw.motion.mode="specified";
            raw.motion.frame="T";
            raw.scenarios=table("moving",1,2,3,4,5,6,7,8,9, ...
                'VariableNames',{'scenario_name','a_x','a_y','a_z','omega_x','omega_y','omega_z', ...
                'alpha_x','alpha_y','alpha_z'});
            cfg=msbsreq.resolveConfig(raw);
            S=msbsreq.buildScenarioTable(cfg);
            testCase.verifyEqual(S.a_C_T_mps2{1},[1;2;3],'AbsTol',1e-14);
            testCase.verifyEqual(S.omega_T_radps{1},[4;5;6],'AbsTol',1e-14);
            testCase.verifyEqual(S.alpha_T_radps2{1},[7;8;9],'AbsTol',1e-14);
        end

        function specifiedMotionMayBeExplicitlyZeroByOmission(testCase)
            raw.motion.mode="specified";
            raw.scenarios=table("unknown_motion",'VariableNames',{'scenario_name'});
            cfg=msbsreq.resolveConfig(raw);
            S=msbsreq.buildScenarioTable(cfg);
            testCase.verifyEqual(S.a_C_T_mps2{1},zeros(3,1),'AbsTol',1e-14);
            testCase.verifyEqual(S.omega_T_radps{1},zeros(3,1),'AbsTol',1e-14);
            testCase.verifyEqual(S.alpha_T_radps2{1},zeros(3,1),'AbsTol',1e-14);
        end

        function harmonicEmptyTableGeneratesCycle(testCase)
            raw.motion.mode="harmonic";
            raw.motion.harmonic.samples_per_cycle=8;
            cfg=msbsreq.resolveConfig(raw);
            S=msbsreq.buildScenarioTable(cfg);
            testCase.verifyEqual(height(S),8);
            testCase.verifyEqual(S.motion_phase_rad(1),0,'AbsTol',1e-14);
        end

        function explicitHarmonicRowsPreserveAeroCorrelation(testCase)
            raw.motion.mode="harmonic";
            raw.motion.harmonic.frequency_Hz=2;
            raw.scenarios=table(["p0";"p1"],[0;pi/2],[20;30],[0.5;0.9], ...
                'VariableNames',{'scenario_name','phase_rad','speed_mps','CD'});
            cfg=msbsreq.resolveConfig(raw);
            S=msbsreq.buildScenarioTable(cfg);
            testCase.verifyEqual(height(S),2);
            testCase.verifyEqual(S.speed_mps,[20;30]);
            testCase.verifyEqual(S.CD,[0.5;0.9]);
            testCase.verifyEqual(S.motion_phase_rad,[0;pi/2],'AbsTol',1e-14);
        end
    end
end
