function scenarios = buildScenarioTable(cfg)
%BUILDSCENARIOTABLE Build correlated physical scenarios and motion states.
arguments
    cfg (1,1) struct
end

motionCases = localBuildMotionCases(cfg);
bodyCases = cfg.frames.body_attitude_cases;
windCases = cfg.frames.wind_orientation_cases;
wrenchNames = localAdditionalWrenchNames(cfg.additional_wrenches);

switch cfg.aero.mode
    case "direct_wrench_cases"
        rows = localBuildDirectAeroRows(cfg,bodyCases,windCases,motionCases,wrenchNames);
    case "wrench_time_history"
        rows = localBuildAeroHistoryRows(cfg,bodyCases,windCases,motionCases,wrenchNames);
    otherwise
        if cfg.combinations.strategy == "user_defined"
            rows = localBuildUserRows(cfg,bodyCases,windCases,motionCases,wrenchNames);
        else
            rows = localBuildFactorialRows(cfg,bodyCases,windCases,motionCases,wrenchNames);
        end
end

if isempty(rows)
    error('msbsreq:EmptyScenarioSet','No physical scenarios were generated.');
end
for i=1:numel(rows)
    rows(i).scenario_id="S"+compose('%05d',i);
end
scenarios=struct2table(rows,'AsArray',true);
scenarios=localAppendMetadataColumns(scenarios,rows);
end

function rows=localBuildFactorialRows(cfg,bodyCases,windCases,motionCases,wrenchNames)
if cfg.aero.mode=="legacy_3coeff"
    factors={localFactorValues(cfg.tunnel.speed),localFactorValues(cfg.aero.CD), ...
        localFactorValues(cfg.aero.CL),localFactorValues(cfg.aero.Cm)};
else
    factors={localFactorValues(cfg.tunnel.speed),localFactorValues(cfg.aero.CD), ...
        localFactorValues(cfg.aero.CY),localFactorValues(cfg.aero.CL), ...
        localFactorValues(cfg.aero.Cl),localFactorValues(cfg.aero.Cm), ...
        localFactorValues(cfg.aero.Cn)};
end
factorRows=localCartesianRows(factors);
estimated=size(factorRows,1)*numel(bodyCases)*numel(windCases)*numel(motionCases);
addNominal=cfg.combinations.include_nominal_case && localAnyVariation(cfg);
if estimated+double(addNominal)>cfg.combinations.max_cases
    error('msbsreq:TooManyScenarios', ...
        ['Full-factorial expansion would create %d cases, above max_cases=%d. ', ...
         'Use correlated user-defined scenarios or increase the limit deliberately.'], ...
        estimated+double(addNominal),cfg.combinations.max_cases);
end
rows=repmat(localEmptyRow(),estimated+double(addNominal),1);
index=0;
for iFactor=1:size(factorRows,1)
    [speed,coeff]=localFactorRow(cfg,factorRows(iFactor,:));
    for iB=1:numel(bodyCases)
        for iW=1:numel(windCases)
            for iK=1:numel(motionCases)
                index=index+1;
                rows(index)=localResolveRow("factorial_"+index,speed,coeff, ...
                    bodyCases(iB),windCases(iW),motionCases(iK), ...
                    ones(1,numel(wrenchNames)),cfg,localEmptyAeroInput(),struct(),NaN);
            end
        end
    end
end
if addNominal
    coeff=localNominalCoefficients(cfg);
    candidate=localResolveRow("all_nominal",cfg.tunnel.speed.nominal,coeff, ...
        bodyCases(1),windCases(1),motionCases(1),ones(1,numel(wrenchNames)), ...
        cfg,localEmptyAeroInput(),struct(),NaN);
    if ~localRowExists(rows(1:index),candidate)
        index=index+1;rows(index)=candidate;
    end
end
rows=rows(1:index);
end

function rows=localBuildUserRows(cfg,bodyCases,windCases,motionCases,wrenchNames)
T=cfg.combinations.user_scenarios;
if height(T)>cfg.combinations.max_cases
    error('msbsreq:TooManyScenarios','User-defined table exceeds max_cases.');
