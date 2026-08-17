classdef TestAerodynamicExtensions < matlab.unittest.TestCase
    methods(Test)
        function sixCoefficientDimensionalisation(testCase)
            [geom,mp,s]=localAeroSetup();
            geom.reference_area_m2=2;
            geom.reference_length_m=0.5;
            geom.reference_span_m=1.2;
            s.CD=1;s.CY=2;s.CL=3;s.Cl_roll=4;s.Cm=5;s.Cn=6;
            s.rho_kgm3=1;s.speed_mps=2;
            w=msbsreq.calculateAeroWrench(s,geom,mp);
            q=2;S=2;b=1.2;c=0.5;
            expected=q*S*[1;2;3;b*4;c*5;b*6];
            testCase.verifyEqual(w,expected,'AbsTol',1e-13);
        end

        function optionalMomentChannelsCanBeZero(testCase)
            [geom,mp,s]=localAeroSetup();
            geom.aero_reference_point_B_m=zeros(3,1);
            s.Cl_roll=0;s.Cm=0;s.Cn=0;
            w=msbsreq.calculateAeroWrench(s,geom,mp);
            testCase.verifyEqual(w(4:6),zeros(3,1),'AbsTol',1e-14);
        end

        function directWrenchEqualsEquivalentCoefficientWrench(testCase)
            [geom,mp,s]=localAeroSetup();
            geom.reference_area_m2=0.2;
            geom.reference_length_m=0.3;
            geom.reference_span_m=0.4;
            geom.aero_reference_point_B_m=[0.05;0;0];
            s.CD=0.7;s.CY=-0.2;s.CL=0.3;s.Cl_roll=0.1;s.Cm=-0.05;s.Cn=0.08;
            wCoeff=msbsreq.calculateAeroWrench(s,geom,mp);
            q=0.5*s.rho_kgm3*s.speed_mps^2;
            forceT=q*geom.reference_area_m2*[s.CD;s.CY;s.CL];
            momentT=q*geom.reference_area_m2*[geom.reference_span_m*s.Cl_roll; ...
                geom.reference_length_m*s.Cm;geom.reference_span_m*s.Cn];
            s.aero_source_mode="direct_wrench";
            s.aero_force_input=forceT;
            s.aero_moment_input=momentT;
            s.aero_input_frame="T";
            s.aero_reference_point_B_m=geom.aero_reference_point_B_m;
            s.R_ET=eye(3);
            wDirect=msbsreq.calculateAeroWrench(s,geom,mp);
            testCase.verifyEqual(wDirect,wCoeff,'AbsTol',1e-12);
        end

        function directWrenchTransformsAndShifts(testCase)
            raw.aero.mode="direct_wrench";
            raw.frames.body_to_tunnel.yaw_pitch_roll_deg=[90 0 0];
            point={[0.1;0;0]};
            raw.scenarios=table("one",0,1,0,0,0,0,"B",point, ...
                'VariableNames',{'scenario_name','Fx_aero_N','Fy_aero_N','Fz_aero_N', ...
                'Mx_aero_Nm','My_aero_Nm','Mz_aero_Nm','aero_frame','aero_reference_point_B_m'});
            cfg=msbsreq.resolveConfig(raw);
            S=msbsreq.buildScenarioTable(cfg);
            t=msbsreq.buildTunnel(cfg);
            g=msbsreq.buildGeometry(cfg,t);
            mp=struct('centre_of_mass_B_m',[0;0;0]);
            w=msbsreq.calculateAeroWrench(localScenario(S,cfg,t.rho_kgm3),g,mp);
            testCase.verifyEqual(w(1:3),[-1;0;0],'AbsTol',1e-12);
            testCase.verifyEqual(w(4:6),[0;0;0.1],'AbsTol',1e-12);
        end

        function directWrenchAndMotionSharePhysicalRow(testCase)
            cfg=case_test_equivalence();
            cfg.output.enable=false;
            cfg.visualisation.enable=false;
            cfg.aero.mode="direct_wrench";
            cfg.motion.mode="specified";
            cfg.scenarios=table(["one";"two"],[1;2],[0;0],[0;0],[0;0],[0;0],[0;0], ...
                [3;4],[0;0],[0;0],[0;0],[0;0],[0;0],[0;0],[0;0],[0;0],[10000;20000], ...
                'VariableNames',{'scenario_name','Fx_aero_N','Fy_aero_N','Fz_aero_N', ...
                'Mx_aero_Nm','My_aero_Nm','Mz_aero_Nm','a_x','a_y','a_z', ...
                'omega_x','omega_y','omega_z','alpha_x','alpha_y','alpha_z','Re'});
            study=runStudy(cfg);
            testCase.verifyEqual(height(study.scenarios),2);
            row=study.results(study.results.scenario_id=="S00002",:);
            row=row(1,:);
            m=study.mass_properties(1).total_mass_kg;
            testCase.verifyEqual(row.Fx_aero_N,2,'AbsTol',1e-12);
            testCase.verifyEqual(row.Fx_inertial_demand_N,4*m,'AbsTol',1e-10);
            testCase.verifyEqual(row.Fx_mag_req_N,4*m-2,'AbsTol',1e-10);
            testCase.verifyEqual(row.Re,20000);
        end

        function harmonicRowsKeepAerodynamicsAndMotionMatched(testCase)
            raw.tunnel.speed_mps=20;
            raw.aero.CD=0.5;
            raw.motion.mode="harmonic";
            raw.motion.harmonic.frequency_Hz=1;
            raw.motion.harmonic.translation_amplitude_m=[0.01;0;0];
            raw.scenarios=table(["p0";"p90"],[0;pi/2],[0.5;0.8], ...
                'VariableNames',{'scenario_name','phase_rad','CD'});
            cfg=msbsreq.resolveConfig(raw);
            S=msbsreq.buildScenarioTable(cfg);
            testCase.verifyEqual(height(S),2);
            testCase.verifyEqual(S.CD,[0.5;0.8]);
            testCase.verifyEqual(S.a_C_T_mps2{1},zeros(3,1),'AbsTol',1e-12);
            testCase.verifyEqual(S.a_C_T_mps2{2}(1),-(2*pi)^2*0.01,'AbsTol',1e-12);
        end

        function metadataPassesToScenarioAndResult(testCase)
            cfg=case_test_equivalence();
            cfg.output.enable=false;
            cfg.visualisation.enable=false;
            cfg.scenarios=table("meta",20,0.5,12345,"paper_A", ...
                'VariableNames',{'scenario_name','speed_mps','CD','Re','source_id'});
            study=runStudy(cfg);
            testCase.verifyTrue(ismember('Re',study.scenarios.Properties.VariableNames));
            testCase.verifyTrue(ismember('source_id',study.results.Properties.VariableNames));
            testCase.verifyEqual(study.results.Re(1),12345);
            testCase.verifyEqual(study.results.source_id(1),"paper_A");
        end

        function directWrenchMissingComponentsRejected(testCase)
            raw.aero.mode="direct_wrench";
            raw.scenarios=table("bad",1,0,0, ...
                'VariableNames',{'scenario_name','Fx_aero_N','Fy_aero_N','Fz_aero_N'});
            cfg=msbsreq.resolveConfig(raw);
            root=string(fileparts(fileparts(mfilename('fullpath'))));
            testCase.verifyError(@()msbsreq.validateConfig(cfg,root),'msbsreq:MissingAeroWrenchColumns');
        end

        function streamlinedDefaultsExcludeRemovedSubsystems(testCase)
            cfg=msbsreq.defaultConfig();
            testCase.verifyEqual(cfg.aero.mode,"coefficients");
            testCase.verifyFalse(isfield(cfg,'combinations'));
            testCase.verifyFalse(isfield(cfg,'requirement_resolution'));
            testCase.verifyFalse(isfield(cfg.frames,'wind_orientation_cases'));
        end
    end
