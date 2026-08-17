function scenarios = buildScenarioTable(cfg)
%BUILDSCENARIOTABLE Build one resolved row per simultaneous physical state.
arguments
    cfg (1,1) struct
end

T=localInputScenarioTable(cfg);
rows=repmat(localEmptyRow(),height(T),1);
for i=1:height(T)
    rows(i)=localResolveRow(T,i,cfg);
    rows(i).scenario_id="S"+compose('%05d',i);
end
scenarios=struct2table(rows,'AsArray',true);
scenarios=localAppendMetadataColumns(scenarios,rows);
end

function T=localInputScenarioTable(cfg)
T=cfg.scenarios;
if ~isempty(T),return,end
if cfg.aero.mode=="direct_wrench"
    error('msbsreq:EmptyScenarioSet', ...
        'Direct aerodynamic wrench mode requires explicit cfg.scenarios rows.');
end
if cfg.motion.mode=="harmonic"
    N=cfg.motion.harmonic.samples_per_cycle;
    phase=(0:N-1).'*2*pi/N;
    names="phase_"+compose('%03d',(0:N-1).');
    T=table(names,phase,'VariableNames',{'scenario_name','phase_rad'});
else
    T=table("nominal",'VariableNames',{'scenario_name'});
end
end

function row=localResolveRow(T,i,cfg)
row=localEmptyRow();
row.scenario_name=localTableString(T,i,'scenario_name',"scenario_"+compose('%03d',i));
row.aero_source_mode=cfg.aero.mode;
row.speed_mps=localTableNumber(T,i,'speed_mps',cfg.tunnel.speed_mps);
row.CD=localTableNumber(T,i,'CD',cfg.aero.CD);
row.CY=localTableNumber(T,i,'CY',cfg.aero.CY);
row.CL=localTableNumber(T,i,'CL',cfg.aero.CL);
row.Cl_roll=localTableNumber(T,i,'Cl_roll',cfg.aero.Cl_roll);
row.Cm=localTableNumber(T,i,'Cm',cfg.aero.Cm);
row.Cn=localTableNumber(T,i,'Cn',cfg.aero.Cn);

[R_TB,motion,phase,time]=localMotionAndAttitude(T,i,cfg);
row.R_TB={R_TB};
row.motion_mode=cfg.motion.mode;
row.a_C_T_mps2={motion.a_T};
row.omega_T_radps={motion.omega_T};
row.alpha_T_radps2={motion.alpha_T};
row.motion_phase_rad=phase;
row.time_s=time;

if cfg.aero.mode=="direct_wrench"
    row.aero_force_input={[T.Fx_aero_N(i);T.Fy_aero_N(i);T.Fz_aero_N(i)]};
    row.aero_moment_input={[T.Mx_aero_Nm(i);T.My_aero_Nm(i);T.Mz_aero_Nm(i)]};
    row.aero_input_frame=upper(localTableString(T,i,'aero_frame',cfg.aero.direct_wrench_frame));
    if ismember('aero_reference_point_B_m',T.Properties.VariableNames)
        row.aero_reference_point_B_m={double(T.aero_reference_point_B_m{i}(:))};
    else
        row.aero_reference_point_B_m={double(cfg.geometry.aero_reference_point_B_m(:))};
    end
else
    row.aero_input_frame="T";
    row.aero_reference_point_B_m={double(cfg.geometry.aero_reference_point_B_m(:))};
end
row.metadata={localMetadataFromTable(T,i,localReservedColumns())};
end

function [R_TB,motion,phase,time]=localMotionAndAttitude(T,i,cfg)
baseR=cfg.frames.R_TB_nominal;
phase=NaN;
time=localTableNumber(T,i,'time_s',NaN);
motion=struct('a_T',zeros(3,1),'omega_T',zeros(3,1),'alpha_T',zeros(3,1));

switch cfg.motion.mode
    case "harmonic"
        h=cfg.motion.harmonic;
        omega0=2*pi*h.frequency_Hz;
        if ismember('phase_rad',T.Properties.VariableNames)
            phase=T.phase_rad(i);
        elseif isfinite(time)
            phase=omega0*time;
        else
            error('msbsreq:MissingHarmonicPhase', ...
                'Explicit harmonic scenario rows require phase_rad or time_s.');
        end
        if ~isfinite(time),time=phase/omega0;end
        At=double(h.translation_amplitude_m(:));Pt=localExpand3(h.translation_phase_rad);
        Aa=double(h.angular_amplitude_rad(:));Pa=localExpand3(h.angular_phase_rad);
        delta=Aa.*sin(phase+Pa); % [roll; pitch; yaw], body-axis small-angle helper
        R_TB=baseR*msbsreq.rotationZYX([delta(3) delta(2) delta(1)],"rad");
        a_B=-omega0^2*At.*sin(phase+Pt);
        omega_B=omega0*Aa.*cos(phase+Pa);
        alpha_B=-omega0^2*Aa.*sin(phase+Pa);
        frames=struct('R_ET',cfg.frames.R_ET,'R_TB',R_TB);
        motion.a_T=msbsreq.transformVector(a_B,"B",frames);
        motion.omega_T=msbsreq.transformVector(omega_B,"B",frames);
        motion.alpha_T=msbsreq.transformVector(alpha_B,"B",frames);

    otherwise
        if all(ismember({'yaw_deg','pitch_deg','roll_deg'},T.Properties.VariableNames))
            R_TB=msbsreq.rotationZYX([T.yaw_deg(i) T.pitch_deg(i) T.roll_deg(i)],"deg");
        else
            R_TB=baseR;
        end
        if cfg.motion.mode=="specified" && localHasKinematics(T)
            a=[T.a_x(i);T.a_y(i);T.a_z(i)];
            omega=[T.omega_x(i);T.omega_y(i);T.omega_z(i)];
            alpha=[T.alpha_x(i);T.alpha_y(i);T.alpha_z(i)];
            frames=struct('R_ET',cfg.frames.R_ET,'R_TB',R_TB);
            motion.a_T=msbsreq.transformVector(a,cfg.motion.frame,frames);
            motion.omega_T=msbsreq.transformVector(omega,cfg.motion.frame,frames);
            motion.alpha_T=msbsreq.transformVector(alpha,cfg.motion.frame,frames);
        end
end
end

function tf=localHasKinematics(T)
names={'a_x','a_y','a_z','omega_x','omega_y','omega_z','alpha_x','alpha_y','alpha_z'};
tf=all(ismember(names,T.Properties.VariableNames));
end

function metadata=localMetadataFromTable(T,i,reserved)
metadata=struct();
for name=string(T.Properties.VariableNames)
    if any(name==reserved),continue,end
    valid=matlab.lang.makeValidName(char(name));
    metadata.(valid)=localTableValue(T,i,name);
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
    keys=unique([keys;string(fieldnames(rows(i).metadata{1}))],'stable');
end
for key=keys(:).'
    if ismember(key,scenarios.Properties.VariableNames),continue,end
    values=cell(numel(rows),1);
    for i=1:numel(rows)
        meta=rows(i).metadata{1};field=char(key);
        if isfield(meta,field),values{i}=meta.(field);else,values{i}=[];end
    end
    provided=~cellfun(@isempty,values);
    numericScalar=cellfun(@(v)isempty(v)||(isnumeric(v)&&isscalar(v)),values);
    if all(numericScalar) && any(provided)
        out=nan(numel(values),1);
        for i=1:numel(values),if provided(i),out(i)=double(values{i});end,end
        scenarios.(char(key))=out;
    elseif all(cellfun(@(v)islogical(v)&&isscalar(v),values))
        scenarios.(char(key))=cellfun(@logical,values);
    else
        out=strings(numel(values),1);
        for i=1:numel(values)
            if ~isempty(values{i}),out(i)=localMetadataText(values{i});end
        end
        scenarios.(char(key))=out;
    end
end
end

function text=localMetadataText(value)
if isnumeric(value) || islogical(value)
    if isscalar(value),text=string(value);else,text=string(mat2str(value));end
elseif ischar(value)
    text=string(value);
elseif isstring(value) || iscategorical(value)
    value=string(value);if isscalar(value),text=value;else,text=strjoin(value(:).',"|");end
else
    text=string(value);if ~isscalar(text),text=strjoin(text(:).',"|");end
end
end

function names=localReservedColumns()
names=["scenario_name","speed_mps","CD","CY","CL","Cl_roll","Cm","Cn", ...
    "Fx_aero_N","Fy_aero_N","Fz_aero_N","Mx_aero_Nm","My_aero_Nm","Mz_aero_Nm", ...
    "aero_frame","aero_reference_point_B_m","time_s","phase_rad", ...
    "yaw_deg","pitch_deg","roll_deg","a_x","a_y","a_z", ...
    "omega_x","omega_y","omega_z","alpha_x","alpha_y","alpha_z"];
end

function row=localEmptyRow()
row=struct('scenario_id',"",'scenario_name',"",'aero_source_mode',"", ...
    'speed_mps',NaN,'CD',NaN,'CY',NaN,'CL',NaN,'Cl_roll',NaN,'Cm',NaN,'Cn',NaN, ...
    'R_TB',{{eye(3)}},'motion_mode',"",'a_C_T_mps2',{{zeros(3,1)}}, ...
    'omega_T_radps',{{zeros(3,1)}},'alpha_T_radps2',{{zeros(3,1)}}, ...
    'aero_force_input',{{zeros(3,1)}},'aero_moment_input',{{zeros(3,1)}}, ...
    'aero_input_frame',"T",'aero_reference_point_B_m',{{zeros(3,1)}}, ...
    'motion_phase_rad',NaN,'time_s',NaN,'metadata',{{struct()}});
end

function v=localExpand3(v)
v=double(v(:));if isscalar(v),v=repmat(v,3,1);end
if numel(v)~=3,error('msbsreq:InvalidHarmonicInput','Harmonic phase inputs must be scalar or 3-vector.');end
end

function value=localTableString(T,i,name,default)
if ismember(name,T.Properties.VariableNames),value=string(T.(name)(i));else,value=string(default);end
end

function value=localTableNumber(T,i,name,default)
if ismember(name,T.Properties.VariableNames),value=T.(name)(i);else,value=default;end
end
