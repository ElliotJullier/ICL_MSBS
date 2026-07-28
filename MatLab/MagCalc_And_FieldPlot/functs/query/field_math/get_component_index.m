function componentIndex = get_component_index(component)
%GET_B_COMPONENT_INDEX Convert a magnetic-field component name to its array index.
%
%   componentIndex = get_B_component_index(component)
%
%   Accepted inputs:
%       "x", 'x', "X", 'X'  -> 1
%       "y", 'y', "Y", 'Y'  -> 2
%       "z", 'z', "Z", 'Z'  -> 3
%
%   The dataset stores magnetic field data as:
%       dataset.B(y, x, z, component, fieldSet)
%
%   with:
%       component = 1 -> Bx
%       component = 2 -> By
%       component = 3 -> Bz

component = lower(string(component));

switch component
    case "x"
        componentIndex = 1;
    case "y"
        componentIndex = 2;
    case "z"
        componentIndex = 3;
    otherwise
        error('Magnetic-field component must be "x", "y", or "z".');
end
end