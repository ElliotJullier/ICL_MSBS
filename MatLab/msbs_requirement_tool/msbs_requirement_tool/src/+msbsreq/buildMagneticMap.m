function map = buildMagneticMap(magnetSet, R_TB, centreOfMassB)
%BUILDMAGNETICMAP Build the 6-by-8 magnetic influence matrix by basis evaluation.
arguments
    magnetSet (1,1) struct
    R_TB (3,3) double {mustBeFinite}
    centreOfMassB (3,1) double {mustBeFinite}
end
n=numel(magnetSet.magnets);
positions=zeros(3,n); dipoles=zeros(3,n);
for i=1:n
    positions(:,i)=R_TB*(magnetSet.magnets(i).centre_B_m-centreOfMassB);
    dipoles(:,i)=R_TB*magnetSet.magnets(i).dipole_moment_B_Am2;
end
A=zeros(6,8);
for j=1:8
    basis=zeros(8,1); basis(j)=1;
    A(:,j)=msbsreq.evaluateMagneticWrench(basis,positions,dipoles);
end
singularValues=svd(A);
mapRank=rank(A);
positive=singularValues(singularValues>max(size(A))*eps(max(singularValues,[],'omitnan')));
if numel(positive)>=2
    conditionNumber=max(positive)/min(positive);
elseif numel(positive)==1
    conditionNumber=1;
else
    conditionNumber=Inf;
end
map=struct();
map.A=A;
map.rank=mapRank;
map.singular_values=singularValues;
map.condition_number=conditionNumber;
map.left_null_space=null(A.');
map.positions_T_m=positions;
map.dipoles_T_Am2=dipoles;
map.magnet_set_id=magnetSet.id;
end
