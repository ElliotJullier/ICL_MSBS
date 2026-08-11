classdef TestAerodynamicExtensions < matlab.unittest.TestCase
    methods(Test)
        function legacyThreeCoefficientBehaviourUnchanged(testCase)
            [geom,mp,s]=localAeroSetup();
            legacy=msbsreq.calculateAeroWrench(s,geom,mp);
            s.aero_source_mode="legacy_3coeff";
            explicit=msbsreq.calculateAeroWrench(s,geom,mp);
            testCase.verifyEqual(explicit,legacy,'AbsTol',1e-14);
            q=0.5*s.rho_kgm3*s.speed_mps^2;
            expected=[q*geom.reference_area_m2*s.CD;0;q*geom.reference_area_m2*s.CL; ...
                0;q*geom.reference_area_m2*geom.reference_length_m*s.Cm;0];
            testCase.verifyEqual(explicit,expected,'AbsTol',1e-13);
        end

        function sixCoefficientDimensionalisation(testCase)
            [geom,mp,s]=localAeroSetup();
            geom.reference_area_m2=2;geom.reference_length_m=0.5;geom.reference_span_m=1.2;
            s.aero_source_mode="coefficients_6dof";
            s.CD=1;s.CY=2;s.CL=3;s.Cl=4;s.Cm=5;s.Cn=6;
            s.rho_kgm3=1;s.speed_mps=2;
            w=msbsreq.calculateAeroWrench(s,geom,mp);
            q=2;S=2;b=1.2;c=0.5;
            expected=q*S*[1;2;3;b*4;c*5;b*6];
            testCase.verifyEqual(w,expected,'AbsTol',1e-13);
        end


        function sixCoefficientWindFrameRotation(testCase)
            [geom,mp,s]=localAeroSetup();
            geom.reference_area_m2=1;geom.reference_length_m=1;geom.reference_span_m=1;
            s.aero_source_mode="coefficients_6dof";s.rho_kgm3=2;s.speed_mps=1;
            s.CD=1;s.CY=2;s.CL=3;s.Cl=4;s.Cm=5;s.Cn=6;
            s.R_TW=msbsreq.rotationZYX([90 0 0],"deg");
            w=msbsreq.calculateAeroWrench(s,geom,mp);
            expected=[s.R_TW*[1;2;3];s.R_TW*[4;5;6]];
            testCase.verifyEqual(w,expected,'AbsTol',1e-12);
        end

        function directWrenchEqualsEquivalentSixCoefficientWrench(testCase)
            [geom,mp,s]=localAeroSetup();
            geom.reference_area_m2=0.2;geom.reference_length_m=0.3;geom.reference_span_m=0.4;
            geom.aero_reference_point_B_m=[0.05;0;0];
            s.aero_source_mode="coefficients_6dof";
            s.CD=0.7;s.CY=-0.2;s.CL=0.3;s.Cl=0.1;s.Cm=-0.05;s.Cn=0.08;
            wCoeff=msbsreq.calculateAeroWrench(s,geom,mp);
            q=0.5*s.rho_kgm3*s.speed_mps^2;
            forceW=q*geom.reference_area_m2*[s.CD;s.CY;s.CL];
            momentW=q*geom.reference_area_m2*[geom.reference_span_m*s.Cl; ...
                geom.reference_length_m*s.Cm;geom.reference_span_m*s.Cn];
            s.aero_source_mode="direct_wrench_cases";
            s.aero_force_input=forceW;s.aero_moment_input=momentW;s.aero_input_frame="W";
            s.aero_reference_point_B_m=geom.aero_reference_point_B_m;s.R_ET=eye(3);
            wDirect=msbsreq.calculateAeroWrench(s,geom,mp);
            testCase.verifyEqual(wDirect,wCoeff,'AbsTol',1e-12);
        end

        function directWrenchTransformsAndShifts(testCase)
            raw.aero.mode="direct_wrench_cases";
            point={[0.1;0;0]};
            raw.aero.direct_wrench_cases=table("one",0,1,0,0,0,0,"B",point, ...
                'VariableNames',{'case_name','Fx_N','Fy_N','Fz_N','Mx_Nm','My_Nm','Mz_Nm','frame','reference_point_B_m'});
            raw.frames.body_to_tunnel.yaw_pitch_roll_deg=[90 0 0];
            cfg=msbsreq.resolveConfig(raw);S=msbsreq.buildScenarioTable(cfg);
            t=msbsreq.buildTunnel(cfg);g=msbsreq.buildGeometry(cfg,t);
            mp=struct('centre_of_mass_B_m',[0;0;0]);
            w=msbsreq.calculateAeroWrench(localScenario(S,cfg,t.rho_kgm3),g,mp);
            testCase.verifyEqual(w(1:3),[-1;0;0],'AbsTol',1e-12);
            testCase.verifyEqual(w(4:6),[0;0;0.1],'AbsTol',1e-12);
        end

        function aerodynamicAndMotionTimeHistoriesCoexist(testCase)
            raw.aero.mode="wrench_time_history";
            raw.aero.wrench_time_history=table([0;0.1],[1;2],[0;0],[0;0],[0;0],[0;0],[0;0], ...
                'VariableNames',{'time_s','Fx_N','Fy_N','Fz_N','Mx_Nm','My_Nm','Mz_Nm'});
            raw.motion.mode="time_history";
            raw.motion.time_history=table([0;0.1],[3;4],[0;0],[0;0],[0;0],[0;0],[0;0], ...
                [0;0],[0;0],[0;0], ...
                'VariableNames',{'time_s','a_x','a_y','a_z','omega_x','omega_y','omega_z', ...
                'alpha_x','alpha_y','alpha_z'});
            cfg=msbsreq.resolveConfig(raw);root=string(fileparts(fileparts(mfilename('fullpath'))));
            testCase.verifyWarningFree(@()msbsreq.validateConfig(cfg,root));
            S=msbsreq.buildScenarioTable(cfg);
            testCase.verifyEqual(height(S),2);
            testCase.verifyEqual(S.time_s,[0;0.1],'AbsTol',1e-14);
            testCase.verifyEqual(S.a_C_T_mps2{2},[4;0;0],'AbsTol',1e-14);
            testCase.verifyEqual(S.aero_force_input{2},[2;0;0],'AbsTol',1e-14);

            cfg.output.enable=false;cfg.visualisation.enable=false;
            study=runStudy(cfg);
            row=study.results(study.results.scenario_id=="S00002",:);
            row=row(1,:);
            m=study.mass_properties(1).total_mass_kg;
            testCase.verifyEqual(row.Fx_aero_N,2,'AbsTol',1e-12);
            testCase.verifyEqual(row.Fx_inertial_demand_N,4*m,'AbsTol',1e-10);
            testCase.verifyEqual(row.Fx_mag_req_N,4*m-2,'AbsTol',1e-10);
        end

        function timeHistoryMismatchRejected(testCase)
            raw.aero.mode="wrench_time_history";
            raw.aero.wrench_time_history=table([0;0.1],[0;0],[0;0],[0;0],[0;0],[0;0],[0;0], ...
                'VariableNames',{'time_s','Fx_N','Fy_N','Fz_N','Mx_Nm','My_Nm','Mz_Nm'});
            raw.motion.mode="time_history";
            raw.motion.time_history=array2table([0 zeros(1,9);0.2 zeros(1,9)], ...
                'VariableNames',{'time_s','a_x','a_y','a_z','omega_x','omega_y','omega_z','alpha_x','alpha_y','alpha_z'});
            cfg=msbsreq.resolveConfig(raw);root=string(fileparts(fileparts(mfilename('fullpath'))));
            testCase.verifyError(@()msbsreq.validateConfig(cfg,root),'msbsreq:TimeHistoryMismatch');
        end

        function sixDofFactorialRequiresExplicitOptIn(testCase)
            raw.aero.mode="coefficients_6dof";raw.aero.CY=msbsreq.rangeSpec(0,0.1,"absolute");
            cfg=msbsreq.resolveConfig(raw);root=string(fileparts(fileparts(mfilename('fullpath'))));
            testCase.verifyError(@()msbsreq.validateConfig(cfg,root),'msbsreq:Explicit6DOFFactorialRequired');
            raw.combinations.allow_full_factorial_6dof=true;
            cfg=msbsreq.resolveConfig(raw);
            testCase.verifyWarningFree(@()msbsreq.validateConfig(cfg,root));
        end

        function sixDofCorrelatedRowsRequireMotionCaseWhenMotionVaries(testCase)
            raw.aero.mode="coefficients_6dof";raw.combinations.strategy="user_defined";
            raw.combinations.user_scenarios=table("one",20,0.5, ...
                'VariableNames',{'scenario_name','speed_mps','CD'});
            raw.motion.mode="harmonic_single_frequency";raw.motion.harmonic.samples_per_cycle=4;
            cfg=msbsreq.resolveConfig(raw);
            testCase.verifyError(@()msbsreq.buildScenarioTable(cfg),'msbsreq:AmbiguousMotionCorrelation');
        end

        function metadataPassesToScenarioAndResult(testCase)
            cfg=case_test_equivalence();cfg.output.enable=false;cfg.visualisation.enable=false;
            cfg.aero.mode="coefficients_6dof";cfg.combinations.strategy="user_defined";
            cfg.combinations.user_scenarios=table("meta",20,0.5,0.1,12345,"paper_A", ...
                'VariableNames',{'scenario_name','speed_mps','CD','CY','Re','source_id'});
            study=runStudy(cfg);
            testCase.verifyTrue(ismember('Re',study.scenarios.Properties.VariableNames));
            testCase.verifyTrue(ismember('source_id',study.results.Properties.VariableNames));
            testCase.verifyEqual(study.results.Re(1),12345);
            testCase.verifyEqual(study.results.source_id(1),"paper_A");
        end

        function baselinePerturbationMatchesDirectIncrement(testCase)
            cfg=case_test_equivalence();cfg.output.enable=false;cfg.visualisation.enable=false;
            cfg.requirement_resolution.enable=true;
            cfg.requirement_resolution.delta_wrench_cases=table("one",1e-3,0,0,0,2e-4,0,"T", ...
                'VariableNames',{'name','dFx_N','dFy_N','dFz_N','dMx_Nm','dMy_Nm','dMz_Nm','frame'});
            study=runStudy(cfg);R=study.resolution_results;
            testCase.verifyEqual(height(R),height(study.results));
            testCase.verifyLessThan(max(R.baseline_plus_perturbation_consistency_norm),1e-10);
            testCase.verifyLessThan(max(R.relative_incremental_residual),1e-6);
        end


        function zeroResolutionIncrementIsStable(testCase)
            cfg=case_test_equivalence();cfg.output.enable=false;cfg.visualisation.enable=false;
            cfg.requirement_resolution.enable=true;
            cfg.requirement_resolution.delta_wrench_cases=table("zero",0,0,0,0,0,0,"T", ...
                'VariableNames',{'name','dFx_N','dFy_N','dFz_N','dMx_Nm','dMy_Nm','dMz_Nm','frame'});
            study=runStudy(cfg);R=study.resolution_results;
            testCase.verifyEqual(R.norm_delta_B0_T,zeros(height(R),1),'AbsTol',1e-12);
            testCase.verifyEqual(R.norm_delta_G_Tpm,zeros(height(R),1),'AbsTol',1e-12);
            testCase.verifyLessThan(max(R.relative_incremental_residual),1e-12);
        end

        function numericalScaleFieldsRetainSemantics(testCase)
            cfg=msbsreq.defaultConfig();
            testCase.verifyEqual(cfg.magnetic.minimum_force_scale_N,1e-9);
            testCase.verifyEqual(cfg.magnetic.minimum_moment_scale_Nm,1e-9);
            testCase.verifyFalse(cfg.requirement_resolution.enable);
        end
    end
