classdef TestResearchExtensions < matlab.unittest.TestCase
    methods(TestClassSetup)
        function researchPath(testCase)
            root=fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root,'research')));
        end
    end
    methods(Test)
        function affineOriginPreservesMagnetFields(t)
            B=[.01;.02;-.03];G=[1 .2 .3;.2 -2 .4;.3 .4 1];r=[.1;-.2;.3];p=[.02;.03;-.04];
            BO=msbsreq.fieldAtTunnelOrigin(B,G,r);
            t.verifyEqual(BO+G*(r+p),B+G*p,'AbsTol',1e-15);
        end
        function positionDoesNotChangeLocalSolve(t)
            cfg=msbsstudy.makeCase("sphere",.6,.10,"h",1);
            cfg.scenarios=cfg.scenarios(1,:);cfg.position.mode="specified";
            cfg.scenarios.x_C_T_m=0;cfg.scenarios.y_C_T_m=0;cfg.scenarios.z_C_T_m=0;
            info=struct('source_type',"test",'case_function_name',"",'case_file_path',"");root=string(fileparts(fileparts(mfilename('fullpath'))));
            a=msbsreq.run(cfg,root,info);cfg.scenarios.x_C_T_m=.02;b=msbsreq.run(cfg,root,info);
            t.verifyEqual(a.results.Bx_T,b.results.Bx_T,'AbsTol',1e-12);
            t.verifyEqual(a.results.G_frobenius_Tpm,b.results.G_frobenius_Tpm,'AbsTol',1e-12);
            t.verifyGreaterThan(max(abs(a.results.BOx_T-b.results.BOx_T)),0);
        end
        function analyticTranslationIsConsistent(t)
            cfg=msbsreq.defaultConfig();cfg.motion.mode="harmonic";cfg.motion.harmonic.frequency_Hz=2;
            cfg.motion.harmonic.translation_amplitude_m=[0;0;.01];cfg.position.mode="harmonic_analytic";
            cfg.scenario_set.relationship="time_history";S=msbsreq.buildScenarioTable(msbsreq.resolveConfig(cfg));
            for k=[1 7 19]
                t.verifyEqual(S.a_C_T_mps2{k}(:),-(4*pi)^2*S.r_C_T_m{k}(:),'AbsTol',1e-12);
            end
        end
        function historiesCannotUseUnorderedTimes(t)
            cfg=msbsreq.defaultConfig();cfg.scenario_set.relationship="time_history";
            cfg.scenarios=table([1;0],'VariableNames',{'time_s'});
            t.verifyError(@()msbsreq.buildScenarioTable(msbsreq.resolveConfig(cfg)),'msbsreq:InvalidHistoryTime');
            cfg.scenario_set.relationship="independent";S=msbsreq.buildScenarioTable(msbsreq.resolveConfig(cfg));
            t.verifyEqual(height(S),2);
        end
        function fixedResidualMassSurvivesMagnetShrink(t)
            root=string(fileparts(fileparts(mfilename('fullpath'))));
            a=msbsstudy.makeCase("sphere",.6,.1,"h",1);b=msbsstudy.makeCase("sphere",.6,.1,"h",.1);
            ga=msbsreq.buildGeometry(a,msbsreq.buildTunnel(a));gb=msbsreq.buildGeometry(b,msbsreq.buildTunnel(b));
            ma=msbsreq.buildMagnetSets(a,ga,root);mb=msbsreq.buildMagnetSets(b,gb,root);
            pa=msbsreq.calculateMassProperties(a,ga,ma(1));pb=msbsreq.calculateMassProperties(b,gb,mb(1));
            t.verifyEqual(pb.magnet_mass_kg/pa.magnet_mass_kg,.1,'AbsTol',1e-12);
            t.verifyEqual(pb.shell_mass_kg,pa.shell_mass_kg,'AbsTol',1e-12);
        end
        function sourceFourierFitsAreRecomputed(t)
            t.verifyEqual(msbsstudy.jannCoefficients(0,0),[.3753 0 0 0 0 0],'AbsTol',1e-12);
            t.verifyEqual(msbsstudy.jannCoefficients(25,-45),[.743947 -.032449 .402542 .025319 .046606 .015231],'AbsTol',6e-7);
        end
        function cuboidSourceAxesAreExplicit(t)
            cfg=msbsstudy.makeCase("cuboid",.6,.1,"h",1);
            t.verifyEqual(cfg.scenarios.attitude_R_TB{1},diag([-1 1 -1]),'AbsTol',1e-12);
            C=msbsstudy.jannCoefficients(0,-45);R=cfg.scenarios.attitude_R_TB{2};
            t.verifyLessThan(R(1,1),0);t.verifyGreaterThan(R(2,1),0);
            expected=R*C(4:6).';actual=cfg.scenarios{2,{'Mx_aero_Nm','My_aero_Nm','Mz_aero_Nm'}}.';
            t.verifyEqual(actual/norm(actual),expected/norm(expected),'AbsTol',1e-12);
        end
        function auxiliaryAuthorityAndEqualVolumes(t)
            root=string(fileparts(fileparts(mfilename('fullpath'))));cfg=msbsstudy.makeCase("cuboid",.6,.1,"h",1);
            geo=msbsreq.buildGeometry(cfg,msbsreq.buildTunnel(cfg));sets=msbsreq.buildMagnetSets(cfg,geo,root);
            volumes=zeros(15,1);ranks=zeros(15,1);
            for k=4:18
                volumes(k-3)=sum([sets(k).magnets.volume_m3]);
                map=msbsreq.buildMagneticMap(sets(k),eye(3),zeros(3,1));ranks(k-3)=map.rank;
                m=sets(k).magnets;
                for i=1:numel(m)-1
                    for j=i+1:numel(m)
                        gap=abs(m(i).centre_B_m-m(j).centre_B_m)-(m(i).dimensions_local_m+m(j).dimensions_local_m)/2;
                        t.verifyTrue(any(gap>0));
                    end
                end
            end
            t.verifyEqual(volumes,repmat(volumes(1),15,1),'RelTol',1e-12);
            t.verifyTrue(any(ranks==6));
        end
        function shortenedVariantsFit(t)
            for family=["cylinder_crossflow","naca0012","sc20714"]
                cfg=msbsstudy.makeCase(family,.6,.2,"h",1);
                t.verifyLessThan(max(cfg.scenarios.wall_envelope_fraction),1);
                t.verifyEqual(max(cfg.scenarios.projected_blockage_ratio),.2,'AbsTol',1e-8);
                t.verifyLessThan(cfg.meta.aspect_ratio,3+double(family=="cylinder_crossflow")*5);
            end
        end
        function upwardGravityAndBlockage(t)
            cfg=msbsstudy.makeCase("cuboid",1,.2,"up",.1);tun=msbsreq.buildTunnel(cfg);
            t.verifyEqual(tun.gravity_T_mps2,[-9.80665;0;0],'AbsTol',1e-12);
            t.verifyEqual(max(cfg.scenarios.projected_blockage_ratio),.2,'AbsTol',1e-12);
            t.verifyLessThanOrEqual(max(cfg.scenarios.speed_mps),50);
        end
        function sourceAirfoilAndAhmedSigns(t)
            a=msbsstudy.makeCase("naca0012",.6,.1,"h",1);S=msbsreq.buildScenarioTable(a);
            k=find(a.scenarios.pitch_deg==7,1);leading=S.R_TB{k}*[-1;0;0];
            t.verifyGreaterThan(leading(3),0);
            t.verifyTrue(any(a.scenarios.Cm>0)&&any(a.scenarios.Cm<0));
            a=msbsstudy.makeCase("ahmed",.6,.1,"h",1);S=msbsreq.buildScenarioTable(a);
            k=find(a.scenarios.beta_deg==15,1);nose=S.R_TB{k}*[-1;0;0];
            t.verifyGreaterThan(nose(2),0);
        end
    end
end
