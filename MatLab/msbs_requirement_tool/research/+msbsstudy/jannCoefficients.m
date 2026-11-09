function C = jannCoefficients(alphaDeg,betaDeg)
%JANNCOEFFICIENTS [CD CY CL Cl Cm Cn], Tables 2 (p11) and 8 (p17).
% Source moment axes: x upstream, z downward; source forces: D,Y,L.
a=deg2rad(alphaDeg);
if betaDeg==0
    h=2:2:16;
    cd=.8395+sum([-.3418 -.0972 -.0165 .0034 -.0148 .0028 -.0033 .0032].*cos(h*a));
    cl=sum([.4786 -.0476 .0223 -.0307 .0050 -.0113 -.0098 .0012].*sin(h*a));
    cm=sum([.0559 -.0436 -.0195 -.0152 -.0089 -.0048 -.0004 .0001].*sin(h*a));
    C=[cd 0 cl 0 cm 0];
elseif betaDeg==-45
    h=2:2:16;
    cd=.8446+sum([-.2042 -.0589 -.0176 -.0071 -.0005 .0005 -.0009 -.0014].*cos(h*a));
    cy=-.1626+sum([.2303 .0217 .0094 .0054 .0031 .0031 -.0011 -.0004].*cos(h*a));
    cl=sum([.3461 .1240 .0419 .0172 .0002 -.0014 .0042 -.0001].*sin(h*a));
    cr=sum([.0428 0 .0010 0 .0070 0 .0057 -.0001].*sin((1:8)*a));
    cm=sum([.0463 .0088 .0105 .0056 .0012 .0002 -.0003 .0006].*sin(h*a));
    cn=sum([.0189 -.0001 -.0045 .0001 -.0020 0 .0019 -.0001].*cos((1:8)*a));
    C=[cd cy cl cr cm cn];
else
    error('msbsstudy:UnsupportedSlice','Only the transcribed beta=0 or -45 deg slices are supported.');
end
end
