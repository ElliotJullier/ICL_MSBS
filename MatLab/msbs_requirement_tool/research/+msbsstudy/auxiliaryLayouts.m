function sets = auxiliaryLayouts(envelope,centre,volumeFraction)
%AUXILIARYLAYOUTS Five disjoint source-inspired layouts, equal magnet volume.
% 3 automatic main-magnet axes per layout; auxiliary pair has zero net dipole.
% All dimensions/centres lie in an analytically valid inscribed cuboid.
d=envelope(:);c=centre(:); sets=struct([]); ii=0;
for layout=1:5
    if layout<=2
        dims={[.9;.4;.9],[.9;.22;.9],[.9;.22;.9]};
        pts={[0;0;0],[0;.37;0],[0;-.37;0]};
        p=[0;0;1];if layout==2,p=[0;1;0];end
        dirs={[],p,-p};
    elseif layout<=4
        dims={[.9;.9;.4],[.9;.9;.22],[.9;.9;.22]};
        pts={[0;0;0],[0;0;.37],[0;0;-.37]};
        p=[0;1;0];if layout==4,p=[0;0;1];end
        dirs={[],p,-p};
    else
        dims={[.95;.32;.32],[.95;.32;.32],[.95;.32;.32],[.95;.32;.32],[.95;.32;.32]};
        pts={[0;0;0],[0;.34;0],[0;-.34;0],[0;0;.34],[0;0;-.34]};
        dirs={[],[0;0;1],[0;0;-1],[0;1;0],[0;-1;0]};
    end
    % Each layout gets the same total volume, 0.4864 of envelope volume.
    rawVolume=sum(cellfun(@prod,dims)); f=(.4864/rawVolume*volumeFraction)^(1/3);
    for axis=1:3
        ii=ii+1;sets(ii).name="layout"+layout+"_main_axis"+axis;
        for k=1:numel(dims)
            m=struct('name',"magnet"+k,'dimensions_local_m',f*dims{k}.*d, ...
                'centre_B_m',c+pts{k}.*d,'R_BM',eye(3),'grade',"N52", ...
                'magnetisation_direction_M',zeros(3,1));
            if k==1,m.magnetisation_direction_M(axis)=1;else,m.magnetisation_direction_M=dirs{k};end
            sets(ii).magnets(k)=m;
        end
    end
end
end
