function sets = cappedMagnets(geometry, side, attitudes, fraction, auxiliary)
%CAPPEDMAGNETS Capped, physically rotated blocks in a certified fit envelope.
% Extents include all corners of every magnet in B and every tested T pose.
arguments
    geometry (1,1) struct
    side (1,1) double {mustBePositive}
    attitudes (1,:) cell
    fraction (1,1) double {mustBePositive}
    auxiliary (1,1) logical
end
d = .95*geometry.inscribed_cuboid.dimensions_B_m;
c = geometry.inscribed_cuboid.centre_B_m;
if isfield(geometry.shape,'review_fit_dimensions_m')
    d=.95*geometry.shape.review_fit_dimensions_m;
end
cap=.30*side;
rotations={eye(3),msbsreq.rotationZYX([90 0 0],"deg"), ...
    msbsreq.rotationZYX([0 -90 0],"deg"),msbsreq.rotationZYX([30 0 0],"deg"), ...
    msbsreq.rotationZYX([0 -30 0],"deg"),attitudes{end}.'};
names=["body_x","body_y","body_z","body_xy30","body_xz30","tunnel_x_at_last_pose"];
sets=struct([]);
for k=1:numel(names)
    R=rotations{k};
    if k>1 && any(cellfun(@(A) norm(A(:,1)-R(:,1))<1e-9,rotations(1:k-1)))
        continue
    end
    % Signed axis permutations fill the same prism. Oblique blocks are
    % uniformly reduced until their rotated corners fit that prism.
    if all(abs(abs(R(:))-round(abs(R(:))))<1e-10)
        dimensions=abs(R).'*min(d,cap);
    else
        dimensions=min(d,cap);
        dimensions=dimensions*min(1,min(d./(abs(R)*dimensions)));
    end
    m=struct('name',"main",'dimensions_local_m',dimensions,'centre_B_m',c, ...
        'R_BM',R,'grade',"N52",'magnetisation_direction_M',[1;0;0]);
    sets(end+1).name="single_"+names(k); %#ok<AGROW>
    sets(end).magnets=m;
end
if auxiliary
    sets=[sets msbsstudy.auxiliaryLayouts(min(d,cap),c,1)];
    % Auxiliary source candidates were specified in B. Re-express every
    % cuboid with its magnetisation along its own +x axis.
    for k=1:numel(sets)
        for j=1:numel(sets(k).magnets)
            m=sets(k).magnets(j);
            if norm(m.magnetisation_direction_M-[1;0;0])<1e-12,continue,end
            a=m.magnetisation_direction_M;
            e=eye(3);b=e(:,find(abs(a)<.5,1));
            R=[a b cross(a,b)];
            m.dimensions_local_m=abs(R).'*m.dimensions_local_m;
            m.R_BM=R;
            m.magnetisation_direction_M=[1;0;0];
            sets(k).magnets(j)=m;
        end
    end
end
for k=1:numel(sets)
    m=sets(k).magnets;
    allPoses=[{eye(3)} attitudes];
    extent=max(cellfun(@(R) max(msbsstudy.magnetExtent(m,R)),allPoses));
    factor=min(1,cap/extent);
    for j=1:numel(m)
        m(j).centre_B_m=c+factor*(m(j).centre_B_m-c);
        m(j).dimensions_local_m=m(j).dimensions_local_m*factor*fraction^(1/3);
    end
    assert(all(cellfun(@(R) all(msbsstudy.magnetExtent(m,R)<=cap+1e-10),allPoses)), ...
        'msbsstudy:MagnetCap','The installed magnet envelope exceeds the cap.');
    sets(k).magnets=m;
end
end