end
rows=repmat(localEmptyRow(),height(T),1);
for i=1:height(T)
    speed=localTableNumber(T,i,'speed_mps',cfg.tunnel.speed.nominal);
    coeff=localCoefficientsFromTable(T,i,cfg);
    bodyCase=localNamedBodyCase(T,i,bodyCases);
    windCase=localNamedWindCase(T,i,windCases);
    requireMotionCorrelation=(cfg.aero.mode=="coefficients_6dof" && numel(motionCases)>1);
    motion=localNamedMotionCase(T,i,motionCases,requireMotionCorrelation);
    scales=localWrenchScales(T,i,wrenchNames);
    metadata=localMetadataFromTable(T,i,localReservedUserScenarioColumns(wrenchNames));
    rows(i)=localResolveRow(string(T.scenario_name(i)),speed,coeff,bodyCase,windCase, ...
        motion,scales,cfg,localEmptyAeroInput(),metadata,NaN);
end
end

function rows=localBuildDirectAeroRows(cfg,bodyCases,windCases,motionCases,wrenchNames)
T=cfg.aero.direct_wrench_cases;
if height(T)>cfg.combinations.max_cases
    error('msbsreq:TooManyScenarios','Direct aerodynamic wrench table exceeds max_cases.');
end
rows=repmat(localEmptyRow(),height(T),1);
for i=1:height(T)
    name=localTableString(T,i,'case_name',"aero_wrench_"+i);
    speed=localTableNumber(T,i,'speed_mps',cfg.tunnel.speed.nominal);
    coeff=localCoefficientsFromTable(T,i,cfg);
    bodyCase=localNamedBodyCase(T,i,bodyCases);
    windCase=localNamedWindCase(T,i,windCases);
    motion=localNamedMotionCase(T,i,motionCases,true);
    scales=localWrenchScales(T,i,wrenchNames);
    aero=localAeroInputFromTable(T,i,cfg);
    metadata=localMetadataFromTable(T,i,localReservedAeroWrenchColumns(wrenchNames,false));
    rows(i)=localResolveRow(name,speed,coeff,bodyCase,windCase,motion,scales,cfg,aero,metadata,NaN);
end
end

function rows=localBuildAeroHistoryRows(cfg,bodyCases,windCases,motionCases,wrenchNames)
T=cfg.aero.wrench_time_history;
if height(T)>cfg.combinations.max_cases
    error('msbsreq:TooManyScenarios','Aerodynamic wrench time history exceeds max_cases.');
end
rows=repmat(localEmptyRow(),height(T),1);
for i=1:height(T)
    name=localTableString(T,i,'case_name',"time_"+i);
    speed=localTableNumber(T,i,'speed_mps',cfg.tunnel.speed.nominal);
    coeff=localCoefficientsFromTable(T,i,cfg);
    bodyCase=localNamedBodyCase(T,i,bodyCases);
    windCase=localNamedWindCase(T,i,windCases);
    if cfg.motion.mode=="time_history"
        motion=motionCases(i);
    else
        motion=motionCases(1);
    end
    scales=localWrenchScales(T,i,wrenchNames);
    aero=localAeroInputFromTable(T,i,cfg);
    metadata=localMetadataFromTable(T,i,localReservedAeroWrenchColumns(wrenchNames,true));
    rows(i)=localResolveRow(name,speed,coeff,bodyCase,windCase,motion,scales,cfg,aero,metadata,T.time_s(i));
end
end

function values=localFactorValues(spec)
if spec.hasVariation
    values=unique([spec.lower spec.upper],'stable');
else
    values=spec.nominal;
end
end

function rows=localCartesianRows(factors)
n=numel(factors);counts=cellfun(@numel,factors);total=prod(counts);
rows=zeros(total,n);
for iRow=1:total
    remainder=iRow-1;
    for j=n:-1:1
        index=mod(remainder,counts(j))+1;
        rows(iRow,j)=factors{j}(index);
        remainder=floor(remainder/counts(j));
    end
