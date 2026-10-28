function key = plot_colour_scale_class(record)
%PLOT_COLOUR_SCALE_CLASS Separate ordinary values from difference values.
% Quantity units remain separate: field, fieldDifference, gradient,
% gradientDifference. A virtual sum/scale/rotation is not itself a difference.
isDifference=false;
if isfield(record,"model") && string(record.model)=="synthetic_difference"
    isDifference=true;
end
if isfield(record,"synthetic"), isDifference=isDifference || difference_source(record.synthetic); end
if isfield(record,"caseMeta") && isfield(record.caseMeta,"isDifference") && ~isempty(record.caseMeta.isDifference)
    validateattributes(record.caseMeta.isDifference,{'logical','numeric'},{'scalar'});
    isDifference=logical(record.caseMeta.isDifference);
end
if isfield(record,"query") && isfield(record.query,"plot") && ...
        isfield(record.query.plot,"isDifference") && ~isempty(record.query.plot.isDifference)
    validateattributes(record.query.plot.isDifference,{'logical','numeric'},{'scalar'});
    isDifference=logical(record.query.plot.isDifference);
end
quantity="field";
if isfield(record,"query") && isfield(record.query,"quantity")
    quantity=lower(string(record.query.quantity));
end
if quantity=="gradient", key="gradient"; else, key="field"; end
if isDifference, key=key+"Difference"; end
end
function yes=difference_source(s)
yes=false;
if ~isstruct(s) || isempty(s), return; end
if isfield(s,"type") && string(s.type)=="difference", yes=true; return; end
if isfield(s,"weights")
    weights=s.weights;
    if any(weights>0) && any(weights<0), yes=true; return; end
    % A scaled/rotated difference is still a difference. For multiple inputs,
    % inherit only when every active source is itself a difference.
    active=find(weights~=0);
    if ~isempty(active) && isfield(s,"inputCases") && ~isempty(s.inputCases)
        inherited=false(size(active));
        for j=1:numel(active)
            for input=s.inputCases
                if isfield(input,"sourceIndex") && input.sourceIndex==active(j) && isfield(input,"synthetic")
                    inherited(j)=difference_source(input.synthetic);
                end
            end
        end
        yes=all(inherited);
    end
end
end
