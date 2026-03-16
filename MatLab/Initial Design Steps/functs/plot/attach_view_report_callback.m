function attach_view_report_callback(ax)

fig = ancestor(ax, 'figure');
fig.WindowButtonUpFcn = @(~,~) report_view(ax);

end

function report_view(ax)
[vaz, vel] = view(ax);
disp("View updated: azimuth = " + num2str(vaz) + ", elevation = " + num2str(vel));
end