end
end

function [speed,coeff]=localFactorRow(cfg,row)
speed=row(1);
if cfg.aero.mode=="legacy_3coeff"
    coeff=localNominalCoefficients(cfg);
    coeff.CD=row(2);coeff.CL=row(3);coeff.Cm=row(4);
    coeff.CY=0;coeff.Cl=0;coeff.Cn=0;
else
    coeff=struct('CD',row(2),'CY',row(3),'CL',row(4), ...
        'Cl',row(5),'Cm',row(6),'Cn',row(7));
end
end

function tf=localAnyVariation(cfg)
tf=cfg.tunnel.speed.hasVariation || cfg.aero.CD.hasVariation || ...
    cfg.aero.CL.hasVariation || cfg.aero.Cm.hasVariation;
if cfg.aero.mode=="coefficients_6dof"
    tf=tf || cfg.aero.CY.hasVariation || cfg.aero.Cl.hasVariation || cfg.aero.Cn.hasVariation;
end
end

function coeff=localNominalCoefficients(cfg)
coeff=struct('CD',cfg.aero.CD.nominal,'CY',cfg.aero.CY.nominal, ...
    'CL',cfg.aero.CL.nominal,'Cl',cfg.aero.Cl.nominal, ...
    'Cm',cfg.aero.Cm.nominal,'Cn',cfg.aero.Cn.nominal);
if cfg.aero.mode=="legacy_3coeff"
    coeff.CY=0;coeff.Cl=0;coeff.Cn=0;
end
end

function coeff=localCoefficientsFromTable(T,i,cfg)
coeff=localNominalCoefficients(cfg);
for name=["CD","CY","CL","Cl","Cm","Cn"]
    if ismember(name,T.Properties.VariableNames)
        coeff.(name)=T.(name)(i);
    end
end
if cfg.aero.mode=="legacy_3coeff"
    coeff.CY=0;coeff.Cl=0;coeff.Cn=0;
end
end

function cases=localBuildMotionCases(cfg)
empty=localEmptyMotion();
switch cfg.motion.mode
    case "none"
        cases=empty;cases.name="static";
    case "direct_kinematics_cases"
        T=cfg.motion.direct_kinematics_cases;
        if isempty(T),error('msbsreq:EmptyMotionCases','Direct kinematics table is empty.');end
        cases=repmat(empty,height(T),1);
        for i=1:height(T)
            cases(i).name=localTableString(T,i,'case_name',"kinematics_"+i);
            cases(i).a=localVectorFromTable(T,i,"a");
            cases(i).omega=localVectorFromTable(T,i,"omega");
            cases(i).alpha=localVectorFromTable(T,i,"alpha");
            cases(i).frame=upper(localTableString(T,i,'frame',"T"));
        end
    case "harmonic_single_frequency"
        h=cfg.motion.harmonic;N=h.samples_per_cycle;cases=repmat(empty,N,1);
        omega0=2*pi*h.frequency_Hz;
        At=double(h.translation_amplitude_m(:));Pt=localExpand3(h.translation_phase_rad);
        Aa=double(h.angular_amplitude_rad(:));Pa=localExpand3(h.angular_phase_rad);
        for i=1:N
            phase=2*pi*(i-1)/N;
            cases(i).name="phase_"+compose('%03d',i-1);
            cases(i).a=-omega0^2*At.*sin(phase+Pt);
            cases(i).omega=omega0*Aa.*cos(phase+Pa);
            cases(i).alpha=-omega0^2*Aa.*sin(phase+Pa);
            cases(i).frame="B";
            cases(i).attitude_mode="incremental_body";
            delta=Aa.*sin(phase+Pa); % [roll; pitch; yaw]
            cases(i).delta_ypr_rad=[delta(3) delta(2) delta(1)];
            cases(i).phase_rad=phase;
            cases(i).time_s=phase/omega0;
        end
    case "time_history"
        T=cfg.motion.time_history;
        if isempty(T),error('msbsreq:EmptyTimeHistory','Time-history table is empty.');end
        cases=repmat(empty,height(T),1);
        for i=1:height(T)
            cases(i).name=localTableString(T,i,'case_name',"time_"+i);
            cases(i).a=localVectorFromTable(T,i,"a");
            cases(i).omega=localVectorFromTable(T,i,"omega");
            cases(i).alpha=localVectorFromTable(T,i,"alpha");
            cases(i).frame=upper(localTableString(T,i,'frame',"T"));
            if ismember('R_TB',T.Properties.VariableNames) && ~isempty(T.R_TB{i})
                cases(i).attitude_mode="absolute";cases(i).R_TB_absolute=T.R_TB{i};
            elseif all(ismember({'yaw_deg','pitch_deg','roll_deg'},T.Properties.VariableNames))
                cases(i).attitude_mode="absolute";
                cases(i).R_TB_absolute=msbsreq.rotationZYX([T.yaw_deg(i) T.pitch_deg(i) T.roll_deg(i)],"deg");
            end
            if ismember('time_s',T.Properties.VariableNames),cases(i).time_s=T.time_s(i);end
        end
    case "direct_required_wrench"
        T=cfg.motion.direct_required_wrench;
        if isempty(T),error('msbsreq:EmptyDirectDemand','Direct required-wrench table is empty.');end
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

