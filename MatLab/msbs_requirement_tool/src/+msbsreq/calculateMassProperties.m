function massProperties = calculateMassProperties(cfg, geometry, magnetSet)
%CALCULATEMASSPROPERTIES Compute hybrid magnet-plus-uniform-shell mass properties.
arguments
    cfg (1,1) struct
    geometry (1,1) struct
    magnetSet (1,1) struct
end

magnets = magnetSet.magnets;
magnetMasses = reshape([magnets.mass_kg],[],1);
magnetMassTotal = sum(magnetMasses);
solidDensity = cfg.mass.solid_abs_density_kgm3;
solidSource = "solid_abs_minus_cavities";
solidNote = "Solid ABS with full magnet volumes removed";
if ~isempty(cfg.mass.solid_body_density_kgm3)
    solidDensity = cfg.mass.solid_body_density_kgm3;
    solidSource = "solid_body_minus_cavities";
    solidNote = "Uniform solid body with full magnet volumes removed";
end
shellCentre = zeros(3,1);
if ~isempty(solidDensity)
    [shellMass,shellCentre,shellInertiaAtCentre] = localSolidMinusCavities(geometry,magnets,solidDensity);
    totalMass = shellMass+magnetMassTotal;
    totalMassSource = solidSource;
elseif isempty(cfg.mass.total_mass_override_kg)
    if isempty(cfg.mass.non_magnet_mass_kg)
        totalMass = cfg.mass.shell_mass_factor*magnetMassTotal;
        totalMassSource = "shell_mass_factor";
    else
        totalMass = magnetMassTotal + cfg.mass.non_magnet_mass_kg;
        totalMassSource = "fixed_non_magnet_mass";
    end
else
    totalMass = cfg.mass.total_mass_override_kg;
    totalMassSource = "override";
end
if totalMass < magnetMassTotal-1e-12
    error('msbsreq:MassBelowMagnetMass', ...
        'Total mass cannot be smaller than the summed magnet mass.');
end
if isempty(solidDensity)
    shellMass = max(0,totalMass-magnetMassTotal);
    shellInertiaAtCentre = localOuterInertia(geometry,shellMass);
end

weighted = shellMass*shellCentre;
for i=1:numel(magnets)
    weighted = weighted + magnets(i).mass_kg*magnets(i).centre_B_m;
end
if totalMass>0
    computedCoM = weighted/totalMass;
else
    error('msbsreq:ZeroMass','Total mass must be positive.');
end
if isempty(cfg.mass.centre_of_mass_override_B_m)
    centreOfMass = computedCoM;
    centreSource = totalMassSource;
else
    centreOfMass = cfg.mass.centre_of_mass_override_B_m(:);
    centreSource = "override";
end

if isempty(cfg.mass.inertia_override_B_kgm2)
    I = shellInertiaAtCentre+localParallelAxis(shellMass,shellCentre-centreOfMass);
    for i=1:numel(magnets)
        m=magnets(i).mass_kg;
        I=I+localMagnetInertia(magnets(i),m,centreOfMass);
    end
    inertiaSource="hybrid_model";
else
    I=cfg.mass.inertia_override_B_kgm2;
    inertiaSource="override";
