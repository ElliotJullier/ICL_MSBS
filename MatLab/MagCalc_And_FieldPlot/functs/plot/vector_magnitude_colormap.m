function colors = vector_magnitude_colormap(count)
%VECTOR_MAGNITUDE_COLORMAP Sequential navy-blue-gold; no signed-field grey.
if nargin<1, count=32; end
anchors=[.035 .10 .25;.06 .24 .46;.10 .43 .64;.39 .64 .70;.76 .75 .40;.97 .69 .12];
colors=interp1(linspace(0,1,size(anchors,1)),anchors,linspace(0,1,count));
end