function row=localResolveRow(name,speed,coeff,bodyCase,windCase,motion,scales,cfg,aero,metadata,timeOverride)
row=localEmptyRow();
row.scenario_name=string(name);row.speed_mps=speed;
row.CD=coeff.CD;row.CY=coeff.CY;row.CL=coeff.CL;
row.Cl=coeff.Cl;row.Cm=coeff.Cm;row.Cn=coeff.Cn;
row.aero_source_mode=cfg.aero.mode;
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
row.R_TB={R_TB};row.R_TW={windCase.R_TW};
if motion.direct
    row.direct_inertial_demand=true;
    row.inertial_force_override_T={msbsreq.transformVector(motion.direct_force,motion.frame,frames)};
    row.inertial_moment_override_T={msbsreq.transformVector(motion.direct_moment,motion.frame,frames)};
else
    row.a_C_T_mps2={msbsreq.transformVector(motion.a,motion.frame,frames)};
    row.omega_T_radps={msbsreq.transformVector(motion.omega,motion.frame,frames)};
    row.alpha_T_radps2={msbsreq.transformVector(motion.alpha,motion.frame,frames)};
end
row.aero_force_input={aero.force};row.aero_moment_input={aero.moment};
if ismember(cfg.aero.mode,["legacy_3coeff","coefficients_6dof"])
    row.aero_input_frame="W";
else
    row.aero_input_frame=aero.frame;
end
if ismember(cfg.aero.mode,["legacy_3coeff","coefficients_6dof"])
    row.aero_reference_point_B_m={double(cfg.geometry.aero_reference_point_B_m(:))};
else
    row.aero_reference_point_B_m={aero.reference_point_B_m};
end
row.additional_wrench_scales={scales};row.motion_phase_rad=motion.phase_rad;
if isfinite(timeOverride),row.time_s=timeOverride;else,row.time_s=motion.time_s;end
row.metadata={metadata};
end

function aero=localAeroInputFromTable(T,i,cfg)
aero=localEmptyAeroInput();
aero.force=[T.Fx_N(i);T.Fy_N(i);T.Fz_N(i)];
aero.moment=[T.Mx_Nm(i);T.My_Nm(i);T.Mz_Nm(i)];
aero.frame=upper(localTableString(T,i,'frame',"T"));
if ismember('reference_point_B_m',T.Properties.VariableNames)
    aero.reference_point_B_m=double(T.reference_point_B_m{i}(:));
else
    aero.reference_point_B_m=double(cfg.geometry.aero_reference_point_B_m(:));
end
end

