function audit_roll_layouts(out)
%AUDIT_ROLL_LAYOUTS Export per-magnet wrench contributions for unit B and G.
root=string(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'src'),fullfile(root,'cases'),fullfile(root,'research'));
if nargin==0,out=fullfile(root,'research','outputs','revision');end
cfg=msbsstudy.revisionCase("cuboid",.6,.10,"h",1);
g=msbsreq.buildGeometry(cfg,msbsreq.buildTunnel(cfg));
sets=msbsreq.buildMagnetSets(cfg,g,root);
use=find(endsWith(string({sets.name}),"_main_axis1"));
% The axial diagonal basis uses 1 T/m on xx. The transverse diagonal
% basis uses 1 T/m on yy and -1 T/m on zz. Cross terms are symmetric.
inputs=eye(8);
inputs(5,4)=-.5;
labels=["Bx","By","Bz","axial_diag","transverse_diag","Gxy","Gxz","Gyz"];
parts=table();
nets=table();
for s=use
    set=sets(s);
    mass=msbsreq.calculateMassProperties(cfg,g,set);
    for phi=[0 45 90]
        R=msbsreq.rotationZYX([0 0 phi],"deg");
        map=msbsreq.buildMagneticMap(set,R,mass.centre_of_mass_B_m);
        for j=1:numel(labels)
            x=inputs(:,j);
            B=x(1:3);
            G=msbsreq.constructGradient(x);
            F=G*map.dipoles_T_Am2;
            D=cross(map.dipoles_T_Am2,B+G*map.positions_T_m,1);
            L=cross(map.positions_T_m,F,1);
            for i=1:numel(set.magnets)
                row=table(set.name,phi,labels(j),set.magnets(i).name, ...
                    F(1,i),F(2,i),F(3,i),D(1,i),D(2,i),D(3,i),L(1,i),L(2,i),L(3,i),D(1,i)+L(1,i), ...
                    'VariableNames',{'layout','roll_deg','unit_mode','part','Fx_N','Fy_N','Fz_N', ...
                    'local_Mx_Nm','local_My_Nm','local_Mz_Nm','lever_Mx_Nm','lever_My_Nm','lever_Mz_Nm','total_Mx_Nm'});
                parts=[parts;row]; %#ok<AGROW>
            end
            W=[sum(F,2);sum(D+L,2)];
            assert(norm(W-map.A*x)<1e-10);
            row=table(set.name,phi,labels(j),W(1),W(2),W(3),W(4),W(5),W(6), ...
                'VariableNames',{'layout','roll_deg','unit_mode','Fx_N','Fy_N','Fz_N','Mx_Nm','My_Nm','Mz_Nm'});
            nets=[nets;row]; %#ok<AGROW>
        end
    end
end
writetable(parts,fullfile(out,'roll_per_magnet_unit_response.csv'));
writetable(nets,fullfile(out,'roll_layout_unit_response.csv'));
end
