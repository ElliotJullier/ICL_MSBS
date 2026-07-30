function scenarios = buildScenarioTable(cfg)
%BUILDSCENARIOTABLE Build physical scenarios from ranges, frame cases, and motion.
arguments
    cfg (1,1) struct
end

motionCases = localBuildMotionCases(cfg);
bodyCases = cfg.frames.body_attitude_cases;
windCases = cfg.frames.wind_orientation_cases;
wrenchNames = localAdditionalWrenchNames(cfg.additional_wrenches);

if cfg.combinations.strategy == "user_defined"
    rows = localBuildUserRows(cfg,bodyCases,windCases,motionCases,wrenchNames);
else
    speeds = localFactorValues(cfg.tunnel.speed);
    CDs = localFactorValues(cfg.aero.CD);
    CLs = localFactorValues(cfg.aero.CL);
    Cms = localFactorValues(cfg.aero.Cm);
    estimated = numel(speeds)*numel(CDs)*numel(CLs)*numel(Cms)* ...
        numel(bodyCases)*numel(windCases)*numel(motionCases);
    addNominal = cfg.combinations.include_nominal_case && ...
        (cfg.tunnel.speed.hasVariation || cfg.aero.CD.hasVariation || ...
        cfg.aero.CL.hasVariation || cfg.aero.Cm.hasVariation);
    if estimated + double(addNominal) > cfg.combinations.max_cases
        error('msbsreq:TooManyScenarios', ...
            ['Full-factorial expansion would create %d cases, above max_cases=%d. ' ...
             'Use correlated user-defined scenarios or increase the limit deliberately.'], ...
             estimated+double(addNominal),cfg.combinations.max_cases);
    end
    rows = repmat(localEmptyRow(),estimated+double(addNominal),1);
    index=0;
    for iV=1:numel(speeds)
        for iD=1:numel(CDs)
            for iL=1:numel(CLs)
                for iM=1:numel(Cms)
                    for iB=1:numel(bodyCases)
                        for iW=1:numel(windCases)
                            for iK=1:numel(motionCases)
                                index=index+1;
                                rows(index)=localResolveRow("factorial_"+index, ...
                                    speeds(iV),CDs(iD),CLs(iL),Cms(iM), ...
                                    bodyCases(iB),windCases(iW),motionCases(iK), ...
                                    ones(1,numel(wrenchNames)),cfg);
                            end
                        end
                    end
                end
            end
        end
    end
    if addNominal
        candidate=localResolveRow("all_nominal",cfg.tunnel.speed.nominal, ...
            cfg.aero.CD.nominal,cfg.aero.CL.nominal,cfg.aero.Cm.nominal, ...
            bodyCases(1),windCases(1),motionCases(1),ones(1,numel(wrenchNames)),cfg);
        if ~localRowExists(rows(1:index),candidate)
            index=index+1; rows(index)=candidate;
        end
    end
    rows=rows(1:index);
end

if isempty(rows)
    error('msbsreq:EmptyScenarioSet','No physical scenarios were generated.');
end
for i=1:numel(rows)
    rows(i).scenario_id="S"+compose('%05d',i);
end
scenarios=struct2table(rows,'AsArray',true);
end

function values=localFactorValues(spec)
if spec.hasVariation
    values=unique([spec.lower spec.upper],'stable');
else
    values=spec.nominal;
end
end