function body=localNamedBodyCase(T,i,cases)
name=localTableString(T,i,'body_attitude_case',string(cases(1).name));
index=localNamedIndex(cases,name);
if isempty(index),error('msbsreq:UnknownScenarioReference','Unknown body attitude case %s.',name);end
body=cases(index);
end

function wind=localNamedWindCase(T,i,cases)
name=localTableString(T,i,'wind_orientation_case',string(cases(1).name));
index=localNamedIndex(cases,name);
if isempty(index),error('msbsreq:UnknownScenarioReference','Unknown wind orientation case %s.',name);end
wind=cases(index);
end

function motion=localNamedMotionCase(T,i,cases,errorIfAmbiguous)
if ismember('motion_case',T.Properties.VariableNames)
    name=string(T.motion_case(i));index=localNamedIndex(cases,name);
    if isempty(index),error('msbsreq:UnknownScenarioReference','Unknown motion case %s.',name);end
    motion=cases(index);return
end
if errorIfAmbiguous && numel(cases)>1
    error('msbsreq:AmbiguousMotionCorrelation', ...
        'Direct aerodynamic wrench rows must specify motion_case when more than one motion case exists.');
end
motion=cases(1);
end

function index=localNamedIndex(cases,name)
index=[];
for i=1:numel(cases)
    if string(cases(i).name)==string(name),index=i;return,end
end
end

function scales=localWrenchScales(T,i,wrenchNames)
scales=ones(1,numel(wrenchNames));
for j=1:numel(wrenchNames)
    column="scale_"+matlab.lang.makeValidName(wrenchNames(j));
    if ismember(column,T.Properties.VariableNames),scales(j)=T.(column)(i);end
end
end

function metadata=localMetadataFromTable(T,i,reserved)
metadata=struct();
names=string(T.Properties.VariableNames);
for name=names
    if any(name==reserved) || startsWith(name,"scale_"),continue,end
    value=localTableValue(T,i,name);
    valid=matlab.lang.makeValidName(char(name));
    metadata.(valid)=value;
end
end

function value=localTableValue(T,i,name)
column=T.(name);
if iscell(column)
    value=column{i};
elseif isstring(column) || iscategorical(column)
    value=string(column(i));
elseif ischar(column)
    value=string(column(i,:));
else
    value=column(i,:);
    if isscalar(value),value=value(1);end
end
end

function scenarios=localAppendMetadataColumns(scenarios,rows)
keys=strings(0,1);
for i=1:numel(rows)
    fields=string(fieldnames(rows(i).metadata{1}));
    keys=unique([keys;fields(:)],'stable');
end
for key=keys(:).'
    if ismember(key,scenarios.Properties.VariableNames),continue,end
    values=cell(numel(rows),1);
    for i=1:numel(rows)
        meta=rows(i).metadata{1};
        field=char(key);if isfield(meta,field),values{i}=meta.(field);else,values{i}=[];end
    end
    provided=~cellfun(@isempty,values);
    numericScalar=cellfun(@(v)isempty(v)||(isnumeric(v)&&isscalar(v)),values);
    if all(numericScalar) && any(provided)
        numericValues=nan(numel(values),1);
        for i=1:numel(values)
            if provided(i),numericValues(i)=double(values{i});end
        end
        scenarios.(char(key))=numericValues;
    elseif all(cellfun(@(v)islogical(v)&&isscalar(v),values))
        scenarios.(char(key))=cellfun(@logical,values);
    else
        text=strings(numel(values),1);
        for i=1:numel(values)
            if isempty(values{i}),text(i)="";else,text(i)=localMetadataText(values{i});end
        end
        scenarios.(char(key))=text;
    end
end
end


function text=localMetadataText(value)
if isnumeric(value) || islogical(value)
    if isscalar(value),text=string(value);else,text=string(mat2str(value));end
elseif ischar(value)
    text=string(value);
