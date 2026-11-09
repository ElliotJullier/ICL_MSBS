function S = resolvePosition(cfg,S)
%RESOLVEPOSITION Explicit absolute CoM trajectory; never integrate unordered rows.
n=height(S); r=repmat(double(cfg.position.reference_C_T_m(:)).',n,1);
v=nan(n,3);
switch cfg.position.mode
    case "nominal"
        % A declared reference location, not an inferred body-origin location.
    case "specified"
        names={'x_C_T_m','y_C_T_m','z_C_T_m'};
        if ~all(ismember(names,cfg.scenarios.Properties.VariableNames))
            error('msbsreq:MissingPosition','Specified position requires x_C_T_m, y_C_T_m, z_C_T_m.');
        end
        r=cfg.scenarios{:,names};
        vn={'vx_C_T_mps','vy_C_T_mps','vz_C_T_mps'};
        if any(ismember(vn,cfg.scenarios.Properties.VariableNames))
            if ~all(ismember(vn,cfg.scenarios.Properties.VariableNames))
                error('msbsreq:MissingVelocity','Supply all three velocity components or omit all.');
            end
            v=cfg.scenarios{:,vn};
            if any(~isfinite(v),'all'),error('msbsreq:InvalidPosition','Velocity must be finite.');end
        end
    case "harmonic_analytic"
        if cfg.motion.mode~="harmonic" || any(cfg.motion.harmonic.angular_amplitude_rad~=0)
            error('msbsreq:InvalidPositionMode','Analytic harmonic position requires pure translational harmonic motion.');
        end
        % Match the existing harmonic helper, whose translation axes are B.
        h=cfg.motion.harmonic; A=h.translation_amplitude_m(:);
        ph=h.translation_phase_rad(:);if isscalar(ph),ph=repmat(ph,3,1);end
        om=2*pi*h.frequency_Hz;
        for k=1:n
            R=S.R_TB{k};phase=S.motion_phase_rad(k);
            r(k,:)=r(k,:)+(R*(A.*sin(phase+ph))).';
            v(k,:)=(R*(om*A.*cos(phase+ph))).';
        end
end
if ~isequal(size(r),[n 3]) || any(~isfinite(r),'all')
    error('msbsreq:InvalidPosition','Absolute CoM position must be finite N-by-3.');
end
S.r_C_T_m=mat2cell(r,ones(n,1),3); S.v_C_T_mps=mat2cell(v,ones(n,1),3);
S.scenario_relationship=repmat(cfg.scenario_set.relationship,n,1);
if cfg.scenario_set.relationship=="time_history"
    if any(~isfinite(S.time_s)),error('msbsreq:InvalidHistoryTime','Time histories require finite timestamps.');end
    if ismember('scenario_group_id',S.Properties.VariableNames)
        groups=string(S.scenario_group_id);
    else
        groups=repmat("history",n,1);
    end
    for g=unique(groups).'
        ts=S.time_s(groups==g);
        if any(diff(ts)<=0),error('msbsreq:InvalidHistoryTime','Timestamps must increase strictly within each history group.');end
    end
end
end