function cases=localBuildMotionCases(cfg)
empty=localEmptyMotion();
switch cfg.motion.mode
    case "none"
        cases=empty; cases.name="static";
    case "direct_kinematics_cases"
        T=cfg.motion.direct_kinematics_cases;
        if isempty(T), error('msbsreq:EmptyMotionCases','Direct kinematics table is empty.'); end
        cases=repmat(empty,height(T),1);
        for i=1:height(T)
            cases(i).name=localTableString(T,i,'case_name',"kinematics_"+i);
            cases(i).a=localVectorFromTable(T,i,"a");
            cases(i).omega=localVectorFromTable(T,i,"omega");
            cases(i).alpha=localVectorFromTable(T,i,"alpha");
            cases(i).frame=upper(localTableString(T,i,'frame',"T"));
        end
    case "harmonic_single_frequency"
        h=cfg.motion.harmonic;
        N=h.samples_per_cycle;
        cases=repmat(empty,N,1);
        omega0=2*pi*h.frequency_Hz;
        At=double(h.translation_amplitude_m(:));
        Pt=localExpand3(h.translation_phase_rad);
        Aa=double(h.angular_amplitude_rad(:));
        Pa=localExpand3(h.angular_phase_rad);
        for i=1:N
            phase=2*pi*(i-1)/N;
            cases(i).name="phase_"+compose('%03d',i-1);
            cases(i).a=-omega0^2*At.*sin(phase+Pt);
            cases(i).omega=omega0*Aa.*cos(phase+Pa);
            cases(i).alpha=-omega0^2*Aa.*sin(phase+Pa);
            cases(i).frame="B";
            cases(i).attitude_mode="incremental_body";
            delta=Aa.*sin(phase+Pa); % [roll; pitch; yaw] about body axes
            cases(i).delta_ypr_rad=[delta(3) delta(2) delta(1)];
            cases(i).phase_rad=phase;
        end
    case "time_history"
        T=cfg.motion.time_history;
        if isempty(T), error('msbsreq:EmptyTimeHistory','Time-history table is empty.'); end
        cases=repmat(empty,height(T),1);
        for i=1:height(T)
            cases(i).name=localTableString(T,i,'case_name',"time_"+i);
            cases(i).a=localVectorFromTable(T,i,"a");
            cases(i).omega=localVectorFromTable(T,i,"omega");
            cases(i).alpha=localVectorFromTable(T,i,"alpha");
            cases(i).frame=upper(localTableString(T,i,'frame',"T"));
            if ismember('R_TB',T.Properties.VariableNames) && ~isempty(T.R_TB{i})
                cases(i).attitude_mode="absolute";
                cases(i).R_TB_absolute=T.R_TB{i};
            elseif all(ismember({'yaw_deg','pitch_deg','roll_deg'},T.Properties.VariableNames))
                cases(i).attitude_mode="absolute";
                cases(i).R_TB_absolute=msbsreq.rotationZYX( ...
                    [T.yaw_deg(i) T.pitch_deg(i) T.roll_deg(i)],"deg");
            end
            if ismember('time_s',T.Properties.VariableNames), cases(i).time_s=T.time_s(i); end
        end
    case "direct_required_wrench"
        T=cfg.motion.direct_required_wrench;
        if isempty(T), error('msbsreq:EmptyDirectDemand','Direct required-wrench table is empty.'); end
        cases=repmat(empty,height(T),1);
        for i=1:height(T)
            cases(i).name=localTableString(T,i,'case_name',"demand_"+i);
            cases(i).direct=true;
            cases(i).direct_force=localVectorFromTable(T,i,"F");
            cases(i).direct_moment=localVectorFromTable(T,i,"M");
            cases(i).frame=upper(localTableString(T,i,'frame',"T"));
        end
end
end

function row=localResolveRow(name,speed,CD,CL,Cm,bodyCase,windCase,motion,scales,cfg)
row=localEmptyRow();
row.scenario_name=string(name);
row.speed_mps=speed; row.CD=CD; row.CL=CL; row.Cm=Cm;
row.body_attitude_case=string(bodyCase.name);
row.wind_orientation_case=string(windCase.name);
row.motion_case=string(motion.name);
R_TB=bodyCase.R_TB;
if motion.attitude_mode=="incremental_body"
    R_TB=R_TB*msbsreq.rotationZYX(motion.delta_ypr_rad,"rad");
elseif motion.attitude_mode=="absolute"
    R_TB=motion.R_TB_absolute;
end
frames=struct('R_ET',cfg.frames.R_ET,'R_TB',R_TB,'R_TW',windCase.R_TW);
row.R_TB={R_TB}; row.R_TW={windCase.R_TW};
if motion.direct
    row.direct_inertial_demand=true;
    row.inertial_force_override_T={msbsreq.transformVector(motion.direct_force,motion.frame,frames)};
    row.inertial_moment_override_T={msbsreq.transformVector(motion.direct_moment,motion.frame,frames)};
else
    row.a_C_T_mps2={msbsreq.transformVector(motion.a,motion.frame,frames)};
    row.omega_T_radps={msbsreq.transformVector(motion.omega,motion.frame,frames)};
    row.alpha_T_radps2={msbsreq.transformVector(motion.alpha,motion.frame,frames)};
end
row.additional_wrench_scales={scales};
row.motion_phase_rad=motion.phase_rad;
row.time_s=motion.time_s;
end

function rows=localBuildUserRows(cfg,bodyCases,windCases,motionCases,wrenchNames)
T=cfg.combinations.user_scenarios;
if ~ismember('scenario_name',T.Properties.VariableNames)
    error('msbsreq:MissingScenarioName','User-defined scenarios require scenario_name.');
end
if height(T)>cfg.combinations.max_cases
    error('msbsreq:TooManyScenarios','User-defined table exceeds max_cases.');
