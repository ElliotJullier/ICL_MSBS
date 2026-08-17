function cfg = resolveConfig(rawCfg)
%RESOLVECONFIG Merge user configuration with defaults and resolve fixed frames.
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
cfg.geometry.aero_reference_area.mode = lower(string(cfg.geometry.aero_reference_area.mode));
cfg.geometry.aero_reference_length.mode = lower(string(cfg.geometry.aero_reference_length.mode));
cfg.geometry.aero_reference_span.mode = lower(string(cfg.geometry.aero_reference_span.mode));
cfg.aero.mode = lower(string(cfg.aero.mode));
cfg.aero.direct_wrench_frame = upper(string(cfg.aero.direct_wrench_frame));
cfg.magnets.mode = lower(string(cfg.magnets.mode));
cfg.magnets.remanence_selection = lower(string(cfg.magnets.remanence_selection));
cfg.motion.mode = lower(string(cfg.motion.mode));
cfg.motion.frame = upper(string(cfg.motion.frame));
cfg.magnetic.model = lower(string(cfg.magnetic.model));

cfg.tunnel.speed_mps = double(cfg.tunnel.speed_mps);
for name = ["CD","CY","CL","Cl_roll","Cm","Cn"]
    cfg.aero.(name) = double(cfg.aero.(name));
end

tunnelYpr = localYprRow(cfg.frames.tunnel_to_earth.yaw_pitch_roll_deg, ...
    'frames.tunnel_to_earth.yaw_pitch_roll_deg');
bodyYpr = localYprRow(cfg.frames.body_to_tunnel.yaw_pitch_roll_deg, ...
    'frames.body_to_tunnel.yaw_pitch_roll_deg');
cfg.frames.tunnel_to_earth.yaw_pitch_roll_deg = tunnelYpr;
cfg.frames.body_to_tunnel.yaw_pitch_roll_deg = bodyYpr;
cfg.frames.R_ET = msbsreq.rotationZYX(tunnelYpr, "deg");
cfg.frames.R_TB_nominal = msbsreq.rotationZYX(bodyYpr, "deg");
cfg.frames.body_origin_T_m = double(cfg.frames.body_origin_T_m(:));
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
