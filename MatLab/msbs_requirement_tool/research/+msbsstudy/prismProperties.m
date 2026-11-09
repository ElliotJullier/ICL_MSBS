function [volume,centre,I] = prismProperties(xz,span)
%PRISMPROPERTIES Exact unit-density properties of a polygon extruded in y.
next=xz([2:end 1],:);
x=xz(:,1);z=xz(:,2);X=next(:,1);Z=next(:,2);
w=x.*Z-X.*z;
w=w*sign(sum(w));
area=sum(w)/2;
cx=sum((x+X).*w)/(6*area);
cz=sum((z+Z).*w)/(6*area);
volume=area*span;
centre=[cx;0;cz];
xx=span*sum((x.^2+x.*X+X.^2).*w)/12-volume*cx^2;
zz=span*sum((z.^2+z.*Z+Z.^2).*w)/12-volume*cz^2;
xz=span*sum((2*x.*z+x.*Z+X.*z+2*X.*Z).*w)/24-volume*cx*cz;
yy=volume*span^2/12;
I=[yy+zz 0 -xz;0 xx+zz 0;-xz 0 xx+yy];
end
