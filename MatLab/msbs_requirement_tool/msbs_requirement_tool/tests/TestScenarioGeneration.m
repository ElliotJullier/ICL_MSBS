classdef TestScenarioGeneration < matlab.unittest.TestCase
    methods(Test)
        function blankVariationNominalOnly(testCase)
            cfg=msbsreq.resolveConfig(struct());S=msbsreq.buildScenarioTable(cfg);
            testCase.verifyEqual(height(S),1);
        end
        function twoRangesFourCornersPlusNominal(testCase)
            raw.tunnel.speed=msbsreq.rangeSpec(10,2,"absolute");
            raw.aero.CD=msbsreq.rangeSpec(0.5,0.1,"absolute");
            cfg=msbsreq.resolveConfig(raw);S=msbsreq.buildScenarioTable(cfg);
            testCase.verifyEqual(height(S),5);
            testCase.verifyEqual(sum(S.speed_mps==10 & S.CD==0.5),1);
        end
        function maximumLimit(testCase)
            raw.tunnel.speed=msbsreq.rangeSpec(10,2,"absolute");
            raw.aero.CD=msbsreq.rangeSpec(0.5,0.1,"absolute");
            raw.combinations.max_cases=3;
            cfg=msbsreq.resolveConfig(raw);
            testCase.verifyError(@()msbsreq.buildScenarioTable(cfg),'msbsreq:TooManyScenarios');
        end
        function userDefinedDefaults(testCase)
            raw.combinations.strategy="user_defined";
            raw.combinations.user_scenarios=table(["one";"two"],[10;20], ...
                'VariableNames',{'scenario_name','speed_mps'});
            raw.aero.CD=msbsreq.rangeSpec(0.4,[],"absolute");
            cfg=msbsreq.resolveConfig(raw);S=msbsreq.buildScenarioTable(cfg);
            testCase.verifyEqual(S.scenario_name,["one";"two"]);
            testCase.verifyEqual(S.CD,[0.4;0.4]);
            testCase.verifyEqual(numel(unique(S.scenario_id)),2);
        end
        function magnetSetsDoNotAlterScenarioIds(testCase)
            cfg=msbsreq.resolveConfig(struct());S=msbsreq.buildScenarioTable(cfg);
            ids=S.scenario_id;
            repeated=repmat(ids,3,1);
            testCase.verifyEqual(unique(repeated,'stable'),ids);
        end
        function frameCaseArraysExpand(testCase)
            raw.frames.body_attitude_cases(1).name="b0";raw.frames.body_attitude_cases(1).yaw_pitch_roll_deg=[0 0 0];
            raw.frames.body_attitude_cases(2).name="b1";raw.frames.body_attitude_cases(2).yaw_pitch_roll_deg=[5 0 0];
            raw.frames.wind_orientation_cases(1).name="w0";raw.frames.wind_orientation_cases(1).R_TW=eye(3);
            raw.frames.wind_orientation_cases(2).name="w1";raw.frames.wind_orientation_cases(2).R_TW=msbsreq.rotationZYX([2 0 0],"deg");
            cfg=msbsreq.resolveConfig(raw);S=msbsreq.buildScenarioTable(cfg);
            testCase.verifyEqual(height(S),4);
            testCase.verifyEqual(numel(unique(S.body_attitude_case)),2);
            testCase.verifyEqual(numel(unique(S.wind_orientation_case)),2);
        end
        function timeHistoryAttitudeOverridesBase(testCase)
            raw.motion.mode="time_history";
            raw.motion.time_history=table(0,0,0,0,0,0,0,0,0,0,"T",10,20,30, ...
                'VariableNames',{'time_s','a_x','a_y','a_z','omega_x','omega_y','omega_z', ...
                'alpha_x','alpha_y','alpha_z','frame','yaw_deg','pitch_deg','roll_deg'});
            cfg=msbsreq.resolveConfig(raw);S=msbsreq.buildScenarioTable(cfg);
            expected=msbsreq.rotationZYX([10 20 30],"deg");
            testCase.verifyEqual(S.R_TB{1},expected,'AbsTol',1e-12);
        end
    end
end
