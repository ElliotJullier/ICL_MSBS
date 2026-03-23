function set_plane_axis_labels(ax, r)
% Applies useful axis labels for plane plots.

if isfield(r, 'plane')
    switch lower(char(string(r.plane)))
        case "xy"
            xlabel(ax, '$x$ [m]', 'Interpreter', 'latex');
            ylabel(ax, '$y$ [m]', 'Interpreter', 'latex');
            zlabel(ax, '');
        case "xz"
            xlabel(ax, '$x$ [m]', 'Interpreter', 'latex');
            ylabel(ax, '$z$ [m]', 'Interpreter', 'latex');
            zlabel(ax, '');
        case "yz"
            xlabel(ax, '$y$ [m]', 'Interpreter', 'latex');
            ylabel(ax, '$z$ [m]', 'Interpreter', 'latex');
            zlabel(ax, '');
        otherwise
            xlabel(ax, '$x$ [m]', 'Interpreter', 'latex');
            ylabel(ax, '$y$ [m]', 'Interpreter', 'latex');
            zlabel(ax, '$z$ [m]', 'Interpreter', 'latex');
    end
else
    xlabel(ax, '$x$ [m]', 'Interpreter', 'latex');
    ylabel(ax, '$y$ [m]', 'Interpreter', 'latex');
    zlabel(ax, '$z$ [m]', 'Interpreter', 'latex');
end
end