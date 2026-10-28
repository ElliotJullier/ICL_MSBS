function test_colour_scale_classes()
%TEST_COLOUR_SCALE_CLASSES Independent scales, shared residuals and overrides.
project=fileparts(fileparts(mfilename("fullpath"))); addpath(genpath(fullfile(project,"functs")));
old=get(groot,"defaultFigureVisible"); set(groot,"defaultFigureVisible","off");
cleanup=onCleanup(@()finish(old)); %#ok<NASGU>
Q={fixture("Ordinary field",1e4,"field",false), ...
   fixture("Difference A",.01,"field",true),fixture("Difference B",.03,"field",true), ...
   fixture("Ordinary gradient",100,"gradient",false), ...
   fixture("Gradient difference A",.001,"gradient",true),fixture("Gradient difference B",.002,"gradient",true)};
records=build_plot_records_from_Q(Q); style=plotStyle(); style.writeMetadata=false;
resolved=resolve_plot_colour_limits(records,style);
assert(isequal(resolved.clim.field,[-1e4 1e4]));
assert(isequal(resolved.clim.fieldDifference,[-.03 .03]));
assert(isequal(resolved.clim.gradient,[-100 100]));
assert(isequal(resolved.clim.gradientDifference,[-.002 .002]));
a=select_plot_colour_scale(resolved,records(2)); b=select_plot_colour_scale(resolved,records(3));
assert(isequal(a.clim.field,b.clim.field) && a.colourScaleClass=="fieldDifference");
assert(isequal(a.clim.field,[-.03 .03]));
a=select_plot_colour_scale(resolved,records(5));
assert(a.gradientColorLimitReport.threshold==.002);
manual=style; manual.clim=struct("field",[-2 2],"gradient",[-3 3]);
resolved=resolve_plot_colour_limits(records,manual);
assert(isequal(resolved.clim.field,[-2 2]) && isequal(resolved.clim.fieldDifference,[-.03 .03]));
assert(isequal(resolved.clim.gradient,[-3 3]) && isequal(resolved.clim.gradientDifference,[-.002 .002]));
manual.clim=struct("fieldDifference",[-.1 .1],"gradientDifference",[-.02 .02]);
resolved=resolve_plot_colour_limits(records,manual);
assert(isequal(resolved.clim.field,[-1e4 1e4]) && isequal(resolved.clim.fieldDifference,[-.1 .1]));
assert(isequal(resolved.clim.gradientDifference,[-.02 .02]));
try
 select_plot_colour_scale(resolved,records(1:2)); error("Expected mixed-class rejection.");
catch e
 assert(string(e.identifier)=="MSBS:MixedColourScales");
end
r=records{2}; r.synthetic.weights=.1; r.synthetic.inputCases=struct([]);
r.caseName="Difference mentioned in a name only";
assert(plot_colour_scale_class(r)=="field");
r.synthetic.inputCases=struct("sourceIndex",1,"synthetic",struct("type","difference"));
assert(plot_colour_scale_class(r)=="fieldDifference");
r.caseMeta.isDifference=false; assert(plot_colour_scale_class(r)=="field");
r.query.plot.isDifference=true; assert(plot_colour_scale_class(r)=="fieldDifference");
r=records{2}; r.model="synthetic_difference"; r=rmfield(r,"synthetic");
assert(plot_colour_scale_class(r)=="fieldDifference");

plot_field(Q,style); figs=findall(groot,"Type","figure"); assert(numel(figs)==6);
counts=struct("field",0,"fieldDifference",0,"gradient",0,"gradientDifference",0);
expected=resolve_plot_colour_limits(records,style);
for f=figs.'
 key=getappdata(f,"MSBSColourScaleClass");
 bar=findall(f,"Type","colorbar");
 assert(isequal(bar.Limits,expected.clim.(key)));
 counts.(key)=counts.(key)+1;
 if startsWith(key,"gradient")
     report=getappdata(f,"MSBSGradientColorLimitReport");
     assert(report.threshold==expected.gradientColorLimitReports.(key).threshold);
 end
end
assert(counts.fieldDifference==2 && counts.gradientDifference==2);
assert(Q{1}.results{1}.data(1)==1e4 && Q{2}.results{1}.data(1)==.01);
fprintf("PASS: independent ordinary/difference scales, shared differences, independent gradient caps, manual overrides and classification.\n");
end
function qcase=fixture(name,value,quantity,isDifference)
query=create_plane_field_query("xy",0,"z","Group",name);
query.quantity=quantity;
[X,Y]=meshgrid([-1 1],[-1 1]);
label="Bz"; if quantity=="gradient", label="dBz/dz"; end
r=struct("queryIndex",1,"X",X,"Y",Y,"Z",zeros(2),"data",value*ones(2),"dataName",label,"plot",query.plot);
qcase=struct("meta",struct("caseName",name,"model","comsol_precomputed","source","fixture"), ...
    "geometry",struct("coil",struct([])),"queries",{{query}},"results",{{r}});
if isDifference
 qcase.meta.model="virtual_field";
 qcase.synthetic=struct("type","weighted_transformed_sum","weights",[1 -1]);
end
end
function finish(old)
close all; set(groot,"defaultFigureVisible",old);
end
