classdef TestGeometry < matlab.unittest.TestCase
    methods(Test)
        function sphereBlockage(testCase)
            cfg=msbsreq.resolveConfig(struct());
            tunnel=msbsreq.buildTunnel(cfg);
            geom=msbsreq.buildGeometry(cfg,tunnel);
            testCase.verifyEqual(geom.projected_area_nominal_m2,0.1*tunnel.area_m2,'RelTol',1e-12);
        end
        function sphereCubeVertices(testCase)
            cfg=msbsreq.resolveConfig(struct());t=msbsreq.buildTunnel(cfg);g=msbsreq.buildGeometry(cfg,t);
            a=g.inscribed_cuboid.dimensions_B_m(1);
            radius=sqrt(3)*(a/2);
            testCase.verifyEqual(radius,g.shape.diameter_m/2,'RelTol',1e-12);
        end
        function cylinderCuboidFits(testCase)
            raw.geometry.type="cylinder";raw.geometry.sizing.mode="absolute";
            raw.geometry.sizing.cylinder_diameter_m=0.2;raw.geometry.sizing.cylinder_length_m=0.5;
            raw.geometry.sizing.cylinder_axis="x";
            cfg=msbsreq.resolveConfig(raw);t=msbsreq.buildTunnel(cfg);g=msbsreq.buildGeometry(cfg,t);
            transverse=g.inscribed_cuboid.dimensions_B_m(2:3);
            testCase.verifyEqual(norm(transverse/2),0.1,'AbsTol',1e-12);
        end
        function cuboidNominalOrientationProjection(testCase)
            raw.geometry.type="cuboid";raw.geometry.sizing.mode="absolute";
            raw.geometry.sizing.nominal_dimensions_m=[0.2;0.1;0.1];
            raw.frames.body_to_tunnel.yaw_pitch_roll_deg=[45 0 0];
            cfg=msbsreq.resolveConfig(raw);t=msbsreq.buildTunnel(cfg);g=msbsreq.buildGeometry(cfg,t);
            expected=cosd(45)*0.1*0.1+sind(45)*0.2*0.1;
            testCase.verifyEqual(g.projected_area_nominal_m2,expected,'AbsTol',1e-13);
        end
        function customProxyUsesSuppliedReferences(testCase)
            raw.geometry.type="custom";raw.geometry.sizing.mode="absolute";
            raw.geometry.sizing.custom=struct('outer_dimensions_m',[0.2;0.1;0.05], ...
                'projected_area_m2',0.01,'reference_area_m2',0.012, ...
                'reference_length_m',0.18,'volume_m3',5e-4, ...
                'inscribed_cuboid_dimensions_m',[0.15;0.08;0.03]);
            cfg=msbsreq.resolveConfig(raw);t=msbsreq.buildTunnel(cfg);g=msbsreq.buildGeometry(cfg,t);
            testCase.verifyEqual(g.reference_area_m2,0.012,'AbsTol',1e-14);
            testCase.verifyEqual(g.reference_length_m,0.18,'AbsTol',1e-14);
            testCase.verifyEqual(g.inscribed_cuboid.dimensions_B_m,[0.15;0.08;0.03],'AbsTol',1e-14);
        end
        function absoluteModeDoesNotRescale(testCase)
            raw.geometry.type="sphere";raw.geometry.sizing.mode="absolute";raw.geometry.sizing.diameter_m=0.1;
            cfg=msbsreq.resolveConfig(raw);t=msbsreq.buildTunnel(cfg);g=msbsreq.buildGeometry(cfg,t);
            testCase.verifyEqual(g.shape.diameter_m,0.1,'AbsTol',1e-14);
            testCase.verifyEqual(g.nominal_blockage_ratio,pi*0.1^2/4/t.area_m2,'RelTol',1e-12);
        end
    end
end
