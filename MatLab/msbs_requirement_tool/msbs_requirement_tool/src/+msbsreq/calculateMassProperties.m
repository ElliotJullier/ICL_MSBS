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
if isempty(cfg.mass.total_mass_override_kg)
    totalMass = cfg.mass.shell_mass_factor*magnetMassTotal;
    totalMassSource = "shell_mass_factor";
else
    totalMass = cfg.mass.total_mass_override_kg;
    totalMassSource = "override";
end
if totalMass < magnetMassTotal-1e-12
    error('msbsreq:MassBelowMagnetMass', ...
        'Total mass cannot be smaller than the summed magnet mass.');
end
shellMass = max(0,totalMass-magnetMassTotal);
shellCentre = [0;0;0];

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
    centreSource = "hybrid_model";
else
    centreOfMass = cfg.mass.centre_of_mass_override_B_m(:);
    centreSource = "override";
end

if isempty(cfg.mass.inertia_override_B_kgm2)
    I = localOuterInertia(geometry,shellMass);
    rShell = shellCentre-centreOfMass;
    I = I + shellMass*((rShell.'*rShell)*eye(3)-rShell*rShell.');
    for i=1:numel(magnets)
        d=magnets(i).dimensions_local_m;
        m=magnets(i).mass_kg;
        I_local=m/12*diag([d(2)^2+d(3)^2,d(1)^2+d(3)^2,d(1)^2+d(2)^2]);
        I_body=magnets(i).R_BM*I_local*magnets(i).R_BM.';
        r=magnets(i).centre_B_m-centreOfMass;
        I=I+I_body+m*((r.'*r)*eye(3)-r*r.');
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
