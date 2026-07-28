function cfg = resolveConfig(rawCfg)
%RESOLVECONFIG Merge user configuration with defaults and resolve frame cases.
arguments
    rawCfg (1,1) struct
end

cfg = localMerge(msbsreq.defaultConfig(), rawCfg);

cfg.meta.case_id = string(cfg.meta.case_id);
cfg.meta.description = string(cfg.meta.description);
cfg.tunnel.cross_section.type = lower(string(cfg.tunnel.cross_section.type));
cfg.tunnel.air.mode = lower(string(cfg.tunnel.air.mode));
cfg.geometry.type = lower(string(cfg.geometry.type));
cfg.geometry.sizing.mode = lower(string(cfg.geometry.sizing.mode));
cfg.magnets.mode = lower(string(cfg.magnets.mode));
cfg.magnets.remanence_selection = lower(string(cfg.magnets.remanence_selection));
cfg.motion.mode = lower(string(cfg.motion.mode));
cfg.combinations.strategy = lower(string(cfg.combinations.strategy));
cfg.magnetic.model = lower(string(cfg.magnetic.model));

cfg.tunnel.speed = localResolveRange(cfg.tunnel.speed);
cfg.aero.CD = localResolveRange(cfg.aero.CD);
cfg.aero.CL = localResolveRange(cfg.aero.CL);
cfg.aero.Cm = localResolveRange(cfg.aero.Cm);

tunnelYpr = localYprRow(cfg.frames.tunnel_to_earth.yaw_pitch_roll_deg, ...
    'frames.tunnel_to_earth.yaw_pitch_roll_deg');
bodyYpr = localYprRow(cfg.frames.body_to_tunnel.yaw_pitch_roll_deg, ...
    'frames.body_to_tunnel.yaw_pitch_roll_deg');
cfg.frames.tunnel_to_earth.yaw_pitch_roll_deg = tunnelYpr;
cfg.frames.body_to_tunnel.yaw_pitch_roll_deg = bodyYpr;
cfg.frames.R_ET = msbsreq.rotationZYX(tunnelYpr, "deg");
cfg.frames.R_TB_nominal = msbsreq.rotationZYX(bodyYpr, "deg");
cfg.frames.R_TW_nominal = double(cfg.frames.wind_to_tunnel.R_TW);
cfg.frames.body_origin_T_m = double(cfg.frames.body_origin_T_m(:));

if isempty(cfg.frames.body_attitude_cases)
    cfg.frames.body_attitude_cases = struct( ...
        'name', "nominal", ...
        'yaw_pitch_roll_deg', double(cfg.frames.body_to_tunnel.yaw_pitch_roll_deg), ...
        'R_TB', cfg.frames.R_TB_nominal);
else
    for i = 1:numel(cfg.frames.body_attitude_cases)
        current = cfg.frames.body_attitude_cases(i);
        if ~isfield(current, 'name') || strlength(string(current.name)) == 0
            cfg.frames.body_attitude_cases(i).name = "body_" + i;
        else
            cfg.frames.body_attitude_cases(i).name = string(current.name);
        end
        if isfield(current, 'R_TB') && ~isempty(current.R_TB)
            cfg.frames.body_attitude_cases(i).R_TB = double(current.R_TB);
            if ~isfield(current, 'yaw_pitch_roll_deg')
                cfg.frames.body_attitude_cases(i).yaw_pitch_roll_deg = [NaN NaN NaN];
            end
        else
            if ~isfield(current, 'yaw_pitch_roll_deg') || isempty(current.yaw_pitch_roll_deg)
                error('msbsreq:MissingBodyAttitude', ...
                    'Each body-attitude case requires R_TB or yaw_pitch_roll_deg.');
            end
            ypr = localYprRow(current.yaw_pitch_roll_deg, ...
                "body attitude "+cfg.frames.body_attitude_cases(i).name);
            cfg.frames.body_attitude_cases(i).yaw_pitch_roll_deg = ypr;
            cfg.frames.body_attitude_cases(i).R_TB = msbsreq.rotationZYX(ypr, "deg");
        end
    end
end

if isempty(cfg.frames.wind_orientation_cases)
    cfg.frames.wind_orientation_cases = struct( ...
        'name', "nominal", 'R_TW', cfg.frames.R_TW_nominal);
else
    for i = 1:numel(cfg.frames.wind_orientation_cases)
        current = cfg.frames.wind_orientation_cases(i);
        if ~isfield(current, 'name') || strlength(string(current.name)) == 0
            cfg.frames.wind_orientation_cases(i).name = "wind_" + i;
        else
            cfg.frames.wind_orientation_cases(i).name = string(current.name);
        end
        cfg.frames.wind_orientation_cases(i).R_TW = double(current.R_TW);
    end
end
end

function out = localMerge(defaultValue, userValue)
out = defaultValue;
if ~isstruct(userValue)
    out = userValue;
    return
end
fields = fieldnames(userValue);
for i = 1:numel(fields)
    name = fields{i};
    if isfield(out, name) && isstruct(out.(name)) && isscalar(out.(name)) && ...
            isstruct(userValue.(name)) && isscalar(userValue.(name))
        out.(name) = localMerge(out.(name), userValue.(name));
    else
        out.(name) = userValue.(name);
    end
end
end

function ypr = localYprRow(value,name)
ypr=double(value(:).');
if numel(ypr)~=3 || any(~isfinite(ypr))
    error('msbsreq:InvalidEulerAngles','%s must contain finite [yaw pitch roll].',name);
end
end

function spec = localResolveRange(value)
if isnumeric(value) && isscalar(value)
    spec = msbsreq.rangeSpec(double(value), [], "absolute");
    return
end
if ~isstruct(value)
    error('msbsreq:InvalidRange', 'Range inputs must be scalar values or range structs.');
end
if isfield(value, 'nominal') && isfield(value, 'lower') && isfield(value, 'upper')
    nominal = double(value.nominal);
    lower = double(value.lower);
    upper = double(value.upper);
    if lower > upper
        error('msbsreq:InvalidRange', 'Range lower bound exceeds upper bound.');
    end
    spec = struct('nominal', nominal, 'lower', lower, 'upper', upper, ...
        'hasVariation', lower ~= upper, 'variation', [], 'variationMode', "explicit");
    return
end
error('msbsreq:InvalidRange', 'Range struct must contain nominal, lower, and upper.');
end
