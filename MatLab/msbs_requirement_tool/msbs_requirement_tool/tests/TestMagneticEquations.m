classdef TestMagneticEquations < matlab.unittest.TestCase
    methods(Test)
        function alignedEquations(testCase)
            mx=2.5;positions=zeros(3,1);dipoles=[mx;0;0];
            x=[0.2;-0.3;0.4;1.1;-0.2;0.5;-0.7;0.9];
            [w,~]=msbsreq.evaluateMagneticWrench(x,positions,dipoles);
            G=msbsreq.constructGradient(x);
            expectedF=G*dipoles;
            expectedT=cross(dipoles,x(1:3));
            testCase.verifyEqual(w,[expectedF;expectedT],'AbsTol',1e-13);
            testCase.verifyEqual(w(4),0,'AbsTol',1e-13);
            testCase.verifyEqual(w(5),-mx*x(3),'AbsTol',1e-13);
            testCase.verifyEqual(w(6),mx*x(2),'AbsTol',1e-13);
        end
        function gradientSourceFree(testCase)
            G=msbsreq.constructGradient((1:8).');
            testCase.verifyEqual(G,G.','AbsTol',1e-14);
            testCase.verifyEqual(trace(G),0,'AbsTol',1e-14);
        end
        function parallelTorqueResidual(testCase)
            set=localSet([1;0;0],[0;0;0]);map=msbsreq.buildMagneticMap(set,eye(3),zeros(3,1));
            cfg=msbsreq.resolveConfig(struct());scales=struct('force_N',1,'moment_Nm',1);
            sol=msbsreq.solveMagneticRequirement(map,[0;0;0;1;0;0],scales,cfg);
            testCase.verifyGreaterThan(sol.relative_scaled_residual,0.99);
            testCase.verifyFalse(sol.controllable);
        end
        function separatedMomentArm(testCase)
            positions=[0;1;0];dipoles=[1;0;0];x=zeros(8,1);x(4)=2;
            w=msbsreq.evaluateMagneticWrench(x,positions,dipoles);
            F=[2;0;0];
            testCase.verifyEqual(w(1:3),F,'AbsTol',1e-14);
            testCase.verifyEqual(w(4:6),cross(positions,F),'AbsTol',1e-14);
        end
        function basisMapMatchesDirect(testCase)
            set=localSet([1;1;0],[0.1;-0.2;0.3]);map=msbsreq.buildMagneticMap(set,eye(3),zeros(3,1));
            x=(1:8).'/10;
            direct=msbsreq.evaluateMagneticWrench(x,map.positions_T_m,map.dipoles_T_Am2);
            testCase.verifyEqual(map.A*x,direct,'AbsTol',1e-12);
        end
        function acceptedSetRankingUsesEffort(testCase)
            cfg=msbsreq.resolveConfig(struct());
            T=localSummaryTable(["A";"B"],[2;1],[1e-8;1e-8]);
            summary=msbsreq.summariseResults(T,cfg);
            testCase.verifyEqual(summary.best_magnet_set_id,"B");
        end
        function noAcceptedSetHasNoBest(testCase)
            cfg=msbsreq.resolveConfig(struct());
            T=localSummaryTable(["A";"B"],[10;1],[1e-3;2e-3]);
            summary=msbsreq.summariseResults(T,cfg);
            testCase.verifyEqual(summary.best_magnet_set_id,"");
            testCase.verifyFalse(any(summary.magnet_set_summary.all_scenarios_acceptable));
            testCase.verifyEqual(summary.ranking.magnet_set_id(1),"A");
        end
        function alignedEducationalMode(testCase)
            w=[1;2;3;4;5;6];r=msbsreq.solveAlignedRequirement(w,2);
            testCase.verifyEqual(r.dBx_dx_Tpm,0.5);
            testCase.verifyEqual(r.By_T,3);
            testCase.verifyEqual(r.Bz_T,-2.5);
            testCase.verifyEqual(r.uncontrollable_Tx_Nm,4);
        end
    end
end
function T=localSummaryTable(ids,efforts,residuals)
n=numel(ids);
T=table(ids,ids,"S"+compose('%02d',(1:n).'),ones(n,1),ones(n,1), ...
    ones(n,1),ones(n,1),ones(n,1),ones(n,1),efforts,residuals, ...
    6*ones(n,1),ones(n,1),zeros(n,1),zeros(n,1),zeros(n,1), ...
    zeros(n,1),zeros(n,1),zeros(n,1), ...
    'VariableNames',{'magnet_set_id','magnet_set_name','scenario_id', ...
    'force_req_norm_N','moment_req_norm_Nm','B_norm_T','B_local_max_norm_T', ...
    'G_frobenius_Tpm','G_max_abs_Tpm','scaled_solution_norm', ...
    'relative_scaled_residual','map_rank','map_condition_number', ...
    'Fx_mag_req_N','Fy_mag_req_N','Fz_mag_req_N', ...
    'Mx_mag_req_Nm','My_mag_req_Nm','Mz_mag_req_Nm'});
end

function set=localSet(direction,centre)
direction=direction/norm(direction);
m=struct('centre_B_m',centre(:),'dipole_moment_B_Am2',direction(:));
set=struct('id',"test",'name',"test",'magnets',m,'automatic_candidate',false);
end
