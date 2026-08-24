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
            sol=msbsreq.solveMagneticRequirement(map,[0;0;0;1;0;0],scales,cfg,localCostMetric(1));
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
        function minimumGradientUsesFrobeniusMetric(testCase)
            set=localSet([1;0;0],[0;0;0]);
            map=msbsreq.buildMagneticMap(set,eye(3),zeros(3,1));
            cfg=msbsreq.resolveConfig(struct());
            scales=struct('force_N',1,'moment_Nm',1);
            % L=sqrt(12) gives ell=L/sqrt(12)=1 m, so the gradient cost is ||G||F.
            sol=msbsreq.solveMagneticRequirement(map,[1;0;0;0;0;0],scales,cfg,localCostMetric(sqrt(12)));
            expected=diag([1 -0.5 -0.5]);
            testCase.verifyEqual(sol.G_Tpm,expected,'AbsTol',1e-12);
            testCase.verifyEqual(sol.G_frobenius_Tpm,sqrt(1.5),'AbsTol',1e-12);
        end
        function centredMapIsForceTorqueDecoupled(testCase)
            cfg=msbsreq.resolveConfig(struct());
            set=localSet([1;0;0],[0;0;0]);map=msbsreq.buildMagneticMap(set,eye(3),zeros(3,1));
            coupling=msbsreq.analyseMagneticCoupling(map,localCostMetric(0.2),cfg);
            testCase.verifyEqual(coupling.classification,"zero");
            testCase.verifyEqual(coupling.ratio,0,'AbsTol',1e-14);
        end
        function offsetMapDetectsGradientMomentCoupling(testCase)
            cfg=msbsreq.resolveConfig(struct());
            set=localSet([1;0;0],[0;0.2;0]);map=msbsreq.buildMagneticMap(set,eye(3),zeros(3,1));
            coupling=msbsreq.analyseMagneticCoupling(map,localCostMetric(0.1),cfg);
            testCase.verifyNotEqual(coupling.classification,"zero");
            testCase.verifyGreaterThan(coupling.ratio,cfg.magnetic.coupling.zero_ratio_tolerance);
        end
        function decoupledReferenceLengthDoesNotChangePhysicalSolution(testCase)
            cfg=msbsreq.resolveConfig(struct());scales=struct('force_N',1,'moment_Nm',1);
            set=localSet([1;0;0],[0;0;0]);map=msbsreq.buildMagneticMap(set,eye(3),zeros(3,1));
            w=[1;0.2;-0.3;0;0.4;-0.2];
            short=msbsreq.solveMagneticRequirement(map,w,scales,cfg,localCostMetric(0.01));
            long=msbsreq.solveMagneticRequirement(map,w,scales,cfg,localCostMetric(10));
            testCase.verifyEqual(short.x,long.x,'AbsTol',1e-10);
        end
        function rmsCostAndEnergyDensityMatchDefinition(testCase)
            cfg=msbsreq.resolveConfig(struct());scales=struct('force_N',1,'moment_Nm',1);
            set=localSet([1;1;0],[0;0;0]);map=msbsreq.buildMagneticMap(set,eye(3),zeros(3,1));
            metric=localCostMetric(0.24);
            sol=msbsreq.solveMagneticRequirement(map,[1;2;0;0;0;0],scales,cfg,metric);
            expected=sqrt(sol.B0_norm_T^2+(metric.reference_cube_side_m^2/12)*sol.G_frobenius_Tpm^2);
            testCase.verifyEqual(sol.magnetic_cost_rms_T,expected,'RelTol',1e-12);
            testCase.verifyEqual(sol.mean_vacuum_energy_density_Jpm3,expected^2/(2*4*pi*1e-7),'RelTol',1e-12);
        end
        function relativeLengthCostMatchesSingleScaleDefinition(testCase)
            cfg=msbsreq.resolveConfig(struct());scales=struct('force_N',1,'moment_Nm',1);
            set=localSet([1;1;0],[0.05;0.03;0]);map=msbsreq.buildMagneticMap(set,eye(3),zeros(3,1));
            metric=localRelativeCostMetric(0.1);
            sol=msbsreq.solveMagneticRequirement(map,[1;2;0;0.1;0.3;-0.2],scales,cfg,metric);
            expected=sqrt(sol.B0_norm_T^2+metric.relative_length_scale_m^2*sol.G_frobenius_Tpm^2);
            testCase.verifyEqual(sol.relative_field_gradient_cost_T,expected,'RelTol',1e-12);
            testCase.verifyEqual(sol.magnetic_cost_value_T,expected,'RelTol',1e-12);
            testCase.verifyTrue(isnan(sol.magnetic_cost_rms_T));
            testCase.verifyTrue(isnan(sol.mean_vacuum_energy_density_Jpm3));
        end
        function sensitivityMetricFamiliesAreDistinct(testCase)
            cfg=msbsreq.resolveConfig(struct());
            tunnel=msbsreq.buildTunnel(cfg);geometry=msbsreq.buildGeometry(cfg,tunnel);
            metrics=msbsreq.buildMagneticCostMetrics(geometry,tunnel,cfg);
            T=struct2table(metrics.sensitivity,'AsArray',true);
            testCase.verifyEqual(height(T),7);
            testCase.verifyEqual(sum(T.metric_type=="relative_length"),4);
            testCase.verifyEqual(sum(T.metric_type=="reference_volume_rms"),3);
            relative=sort(T.relative_length_scale_m(T.metric_type=="relative_length"));
            testCase.verifyEqual(relative,[0.01;0.1;1;10],'AbsTol',1e-14);
            testCase.verifyEqual(metrics.primary.metric_type,"reference_volume_rms");
            testCase.verifyEqual(metrics.primary.reference_cube_side_m,max(geometry.outer_dimensions_B_m),'RelTol',1e-12);
        end
        function acceptedSetRankingUsesPrimaryCost(testCase)
            cfg=msbsreq.resolveConfig(struct());
            T=localSummaryTable();
            summary=msbsreq.summariseResults(T,cfg);
            testCase.verifyEqual(summary.best_magnet_set_id,"A");
            testCase.verifyEqual(summary.fixed_configuration_ranking.magnet_set_id(1),"A");
        end
        function independentRankingCanDifferFromFixedRanking(testCase)
            cfg=msbsreq.resolveConfig(struct());
            T=localSummaryTable();
            summary=msbsreq.summariseResults(T,cfg);
            % A is the better fixed set (worst cost 5 vs B worst cost 10), but
            % scenario S2 independently prefers B (cost 1 vs A cost 5).
            row=summary.independent_scenario_ranking(summary.independent_scenario_ranking.scenario_id=="S2",:);
            testCase.verifyEqual(row.best_magnet_set_id,"B");
        end
        function componentAbsoluteExtremaRetainActualScenario(testCase)
            cfg=msbsreq.resolveConfig(struct());
            T=localSummaryTable();
            summary=msbsreq.summariseResults(T,cfg);
            row=summary.scenario_extrema(summary.scenario_extrema.magnet_set_id=="A" & ...
                summary.scenario_extrema.quantity=="Fx magnetic requirement",:);
            testCase.verifyEqual(row.value,-3);
            testCase.verifyEqual(row.scenario_id,"S2");
        end
        function noAcceptedSetHasNoBest(testCase)
            cfg=msbsreq.resolveConfig(struct());
            T=localSummaryTable();T.relative_scaled_residual(:)=1e-3;
            summary=msbsreq.summariseResults(T,cfg);
            testCase.verifyEqual(summary.best_magnet_set_id,"");
            testCase.verifyFalse(any(summary.magnet_set_summary.all_scenarios_acceptable));
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

