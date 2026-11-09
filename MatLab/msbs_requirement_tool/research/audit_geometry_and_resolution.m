function audit_geometry_and_resolution()
%AUDIT_GEOMETRY_AND_RESOLUTION Export dimensions and check phase convergence.
root=string(fileparts(fileparts(mfilename('fullpath'))));
addpath(root,fullfile(root,'src'),fullfile(root,'cases'),fullfile(root,'research'));
out=fullfile(root,'research','outputs');
M=readtable(fullfile(out,'study_manifest.csv'),'TextType','string');G=table();full=struct([]);
for k=1:height(M)
    data=load(fullfile(out,M.case_id(k),'study_input.mat'),'cfg');cfg=data.cfg;
    geo=msbsreq.buildGeometry(cfg,msbsreq.buildTunnel(cfg));sets=msbsreq.buildMagnetSets(cfg,geo,root);
    j=find(string({sets.id})==M.best_fixed_set_id(k));mp=msbsreq.calculateMassProperties(cfg,geo,sets(j));
    S=msbsreq.buildScenarioTable(cfg);wall=0;
    for s=1:height(S)
        R=S.R_TB{s};bodyOrigin=S.r_C_T_m{s}(:)-R*mp.centre_of_mass_B_m;
        ext=abs(R)*geo.outer_dimensions_B_m;
        wall=max(wall,max((ext(2:3)+2*abs(bodyOrigin(2:3)))/cfg.tunnel.cross_section.width_m));
    end
    assert(wall<1,'Resolved CoM/body placement crosses a tunnel wall.');
    d=geo.outer_dimensions_B_m;e=geo.inscribed_cuboid.dimensions_B_m;
    row=table(M.case_id(k),d(1),d(2),d(3),e(1),e(2),e(3),geo.reference_area_m2,geo.reference_length_m,geo.reference_span_m,wall, ...
        'VariableNames',{'case_id','Lx_m','Ly_m','Lz_m','envelope_x_m','envelope_y_m','envelope_z_m','reference_area_m2','reference_length_m','reference_span_m','maximum_wall_fraction_selected'});
    G=[G;row]; %#ok<AGROW>
    full(k).case_id=M.case_id(k);full(k).geometry=geo;full(k).selected_magnet_set=sets(j);full(k).mass_properties=mp;
end
writetable(G,fullfile(out,'geometry_comparison.csv'));
fid=fopen(fullfile(out,'selected_geometry_and_magnets.json'),'w');fprintf(fid,'%s',jsonencode(full,'PrettyPrint',true));fclose(fid);
info=struct('source_type',"phase_resolution",'case_function_name',"msbsstudy.makeCase",'case_file_path',"");C=table();
for family=["cylinder_crossflow","cylinder_inline"]
    values=zeros(3,3);samples=[72 144 288];
    for i=1:3
        cfg=msbsstudy.makeCase(family,.6,.03,"h",.1,samples(i));
        study=msbsreq.run(cfg,root,info);T=study.results(TakeSelected(study),:);
        values(i,:)=[max(T.G_frobenius_Tpm),max(T.G_max_abs_Tpm),max(T.magnetic_cost_rms_T)];
    end
    for i=1:3
        row=table(family,samples(i),values(i,1),values(i,2),values(i,3),(values(3,1)-values(i,1))/values(3,1), ...
            'VariableNames',{'family','phase_samples','max_G_F_Tpm','max_G_entry_Tpm','max_cost_T','relative_G_shortfall_vs_288'});
        C=[C;row]; %#ok<AGROW>
    end
end
writetable(C,fullfile(out,'phase_resolution.csv'));
end
function take=TakeSelected(study)
take=study.results.magnet_set_id==study.summary.best_magnet_set_id;
end
