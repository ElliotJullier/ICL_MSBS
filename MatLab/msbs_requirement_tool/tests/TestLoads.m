classdef TestLoads < matlab.unittest.TestCase
    methods(Test)
        function speedScaling(testCase)
            [geom,mp,s]=localAeroSetup();
            s.speed_mps=0;
            w0=msbsreq.calculateAeroWrench(s,geom,mp);
            testCase.verifyEqual(w0,zeros(6,1),'AbsTol',1e-14);
            s.speed_mps=10;
            w1=msbsreq.calculateAeroWrench(s,geom,mp);
            s.speed_mps=20;
            w2=msbsreq.calculateAeroWrench(s,geom,mp);
            testCase.verifyEqual(w2,4*w1,'RelTol',1e-12);
            testCase.verifyGreaterThan(w1(1),0);
        end

        function referencePointMoment(testCase)
            [geom,mp,s]=localAeroSetup();
            s.speed_mps=10;
            s.Cm=0;
            geom.aero_reference_point_B_m=[0;0.1;0];
            w=msbsreq.calculateAeroWrench(s,geom,mp);
            testCase.verifyEqual(w(6),-0.1*w(1),'RelTol',1e-12);
        end

        function gyroscopicTerm(testCase)
            mp.inertia_B_kgm2=diag([1 2 3]);
            mp.total_mass_kg=1;
            s.R_TB=eye(3);
            s.a_C_T_mps2=zeros(3,1);
            s.omega_T_radps=[1;1;0];
            s.alpha_T_radps2=zeros(3,1);
            d=msbsreq.calculateInertialDemand(s,mp);
            expected=cross(s.omega_T_radps,mp.inertia_B_kgm2*s.omega_T_radps);
            testCase.verifyEqual(d(4:6),expected,'AbsTol',1e-14);
        end

        function harmonicPeakAccelerationAndAttitude(testCase)
            raw.motion.mode="harmonic";
            raw.motion.harmonic.frequency_Hz=2;
            raw.motion.harmonic.translation_amplitude_m=[0.01;0;0];
            raw.motion.harmonic.angular_amplitude_rad=[0;0.1;0];
            raw.motion.harmonic.samples_per_cycle=4;
            cfg=msbsreq.resolveConfig(raw);
            S=msbsreq.buildScenarioTable(cfg);
            accelerationMagnitudes=cellfun(@norm,S.a_C_T_mps2);
            testCase.verifyEqual(max(accelerationMagnitudes),(2*pi*2)^2*0.01,'RelTol',1e-12);
            testCase.verifyGreaterThan(norm(S.R_TB{2}-eye(3),'fro'),0);
        end

        function gravityChangesWithTunnelOrientation(testCase)
            raw.frames.tunnel_to_earth.yaw_pitch_roll_deg=[0 -90 0];
            cfg1=msbsreq.resolveConfig(raw);
            t1=msbsreq.buildTunnel(cfg1);
            raw.frames.tunnel_to_earth.yaw_pitch_roll_deg=[0 90 0];
            cfg2=msbsreq.resolveConfig(raw);
            t2=msbsreq.buildTunnel(cfg2);
            testCase.verifyLessThan(t1.gravity_T_mps2(1)*t2.gravity_T_mps2(1),0);
            testCase.verifyEqual(norm(t1.gravity_T_mps2),9.80665,'AbsTol',1e-12);
        end

        function additionalWrenchTransformsAndShifts(testCase)
            root=string(fileparts(fileparts(mfilename('fullpath'))));
            point={[0.01;0;0]};
            raw.frames.body_to_tunnel.yaw_pitch_roll_deg=[90 0 0];
            raw.additional_wrenches=table("test",0,1,0,0,0,0,"B",point, ...
                'VariableNames',{'name','Fx_N','Fy_N','Fz_N','Mx_Nm','My_Nm','Mz_Nm','components_frame','reference_point_B_m'});
            cfg=msbsreq.resolveConfig(raw);
            t=msbsreq.buildTunnel(cfg);
            g=msbsreq.buildGeometry(cfg,t);
            [sets,~]=msbsreq.buildMagnetSets(cfg,g,root);
            mp=msbsreq.calculateMassProperties(cfg,g,sets(1));
            S=msbsreq.buildScenarioTable(cfg);
            loads=msbsreq.calculateRequiredMagneticWrench(cfg,t,g,S(1,:),mp);
            testCase.verifyEqual(loads.other_wrench_T(1:3),[-1;0;0],'AbsTol',1e-12);
            testCase.verifyEqual(loads.other_wrench_T(4:6),[0;0;0.01],'AbsTol',1e-12);
        end

        function combinedBalanceUsesSingleTunnelFrameWrench(testCase)
            cfg=case_test_equivalence();
            cfg.output.enable=false;
            cfg.visualisation.enable=false;
            cfg.aero.mode="direct_wrench";
            cfg.motion.mode="specified";
            cfg.scenarios=table("combined",2,0,0,0,0,0,3,0,0,0,0,0,0,0,0, ...
                'VariableNames',{'scenario_name','Fx_aero_N','Fy_aero_N','Fz_aero_N', ...
                'Mx_aero_Nm','My_aero_Nm','Mz_aero_Nm','a_x','a_y','a_z', ...
                'omega_x','omega_y','omega_z','alpha_x','alpha_y','alpha_z'});
            study=runStudy(cfg);
            row=study.results(1,:);
            m=study.mass_properties(1).total_mass_kg;
            testCase.verifyEqual(row.Fx_mag_req_N,3*m-2,'AbsTol',1e-10);
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