function T=localSummaryTable()
% A: costs [1,5] -> fixed worst 5. B: [10,1] -> fixed worst 10.
magnet_set_id=["A";"A";"B";"B"];
magnet_set_name=magnet_set_id;
scenario_id=["S1";"S2";"S1";"S2"];
scenario_name=["one";"two";"one";"two"];
force_req_norm_N=ones(4,1);moment_req_norm_Nm=ones(4,1);
B_norm_T=ones(4,1);B_local_max_norm_T=ones(4,1);G_frobenius_Tpm=ones(4,1);G_max_abs_Tpm=ones(4,1);
magnetic_cost_rms_T=[1;5;10;1];mean_vacuum_energy_density_Jpm3=magnetic_cost_rms_T.^2;
relative_scaled_residual=1e-8*ones(4,1);map_rank=6*ones(4,1);map_condition_number=ones(4,1);
coupling_class=repmat("zero",4,1);coupling_ratio=zeros(4,1);
Fx_mag_req_N=[1;-3;1;-2];Fy_mag_req_N=zeros(4,1);Fz_mag_req_N=zeros(4,1);
Mx_mag_req_Nm=zeros(4,1);My_mag_req_Nm=zeros(4,1);Mz_mag_req_Nm=zeros(4,1);
T=table(magnet_set_id,magnet_set_name,scenario_id,scenario_name,force_req_norm_N,moment_req_norm_Nm, ...
    B_norm_T,B_local_max_norm_T,G_frobenius_Tpm,G_max_abs_Tpm,magnetic_cost_rms_T, ...
    mean_vacuum_energy_density_Jpm3,relative_scaled_residual,map_rank,map_condition_number, ...
    coupling_class,coupling_ratio,Fx_mag_req_N,Fy_mag_req_N,Fz_mag_req_N,Mx_mag_req_Nm,My_mag_req_Nm,Mz_mag_req_Nm);
end

function metric=localCostMetric(L)
metric=struct('id',"test_volume",'metric_type',"reference_volume_rms",'reference_source',"test", ...
    'reference_cube_side_m',L,'relative_length_scale_m',NaN, ...
    'gradient_equivalent_length_m',L/sqrt(12),'tunnel_length_fraction',NaN, ...
    'is_primary',true,'cost_definition',"test",'cost_interpretation',"test");
end

function metric=localRelativeCostMetric(ell)
metric=struct('id',"test_relative",'metric_type',"relative_length",'reference_source',"test", ...
    'reference_cube_side_m',NaN,'relative_length_scale_m',ell, ...
    'gradient_equivalent_length_m',ell,'tunnel_length_fraction',NaN, ...
    'is_primary',false,'cost_definition',"test",'cost_interpretation',"test");
end

function set=localSet(direction,centre)
direction=direction/norm(direction);
m=struct('centre_B_m',centre(:),'dipole_moment_B_Am2',direction(:));
set=struct('id',"test",'name',"test",'magnets',m,'automatic_candidate',false);
end