end
rows=repmat(localEmptyRow(),height(T),1);
for i=1:height(T)
    speed=localTableNumber(T,i,'speed_mps',cfg.tunnel.speed.nominal);
    CD=localTableNumber(T,i,'CD',cfg.aero.CD.nominal);
    CL=localTableNumber(T,i,'CL',cfg.aero.CL.nominal);
    Cm=localTableNumber(T,i,'Cm',cfg.aero.Cm.nominal);
    bodyName=localTableString(T,i,'body_attitude_case',string(bodyCases(1).name));
    windName=localTableString(T,i,'wind_orientation_case',string(windCases(1).name));
    motionName=localTableString(T,i,'motion_case',string(motionCases(1).name));
    iB=find(strcmp([bodyCases.name],bodyName),1);
    iW=find(strcmp([windCases.name],windName),1);
    iK=find(strcmp([motionCases.name],motionName),1);
    if isempty(iB)||isempty(iW)||isempty(iK)
        error('msbsreq:UnknownScenarioReference', ...
            'Scenario %s references an unknown frame or motion case.',string(T.scenario_name(i)));
    end
    scales=ones(1,numel(wrenchNames));
    for j=1:numel(wrenchNames)
        column="scale_"+matlab.lang.makeValidName(wrenchNames(j));
        if ismember(column,T.Properties.VariableNames)
            values=T.(column); scales(j)=values(i);
        end
    end
    rows(i)=localResolveRow(string(T.scenario_name(i)),speed,CD,CL,Cm, ...
        bodyCases(iB),windCases(iW),motionCases(iK),scales,cfg);
end
end

function tf=localRowExists(rows,candidate)
tf=false;
for i=1:numel(rows)
    if rows(i).speed_mps==candidate.speed_mps && rows(i).CD==candidate.CD && ...
            rows(i).CL==candidate.CL && rows(i).Cm==candidate.Cm && ...
            rows(i).body_attitude_case==candidate.body_attitude_case && ...
            rows(i).wind_orientation_case==candidate.wind_orientation_case && ...
            rows(i).motion_case==candidate.motion_case
        tf=true; return
    end
end
end

function names=localAdditionalWrenchNames(T)
if isempty(T), names=strings(0,1); return, end
if ~ismember('name',T.Properties.VariableNames)
    error('msbsreq:InvalidAdditionalWrenches','Additional-wrench table requires name.');
end
names=string(T.name);
end

function motion=localEmptyMotion()
motion=struct('name',"",'a',zeros(3,1),'omega',zeros(3,1),'alpha',zeros(3,1), ...
    'frame',"T",'attitude_mode',"base",'R_TB_absolute',eye(3), ...
    'delta_ypr_rad',[0 0 0],'direct',false,'direct_force',zeros(3,1), ...
    'direct_moment',zeros(3,1),'phase_rad',NaN,'time_s',NaN);
end
function row=localEmptyRow()
row=struct('scenario_id',"",'scenario_name',"",'speed_mps',NaN,'CD',NaN,'CL',NaN,'Cm',NaN, ...
    'body_attitude_case',"",'wind_orientation_case',"",'motion_case',"", ...
    'R_TB',{{eye(3)}},'R_TW',{{eye(3)}},'a_C_T_mps2',{{zeros(3,1)}}, ...
    'omega_T_radps',{{zeros(3,1)}},'alpha_T_radps2',{{zeros(3,1)}}, ...
    'direct_inertial_demand',false,'inertial_force_override_T',{{zeros(3,1)}}, ...
    'inertial_moment_override_T',{{zeros(3,1)}},'additional_wrench_scales',{{zeros(1,0)}}, ...
    'motion_phase_rad',NaN,'time_s',NaN);
end

function v=localVectorFromTable(T,i,prefix)
names=prefix+["_x","_y","_z"];
if ~all(ismember(names,T.Properties.VariableNames))
    error('msbsreq:MissingMotionColumns','Motion table requires %s.',strjoin(names,', '));
end
vx=T.(names(1)); vy=T.(names(2)); vz=T.(names(3));
v=[vx(i);vy(i);vz(i)];
end
function value=localTableString(T,i,name,default)
if ismember(name,T.Properties.VariableNames)
    values=T.(name); value=string(values(i));
else
    value=string(default);
end
end
function value=localTableNumber(T,i,name,default)
if ismember(name,T.Properties.VariableNames)
    values=T.(name); value=values(i);
else
    value=default;
end
end
function v=localExpand3(v)
v=double(v(:));
if isscalar(v),v=repmat(v,3,1);end
if numel(v)~=3,error('msbsreq:InvalidHarmonicInput','Harmonic phase/amplitude inputs must be scalar or 3-vector.');end
end
