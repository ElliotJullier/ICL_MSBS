classdef TestFrames < matlab.unittest.TestCase
    methods(Test)
        function identityVector(testCase)
            frames=struct('R_ET',eye(3),'R_TB',eye(3));
            v=[1;2;3];
            testCase.verifyEqual(msbsreq.transformVector(v,"B",frames),v,'AbsTol',1e-14);
            testCase.verifyEqual(msbsreq.transformVector(v,"E",frames),v,'AbsTol',1e-14);
        end

        function yawNinety(testCase)
            R=msbsreq.rotationZYX([90 0 0],"deg");
            testCase.verifyEqual(R*[1;0;0],[0;1;0],'AbsTol',1e-12);
            testCase.verifyLessThan(norm(R.'*R-eye(3),'fro'),1e-12);
            testCase.verifyEqual(det(R),1,'AbsTol',1e-12);
        end

        function wrenchShift(testCase)
            frames=struct('R_ET',eye(3),'R_TB',eye(3));
            F=[0;1;0]; M=[0;0;0]; point=[1;0;0]; com=[0;0;0];
            w=msbsreq.transformWrench(F,M,"T",point,com,frames);
            testCase.verifyEqual(w,[0;1;0;0;0;1],'AbsTol',1e-14);
        end

        function earthToTunnelRotation(testCase)
            R_ET=msbsreq.rotationZYX([0 -90 0],"deg");
            frames=struct('R_ET',R_ET,'R_TB',eye(3));
            vE=[0;0;-1];
            testCase.verifyEqual(msbsreq.transformVector(vE,"E",frames),R_ET.'*vE,'AbsTol',1e-12);
        end
    end
end