end

function [geom,mp,s]=localAeroSetup()
cfg=msbsreq.resolveConfig(struct());t=msbsreq.buildTunnel(cfg);geom=msbsreq.buildGeometry(cfg,t);
mp=struct('centre_of_mass_B_m',[0;0;0]);
s=struct('rho_kgm3',1.2,'speed_mps',10,'CD',0.5,'CY',0,'CL',0.1, ...
    'Cl',0,'Cm',0.02,'Cn',0,'R_TW',eye(3),'R_TB',eye(3),'R_ET',eye(3));
end

function s=localScenario(S,cfg,rho)
s=struct();s.aero_source_mode=string(S.aero_source_mode(1));s.rho_kgm3=rho;s.speed_mps=S.speed_mps(1);
s.CD=S.CD(1);s.CY=S.CY(1);s.CL=S.CL(1);s.Cl=S.Cl(1);s.Cm=S.Cm(1);s.Cn=S.Cn(1);
s.R_TB=S.R_TB{1};s.R_TW=S.R_TW{1};s.R_ET=cfg.frames.R_ET;
s.aero_force_input=S.aero_force_input{1};s.aero_moment_input=S.aero_moment_input{1};
s.aero_input_frame=string(S.aero_input_frame(1));s.aero_reference_point_B_m=S.aero_reference_point_B_m{1};
end
