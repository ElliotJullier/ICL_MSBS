classdef TestRequirementsRevision < matlab.unittest.TestCase
    methods(TestClassSetup)
        function researchPath(t)
            root=fileparts(fileparts(mfilename('fullpath')));
            t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root,'research')));
        end
    end
    methods(Test)
        function replaceOffsetCavityWithMagnet(t)
            cfg=msbsreq.defaultConfig();
            cfg.mass.solid_abs_density_kgm3=1000;
            g=struct('type',"cuboid",'volume_m3',1,'outer_dimensions_B_m',ones(3,1));
            m=struct('mass_kg',7,'volume_m3',.001,'dimensions_local_m',.1*ones(3,1), ...
                'centre_B_m',[.25;0;0],'R_BM',eye(3));
            mp=msbsreq.calculateMassProperties(cfg,g,struct('id',"test",'magnets',m));
            c=6*.25/1006;
            t.verifyEqual(mp.total_mass_kg,1006,'AbsTol',1e-12);
            t.verifyEqual(mp.centre_of_mass_B_m,[c;0;0],'AbsTol',1e-14);
            want=eye(3)*(1000/6+6*.1^2/6)+diag([0 1 1])*(6*.25^2-1006*c^2);
            t.verifyEqual(mp.inertia_B_kgm2,want,'AbsTol',1e-12);
            t.verifyError(@()msbsreq.calculateMassProperties(cfg,g,struct('id',"test",'magnets',[m m])), ...
                'msbsreq:OverlappingSolidCavities');
        end
        function exactPrismProperties(t)
            [V,C,I]=msbsstudy.prismProperties([0 0;2 0;2 3;0 3],4);
            t.verifyEqual(V,24);
            t.verifyEqual(C,[1;0;1.5],'AbsTol',1e-13);
            t.verifyEqual(I,2*diag([25 13 20]),'AbsTol',1e-13);
        end
        function completeAssemblyCapAndVolume(t)
            large=msbsstudy.revisionCase("cuboid",1,.20,"h",1);
            small=msbsstudy.revisionCase("cuboid",1,.20,"h",.1);
            poses=msbsreq.buildScenarioTable(large).R_TB;
            for i=1:numel(large.magnets.sets)
                a=large.magnets.sets(i).magnets;
                b=small.magnets.sets(i).magnets;
                volumes=arrayfun(@(m)prod(m.dimensions_local_m),a);
                t.verifyTrue(all(volumes(2:end)<volumes(1)));
                t.verifyEqual(sum(arrayfun(@(m)prod(m.dimensions_local_m),b)), ...
                    .1*sum(arrayfun(@(m)prod(m.dimensions_local_m),a)),'AbsTol',1e-12);
                for R=[{eye(3)};poses].'
                    t.verifyLessThanOrEqual(max(msbsstudy.magnetExtent(a,R{1})),.30+1e-10);
                end
            end
        end
        function sourceReynoldsAndBlockage(t)
            for H=[.6 1]
                for b=[.03 .10 .20]
                    cfg=msbsstudy.revisionCase("naca0012",H,b,"up",1);
                    S=cfg.scenarios;
                    t.verifyEqual(unique(S.Re),[129000;215000;300000]);
                    t.verifyEqual(S.speed_mps.*S.Re_length_m/(1.81e-5/1.225),S.Re,'RelTol',1e-12);
                    t.verifyEqual(max(S.projected_blockage_ratio),b,'AbsTol',1e-11);
                end
            end
            t.verifyError(@()msbsstudy.revisionCase("cylinder_crossflow",1,.10,"h",1), ...
                'msbsstudy:SourceSpan');
        end
        function rankingHoldsHardwareThroughHistory(t)
            T=table(["A";"A";"A";"B";"B";"B"],["g1";"g1";"g2";"g1";"g1";"g2"], ...
                'VariableNames',{'magnet_set_id','operating_group'});
            [S,W]=msbsstudy.selectHardware(T,[1;8;2;4;4;5],true(6,1),"L");
            t.verifyEqual(W.fixed_winner,"B");
            t.verifyEqual(W.fixed_worst_J_T,5);
            t.verifyEqual(W.independent_worst_J_T,4);
            t.verifyEqual(S.magnet_set_id(S.selection_mode=="independent_group"),["B";"B";"A"]);
        end
    end
end
