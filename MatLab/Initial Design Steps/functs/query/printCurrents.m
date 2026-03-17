function printCurrents(coils, I_use, isOverridden)

fprintf('\nCurrents used:\n');

for k = 1:numel(I_use)
    if exist('coils', 'var') && numel(coils) >= k && isfield(coils, 'name') && ~isempty(coils(k).name)
        coilLabel = string(coils(k).name);
    else
        coilLabel = "coil " + string(k-1);
    end

    fprintf('%s: %.6g A\n', coilLabel, I_use(k));
end

if isOverridden
    fprintf('(Current vector overridden manually)\n\n');
else
    fprintf('(Current vector solved using lsqminnorm)\n\n');
end
end