end
I=(I+I.')/2;
if any(eig(I)<=0)
    error('msbsreq:InvalidCalculatedInertia','Calculated inertia tensor is not positive definite.');
end

massProperties=struct();
massProperties.magnet_set_id=magnetSet.id;
massProperties.total_mass_kg=totalMass;
massProperties.magnet_mass_kg=magnetMassTotal;
massProperties.shell_mass_kg=shellMass;
massProperties.centre_of_mass_B_m=centreOfMass;
massProperties.computed_centre_of_mass_B_m=computedCoM;
massProperties.inertia_B_kgm2=I;
massProperties.total_mass_source=totalMassSource;
massProperties.centre_of_mass_source=centreSource;
massProperties.inertia_source=inertiaSource;
massProperties.model_note="Magnets are explicit cuboids; remaining mass is uniformly distributed through the outer primitive and combined by parallel-axis shifts.";
if isempty(solidDensity)
    if isempty(cfg.mass.centre_of_mass_override_B_m)
        massProperties.centre_of_mass_source="hybrid_model";
    end
else
    massProperties.inertia_source=totalMassSource;
    massProperties.model_note=solidNote+"; rotated magnets are added using the parallel-axis theorem.";
end
end

function [mass,centre,inertia] = localSolidMinusCavities(geometry,magnets,density)
outerMass = geometry.volume_m3*density;
outerCentre = zeros(3,1);
if geometry.type=="custom"
    if ~isfield(geometry.shape,'solid_centroid_B_m') || ...
            ~isfield(geometry.shape,'solid_unit_density_inertia_B_m5')
        error('msbsreq:MissingSolidGeometry','Custom solid geometry needs a centroid and unit-density inertia.');
    end
    outerCentre = geometry.shape.solid_centroid_B_m(:);
    outerInertia = density*geometry.shape.solid_unit_density_inertia_B_m5;
else
    outerInertia = localOuterInertia(geometry,outerMass);
end
mass = outerMass;
firstMoment = outerMass*outerCentre;
inertiaAtOrigin = outerInertia+localParallelAxis(outerMass,outerCentre);
for i=1:numel(magnets)
    for j=1:i-1
        if localCavitiesOverlap(magnets(i),magnets(j))
            error('msbsreq:OverlappingSolidCavities','Solid ABS magnet cavities must be disjoint.');
        end
    end
    cavityMass = magnets(i).volume_m3*density;
    mass = mass-cavityMass;
    firstMoment = firstMoment-cavityMass*magnets(i).centre_B_m;
    inertiaAtOrigin = inertiaAtOrigin-localMagnetInertia(magnets(i),cavityMass,zeros(3,1));
end
if ~(isfinite(mass) && mass>0)
    error('msbsreq:InvalidCavityMass','Magnet cavities must leave positive ABS mass.');
end
centre = firstMoment/mass;
inertia = inertiaAtOrigin-localParallelAxis(mass,centre);
end

function overlap = localCavitiesOverlap(a,b)
% Separating axis test for two oriented boxes. Contact has zero overlap volume.
axes = [a.R_BM b.R_BM];
for i=1:3
    for j=1:3
        axes(:,end+1)=cross(a.R_BM(:,i),b.R_BM(:,j)); %#ok<AGROW>
    end
end
lengths=vecnorm(axes);
axes=axes(:,lengths>1e-12)./lengths(lengths>1e-12);
reach=(a.dimensions_local_m.'*abs(a.R_BM.'*axes)+ ...
    b.dimensions_local_m.'*abs(b.R_BM.'*axes))/2;
separation=abs((a.centre_B_m-b.centre_B_m).'*axes);
overlap=all(separation<reach-1e-12);
end

function inertia = localMagnetInertia(magnet,mass,aboutPoint)
d = magnet.dimensions_local_m;
I = mass/12*diag(sum(d.^2)-d.^2);
inertia = magnet.R_BM*I*magnet.R_BM.'+localParallelAxis(mass,magnet.centre_B_m-aboutPoint);
end

function inertia = localParallelAxis(mass,r)
inertia = mass*((r.'*r)*eye(3)-r*r.');
end

function I=localOuterInertia(geometry,mass)
if mass==0
    I=zeros(3); return
end
switch geometry.type
    case {"cuboid","flat_plate","custom"}
        d=geometry.outer_dimensions_B_m;
        I=mass/12*diag([d(2)^2+d(3)^2,d(1)^2+d(3)^2,d(1)^2+d(2)^2]);
    case "sphere"
        R=geometry.shape.diameter_m/2;
        I=(2/5*mass*R^2)*eye(3);
    case "ellipsoid"
        a=geometry.shape.diameters_m(1)/2;
        b=geometry.shape.diameters_m(2)/2;
        c=geometry.shape.diameters_m(3)/2;
        I=mass/5*diag([b^2+c^2,a^2+c^2,a^2+b^2]);
    case "cylinder"
        R=geometry.shape.diameter_m/2; L=geometry.shape.length_m;
        Iax=0.5*mass*R^2; Itr=mass*(3*R^2+L^2)/12;
        switch geometry.shape.axis
            case "x", I=diag([Iax,Itr,Itr]);
            case "y", I=diag([Itr,Iax,Itr]);
            case "z", I=diag([Itr,Itr,Iax]);
        end
end
end
