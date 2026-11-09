function S = checkClearance(cfg,geo,tunnel)
%CHECKCLEARANCE Conservative bounding-box wall check at all sampled states.
S=cfg.scenarios;resolved=msbsreq.buildScenarioTable(cfg);n=height(S);
ratios=zeros(n,1);swept=zeros(n,1);d=geo.outer_dimensions_B_m;
for k=1:n
    R=resolved.R_TB{k};ext=abs(R)*d;
    r=resolved.r_C_T_m{k}(:);
    % Allow for a CoM offset anywhere inside the inscribed envelope centre;
    % actual chosen-set CoM offsets are small; record nominal body envelope here.
    swept(k)=max((ext(2:3)/2+abs(r(2:3)))./[tunnel.width_m;tunnel.height_m]*2);
    if swept(k)>=1-1e-12,error('msbsstudy:EnvelopeExceedsTunnel','Body or prescribed transverse sweep reaches a tunnel wall.');end
    nB=abs(R.'*[1;0;0]);
    if geo.type=="sphere"
        A=pi*geo.shape.diameter_m^2/4;
    elseif geo.type=="cylinder"
        A=geo.shape.diameter_m*geo.shape.length_m;
    else
        A=dot(nB,[d(2)*d(3);d(1)*d(3);d(1)*d(2)]);
    end
    ratios(k)=A/tunnel.area_m2;
end
S.projected_blockage_ratio=ratios;S.wall_envelope_fraction=swept;
end
