function q = validate_and_complete_query(q, model)
%VALIDATE_AND_COMPLETE_QUERY Fill defaults and validate one query.
%
% This function is the public contract for the internal query structure. It
% fills optional fields, validates common fields, then checks whether the
% selected model can evaluate the requested query.

if ~isfield(q, "type")
    error("Query is missing q.type.");
end
if ~isfield(q, "quantity")
    q.quantity = "field";
end
if ~isfield(q, "component")
    error("Query is missing q.component.");
end

q.type = lower(string(q.type));
q.quantity = lower(string(q.quantity));

% Keep the analytical simple Biot-Savart contract unchanged.
if lower(string(model)) ~= "simple_biotsavart"
    q.fieldDirection = normalise_direction(q.component);
    if isnumeric(q.component), q.component = q.fieldDirection; end
    if q.type == "custom_plane", q.normal = normalise_direction(q.normal); end
    if q.quantity == "gradient"
        if ~isfield(q,"gradientDirection"), q.gradientDirection = []; end
        if ~isempty(q.gradientDirection)
            q.gradientDirection = normalise_direction(q.gradientDirection);
        end
    end
end

if ~isfield(q, "name")
    q.name = "";
end
q.name = string(q.name);

if ~isfield(q, "plot") || isempty(q.plot)
    q.plot = struct();
end
if ~isfield(q.plot, "group")
    q.plot.group = [];
end
if ~isfield(q.plot, "inOverview")
    q.plot.inOverview = false;
end
q.plot.inOverview = logical(q.plot.inOverview);

if ~isfield(q.plot, "showCoils")
    q.plot.showCoils = false;
end
q.plot.showCoils = logical(q.plot.showCoils);

validate_query_fields(q);
validate_query_for_model(q, model);
end

function validate_query_fields(q)
switch q.type
    case "line"
        required = ["start", "end", "nPoints"];
    case "fundamental_plane"
        required = ["plane", "planeOffset"];
        if ~any(lower(string(q.plane)) == ["xy", "xz", "yz"])
            error('q.plane must be "xy", "xz", or "yz".');
        end
    case "custom_plane"
        required = ["point", "normal", "resolution"];
    otherwise
        error("Unknown query type: %s", q.type);
end

if q.type=="line"
    validateattributes(q.start,{'numeric'},{'real','finite','numel',3});
    validateattributes(q.end,{'numeric'},{'real','finite','numel',3});
    validateattributes(q.nPoints,{'numeric'},{'scalar','integer','>=',2});
    if norm(q.end(:)-q.start(:))==0, error("MSBS:Line","Line endpoints must differ."); end
elseif q.type=="custom_plane"
    validateattributes(q.point,{'numeric'},{'real','finite','numel',3});
    validateattributes(q.resolution,{'numeric'},{'real','finite','integer','>=',2});
    if ~any(numel(q.resolution)==[1 2]), error("MSBS:Resolution","Use one or two resolutions."); end
    for name=["uLimits","vLimits"]
        if isfield(q,name) && ~isempty(q.(name))
            validateattributes(q.(name),{'numeric'},{'real','finite','numel',2});
            if q.(name)(2)<=q.(name)(1), error("MSBS:PlaneLimits","Plane limits must increase."); end
        end
    end
elseif q.type=="fundamental_plane"
    validateattributes(q.planeOffset,{'numeric'},{'real','finite','scalar'});
end

for k = 1:numel(required)
    if ~isfield(q, required(k))
        error("Query of type '%s' is missing q.%s.", q.type, required(k));
    end
end

if q.quantity == "gradient"
    if ~isfield(q, "gradientDirection")
        q.gradientDirection = [];
    end
    if q.type ~= "line" && isempty(q.gradientDirection)
        error("GradientDirection is required for non-line gradient queries.");
    end
elseif q.quantity ~= "field"
    error("q.quantity must be 'field' or 'gradient'.");
end
end