elseif isstring(value) || iscategorical(value)
    value=string(value);
    if isscalar(value),text=value;else,text=strjoin(value(:).',"|");end
else
    text=string(value);
    if ~isscalar(text),text=strjoin(text(:).',"|");end
end
end

function reserved=localReservedUserScenarioColumns(wrenchNames)
reserved=["scenario_name","speed_mps","CD","CY","CL","Cl","Cm","Cn", ...
    "body_attitude_case","wind_orientation_case","motion_case"];
for name=wrenchNames(:).',reserved(end+1)="scale_"+matlab.lang.makeValidName(name);end
end

function reserved=localReservedAeroWrenchColumns(wrenchNames,withTime)
reserved=["case_name","scenario_name","speed_mps","Fx_N","Fy_N","Fz_N", ...
    "Mx_Nm","My_Nm","Mz_Nm","frame","reference_point_B_m", ...
    "CD","CY","CL","Cl","Cm","Cn","body_attitude_case", ...
    "wind_orientation_case","motion_case"];
if withTime,reserved(end+1)="time_s";end
for name=wrenchNames(:).',reserved(end+1)="scale_"+matlab.lang.makeValidName(name);end
end

function tf=localRowExists(rows,candidate)
tf=false;
for i=1:numel(rows)
    if rows(i).speed_mps==candidate.speed_mps && rows(i).CD==candidate.CD && ...
            rows(i).CY==candidate.CY && rows(i).CL==candidate.CL && ...
            rows(i).Cl==candidate.Cl && rows(i).Cm==candidate.Cm && rows(i).Cn==candidate.Cn && ...
            rows(i).body_attitude_case==candidate.body_attitude_case && ...
            rows(i).wind_orientation_case==candidate.wind_orientation_case && ...
            rows(i).motion_case==candidate.motion_case
        tf=true;return
    end
end
end

function names=localAdditionalWrenchNames(T)
if isempty(T),names=strings(0,1);return,end
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

function aero=localEmptyAeroInput()
aero=struct('force',zeros(3,1),'moment',zeros(3,1),'frame',"T", ...
    'reference_point_B_m',zeros(3,1));
end

function row=localEmptyRow()
row=struct('scenario_id',"",'scenario_name',"",'aero_source_mode',"", ...
    'speed_mps',NaN,'CD',NaN,'CY',NaN,'CL',NaN,'Cl',NaN,'Cm',NaN,'Cn',NaN, ...
    'body_attitude_case',"",'wind_orientation_case',"",'motion_case',"", ...
    'R_TB',{{eye(3)}},'R_TW',{{eye(3)}},'a_C_T_mps2',{{zeros(3,1)}}, ...
    'omega_T_radps',{{zeros(3,1)}},'alpha_T_radps2',{{zeros(3,1)}}, ...
    'direct_inertial_demand',false,'inertial_force_override_T',{{zeros(3,1)}}, ...
    'inertial_moment_override_T',{{zeros(3,1)}}, ...
    'aero_force_input',{{zeros(3,1)}},'aero_moment_input',{{zeros(3,1)}}, ...
    'aero_input_frame',"T",'aero_reference_point_B_m',{{zeros(3,1)}}, ...
    'additional_wrench_scales',{{zeros(1,0)}},'motion_phase_rad',NaN,'time_s',NaN, ...
    'metadata',{{struct()}});
end

function v=localVectorFromTable(T,i,prefix)
names=prefix+["_x","_y","_z"];
if ~all(ismember(names,T.Properties.VariableNames))
    error('msbsreq:MissingMotionColumns','Motion table requires %s.',strjoin(names,', '));
end
v=[T.(names(1))(i);T.(names(2))(i);T.(names(3))(i)];
end

function value=localTableString(T,i,name,default)
if ismember(name,T.Properties.VariableNames),value=string(T.(name)(i));else,value=string(default);end
end

function value=localTableNumber(T,i,name,default)
if ismember(name,T.Properties.VariableNames),value=T.(name)(i);else,value=default;end
end

function v=localExpand3(v)
v=double(v(:));if isscalar(v),v=repmat(v,3,1);end
if numel(v)~=3,error('msbsreq:InvalidHarmonicInput','Harmonic phase/amplitude inputs must be scalar or 3-vector.');end
end
