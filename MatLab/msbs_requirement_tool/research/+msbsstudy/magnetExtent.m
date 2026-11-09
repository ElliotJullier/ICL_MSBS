function extent = magnetExtent(magnets,R)
%MAGNETEXTENT Installed assembly bounding-box dimensions in frame R*B.
lo=inf(3,1);
hi=-lo;
for m=reshape(magnets,1,[])
    centre=R*m.centre_B_m;
    half=abs(R*m.R_BM)*m.dimensions_local_m/2;
    lo=min(lo,centre-half);
    hi=max(hi,centre+half);
end
extent=hi-lo;
end