end

function [geom,mp,s]=localAeroSetup()
cfg=msbsreq.resolveConfig(struct());
t=msbsreq.buildTunnel(cfg);
geom=msbsreq.buildGeometry(cfg,t);
mp=struct('centre_of_mass_B_m',[0;0;0]);
s=struct('aero_source_mode',"coefficients",'rho_kgm3',1.2,'speed_mps',10, ...
    'CD',0.5,'CY',0,'CL',0.1,'Cl_roll',0,'Cm',0.02,'Cn',0,'R_TB',eye(3));
end

function s=localScenario(S,cfg,rho)
s=struct();
s.scenario_id=S.scenario_id(1);
s.scenario_name=S.scenario_name(1);
s.aero_source_mode=S.aero_source_mode(1);
s.speed_mps=S.speed_mps(1);
s.CD=S.CD(1);s.CY=S.CY(1);s.CL=S.CL(1);s.Cl_roll=S.Cl_roll(1);s.Cm=S.Cm(1);s.Cn=S.Cn(1);
s.R_TB=S.R_TB{1};s.R_ET=cfg.frames.R_ET;
s.a_C_T_mps2=S.a_C_T_mps2{1};s.omega_T_radps=S.omega_T_radps{1};s.alpha_T_radps2=S.alpha_T_radps2{1};
s.aero_force_input=S.aero_force_input{1};s.aero_moment_input=S.aero_moment_input{1};
s.aero_input_frame=S.aero_input_frame(1);s.aero_reference_point_B_m=S.aero_reference_point_B_m{1};
s.motion_mode=S.motion_mode(1);s.motion_phase_rad=S.motion_phase_rad(1);s.time_s=S.time_s(1);s.rho_kgm3=rho;s.metadata=struct();
end
